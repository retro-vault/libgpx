#!/usr/bin/env python3
"""Amstrad CPC micro-benchmarks, in T-states on amstrad-cpc-mcp.

Each benchmark image runs to bench_body(), where the clock is read, then on
to HALT. Setup is therefore excluded and the number reported is the cost of
the primitive under test. Every benchmark runs in both display modes.

  make cpc-bench                    # current numbers
  make cpc-bench ARGS="--save"      # record a baseline
  make cpc-bench ARGS="--diff"      # compare against the baseline
"""

import argparse
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from cpcmcp import Cpc                              # noqa: E402
from run_cpc_tests import read_symbol               # noqa: E402

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
BENCH_DIR = os.path.join(ROOT, "build", "cpc-bench")
BASELINE = os.path.join(ROOT, "tests", "cpc", "bench-src", "baseline.json")
LOAD_ADDR = 0x8000
MODES = ("640x200", "320x200")


def measure(cpc, binp, mapp):
    body = read_symbol(mapp, "_bench_body")
    cpc.reset(clear_memory=True)
    cpc.load_binary(binp, LOAD_ADDR, start=LOAD_ADDR)
    cpc.registers(pc=LOAD_ADDR, iff1=False, iff2=False)

    r = cpc.call("run_until", address=body, max_tstates=60_000_000)
    if r.get("reason") != "address_reached":
        raise RuntimeError(f"{os.path.basename(binp)}: never entered "
                           f"bench_body ({r.get('reason')})")
    start = cpc.status()["tstates"]
    while True:
        r = cpc.run(stop_on_halt=True, frames=50)
        now = cpc.status()["tstates"]
        if (r.get("reason") or "") == "halted":
            return now - start
        if now - start > 400_000_000:
            raise RuntimeError(f"{os.path.basename(binp)}: no HALT")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("benchmarks", nargs="*")
    ap.add_argument("--save", action="store_true")
    ap.add_argument("--diff", action="store_true")
    args = ap.parse_args()

    names = args.benchmarks or sorted(
        {f.rsplit("-", 1)[0] for f in os.listdir(BENCH_DIR)
         if f.endswith(".bin")})

    results = {}
    for mode in MODES:
        with Cpc() as cpc:
            for name in names:
                binp = os.path.join(BENCH_DIR, f"{name}-{mode}.bin")
                mapp = os.path.join(BENCH_DIR, f"{name}-{mode}.map")
                results[f"{name} {mode}"] = measure(cpc, binp, mapp)

    old = {}
    if (args.diff or args.save) and os.path.exists(BASELINE):
        old = json.load(open(BASELINE))

    width = max(len(k) for k in results) + 2
    print(f"{'benchmark':{width}}{'T-states':>12}" +
          ("{:>14}".format("vs baseline") if args.diff and old else ""))
    for k in sorted(results):
        line = f"{k:{width}}{results[k]:>12,}"
        if args.diff and k in old:
            was = old[k]
            delta = results[k] - was
            pct = (delta / was * 100.0) if was else 0.0
            line += f"{pct:>+13.1f}%"
        print(line)

    if args.save:
        json.dump(results, open(BASELINE, "w"), indent=1, sort_keys=True)
        open(BASELINE, "a").write("\n")
        print(f"\nbaseline written to {os.path.relpath(BASELINE, ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
