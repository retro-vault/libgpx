#!/usr/bin/env python3
"""Exercise the ZX byte blitter against an independent per-pixel model.

Build tests/zx first. Covers every source/destination bit phase, arbitrary
AND and OR planes, internal text compositors, clipping and preserved ABI.
"""
import random
import struct
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tests/mcp'))
from ihx import read_entry, read_ihx  # noqa: E402
from zxmcp import Spectrum, zx_offset  # noqa: E402


def word(value):
    return struct.pack('<H', value & 65535)


def write(machine, address, data):
    machine.call('write_memory', address=address, data=bytes(data).hex())


def main():
    rng = random.Random(0xB17)
    image = ROOT / 'bin/zx/test_bmp_gather.ihx'
    base, code = read_ihx(image)
    entry = read_entry(image.with_suffix('.map'), '_gpx_draw_bmp_clip')
    scratch = ROOT / 'build/mcp-scratch/bitmap-regressions.bin'
    scratch.parent.mkdir(parents=True, exist_ok=True)
    scratch.write_bytes(code)
    cases = []
    # 64 independent alignments: x sets destination phase, left clip sets
    # source phase, with two source planes that have no complement relation.
    for masked in (False, True):
        for dest in range(8):
            for source in range(8):
                x = 40 + ((dest - source) % 8)
                cases.append((x, 7, 31, 5, masked, 0x80, 1,
                              (x + source, 7, x + 28, 11)))
    for masked in (False, True):
        for mode, color in ((0, 0), (0, 1), (1, 0), (1, 1),
                            (0x40, 0), (0x40, 1)):
            for phase in range(8):
                cases.append((80 + phase, 63, 23, 4, masked, mode, color, None))
    for trial in range(128):
        width = rng.choice((1, 3, 7, 8, 9, 15, 16, 17, 31, 63, 127, 128))
        height = rng.choice((1, 2, 7, 8, 17, 31))
        x = rng.choice((-32768, -127, -7, -1, 0, 1, 249, 255, 256,
                        32767, rng.randrange(256)))
        y = rng.choice((-32768, -30, -7, -1, 0, 7, 63, 127, 185, 191,
                        192, 32767))
        clip = (x + 2, y + 1, x + width - 2, y + height - 2) if trial % 3 == 0 else None
        cases.append((x, y, width, height, trial % 2,
                      (0x80, 0, 1, 0x40)[trial % 4], (trial // 4) % 2, clip))
    # Source-row skips at and beyond the signed-byte boundary.
    for y in (-254, -191, -128, -127, -63):
        for masked in (False, True):
            cases.append((-3, y, 17, 255, masked, 0x80, 1, None))
    with Spectrum() as machine:
        machine.reset(clear_memory=True)
        machine.load_binary(scratch, base)
        write(machine, 0x7000, b'\x76')
        expected = bytearray(rng.randbytes(6912))
        write(machine, 0x4000, expected)
        checked = 0
        for trial, (x, y, width, height, masked, mode, color, clip) in enumerate(cases):
            stride = (width + 7) // 8
            payload = rng.randbytes(stride * height * (1 + masked))
            blob = bytes((stride - 1 + 16 * masked, width, height))
            blob += word(len(payload)) + payload
            write(machine, 0x6000, blob)
            if clip:
                write(machine, 0x6E00, b''.join(map(word, clip)))
            args = word(y) + word(0x6000) + word(0x6E00 if clip else 0)
            write(machine, 0xFF00, word(0x7000) + args)
            machine.registers(pc=entry, sp=0xFF00, iff1=False, iff2=False,
                              hl=0, de=x & 65535, bc=(mode << 8) | color,
                              ix=0x1357, iy=0x2468)
            result = machine.run(stop_on_halt=True, tstates=40_000_000)
            assert result.get('reason') == 'halted', (trial, result)
            regs = machine.registers()
            assert (regs['sp'], regs['ix'], regs['iy']) == (0xFF08, 0x1357, 0x2468), (trial, regs)
            for sy in range(height):
                py = y + sy
                if not 0 <= py < 192:
                    continue
                for sx in range(width):
                    px = x + sx
                    if not 0 <= px < 256 or clip and not (clip[0] <= px <= clip[2] and clip[1] <= py <= clip[3]):
                        continue
                    row = sy * stride * (1 + masked)
                    bit = 0x80 >> (sx % 8)
                    source = bool(payload[row + masked * stride + sx // 8] & bit)
                    keep = bool(payload[row + sx // 8] & bit)
                    offset = zx_offset(px, py)
                    mask = 0x80 >> (px % 8)
                    old = bool(expected[offset] & mask)
                    if mode == 0x80:
                        new = (old and keep or source) if masked else old or source
                    elif mode & 1:
                        new = old != source
                    elif mode & 0x40:
                        new = bool(color) if source else old
                    else:
                        new = source if color else not source
                    expected[offset] = (expected[offset] & ~mask) | (mask if new else 0)
                    checked += 1
            actual = machine.screen(attrs=True)
            if actual != expected:
                offset = next(i for i, pair in enumerate(zip(actual, expected)) if pair[0] != pair[1])
                raise AssertionError((trial, cases[trial], hex(offset + 0x4000), actual[offset], expected[offset]))
    print(f'{len(cases)} bitmap cases, {checked:,} independently composed pixels and IX/IY/stack checks passed')


if __name__ == '__main__':
    main()
