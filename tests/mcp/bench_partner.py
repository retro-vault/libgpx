#!/usr/bin/env python3
"""Per-primitive Z80 cost for the Partner GDP backend.

Runs tests/partner/gdp-bench scenarios on idp-mcp and differences the T-state
counter across each phase. The current emulator models command-dependent
GDP busy time, so these include CPU work and time spent waiting for the GDP.
An asynchronous command can finish during the next phase; crossbench isolates
whole workloads when that distinction matters.

  --save FILE   write the results as a baseline
  --against F   compare against a saved baseline
"""

import argparse
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from idpmcp import Partner                       # noqa: E402
from ihx import read_entry, read_ihx             # noqa: E402

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
IMAGE_DIR = os.path.join(ROOT, "bin", "partner-gdp")
SCRATCH_DIR = os.path.join(ROOT, "build", "gdp-scratch")
LOAD_ADDR = 0x8000
STACK_TOP = 0xFF00
SLICE = 60_000_000

# phase index -> (label, iteration count)
LABELS = {
    "bench_patterns": [("settle", 1)] + [
        (f"hline {pattern:02X} {mode}", 40)
        for mode in ("CPY", "XOR")
        for pattern in (0xAA, 0x55, 0xCC, 0x33, 0xF0, 0x0F,
                        0x11, 0x88, 0x77, 0xEE, 0x1F, 0x3F, 0x7F, 0xA5, 0x5A, 0x9B)
    ],
    "bench_prims": [
        ("settle", 1),
        ("draw_line solid (hw vector)", 200),
        ("draw_line solid, clipped", 200),
        ("draw_line patterned (sw bresenham)", 20),
        ("draw_pixel", 2000),
        ("fill_rectangle solid", 5),
        ("fill_rectangle patterned (sw)", 2),
        ("draw_bmp 16x8", 200),
        ("draw_text 30 chars", 20),
        ("clrscr alone", 4),
        ("40 measure_text alone (no GDP)", 4),
        ("clrscr + 40 measure_text", 4),
        ("sprite show+hide", 100),
    ],
}


def phase_costs(gdp, name):
    base, image = read_ihx(os.path.join(IMAGE_DIR, name + ".ihx"))
    map_path = os.path.join(IMAGE_DIR, name + ".map")
    entry = read_entry(map_path)
    finished_at = read_entry(map_path, "_gdp_finished")

    bin_path = os.path.join(SCRATCH_DIR, "bench.bin")
    with open(bin_path, "wb") as fh:
        fh.write(image)
    gdp.reset(clear_memory=True)
    gdp.load_binary(bin_path, base)
    gdp.registers(pc=entry, sp=STACK_TOP, iff1=False, iff2=False)

    costs = []
    prev = 0
    while True:
        while True:
            r = gdp.run(stop_on_halt=True, tstates=SLICE)
            if r.get("run", {}).get("reason") == "halted":
                break
        now = r["tstates"]
        costs.append(now - prev)
        prev = now
        if gdp.read_memory(finished_at, 1)[0] == 0xA5:
            break
        gdp.registers(pc=r["cpu"]["pc"] + 1)
    return costs


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--save")
    ap.add_argument("--against")
    args = ap.parse_args()

    os.makedirs(SCRATCH_DIR, exist_ok=True)
    names = sorted(f[:-4] for f in os.listdir(IMAGE_DIR)
                   if f.startswith("bench_") and f.endswith(".ihx"))
    if not names:
        print("no benches built; run `make -C tests/partner gdp-bench`",
              file=sys.stderr)
        return 2

    old = {}
    if args.against and os.path.exists(args.against):
        old = json.load(open(args.against))

    out = {}
    with Partner(rom=False) as gdp:
        for name in names:
            costs = phase_costs(gdp, name)
            labels = LABELS.get(name, [])
            print(f"\n{name}")
            print(f"  {'primitive':<38} {'total T':>11} {'T/call':>9}"
                  + (f" {'vs base':>10}" if old else ""))
            for i, cost in enumerate(costs):
                label, n = labels[i] if i < len(labels) else (f"phase {i}", 1)
                if label == "settle":
                    continue
                per = cost / n
                key = f"{name}:{label}"
                out[key] = per
                line = f"  {label:<38} {cost:>11,} {per:>9,.0f}"
                if old and key in old:
                    delta = (per - old[key]) / old[key] * 100.0
                    line += f" {delta:>+9.1f}%"
                print(line)

    if args.save:
        json.dump(out, open(args.save, "w"), indent=1, sort_keys=True)
        print(f"\nbaseline written to {args.save}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
