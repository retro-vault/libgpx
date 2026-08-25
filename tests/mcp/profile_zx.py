#!/usr/bin/env python3
"""Sampling profiler for the ZX backend, driven by zx-spectrum-mcp.

Runs a benchmark image in short T-state slices and records where the program
counter lands, then attributes each sample to the nearest preceding symbol
from the linker map. Sampling is deterministic: the emulator advances by an
exact number of T-states, so the same run always produces the same profile.

  tests/mcp/profile_zx.py bench_text            # hot symbols
  tests/mcp/profile_zx.py bench_text --samples 4000
"""

import argparse
import bisect
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from ihx import read_entry, read_ihx               # noqa: E402
from zxmcp import Spectrum                         # noqa: E402
from run_zx_tests import ROOT, SCRATCH_DIR, STACK_TOP   # noqa: E402

BENCH_DIR = os.path.join(ROOT, "bin", "zx-bench")
SYMBOL_RE = re.compile(r"^([0-9A-Fa-f]{8})\s+(\S+)\s*$")
# Linker bookkeeping symbols would otherwise swallow whole address ranges.
IGNORED_SUFFIXES = ("__CODE", "__DATA", "__BSS")


def load_symbols(map_path):
    syms = []
    with open(map_path) as fh:
        for line in fh:
            m = SYMBOL_RE.match(line.strip())
            if not m:
                continue
            name = m.group(2)
            if name.endswith(IGNORED_SUFFIXES) or name.endswith("; linker"):
                continue
            syms.append((int(m.group(1), 16), name))
    syms = sorted(set(s for s in syms if s[0] >= 0x4000))
    return [a for a, _ in syms], [n for _, n in syms]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("benchmark")
    ap.add_argument("--samples", type=int, default=2000)
    ap.add_argument("--top", type=int, default=20)
    args = ap.parse_args()

    ihx = os.path.join(BENCH_DIR, args.benchmark + ".ihx")
    map_path = ihx[:-4] + ".map"
    addrs, names = load_symbols(map_path)

    base, image = read_ihx(ihx)
    os.makedirs(SCRATCH_DIR, exist_ok=True)
    bin_path = os.path.join(SCRATCH_DIR, "profile.bin")
    with open(bin_path, "wb") as fh:
        fh.write(image)

    with Spectrum() as zx:
        zx.reset(clear_memory=True)
        zx.load_binary(bin_path, base)
        zx.registers(pc=read_entry(map_path), sp=STACK_TOP, iff1=False,
                     iff2=False)
        body = read_entry(map_path, "_bench_body")
        zx.call("run_until", address=body, max_tstates=60_000_000)
        start = zx.status()["tstates"]

        # One pass to learn the total, then sample evenly across it.
        total = 0
        while True:
            res = zx.run(stop_on_halt=True, tstates=60_000_000)
            total = zx.status()["tstates"] - start
            if res.get("reason") == "halted":
                break

        step = max(1, total // args.samples)
        zx.reset(clear_memory=True)
        zx.load_binary(bin_path, base)
        zx.registers(pc=read_entry(map_path), sp=STACK_TOP, iff1=False,
                     iff2=False)
        zx.call("run_until", address=body, max_tstates=60_000_000)

        counts = {}
        taken = 0
        while taken < args.samples:
            res = zx.run(tstates=step)
            pc = zx.status()["pc"]
            i = bisect.bisect_right(addrs, pc) - 1
            counts[names[i] if i >= 0 else "?"] = \
                counts.get(names[i] if i >= 0 else "?", 0) + 1
            taken += 1
            if res.get("reason") == "halted":
                break

    print(f"{args.benchmark}: {total:,} T-states, {taken} samples")
    print(f"{'symbol':<28} {'samples':>8} {'share':>7} {'T-states':>13}")
    print("-" * 60)
    for name, n in sorted(counts.items(), key=lambda kv: -kv[1])[:args.top]:
        share = n * 100.0 / taken
        print(f"{name:<28} {n:>8} {share:>6.1f}% {int(total * n / taken):>13,}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
