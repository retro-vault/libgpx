#!/usr/bin/env python3
"""Cross-backend conformance: the same program, the same pixels.

Anything built on top of libgpx has to behave the same everywhere, so the
backends must agree pixel for pixel on everything except the bitmap payload
format (Partner takes vector move-streams, the ZX and CPC take rasters).

A scenario is compiled for each backend, run on its emulator, and the
top-left 256x192 of each raster is compared against the ZX. Scenarios stay
inside that box on purpose.

The CPC is compared in **both** display modes and is held to an exact match:
it shares the ZX's font, stock cursors and software rasteriser, so it has no
accepted divergence at all. That is what makes it the tightest gate in the
suite -- a masked-sprite bug that survived the CPC's own golden rasters
would have failed here immediately.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from cpcmcp import Cpc, SCREEN_BASE, cpc_offset                # noqa: E402
from idpmcp import Partner, raster_from_png                   # noqa: E402
from ihx import read_entry, read_ihx                          # noqa: E402
from zxmcp import Spectrum, zx_offset                         # noqa: E402

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
IMAGE_DIR = os.path.join(ROOT, "bin", "conf")
SCRATCH = os.path.join(ROOT, "build", "conf")

W, H = 256, 192

# Divergences that are accepted, with the most pixels each may differ by.
# Anything not listed here must match exactly; anything listed that drifts
# past its budget is still a failure, so an accepted difference cannot
# quietly grow. Keyed by (scenario, phase).
ACCEPTED = {
    ("conf_lines", 0): (
        260,
        "slanted solid lines: the EF9367 vector generator picks its own "
        "interior pixels. Endpoints, clipping and patterns still match; "
        "walking diagonals in software instead measured 84x slower."),
    ("conf_bitmaps", 3): (
        200,
        "stock cursors via gpx_show_sprite: the Partner has no readable "
        "display memory, so it XORs a vector payload instead of blitting a "
        "raster and saving what was underneath. The artwork therefore "
        "differs, which is the standing bitmap-payload exception. The "
        "clipped phases either side of this one match exactly on all three "
        "backends, so the clipping decisions themselves are conformant."),
    ("conf_octants", 0): (
        50,
        "slanted solid lines, all eight octants: the same EF9367 vector "
        "generator divergence as conf_lines phase 0. Only the solid phases "
        "differ -- the patterned fans either side of this one match exactly, "
        "because a non-solid pattern is drawn in software on the Partner."),
    ("conf_octants", 2): (
        10,
        "steep solid rays: EF9367 vector generator again, y-major this time. "
        "The patterned rays in the same phase match exactly."),
    ("conf_lines", 8): (
        400,
        "XOR text: both backends knock the glyphs out of the ink, but the "
        "glyphs themselves are different faces (see phase 9). What is "
        "checked here is that XOR reaches the text at all."),
    ("conf_lines", 9): (
        1200,
        "text: the backends ship different fonts -- ZX a raster 8-pixel "
        "face, Partner an Unscii-8 vector face. Glyph shapes cannot match, and "
        "font payloads follow the bitmap-format exception."),
}
LOAD_ADDR = 0x8000
STACK_TOP = 0xFF00
SLICE = 60_000_000


def _phases_zx(zx, name):
    base, image = read_ihx(os.path.join(IMAGE_DIR, name + "_zx.ihx"))
    map_path = os.path.join(IMAGE_DIR, name + "_zx.map")
    entry = read_entry(map_path)
    finished = read_entry(map_path, "_gdp_finished")
    binp = os.path.join(SCRATCH, "zx.bin")
    open(binp, "wb").write(image)

    zx.reset(clear_memory=True)
    zx.load_binary(binp, base)
    zx.registers(pc=entry, sp=STACK_TOP, iff1=False, iff2=False)
    out = []
    while True:
        while True:
            r = zx.run(stop_on_halt=True, tstates=SLICE)
            if r.get("reason") == "halted" or r.get("run", {}).get(
                    "reason") == "halted":
                break
        disp = zx.read_memory(0x4000, 6144)
        out.append([bytes((disp[zx_offset(x, y)] >> (7 - (x & 7))) & 1
                          for x in range(W)) for y in range(H)])
        if zx.read_memory(finished, 1)[0] == 0xA5:
            break
        pc = zx.status()["pc"]
        zx.registers(pc=pc + 1)
    return out


def _phases_partner(gdp, name):
    base, image = read_ihx(os.path.join(IMAGE_DIR, name + "_partner.ihx"))
    map_path = os.path.join(IMAGE_DIR, name + "_partner.map")
    entry = read_entry(map_path)
    finished = read_entry(map_path, "_gdp_finished")
    binp = os.path.join(SCRATCH, "partner.bin")
    open(binp, "wb").write(image)

    gdp.reset(clear_memory=True)
    gdp.load_binary(binp, base)
    gdp.registers(pc=entry, sp=STACK_TOP, iff1=False, iff2=False)
    shot = os.path.join(SCRATCH, "partner.png")
    out = []
    while True:
        while True:
            r = gdp.run(stop_on_halt=True, tstates=SLICE)
            if r.get("run", {}).get("reason") == "halted":
                break
        gdp.screenshot(shot)
        full = raster_from_png(shot)
        out.append([row[:W] for row in full[:H]])
        if gdp.read_memory(finished, 1)[0] == 0xA5:
            break
        gdp.registers(pc=r["cpu"]["pc"] + 1)
    return out


def _phases_cpc(cpc, name, mode, per_byte):
    """Run the CPC image and return the top-left 256x192 of each phase.

    The raster is read out of display memory rather than through the
    emulator's screenshot crop, which is one scanline high.
    """
    stem = os.path.join(IMAGE_DIR, f"{name}_cpc-{mode}")
    finished = _read_map_symbol(stem + ".map", "_gdp_finished")

    cpc.reset(clear_memory=True)
    cpc.load_binary(stem + ".bin", LOAD_ADDR, start=LOAD_ADDR)
    cpc.registers(pc=LOAD_ADDR, iff1=False, iff2=False)
    out = []
    while True:
        while True:
            r = cpc.run(stop_on_halt=True, frames=8)
            if (r.get("reason") or "") == "halted":
                break
        mem = cpc.read_memory(SCREEN_BASE, 0x4000)
        rows = []
        for y in range(H):
            row = bytearray(W)
            for x in range(W):
                b = mem[cpc_offset(x // per_byte, y)]
                row[x] = 1 if b & (0x80 >> (x % per_byte)) else 0
            rows.append(bytes(row))
        out.append(rows)
        if cpc.read_memory(finished, 1)[0] == 0xA5:
            break
        cpc.registers(pc=cpc.status()["pc"] + 1)
    return out


def _read_map_symbol(map_path, name):
    with open(map_path) as fh:
        for line in fh:
            parts = line.split()
            if len(parts) >= 2 and parts[1] == name:
                return int(parts[0], 16)
    raise RuntimeError(f"{map_path}: no symbol {name}")


def compare(name, zx_phases, p_phases, limit=6, other="partner",
            accepted=True):
    fails = []
    if len(zx_phases) != len(p_phases):
        fails.append(f"{name}: ZX produced {len(zx_phases)} phases, "
                     f"{other} {len(p_phases)}")
        return fails
    for i, (z, p) in enumerate(zip(zx_phases, p_phases)):
        diffs = [(x, y) for y in range(H) for x in range(W) if z[y][x] != p[y][x]]
        allowed = ACCEPTED.get((name, i)) if accepted else None
        if not diffs:
            print(f"  phase {i}: identical")
            continue
        rows = sorted({y for _, y in diffs})
        if allowed and len(diffs) <= allowed[0]:
            print(f"  phase {i}: {len(diffs)} pixels differ, within the "
                  f"{allowed[0]} allowed -- {allowed[1]}")
            continue
        print(f"  phase {i}: {len(diffs)} pixels differ "
              f"on {len(rows)} rows (y={rows[0]}..{rows[-1]})")
        for x, y in diffs[:limit]:
            print(f"      x={x:3d} y={y:3d}: zx={z[y][x]} {other}={p[y][x]}")
        if len(diffs) > limit:
            print(f"      ... and {len(diffs) - limit} more")
        if allowed:
            fails.append(f"{name} phase {i}: {len(diffs)} pixels differ, "
                         f"over the {allowed[0]} allowed for: {allowed[1]}")
        else:
            fails.append(f"{name} phase {i}: {len(diffs)} pixels differ")
    return fails


def main():
    os.makedirs(SCRATCH, exist_ok=True)
    names = sys.argv[1:] or sorted(
        f[:-len("_zx.ihx")] for f in os.listdir(IMAGE_DIR)
        if f.endswith("_zx.ihx"))
    fails = []
    for name in names:
        print(f"{name}:")
        with Spectrum() as zx:
            zp = _phases_zx(zx, name)

        print("  vs Iskra Delta Partner:")
        with Partner(rom=False) as gdp:
            pp = _phases_partner(gdp, name)
        fails += compare(name, zp, pp, other="partner")

        # The CPC shares the ZX's font, cursors and rasteriser, so it is held
        # to an exact match in both of its display modes.
        for mode, per_byte in (("640x200", 8), ("320x200", 4)):
            print(f"  vs Amstrad CPC {mode}:")
            with Cpc() as cpc:
                cp = _phases_cpc(cpc, name, mode, per_byte)
            fails += compare(name, zp, cp, other=f"cpc-{mode}",
                             accepted=False)
    if fails:
        print(f"\n{len(fails)} divergence(s)")
        return 1
    print("\nbackends agree, apart from the documented exceptions above")
    return 0


if __name__ == "__main__":
    sys.exit(main())
