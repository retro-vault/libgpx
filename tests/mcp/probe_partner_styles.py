#!/usr/bin/env python3
"""Probe EF9367 style phases and finite pattern compositions through idp-mcp.

The production optimization uses styles 1/2. The last two rows explore
style 3 without adding its recipe decoder or endpoint repairs to libgpx.
The GF(2) enumeration reports ideal cyclic stroke counts, before repairs.
"""
from collections import Counter
from pathlib import Path

from idpmcp import Partner, raster_from_png

ROOT = Path(__file__).resolve().parents[2]


def dashdot_space():
    mask = 0x33FF
    basis = [((mask << i) | (mask >> (16 - i))) & 65535
             for i in range(16)]
    values = [0] * 65536
    best = {}
    for subset in range(65536):
        if subset:
            bit = subset & -subset
            values[subset] = values[subset ^ bit] ^ basis[bit.bit_length()-1]
        value = values[subset]
        if value & 255 == value >> 8:
            pattern = value & 255
            if pattern not in best or subset.bit_count() < best[pattern].bit_count():
                best[pattern] = subset
    assert len(best) == 256
    return dict(sorted(Counter(s.bit_count() for s in best.values()).items()))


def main():
    code = bytearray()

    def out(port, value):
        code.extend([0x3E, value, 0xD3, port])

    def wait():
        code.extend([0xDB, 0x2F, 0xE6, 4, 0x28, 0xFA])

    def cmd(value):
        wait()
        out(0x20, value)

    def xy(x, y):
        wait()
        out(0x29, x & 255)
        out(0x28, x >> 8)
        out(0x2B, 255 - y)
        out(0x2A, 0)

    def vector(delta, direction=0x10):
        wait()
        out(0x25, delta)
        out(0x27, 0)
        cmd(direction)

    out(0x31, 0x0F)
    out(0x30, 0)
    cmd(0)
    cmd(2)
    cmd(4)
    expected = {}
    masks = [0xFFFF, 0x3333, 0x0F0F, 0x33FF]
    for style, mask in enumerate(masks):
        wait()
        out(0x22, style)
        xy(20, style * 8)
        vector(31)
        xy(20, style * 8 + 1)
        vector(4)
        vector(27)
        xy(51, style * 8 + 2)
        vector(31, 0x16)
        bit = lambda n: (mask >> (n & 15)) & 1
        expected[style * 8] = bytes(bit(i) for i in range(32))
        expected[style * 8 + 1] = bytes(
            (bit(i) if i <= 4 else 0) | (bit(i-4) if i >= 4 else 0)
            for i in range(32))
        expected[style * 8 + 2] = bytes(bit(31-i) for i in range(32))

    wait()
    out(0x22, 0)
    xy(20, 40)
    vector(40)
    wait()
    out(0x30, 4)
    out(0x22, 1)
    for y in (40, 41):
        xy(20, y)
        vector(31)
        xy(21, y)
        vector(30)
    xy(21, 42)
    vector(30)
    xy(22, 42)
    vector(29)
    expected[40] = bytes(i & 1 for i in range(32))
    expected[41] = bytes(1 - (i & 1) for i in range(32))
    expected[42] = bytes(i & 1 for i in range(32))

    wait()
    out(0x22, 3)
    xy(20, 45)
    vector(31)
    xy(24, 45)
    vector(27)
    for x in (20, 21):
        xy(x, 45)
        cmd(0x80)
    for shift in range(4):
        xy(20 + shift, 46)
        vector(31 - shift)
    xy(20, 46)
    cmd(0x80)
    expected[45] = bytes((0x0C >> (i & 7)) & 1 for i in range(32))
    expected[46] = bytes((0x04 >> (i & 7)) & 1 for i in range(32))
    wait()
    code.append(0x76)

    scratch = ROOT / 'build/pattern-composition'
    scratch.mkdir(parents=True, exist_ok=True)
    binary, shot = scratch / 'styles.bin', scratch / 'styles.png'
    binary.write_bytes(code)
    with Partner(rom=False) as gdp:
        gdp.load_binary(str(binary), 0x8000)
        gdp.registers(pc=0x8000, sp=0xFF00, iff1=False, iff2=False)
        state = gdp.run(tstates=1_000_000, stop_on_halt=True)
        assert state['run']['reason'] == 'halted'
        gdp.screenshot(str(shot))
        rows = raster_from_png(str(shot))
    for y, row in expected.items():
        assert rows[y][20:52] == row, f'style probe row {y} differs'
        assert not any(rows[y][:20]), f'left endpoint leak on row {y}'
        assert not any(rows[y][61 if y == 40 else 52:]), f'right leak on row {y}'
    print('17 MCP rows passed: phase reset, reverse direction, finite XOR, dash-dot repairs.')
    print('Dash-dot periodic 8-bit minimum stroke counts (before repairs):', dashdot_space())


if __name__ == '__main__':
    main()
