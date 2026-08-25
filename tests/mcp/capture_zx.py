#!/usr/bin/env python3
"""Capture real-backend and oracle screens for every ZX scenario as PNGs.

Uses the MCP `screenshot` tool, so the images are exactly what the ULA beam
painted. Output goes to bin/lib-visuals/.
"""

import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from ihx import read_entry, read_ihx          # noqa: E402
from zxmcp import Spectrum                    # noqa: E402
from run_zx_tests import (                    # noqa: E402
    MAX_TSTATES, ORACLE_DIR, REAL_DIR, ROOT, RUN_SLICE_TSTATES, SCRATCH_DIR,
    STACK_TOP, discover)

OUT_DIR = os.path.join(ROOT, "bin", "lib-visuals")


def capture(zx, ihx_path, png_path, scratch, scale):
    base, image = read_ihx(ihx_path)
    # Entry comes from the map: a scenario may declare helpers above main.
    entry = read_entry(ihx_path[:-4] + ".map")
    bin_path = os.path.join(scratch, "image.bin")
    with open(bin_path, "wb") as fh:
        fh.write(image)
    zx.reset(clear_memory=True)
    zx.load_binary(bin_path, base)
    zx.registers(pc=entry, sp=STACK_TOP, iff1=False, iff2=False)
    while zx.status()["tstates"] < MAX_TSTATES:
        if zx.run(stop_on_halt=True,
                  tstates=RUN_SLICE_TSTATES).get("reason") == "halted":
            break
    # Let the beam paint a whole frame with the finished display file.
    zx.run(frames=2)
    zx.call("screenshot", path=zx.guest_path(png_path),
            include_border=False, scale=scale)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("tests", nargs="*")
    ap.add_argument("--scale", type=int, default=2, choices=(1, 2, 3, 4))
    args = ap.parse_args()

    os.makedirs(OUT_DIR, exist_ok=True)
    names = discover(args.tests)
    os.makedirs(SCRATCH_DIR, exist_ok=True)
    scratch = SCRATCH_DIR
    with Spectrum() as zx:
        for name in names:
            for label, src_dir in (("real", REAL_DIR), ("oracle", ORACLE_DIR)):
                ihx = os.path.join(src_dir, name + ".ihx")
                if not os.path.exists(ihx):
                    continue
                png = os.path.join(OUT_DIR, f"{name}-{label}.png")
                capture(zx, ihx, png, scratch, args.scale)
            print(f"captured {name}")
    print(f"\nPNGs written to {OUT_DIR}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
