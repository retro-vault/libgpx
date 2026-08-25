#!/usr/bin/env python3
"""Differential ZX Spectrum test runner driven by zx-spectrum-mcp.

Each scenario is compiled twice: once against the real assembler backend in
src/zx, once against the independent C oracle in tests/zx/stub. Both images
run on the same cycle-accurate emulator through MCP and their display files
must come out identical.
"""

import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from ihx import read_entry, read_ihx          # noqa: E402
from zxmcp import Spectrum, zx_offset         # noqa: E402

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
REAL_DIR = os.path.join(ROOT, "bin", "zx")
ORACLE_DIR = os.path.join(ROOT, "bin", "zx-oracle")
# The emulator container can only see the repo, so scratch images live in it.
SCRATCH_DIR = os.path.join(ROOT, "build", "mcp-scratch")

LOAD_ADDR = 0x8000
STACK_TOP = 0xFF00
# One MCP `run` is capped at ~20s of emulated time, so long scenarios are
# resumed in slices. The C oracle is far slower than the assembler backend
# and a heavy fill can legitimately need tens of millions of T-states.
RUN_SLICE_TSTATES = 60_000_000
MAX_TSTATES = 1_000_000_000
# Scenarios that assert on return values write them into `test_results`
# (see tests/zx/test-src/zxtest.h); absent from a scenario, nothing is read.
RESULTS_SYMBOL = "_test_results"
RESULTS_BYTES = 96


def run_image(zx, ihx_path, scratch):
    base, image = read_ihx(ihx_path)
    if base != LOAD_ADDR:
        raise RuntimeError(f"{ihx_path}: links at {base:#06x}, want {LOAD_ADDR:#06x}")
    # Entry comes from the linker map, so scenarios may declare helpers above
    # main without silently shifting the entry point.
    map_path = ihx_path[:-4] + ".map"
    entry = read_entry(map_path)
    bin_path = os.path.join(scratch, "image.bin")
    with open(bin_path, "wb") as fh:
        fh.write(image)

    zx.reset(clear_memory=True)
    zx.load_binary(bin_path, base)
    zx.registers(pc=entry, sp=STACK_TOP, iff1=False, iff2=False)
    elapsed = 0
    while True:
        result = zx.run(stop_on_halt=True, tstates=RUN_SLICE_TSTATES)
        elapsed = zx.status()["tstates"]
        if result.get("reason") == "halted":
            break
        if elapsed >= MAX_TSTATES:
            raise RuntimeError(
                f"{os.path.basename(ihx_path)}: no HALT after {elapsed:,} "
                f"T-states (pc={zx.status()['pc']:#06x})")
    results = b""
    try:
        addr = read_entry(map_path, RESULTS_SYMBOL)
    except ValueError:
        pass                       # scenario records nothing
    else:
        results = zx.read_memory(addr, RESULTS_BYTES)
    status = zx.status()
    return zx.screen(attrs=True), elapsed, status["border"], results


BITMAP_BYTES = 0x1800


def describe_mismatch(actual, expected, limit=6):
    """Report differing bytes in screen coordinates, not raw offsets."""
    where = [off for off in range(len(expected)) if actual[off] != expected[off]]
    lines = [f"{len(where)} screen bytes differ"]
    for off in where[:limit]:
        if off < BITMAP_BYTES:
            y = (((off & 0x1800) >> 5) | ((off & 0x0700) >> 8)
                 | ((off & 0x00E0) >> 2))
            x = (off & 0x1F) * 8
            place = f"pixels x={x:3d}..{x + 7:3d} y={y:3d}"
            fmt = "08b"
        else:
            cell = off - BITMAP_BYTES
            place = f"attr col={cell % 32:2d} row={cell // 32:2d}"
            fmt = "02x"
        lines.append(f"  {place}  real={actual[off]:{fmt}} "
                     f"oracle={expected[off]:{fmt}}")
    if len(where) > limit:
        lines.append(f"  ... and {len(where) - limit} more")
    return "\n".join(lines)


def describe_results(actual, expected, limit=8):
    """Report differing slots of the recorded-results block."""
    where = [i for i in range(len(expected)) if actual[i] != expected[i]]
    lines = [f"{len(where)} recorded result bytes differ"]
    for i in where[:limit]:
        lines.append(f"  slot {i:2d}  real={actual[i]:#04x} "
                     f"oracle={expected[i]:#04x}")
    if len(where) > limit:
        lines.append(f"  ... and {len(where) - limit} more")
    return "\n".join(lines)


def check_fresh(names):
    """Refuse to report on images older than the backend they link against.

    A failed build leaves the previous images in place, and running them
    reports a pass for code that was never assembled."""
    srcs = []
    for root in (os.path.join(ROOT, "src", "zx"),
                 os.path.join(ROOT, "tests", "zx", "test-src")):
        for entry in os.listdir(root):
            if entry.endswith((".s", ".c", ".h")):
                srcs.append(os.path.getmtime(os.path.join(root, entry)))
    if not srcs:
        return []
    newest = max(srcs)
    stale = []
    for name in names:
        for d in (REAL_DIR, ORACLE_DIR):
            image = os.path.join(d, name + ".ihx")
            if os.path.exists(image) and os.path.getmtime(image) < newest:
                stale.append(os.path.relpath(image, ROOT))
    return stale


def discover(names):
    if names:
        return list(names)
    found = []
    for entry in sorted(os.listdir(REAL_DIR)):
        if entry.startswith("test_") and entry.endswith(".ihx"):
            found.append(entry[:-4])
    return found


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("tests", nargs="*", help="test names (default: all)")
    ap.add_argument("--verbose", "-v", action="store_true")
    ap.add_argument("--timing", action="store_true",
                    help="report T-states consumed by the real backend")
    args = ap.parse_args()

    names = discover(args.tests)
    if not names:
        print("no ZX test images found; run 'make -C tests/zx build' first",
              file=sys.stderr)
        return 1

    stale = check_fresh(names)
    if stale:
        print(f"{len(stale)} image(s) are older than the sources they link "
              f"against, e.g. {stale[0]}.\n"
              f"The build did not complete; refusing to report a result.",
              file=sys.stderr)
        return 2

    failures = []
    timings = {}
    os.makedirs(SCRATCH_DIR, exist_ok=True)
    scratch = SCRATCH_DIR
    with Spectrum() as zx:
        for name in names:
            real = os.path.join(REAL_DIR, name + ".ihx")
            oracle = os.path.join(ORACLE_DIR, name + ".ihx")
            if not os.path.exists(oracle):
                failures.append((name, "no oracle image"))
                print(f"FAIL {name}: no oracle image")
                continue
            try:
                actual, ts, border, res = run_image(zx, real, scratch)
                expected, _, oracle_border, oracle_res = run_image(
                    zx, oracle, scratch)
            except Exception as exc:                    # noqa: BLE001
                failures.append((name, str(exc)))
                print(f"FAIL {name}: {exc}")
                continue
            timings[name] = ts
            if res != oracle_res:
                detail = describe_results(res, oracle_res)
                failures.append((name, detail))
                print(f"FAIL {name}\n{detail}")
            elif border != oracle_border:
                detail = (f"border colour {border} != oracle {oracle_border}")
                failures.append((name, detail))
                print(f"FAIL {name}: {detail}")
            elif actual != expected:
                detail = describe_mismatch(actual, expected)
                failures.append((name, detail))
                print(f"FAIL {name}\n{detail}")
            elif args.verbose or args.timing:
                extra = f"  {ts:>9,} T" if args.timing else ""
                print(f"ok   {name}{extra}")

    total = len(names)
    if failures:
        print(f"\n{len(failures)} of {total} ZX tests failed:")
        for name, _ in failures:
            print(f"  - {name}")
        return 1
    print(f"\nAll {total} ZX tests passed.")
    if args.timing:
        print(f"Total backend time: {sum(timings.values()):,} T-states")
    return 0


if __name__ == "__main__":
    sys.exit(main())
