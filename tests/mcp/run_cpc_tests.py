#!/usr/bin/env python3
"""Run the Amstrad CPC scenarios on amstrad-cpc-mcp, in both display modes.

Each scenario halts between phases. The runner screenshots the framebuffer
at every HALT, steps past it, and stops when the `cpc_finished` sentinel is
set -- the same protocol the Partner GDP suite uses. Every phase is compared
against a golden raster; use --bless to record the current output instead.

Rasters are read out of display memory rather than through the emulator's
screenshot crop, which is one scanline high (docs/todo/EMULATION-CPC.md).
"""

import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from cpcmcp import Cpc, SCREEN_BASE, cpc_offset      # noqa: E402

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
IMAGE_DIR = os.path.join(ROOT, "build", "cpc-tests")
GOLDEN_DIR = os.path.join(ROOT, "tests", "cpc", "golden")
LOAD_ADDR = 0x8000
HEIGHT = 200
# name -> (width, pixels per byte). One library serves both, so the two
# images differ only in the mode they pass to gpx_create().
MODES = {"640x200": (640, 8), "320x200": (320, 4)}


def raster(mach, width, per_byte):
    """Read display memory back as one row of 0/1 per scanline.

    Mode 2 is one bit per pixel; mode 1 carries pen 1 in the high nibble, so
    only four of a byte's bits are pixels and the mask walks the top nibble.
    Reading memory sidesteps the emulator's one-line-high screenshot crop.
    """
    mem = mach.read_memory(SCREEN_BASE, 0x4000)
    rows = []
    for y in range(HEIGHT):
        row = bytearray(width)
        for xb in range(width // per_byte):
            b = mem[cpc_offset(xb, y)]
            for p in range(per_byte):
                row[xb * per_byte + p] = 1 if b & (0x80 >> p) else 0
        rows.append(bytes(row))
    return rows


def write_pbm(path, rows):
    w, h = len(rows[0]), len(rows)
    stride = (w + 7) // 8
    body = bytearray(stride * h)
    for y, row in enumerate(rows):
        for x, v in enumerate(row):
            if v:
                body[y * stride + (x >> 3)] |= 0x80 >> (x & 7)
    with open(path, "wb") as fh:
        fh.write(b"P4\n%d %d\n" % (w, h))
        fh.write(bytes(body))


def read_pbm(path):
    with open(path, "rb") as fh:
        data = fh.read()
    parts = data.split(b"\n", 2)
    w, h = (int(v) for v in parts[1].split())
    stride = (w + 7) // 8
    body = parts[2]
    return [bytes((body[y * stride + (x >> 3)] >> (7 - (x & 7))) & 1
                  for x in range(w)) for y in range(h)]


def describe(actual, expected, limit=8):
    diffs = [(x, y) for y in range(len(expected))
             for x in range(len(expected[y])) if actual[y][x] != expected[y][x]]
    lines = [f"{len(diffs)} pixels differ"]
    for x, y in diffs[:limit]:
        lines.append(f"    x={x:4d} y={y:3d}: got {actual[y][x]}, "
                     f"want {expected[y][x]}")
    if len(diffs) > limit:
        lines.append(f"    ... and {len(diffs) - limit} more")
    return "\n".join(lines)


def run_scenario(cpc, path, width, per_byte):
    """Run one image, returning one raster per phase."""
    cpc.reset(clear_memory=True)
    cpc.load_binary(path, LOAD_ADDR, start=LOAD_ADDR)
    cpc.registers(pc=LOAD_ADDR, iff1=False, iff2=False)
    sentinel = read_symbol(path[:-4] + ".map", "_cpc_finished")
    phases = []
    while True:
        while True:
            r = cpc.run(stop_on_halt=True, frames=4)
            if (r.get("reason") or "") == "halted":
                break
        pc = cpc.status()["pc"]
        if cpc.read_memory(pc, 1) != b"\x76":
            raise RuntimeError(f"{path}: stopped at {pc:#06x}, not a HALT")
        phases.append(raster(cpc, width, per_byte))
        if cpc.read_memory(sentinel, 1)[0]:
            break
        if len(phases) > 16:
            raise RuntimeError(f"{path}: too many phases; is cpc_finish() "
                               f"missing?")
        # A halted Z80 does not advance, so stepping would re-execute the
        # HALT for ever. Move PC over it instead, exactly as the Partner
        # runner does.
        cpc.registers(pc=pc + 1)
    return phases


def read_symbol(map_path, name):
    with open(map_path) as fh:
        for line in fh:
            parts = line.split()
            if len(parts) >= 2 and parts[1] == name:
                return int(parts[0], 16)
    raise RuntimeError(f"{map_path}: no symbol {name}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--bless", action="store_true",
                    help="record the current output as the new golden")
    ap.add_argument("names", nargs="*")
    args = ap.parse_args()

    os.makedirs(GOLDEN_DIR, exist_ok=True)
    names = args.names or sorted(
        os.path.splitext(f)[0]
        for f in os.listdir(os.path.join(ROOT, "tests", "cpc", "src"))
        if f.endswith(".c") and f != "cpctest.c")

    failures = []
    for mode, (width, per_byte) in MODES.items():
        print(f"{mode}:")
        with Cpc() as cpc:
            for name in names:
                binp = os.path.join(IMAGE_DIR, f"{name}-{mode}.bin")
                if not os.path.exists(binp):
                    failures.append((name, mode, "no image"))
                    print(f"  FAIL {name}: no image")
                    continue
                phases = run_scenario(cpc, binp, width, per_byte)
                print(f"  {name:14s} {len(phases)} phase(s)")
                for idx, rows in enumerate(phases):
                    golden = os.path.join(GOLDEN_DIR, f"{name}-{mode}-{idx}.pbm")
                    if args.bless or not os.path.exists(golden):
                        write_pbm(golden, rows)
                        print(f"    phase {idx}: golden recorded")
                        continue
                    want = read_pbm(golden)
                    if rows != want:
                        failures.append((name, mode, f"phase {idx}"))
                        print(f"    phase {idx}: MISMATCH")
                        print(describe(rows, want))
    if failures:
        print(f"\n{len(failures)} CPC failure(s)")
        return 1
    print("\nall CPC scenarios passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
