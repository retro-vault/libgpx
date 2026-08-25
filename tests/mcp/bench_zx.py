#!/usr/bin/env python3
"""ZX Spectrum micro-benchmarks, measured in T-states on the cycle-accurate
emulator behind zx-spectrum-mcp.

Each benchmark image runs to bench_body(), where the clock is read, then on
to HALT. Setup is therefore excluded and the number reported is the cost of
the primitive under test.

  make zx-bench                     # current numbers
  make zx-bench ARGS="--save"       # record a baseline
  make zx-bench ARGS="--diff"       # compare against the baseline
"""

import argparse
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from ihx import read_entry, read_ihx               # noqa: E402
from zxmcp import Spectrum                         # noqa: E402
from run_zx_tests import (                         # noqa: E402
    MAX_TSTATES, ROOT, RUN_SLICE_TSTATES, SCRATCH_DIR, STACK_TOP)

BENCH_DIR = os.path.join(ROOT, "bin", "zx-bench")
BASELINE = os.path.join(ROOT, "tests", "zx", "bench-src", "baseline.json")


def measure(zx, ihx_path, scratch):
    base, image = read_ihx(ihx_path)
    map_path = ihx_path[:-4] + ".map"
    entry = read_entry(map_path)
    body = read_entry(map_path, "_bench_body")

    bin_path = os.path.join(scratch, "bench.bin")
    with open(bin_path, "wb") as fh:
        fh.write(image)

    zx.reset(clear_memory=True)
    zx.load_binary(bin_path, base)
    zx.registers(pc=entry, sp=STACK_TOP, iff1=False, iff2=False)

    result = zx.call("run_until", address=body, max_tstates=RUN_SLICE_TSTATES)
    if result.get("reason") != "address_reached":
        raise RuntimeError(f"{os.path.basename(ihx_path)}: never entered "
                           f"bench_body ({result.get('reason')})")
    start = zx.status()["tstates"]

    while True:
        result = zx.run(stop_on_halt=True, tstates=RUN_SLICE_TSTATES)
        now = zx.status()["tstates"]
        if result.get("reason") == "halted":
            return now - start
        if now >= MAX_TSTATES:
            raise RuntimeError(f"{os.path.basename(ihx_path)}: no HALT")


def discover(names):
    if names:
        return list(names)
    if not os.path.isdir(BENCH_DIR):
        return []
    return sorted(e[:-4] for e in os.listdir(BENCH_DIR)
                  if e.startswith("bench_") and e.endswith(".ihx"))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("benchmarks", nargs="*")
    ap.add_argument("--save", action="store_true")
    ap.add_argument("--diff", action="store_true")
    args = ap.parse_args()

    names = discover(args.benchmarks)
    if not names:
        print("no benchmark images; run 'make -C tests/zx bench' first",
              file=sys.stderr)
        return 1

    baseline = {}
    if args.diff or args.save:
        if os.path.exists(BASELINE):
            with open(BASELINE) as fh:
                baseline = json.load(fh)
    if args.diff and not baseline:
        print(f"no baseline at {BASELINE}; run with --save first",
              file=sys.stderr)
        return 1

    os.makedirs(SCRATCH_DIR, exist_ok=True)
    results = {}
    with Spectrum() as zx:
        for name in names:
            results[name] = measure(
                zx, os.path.join(BENCH_DIR, name + ".ihx"), SCRATCH_DIR)

    width = max(len(n) for n in results)
    if args.diff:
        print(f"{'benchmark':<{width}}  {'T-states':>12}  {'baseline':>12}  "
              f"{'change':>9}")
        print("-" * (width + 40))
    else:
        print(f"{'benchmark':<{width}}  {'T-states':>12}")
        print("-" * (width + 15))

    total = 0
    base_total = 0
    for name in names:
        ts = results[name]
        total += ts
        if args.diff:
            was = baseline.get(name, 0)
            base_total += was
            pct = f"{(ts - was) * 100.0 / was:+.1f}%" if was else "n/a"
            print(f"{name:<{width}}  {ts:>12,}  {was:>12,}  {pct:>9}")
        else:
            print(f"{name:<{width}}  {ts:>12,}")
    if args.diff:
        pct = (f"{(total - base_total) * 100.0 / base_total:+.1f}%"
               if base_total else "n/a")
        print("-" * (width + 40))
        print(f"{'TOTAL':<{width}}  {total:>12,}  {base_total:>12,}  "
              f"{pct:>9}")
    else:
        print("-" * (width + 15))
        print(f"{'TOTAL':<{width}}  {total:>12,}")

    if args.save:
        with open(BASELINE, "w") as fh:
            json.dump(results, fh, indent=2, sort_keys=True)
        print(f"\nbaseline written to {BASELINE}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
