#!/usr/bin/env python3
"""Independent span/box pixels and public-entry ABI checks on the ZX emulator.

Build with make -C tests/zx build. The pixel model is test-only; the library
must keep its byte-span paths. Screen attributes and adjacent guards are also
compared, so an underflowed span cannot silently pass a visible-pixel check.
"""
import itertools
import random

from bitmap_regressions import ROOT, word, write
from ihx import read_entry, read_ihx
from zxmcp import Spectrum, zx_offset


def main():
    rng = random.Random(0x405)
    image = ROOT / 'bin/zx/test_bmp_gather.ihx'
    base, code = read_ihx(image)
    scratch = ROOT / 'build/mcp-scratch/span-regressions.bin'
    scratch.parent.mkdir(parents=True, exist_ok=True)
    scratch.write_bytes(code)
    names = ('fill_rectangle', 'draw_box', 'draw_rectangle', 'draw_line',
             'draw_text', 'draw_pixel')
    entries = {n: read_entry(image.with_suffix('.map'), '_gpx_' + n) for n in names}
    font = read_entry(image.with_suffix('.map'), '_gpx_font_envy')
    count = 0
    with Spectrum() as machine:
        machine.reset(clear_memory=True)
        machine.load_binary(scratch, base)
        write(machine, 0x7000, b'\x76')
        expected = bytearray(rng.randbytes(6912))
        write(machine, 0x4000, expected)
        guard = rng.randbytes(256)
        write(machine, 0x5B00, guard)

        def invoke(name, args, de=0x6000, hl=0):
            nonlocal count
            write(machine, 0xFF00, word(0x7000) + args)
            machine.registers(pc=entries[name], sp=0xFF00, hl=hl, de=de,
                              ix=0x1357, iy=0x2468, iff1=False, iff2=False)
            result = machine.run(stop_on_halt=True, tstates=40_000_000)
            assert result.get('reason') == 'halted', (name, count, result)
            regs = machine.registers()
            assert (regs['sp'], regs['ix'], regs['iy']) == (
                0xFF02 + len(args), 0x1357, 0x2468), (name, count, regs)
            assert machine.read_memory(0x5B00, 256) == guard, (name, count, 'high guard')
            count += 1
            return regs['af'] >> 8

        def pixel(x, y, bit, color, mode, clip):
            if not (0 <= x < 256 and 0 <= y < 192):
                return
            if clip and not (clip[0] <= x <= clip[2] and clip[1] <= y <= clip[3]):
                return
            offset, mask = zx_offset(x, y), 0x80 >> (x & 7)
            if mode == 1:
                if bit:
                    expected[offset] ^= mask
            elif mode == 0 or bit:
                value = color if bit else 1 - color
                expected[offset] = (expected[offset] & ~mask) | (mask if value else 0)

        def check(case):
            actual = machine.screen(attrs=True)
            assert actual == expected, (count, case, next(
                (i, a, e) for i, (a, e) in enumerate(zip(actual, expected)) if a != e))

        clips = (None, (3, 2, 251, 189), (8, 8, 7, 7), (-32768, -32768, 32767, 32767))
        rects = ((1, 1, 1, 1), (3, 7, 7, 9), (7, 63, 8, 65),
                 (255, 191, 0, 188), (-7, -3, 39, 3),
                 (-32768, -32768, 9, 3), (256, 192, 32767, 32767),
                 (0, 0, 255, 191))
        patterns = (b'\x00', b'\xFF', b'\xAA\x55', b'\x93\x00\xFF\x66\x3C')
        for rect, clip, mode, color in itertools.product(rects, clips, range(3), range(2)):
            pattern = patterns[count % len(patterns)]
            write(machine, 0x6000, b''.join(map(word, rect)))
            write(machine, 0x6100, pattern)
            if clip:
                write(machine, 0x6200, b''.join(map(word, clip)))
            args = bytes((color, mode)) + word(0x6100) + bytes((len(pattern),))
            args += word(0x6200 if clip else 0)
            invoke('fill_rectangle', args)
            x0, x1 = sorted((rect[0], rect[2]))
            y0, y1 = sorted((rect[1], rect[3]))
            for y in range(max(0, y0), min(191, y1) + 1):
                row = pattern[(y - y0) % len(pattern)]
                for x in range(max(0, x0), min(255, x1) + 1):
                    pixel(x, y, (row >> (7 - ((x - x0) & 7))) & 1, color, mode, clip)
            check(('fill', rect, clip, mode, color, pattern))

        # Deduplicate the geometric perimeter in clockwise order; this is
        # independent of the assembler's shortened-edge implementation.
        for rect, edges, mode, color in itertools.product(
                ((5, 7, 26, 8), (253, 193, -3, -2)), range(16), range(3), range(2)):
            clip = clips[count % len(clips)]
            pattern = 0x96
            write(machine, 0x6000, b''.join(map(word, rect)))
            if clip:
                write(machine, 0x6200, b''.join(map(word, clip)))
            args = bytes((edges, color, mode, pattern)) + word(0x6200 if clip else 0)
            phase = invoke('draw_box', args)
            x0, x1 = sorted((rect[0], rect[2]))
            y0, y1 = sorted((rect[1], rect[3]))
            runs = ((2, [(x, y0) for x in range(x0, x1 + 1)]),
                    (4, [(x1, y) for y in range(y0, y1 + 1)]),
                    (8, [(x, y1) for x in range(x1, x0 - 1, -1)]),
                    (1, [(x0, y) for y in range(y1, y0 - 1, -1)]))
            seen = set()
            for edge, points in runs:
                if not edges & edge:
                    continue
                for x, y in points:
                    if (x, y) in seen:
                        continue
                    seen.add((x, y))
                    pixel(x, y, pattern & 1, color, mode, clip)
                    pattern = (pattern >> 1) | ((pattern & 1) << 7)
            assert phase == pattern, (rect, edges, mode, color, phase, pattern)
            check(('box', rect, edges, mode, color))

        # Success and early-return paths must all preserve caller IX/IY and
        # pop exactly their own arguments (including rectangle's tail call).
        write(machine, 0x6000, b''.join(map(word, (8, 8, 23, 15))))
        write(machine, 0x6100, b'\xAA')
        write(machine, 0x6300, b'AB Z\0')
        for valid in (False, True):
            invoke('fill_rectangle', b'\x01\x00' + word(0x6100) + b'\x01\0\0',
                   de=0x6000 if valid else 0)
            invoke('draw_box', b'\x0F\x01\x00\x96\0\0', de=0x6000 if valid else 0)
            invoke('draw_rectangle', b'\x01\x00\x96\0\0', de=0x6000 if valid else 0)
            for y in (8, 16):
                invoke('draw_line', word(8) + word(23) + word(y) + b'\x01\x00\x96\0\0',
                       de=8 if valid else 32767)
            invoke('draw_pixel', word(8) + b'\x01\x00\0\0', de=8 if valid else 32767)
            for mode, background in itertools.product(range(3), range(2)):
                write(machine, 0x6400, bytes((0, 0, 0, 0, 0, background)))
                args = word(8) + word(0x6300 if valid else 0) + word(font)
                args += bytes((1, mode)) + word(0)
                invoke('draw_text', args, de=8, hl=0x6400)
    print(f'{count} span/box/entry cases passed: pixels, phase, attributes, guards, IX/IY/stack')


if __name__ == '__main__':
    main()
