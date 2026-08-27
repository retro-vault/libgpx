#!/usr/bin/env python3
"""Report per-module code size of a libgpx backend's objects.

Sizes come straight from the `A <area> size <n>` records the assembler writes
into each .rel, so a module's cost is exact and independent of link order.

  make lib-size                            # current sizes (ZX)
  make lib-size ARGS="--save"              # record a baseline
  make lib-size ARGS="--diff"              # compare against the baseline
  make lib-size ARGS="--backend cpc"       # any backend with built objects
"""

import argparse
import glob
import json
import os
import re
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
# Each backend keeps its objects and its baseline separately.
BACKENDS = {"zx": "zx", "partner": "partner-lib", "cpc": "cpc"}

AREA_RE = re.compile(r"^A (\S+) size ([0-9A-Fa-f]+) flags")


def module_sizes(obj_dir):
    sizes = {}
    for path in sorted(glob.glob(os.path.join(obj_dir, "*.rel"))):
        name = os.path.basename(path)[:-4]
        areas = {}
        with open(path, "r", errors="replace") as fh:
            for line in fh:
                m = AREA_RE.match(line)
                if m:
                    areas[m.group(1)] = areas.get(m.group(1), 0) + int(m.group(2), 16)
        sizes[name] = areas
    return sizes


def total(sizes, area):
    return sum(a.get(area, 0) for a in sizes.values())


def report(sizes, baseline=None):
    rows = sorted(sizes.items(), key=lambda kv: -kv[1].get("_CODE", 0))
    width = max((len(n) for n, _ in rows), default=10)
    if baseline:
        print(f"{'module':<{width}}  {'_CODE':>7}  {'base':>7}  {'delta':>7}")
    else:
        print(f"{'module':<{width}}  {'_CODE':>7}  {'_DATA':>7}")
    print("-" * (width + 26))
    for name, areas in rows:
        code = areas.get("_CODE", 0)
        if baseline:
            was = baseline.get(name, {}).get("_CODE", 0)
            delta = code - was
            mark = "" if delta == 0 else f"{delta:+d}"
            print(f"{name:<{width}}  {code:>7}  {was:>7}  {mark:>7}")
        else:
            print(f"{name:<{width}}  {code:>7}  {areas.get('_DATA', 0):>7}")
    print("-" * (width + 26))
    code = total(sizes, "_CODE")
    if baseline:
        was = sum(a.get("_CODE", 0) for a in baseline.values())
        print(f"{'TOTAL':<{width}}  {code:>7}  {was:>7}  {code - was:>+7}")
    else:
        print(f"{'TOTAL':<{width}}  {code:>7}  {total(sizes, '_DATA'):>7}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--save", action="store_true",
                    help="write current sizes to tests/size/baseline.json")
    ap.add_argument("--diff", action="store_true",
                    help="compare current sizes against the saved baseline")
    ap.add_argument("--json", action="store_true", help="machine-readable output")
    ap.add_argument("--backend", default="zx", choices=sorted(BACKENDS),
                    help="which backend's objects to measure")
    args = ap.parse_args()

    obj_dir = os.path.join(ROOT, "build", BACKENDS[args.backend])
    baseline_path = os.path.join(
        ROOT, "tests", "size",
        "baseline.json" if args.backend == "zx"
        else f"baseline-{args.backend}.json")

    sizes = module_sizes(obj_dir)
    if not sizes:
        print(f"no objects in {obj_dir}; build that backend first",
              file=sys.stderr)
        return 1

    if args.json:
        print(json.dumps(sizes, indent=2, sort_keys=True))
        return 0

    baseline = None
    if args.diff:
        if not os.path.exists(baseline_path):
            print(f"no baseline at {baseline_path}; run with --save first",
                  file=sys.stderr)
            return 1
        with open(baseline_path) as fh:
            baseline = json.load(fh)

    report(sizes, baseline)

    if args.save:
        with open(baseline_path, "w") as fh:
            json.dump(sizes, fh, indent=2, sort_keys=True)
        print(f"\nbaseline written to {baseline_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
