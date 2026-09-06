#!/usr/bin/env python3
"""Independent ZX sprite and save-under checks against patterned screen RAM.

Build `make -C tests/zx build` first. Checks every width/alignment for both
source strides and formats, including clipped rows and full background padding.
"""
import json
import random
import struct
from pathlib import Path

from ihx import read_entry, read_ihx
from zxmcp import Spectrum, zx_offset

ROOT = Path(__file__).resolve().parents[2]


def main():
    image = ROOT / 'bin/zx/test_sprite_align.ihx'
    symbols = image.with_suffix('.map')
    scratch = ROOT / 'build/sprite-regressions'
    scratch.mkdir(parents=True, exist_ok=True)
    base, binary = read_ihx(image)
    program = scratch / 'program.bin'
    program.write_bytes(binary)
    rng = random.Random(9367)
    original = bytes(rng.randrange(256) for _ in range(6912))
    guard = bytes([0xa5] * 8)
    cases = pixels = 0
    with Spectrum() as zx:
        zx.reset(clear_memory=True)
        zx.load_binary(program, base)

        def write(address, data):
            zx.call('write_memory', address=address, data=bytes(data).hex())

        def invoke(name, sprite=0x6100):
            write(0x7000, b'\x76')
            write(0x7f00, struct.pack('<H', 0x7000))
            zx.registers(pc=read_entry(symbols, name), sp=0x7f00,
                         hl=0, de=sprite, ix=0x1357, iy=0x2468,
                         iff1=False, iff2=False)
            result = zx.run(stop_on_halt=True, tstates=2_000_000)
            assert result.get('reason') == 'halted', result
            regs = zx.registers()
            assert (regs['sp'], regs['ix'], regs['iy']) == (0x7f02, 0x1357, 0x2468), regs

        for masked in (False, True):
            for stride in (1, 2):
                for width in range(1, 17):
                    for shift in range(8):
                        for edge in (False, True):
                            height = (1, 2, 7, 8, 9, 15, 16)[cases % 7]
                            x = (248 if edge else 40) + shift
                            y = (0, 7, 63, 64, 127, 128, 183, 191)[(cases // 2) % 8]
                            rowbytes = stride * (2 if masked else 1)
                            payload = bytes(rng.randrange(256) for _ in range(rowbytes * height))
                            bitmap = bytes([(0x10 if masked else 0) | (stride - 1), width, height]) + struct.pack('<H', len(payload)) + payload
                            write(0x4000, original)
                            write(0x6000, bitmap + guard)
                            clip = (x + 1, y + 1, x + width - 2, y + height - 2) if cases % 3 == 0 and width <= stride * 8 else None
                            if clip:
                                write(0x6300, struct.pack('<4h', *clip))
                            write(0x6100, struct.pack('<5H', x, y, 0x6000, 0x6208, 0x6300 if clip else 0))
                            write(0x6200, guard + b'\xcc' * 37 + guard)
                            expected = bytearray(original)
                            background = bytearray([1, width, height, 2 * height, 0] + [0] * 32)
                            for dy in range(min(height, 192 - y)):
                                for dx in range(min(width, 256 - x)):
                                    at, bit = zx_offset(x + dx, y + dy), 0x80 >> ((x + dx) % 8)
                                    old = bool(original[at] & bit)
                                    background[5 + dy * 2 + dx // 8] |= (0x80 >> (dx % 8)) if old else 0
                                    if clip and not (clip[0] <= x + dx <= clip[2] and clip[1] <= y + dy <= clip[3]):
                                        continue
                                    sourcebit = 0x80 >> (dx % 8)
                                    if dx // 8 < stride:
                                        andbit = bool(payload[dy * rowbytes + dx // 8] & sourcebit) if masked else True
                                        orbit = bool(payload[dy * rowbytes + (stride if masked else 0) + dx // 8] & sourcebit)
                                    else:
                                        andbit, orbit = True, False
                                    if (old and andbit) or orbit:
                                        expected[at] |= bit
                                    else:
                                        expected[at] &= 255 ^ bit
                                    pixels += 1
                            invoke('_gpx_show_sprite')
                            label = masked, stride, width, height, x, y
                            assert zx.screen(attrs=True) == expected, ('show', label)
                            assert zx.read_memory(0x6200, 53) == guard + background + guard, ('background', label)
                            invoke('_gpx_hide_sprite')
                            assert zx.screen(attrs=True) == original, ('hide', label)
                            assert zx.read_memory(0x6000, len(bitmap) + 8) == bitmap + guard, ('source', label)
                            cases += 1
        # Rejected descriptors must leave both screen and background alone.
        valid = bytes([0x11, 16, 16, 64, 0]) + bytes([0x55, 0xaa, 0x96, 0x69] * 16)
        invalid = [(256, 0, valid, 0x6000, 0x6208, 0x6100),
                   (65535, 0, valid, 0x6000, 0x6208, 0x6100),
                   (0, 192, valid, 0x6000, 0x6208, 0x6100),
                   (0, 65535, valid, 0x6000, 0x6208, 0x6100),
                   (0, 0, valid, 0, 0x6208, 0x6100),
                   (0, 0, valid, 0x6000, 0, 0x6100),
                   (0, 0, valid, 0x6000, 0x6208, 0)]
        for field, value in ((0, 0x21), (0, 0x12), (1, 0), (1, 17), (2, 0), (2, 17)):
            bad = bytearray(valid)
            bad[field] = value
            invalid.append((0, 0, bad, 0x6000, 0x6208, 0x6100))
        for x, y, bitmap, bmp_ptr, bg_ptr, sprite_ptr in invalid:
            write(0x4000, original)
            write(0x6000, bitmap)
            write(0x6100, struct.pack('<5H', x, y, bmp_ptr, bg_ptr, 0))
            write(0x6200, guard + b'\xcc' * 37 + guard)
            invoke('_gpx_show_sprite', sprite_ptr)
            assert zx.screen(attrs=True) == original, ('invalid screen', x, y, bitmap[:5])
            assert zx.read_memory(0x6200, 53) == guard + b'\xcc' * 37 + guard
            cases += 1
    result = {'cases': cases, 'pixels': pixels, 'checks': 'show/hide, full save-under, guards, IX/IY/SP'}
    (scratch / 'results.json').write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps(result))


if __name__ == '__main__':
    main()
