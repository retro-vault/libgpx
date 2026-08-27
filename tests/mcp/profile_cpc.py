#!/usr/bin/env python3
"""Sampling profiler for the Amstrad CPC backend, driven by amstrad-cpc-mcp.

Runs a benchmark image in short T-state slices and records where the program
counter lands, then attributes each sample to the nearest preceding symbol
from the linker map. Sampling is deterministic: the emulator advances by an
exact number of T-states, so the same run always produces the same profile.

  tests/mcp/profile_cpc.py bench_text 640x200
  tests/mcp/profile_cpc.py bench_fill 320x200 --samples 4000
"""

import argparse
import bisect
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from cpcmcp import Cpc                              # noqa: E402

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
BENCH_DIR = os.path.join(ROOT, "build", "cpc-bench")
LOAD_ADDR = 0x8000
SYMBOL_RE = re.compile(r"^([0-9A-Fa-f]{8})\s+(\S+)\s*$")
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
    syms = sorted(set(s for s in syms if s[0] >= LOAD_ADDR))
    return [a for a, _ in syms], [n for _, n in syms]


def start_at_body(cpc, binp, body):
    cpc.reset(clear_memory=True)
    cpc.load_binary(binp, LOAD_ADDR, start=LOAD_ADDR)
    cpc.registers(pc=LOAD_ADDR, iff1=False, iff2=False)
    cpc.call("run_until", address=body, max_tstates=60_000_000)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("benchmark")
    ap.add_argument("mode", nargs="?", default="640x200")
    ap.add_argument("--samples", type=int, default=2000)
    ap.add_argument("--top", type=int, default=18)
    args = ap.parse_args()

    stem = os.path.join(BENCH_DIR, f"{args.benchmark}-{args.mode}")
    addrs, names = load_symbols(stem + ".map")
    body = next(a for a, n in zip(addrs, names) if n == "_bench_body")

    with Cpc() as cpc:
        start_at_body(cpc, stem + ".bin", body)
        start = cpc.status()["tstates"]
        while True:
            res = cpc.run(stop_on_halt=True, frames=50)
            total = cpc.status()["tstates"] - start
            if (res.get("reason") or "") == "halted":
                break

        step = max(1, total // args.samples)
        start_at_body(cpc, stem + ".bin", body)

        counts = {}
        for _ in range(args.samples):
            cpc.run(tstates=step)
            pc = cpc.status()["pc"]
            i = bisect.bisect_right(addrs, pc) - 1
            key = names[i] if i >= 0 else "?"
            counts[key] = counts.get(key, 0) + 1

    print(f"{args.benchmark} {args.mode}: {total:,} T-states, "
          f"{args.samples} samples")
    width = max(len(k) for k in counts) + 2
    for name, n in sorted(counts.items(), key=lambda kv: -kv[1])[:args.top]:
        share = n / args.samples
        print(f"  {name:{width}}{share*100:5.1f}%  {int(share*total):>12,} T")
    return 0


if __name__ == "__main__":
    sys.exit(main())
