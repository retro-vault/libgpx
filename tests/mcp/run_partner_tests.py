#!/usr/bin/env python3
"""Partner GDP test runner driven by idp-mcp.

Scenarios in tests/partner/gdp-src link against the real assembler backend
and run on the emulated EF9367 inside the xcc-z80-idp image. Each scenario
HALTs between phases; the runner captures the GDP raster at every HALT.

Two kinds of check run against those rasters:

  * golden   -- the raster must match tests/partner/gdp-golden/<name>-<n>.pbm.
                Use --bless to record the current output as the new golden.
                The goldens were recorded against an idp-emu that implements
                CTRL2 vector line styles (see docs/todo/EMULATION.md). An
                older emulator draws every vector continuous and fails most of
                them; point IDP_MCP at a local build if the packaged image is
                behind.
  * identity -- listed phase pairs must be byte-identical. This is how the
                XOR sprite contract is checked: the Partner has no readable
                framebuffer and therefore no save-under, so hide is show run
                a second time, and the screen must come back exactly.
"""

import argparse
import hashlib
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from idpmcp import Partner, raster_from_png, raster_packed   # noqa: E402
from ihx import read_entry, read_ihx                          # noqa: E402

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
IMAGE_DIR = os.path.join(ROOT, "bin", "partner-gdp")
GOLDEN_DIR = os.path.join(ROOT, "tests", "partner", "gdp-golden")
SCRATCH_DIR = os.path.join(ROOT, "build", "gdp-scratch")

LOAD_ADDR = 0x8000
STACK_TOP = 0xFF00
RUN_SLICE_TSTATES = 60_000_000
MAX_TSTATES = 4_000_000_000
MAX_PHASES = 64

WIDTH = 1024
HEIGHT = 256

# Phase pairs that must come out byte-identical. Indices are 0-based in the
# order the scenario HALTs. For the sprite scenario every "clean plate" is
# paired with the raster after the matching hide pass.
IDENTITIES = {
    "test_gdp_sprite": [
        (0, 2, "five stock cursors XOR'd in then out"),
        (3, 4, "one cursor walked across the scene"),
        (5, 7, "clipped sprites shown then hidden"),
    ],
}


def write_pbm(path, rows):
    with open(path, "wb") as fh:
        fh.write(b"P4\n%d %d\n" % (len(rows[0]), len(rows)))
        fh.write(raster_packed(rows))


def read_pbm(path):
    with open(path, "rb") as fh:
        data = fh.read()
    if not data.startswith(b"P4"):
        raise ValueError(f"{path}: not a binary PBM")
    fields = []
    pos = 2
    while len(fields) < 2:
        while pos < len(data) and data[pos:pos + 1].isspace():
            pos += 1
        if data[pos:pos + 1] == b"#":
            while data[pos:pos + 1] not in (b"\n", b""):
                pos += 1
            continue
        start = pos
        while pos < len(data) and not data[pos:pos + 1].isspace():
            pos += 1
        fields.append(int(data[start:pos]))
    pos += 1
    w, h = fields
    stride = (w + 7) // 8
    body = data[pos:pos + stride * h]
    rows = []
    for y in range(h):
        line = body[y * stride:(y + 1) * stride]
        rows.append(bytes((line[x >> 3] >> (7 - (x & 7))) & 1 for x in range(w)))
    return rows


def describe_mismatch(actual, expected, limit=8):
    diffs = [(x, y) for y in range(len(expected))
             for x in range(len(expected[y])) if actual[y][x] != expected[y][x]]
    lines = [f"{len(diffs)} pixels differ"]
    for x, y in diffs[:limit]:
        lines.append(f"    x={x:4d} y={y:3d}: got {actual[y][x]}, "
                     f"want {expected[y][x]}")
    if len(diffs) > limit:
        lines.append(f"    ... and {len(diffs) - limit} more")
    return "\n".join(lines)


def run_scenario(gdp, name):
    """Run one image to completion, returning (phase rasters, T-states)."""
    ihx = os.path.join(IMAGE_DIR, name + ".ihx")
    base, image = read_ihx(ihx)
    if base != LOAD_ADDR:
        raise RuntimeError(f"{name}: links at {base:#06x}, want {LOAD_ADDR:#06x}")
    map_path = os.path.join(IMAGE_DIR, name + ".map")
    entry = read_entry(map_path)
    finished_at = read_entry(map_path, "_gdp_finished")

    bin_path = os.path.join(SCRATCH_DIR, "image.bin")
    with open(bin_path, "wb") as fh:
        fh.write(image)

    gdp.reset(clear_memory=True)
    gdp.load_binary(bin_path, base)
    gdp.registers(pc=entry, sp=STACK_TOP, iff1=False, iff2=False)

    shot = os.path.join(SCRATCH_DIR, "phase.png")
    phases = []
    while True:
        while True:
            result = gdp.run(stop_on_halt=True, tstates=RUN_SLICE_TSTATES)
            if result.get("run", {}).get("reason") == "halted":
                break
            if result["tstates"] >= MAX_TSTATES:
                raise RuntimeError(
                    f"{name}: no HALT after {result['tstates']:,} T-states "
                    f"(pc={result['cpu']['pc']:#06x})")
        pc = result["cpu"]["pc"]
        if gdp.read_memory(pc, 1) != b"\x76":
            raise RuntimeError(f"{name}: stopped at {pc:#06x}, not a HALT")

        gdp.screenshot(shot)
        phases.append(raster_from_png(shot, WIDTH, HEIGHT))

        if gdp.read_memory(finished_at, 1)[0] == 0xA5:
            break
        if len(phases) > MAX_PHASES:
            raise RuntimeError(f"{name}: more than {MAX_PHASES} phases; is "
                               f"gdp_done() missing?")
        gdp.registers(pc=pc + 1)        # step over the HALT and continue

    return phases, gdp.status()["tstates"]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("names", nargs="*", help="scenarios to run (default: all)")
    ap.add_argument("--bless", action="store_true",
                    help="record current output as the golden images")
    args = ap.parse_args()

    os.makedirs(SCRATCH_DIR, exist_ok=True)
    os.makedirs(GOLDEN_DIR, exist_ok=True)

    names = args.names or sorted(
        f[:-4] for f in os.listdir(IMAGE_DIR)
        if f.startswith("test_") and f.endswith(".ihx"))
    if not names:
        print("no scenarios built; run `make -C tests/partner gdp`",
              file=sys.stderr)
        return 2

    failures = []
    with Partner(rom=False) as gdp:
        for name in names:
            phases, tstates = run_scenario(gdp, name)
            digest = hashlib.sha256(
                b"".join(raster_packed(p) for p in phases)).hexdigest()[:12]
            print(f"{name:24s} {len(phases)} phase(s)  "
                  f"{tstates:>10,} T  {digest}")

            for idx, rows in enumerate(phases):
                golden = os.path.join(GOLDEN_DIR, f"{name}-{idx}.pbm")
                if args.bless or not os.path.exists(golden):
                    write_pbm(golden, rows)
                    print(f"    phase {idx}: golden recorded")
                    continue
                want = read_pbm(golden)
                if want != rows:
                    failures.append(f"{name} phase {idx}:\n"
                                    f"{describe_mismatch(rows, want)}")
                    bad = os.path.join(SCRATCH_DIR, f"{name}-{idx}-actual.pbm")
                    write_pbm(bad, rows)
                    print(f"    phase {idx}: MISMATCH (wrote {bad})")

            for a, b, why in IDENTITIES.get(name, []):
                if max(a, b) >= len(phases):
                    failures.append(
                        f"{name}: identity {a}=={b} needs {max(a, b) + 1} "
                        f"phases, scenario produced {len(phases)}")
                    continue
                if phases[a] == phases[b]:
                    print(f"    phases {a}=={b} ok  ({why})")
                else:
                    failures.append(
                        f"{name}: phase {a} != phase {b} ({why})\n"
                        f"{describe_mismatch(phases[b], phases[a])}")
                    print(f"    phases {a}=={b} FAILED  ({why})")

    if failures:
        print("\n" + "\n\n".join(failures), file=sys.stderr)
        print(f"\n{len(failures)} failure(s)", file=sys.stderr)
        return 1
    print("\nall Partner GDP scenarios passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
