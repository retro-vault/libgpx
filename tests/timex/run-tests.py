#!/usr/bin/env python3
"""Validate the Timex logical raster in the ZX CPU/memory emulator."""

import os
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
sys.path.insert(0, os.path.join(ROOT, "tests", "mcp"))

from ihx import read_entry, read_ihx  # noqa: E402
from zxmcp import Spectrum, zx_offset  # noqa: E402

IMAGE = os.path.join(ROOT, "build", "timex", "test_timex.ihx")
MAP = os.path.join(ROOT, "build", "timex", "test_timex.map")
BINARY = os.path.join(ROOT, "build", "timex", "test_timex.bin")


def expected_pixels():
    pixels = [[0] * 512 for _ in range(192)]
    for x, y in (
            (0, 0), (7, 0), (8, 0), (15, 0), (16, 0), (255, 0),
            (256, 0), (511, 0), (9, 1), (17, 7), (25, 8), (33, 63),
            (41, 64), (49, 191)):
        pixels[y][x] = 1
    for x in range(512):
        pixels[10][x] = 1
    for step in range(41):
        pixels[20 + step][240 + step] = 1
    for y in range(70, 73):
        for x in range(248, 273):
            pixels[y][x] = (0xAA >> (7 - ((x - 248) & 7))) & 1
    rows = ((0xA5, 0x5A), (0x81, 0x7E), (0xFF, 0x01))
    for row, values in enumerate(rows):
        for byte, value in enumerate(values):
            for bit in range(8):
                if (value >> (7 - bit)) & 1:
                    pixels[80 + row][252 + byte * 8 + bit] = 1
    return pixels


def decode(primary, secondary):
    pixels = [[0] * 512 for _ in range(192)]
    for y in range(192):
        row = zx_offset(0, y)
        for logical_byte in range(64):
            display = secondary if logical_byte & 1 else primary
            value = display[row + logical_byte // 2]
            for bit in range(8):
                pixels[y][logical_byte * 8 + bit] = \
                    (value >> (7 - bit)) & 1
    return pixels


def main():
    base, image = read_ihx(IMAGE)
    with open(BINARY, "wb") as output:
        output.write(image)

    with Spectrum(workdir=ROOT) as zx:
        zx.reset(clear_memory=True)
        zx.load_binary(BINARY, base)
        zx.registers(pc=read_entry(MAP), sp=0xFF00,
                     iff1=False, iff2=False)
        result = zx.run(stop_on_halt=True, tstates=60_000_000)
        if result.get("reason") != "halted":
            raise RuntimeError(f"test did not halt: {result}")
        primary = zx.read_memory(0x4000, 0x1800)
        secondary = zx.read_memory(0x6000, 0x1800)
        results_addr = read_entry(MAP, "_timex_results")
        geometry = zx.read_memory(results_addr, 4)

    failures = []
    if geometry != bytes((0x00, 0x02, 0xC0, 0x00)):
        failures.append(f"geometry bytes are {geometry.hex()}, want 0002c000")

    actual = decode(primary, secondary)
    expected = expected_pixels()
    for y in range(192):
        for x in range(512):
            if actual[y][x] != expected[y][x]:
                failures.append(
                    f"pixel ({x},{y}) is {actual[y][x]}, want {expected[y][x]}")
                if len(failures) == 9:
                    break
        if len(failures) == 9:
            break

    if failures:
        print("Timex regression failed:")
        for failure in failures:
            print(f"  {failure}")
        return 1
    print("Timex 512x192 layout regression passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
