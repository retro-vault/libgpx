#!/usr/bin/env python3
"""Cross-backend benchmarks: the same picture, timed on every machine.

The per-backend suites size their work from gpx_width()/gpx_height(), so
their numbers cannot be compared -- "fill the screen" is 256x192 on a
Spectrum and 1024x256 on a Partner. The scenarios under
tests/crossbench/src/ instead draw at fixed coordinates inside a 256x192 box
that fits every supported display, so all three backends are asked for the
same picture and the results can go side by side.

Each image is run to bench_body(), where the clock is read, then on to HALT,
which excludes gpx_create() and the initial clear.

T-states are also converted to milliseconds, because the machines are not
clocked alike: a Spectrum Z80 runs at 3.5 MHz, the CPC and the Partner at
4 MHz. Milliseconds are the honest comparison; T-states are what you tune
against on one machine.

  make crossbench
  make crossbench ARGS=--tstates    # raw T-states as well
"""

import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from cpcmcp import Cpc                                        # noqa: E402
from idpmcp import Partner                                    # noqa: E402
from ihx import read_entry, read_ihx                          # noqa: E402
from zxmcp import Spectrum                                    # noqa: E402

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
IMAGE_DIR = os.path.join(ROOT, "bin", "xbench")
SCRATCH = os.path.join(ROOT, "build", "xbench")
LOAD_ADDR = 0x8000
STACK_TOP = 0xFF00
SLICE = 60_000_000
CAP = 4_000_000_000

# Z80 clock, in MHz, as each machine actually runs it.
CLOCK = {
    "zx": 3.5,
    "partner": 4.0,
    "cpc-640x200": 4.0,
    "cpc-320x200": 4.0,
}

COLUMNS = ("zx", "partner", "cpc-640x200", "cpc-320x200")
HEADINGS = {
    "zx": "ZX Spectrum",
    "partner": "Partner",
    "cpc-640x200": "CPC 640x200",
    "cpc-320x200": "CPC 320x200",
}


def _run_to_halt(mach, by_frames):
    """Drive one machine to its HALT, whichever run interface it offers."""
    while True:
        if by_frames:
            r = mach.run(stop_on_halt=True, frames=50)
        else:
            r = mach.run(stop_on_halt=True, tstates=SLICE)
        reason = r.get("reason") or r.get("run", {}).get("reason")
        if reason == "halted":
            return
        if mach.status()["tstates"] > CAP:
            raise RuntimeError("no HALT")


def _measure_ihx(mach, stem, by_frames):
    base, image = read_ihx(stem + ".ihx")
    body = read_entry(stem + ".map", "_bench_body")
    entry = read_entry(stem + ".map")
    binp = os.path.join(SCRATCH, "xb.bin")
    open(binp, "wb").write(image)

    mach.reset(clear_memory=True)
    mach.load_binary(binp, base)
    mach.registers(pc=entry, sp=STACK_TOP, iff1=False, iff2=False)
    r = mach.call("run_until", address=body, max_tstates=SLICE)
    if (r.get("reason") or r.get("run", {}).get("reason")) not in (
            "address_reached", "breakpoint"):
        raise RuntimeError(f"{stem}: never entered bench_body")
    start = mach.status()["tstates"]
    _run_to_halt(mach, by_frames)
    return mach.status()["tstates"] - start


def _measure_cpc(cpc, stem):
    body = read_entry(stem + ".map", "_bench_body")
    cpc.reset(clear_memory=True)
    cpc.load_binary(stem + ".bin", LOAD_ADDR, start=LOAD_ADDR)
    cpc.registers(pc=LOAD_ADDR, iff1=False, iff2=False)
    r = cpc.call("run_until", address=body, max_tstates=SLICE)
    if r.get("reason") != "address_reached":
        raise RuntimeError(f"{stem}: never entered bench_body")
    start = cpc.status()["tstates"]
    _run_to_halt(cpc, True)
    return cpc.status()["tstates"] - start


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("benchmarks", nargs="*")
    ap.add_argument("--tstates", action="store_true",
                    help="print raw T-states as well as milliseconds")
    args = ap.parse_args()

    os.makedirs(SCRATCH, exist_ok=True)
    names = args.benchmarks or sorted(
        f[:-len("_zx.ihx")] for f in os.listdir(IMAGE_DIR)
        if f.endswith("_zx.ihx"))

    res = {n: {} for n in names}
    with Spectrum() as zx:
        for n in names:
            res[n]["zx"] = _measure_ihx(zx, os.path.join(IMAGE_DIR, n + "_zx"),
                                        False)
    with Partner(rom=False) as gdp:
        for n in names:
            res[n]["partner"] = _measure_ihx(
                gdp, os.path.join(IMAGE_DIR, n + "_partner"), False)
    with Cpc() as cpc:
        for n in names:
            for mode in ("640x200", "320x200"):
                res[n]["cpc-" + mode] = _measure_cpc(
                    cpc, os.path.join(IMAGE_DIR, f"{n}_cpc-{mode}"))

    head = f"{'benchmark':<14}" + "".join(f"{HEADINGS[c]:>14}" for c in COLUMNS)
    print(head)
    print("-" * len(head))
    for n in names:
        row = f"{n:<14}"
        for c in COLUMNS:
            ms = res[n][c] / (CLOCK[c] * 1000.0)
            row += f"{ms:>13.1f}m"
        print(row)
    if args.tstates:
        print()
        print(head)
        print("-" * len(head))
        for n in names:
            print(f"{n:<14}" + "".join(f"{res[n][c]:>14,}" for c in COLUMNS))
    return 0


if __name__ == "__main__":
    sys.exit(main())
