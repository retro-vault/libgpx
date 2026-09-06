#!/usr/bin/env python3
"""Independent Partner fill-phase checks, including full signed origins.

Build with ``make -C tests/partner gdp-bench`` before running this script.
The return trampoline waits for GDP completion before each raster capture.
"""
import struct
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tests/mcp"))
from idpmcp import Partner, raster_from_png  # noqa: E402
from ihx import read_entry, read_ihx  # noqa: E402


def word(value):
    return struct.pack("<H", value & 65535)


def invoke(machine, symbols, name, args=b"", **regs):
    machine.write_memory(0x7000, bytes.fromhex("db20e60428fa76"))
    machine.write_memory(0x7F00, word(0x7000) + args)
    machine.registers(pc=read_entry(str(symbols), name), sp=0x7F00,
                      iff1=False, iff2=False, ix=0x6AA6, **regs)
    result = machine.run(stop_on_halt=True, tstates=60_000_000)
    assert result.get("run", {}).get("reason") == "halted", (name, result)
    registers = machine.registers()
    assert registers["sp"] == 0x7F02 + len(args), (name, registers)
    assert registers["ix"] == 0x6AA6, (name, registers)
    return registers


def main():
    scratch = ROOT / "build/optimization2/fill-phase"
    scratch.mkdir(parents=True, exist_ok=True)
    source = (Path(sys.argv[1]) if len(sys.argv) > 1 else
              ROOT / "bin/partner-gdp/bench_prims.ihx")
    symbols = source.with_suffix(".map")
    address, image = read_ihx(str(source))
    binary = scratch / "image.bin"
    binary.write_bytes(image)
    shot = scratch / "phase.png"
    patterns = (0xCC, 0x33, 0xF0, 0x0F, 0xAA, 0x55, 0x11,
                0x77, 0x00, 0xFF, 0x96, 0xE3)
    total = 0
    with Partner(rom=False) as machine:
        for mode, height in ((0, 256), (1, 512)):
            machine.reset(clear_memory=True)
            machine.load_binary(binary, address)
            context = invoke(machine, symbols, "_gpx_create", af=mode << 8)["de"]
            expected = [bytearray(1024) for _ in range(height)]
            for trial in range(30):
                origin = (-32768, -32767, -257, -1, 0)[trial // 6]
                count = (1, 3, 5, 127, 128, 255)[trial % 6]
                left = (-32768, -511, -1, 0, 17)[trial % 5]
                color, operation = (trial // 2) & 1, trial & 1
                rows = bytes(patterns[(i + trial) % len(patterns)]
                             for i in range(count))
                rectangle = (left, origin, 1023, 3)
                # Fill clips normalize reversed rectangles; line clips do
                # not. Exercise the fill contract independently here.
                clip = (3, 1, 1019, 2)
                stored_clip = clip if trial % 2 else (1019, 2, 3, 1)
                machine.write_memory(0x7100, b"".join(map(word, rectangle)))
                machine.write_memory(0x7200, rows)
                machine.write_memory(0x7400, b"".join(map(word, stored_clip)))
                invoke(machine, symbols, "_gpx_fill_rectangle",
                       bytes((color, operation)) + word(0x7200) +
                       bytes((count,)) + word(0x7400), hl=context, de=0x7100)
                for y in range(1, 3):
                    pattern = rows[(y - origin) % count]
                    for x in range(max(left, 3), 1020):
                        if pattern & (0x80 >> ((x - left) & 7)):
                            expected[y][x] = (expected[y][x] ^ 1) if operation else color
                machine.screenshot(shot)
                actual = raster_from_png(shot, 1024, height)
                if actual != expected:
                    mismatch = next((x, y, actual[y][x], expected[y][x])
                                    for y in range(height) for x in range(1024)
                                    if actual[y][x] != expected[y][x])
                    raise AssertionError((mode, trial, origin, count, mismatch))
                total += 1
    print(f"Partner: {total} independent full-raster fill-phase cases passed.")


if __name__ == "__main__":
    main()
