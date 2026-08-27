#!/usr/bin/env python3
"""Render every sample program and save its documentation screenshot.

Builds every program for every backend -- ZX Spectrum, Iskra Delta Partner,
and the Amstrad CPC in both of its display modes. Each image is run through
that machine's MCP emulator and written to docs/images/. Regenerate with:

    python3 scripts/docs/capture-manual-shots.py
"""

import os
import subprocess
import sys

from PIL import Image

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                "..", "..", "tests", "mcp"))

from cpcmcp import Cpc                                       # noqa: E402
from idpmcp import Partner                                   # noqa: E402
from ihx import read_entry, read_ihx                         # noqa: E402
from zxmcp import Spectrum                                   # noqa: E402

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
BUILD = os.path.join(ROOT, "build", "demo-shots")
IMAGES = os.path.join(ROOT, "docs", "images", "screenshots")
LOAD = 0x8000
SLICE = 60_000_000
# Comfortably longer than one video frame on either machine (ZX 69888 T).
SETTLE = 200_000

ZX_SHOTS = (
    ("demo1", "samples/demo1/src/main.c", "demo1-zx.png", True),
    # demo2 deliberately parks in an endless loop once its picture is done.
    ("demo2", "samples/demo2/src/main.c", "demo2-zx.png", False),
    ("panels", "samples/demo3/src/panels.c", "panels-zx.png", True),
    ("bounce", "samples/demo3/src/bounce.c", "bounce-zx.png", True),
)

# The CPC has two display modes behind one library, so each sample is built
# twice with a different DEMO_MODE. amstrad-cpc-mcp crops its 640x200 view
# one scanline high (see docs/todo/EMULATION-CPC.md), so these are grabbed as
# full overscan frames and cropped here instead.
CPC_DISPLAY_BOX = (64, 37, 704, 237)

CPC_SHOTS = (
    ("demo1", "samples/demo1/src/main.c", "demo1-cpc-{mode}.png", True),
    # demo2 deliberately parks in an endless loop once its picture is done.
    ("demo2", "samples/demo2/src/main.c", "demo2-cpc-{mode}.png", False),
    ("panels", "samples/demo3/src/panels.c", "panels-cpc-{mode}.png", True),
    ("bounce", "samples/demo3/src/bounce.c", "bounce-cpc-{mode}.png", True),
)

# A CPC scanline is far wider than it is tall: 640x200 on a 4:3 monitor makes
# a pixel about 2.4 times taller than wide. Saved 1:1 the picture looks
# stretched flat, so every capture is doubled vertically, which is also how
# CPC screenshots are conventionally presented.
CPC_SAVE_SIZE = (640, 400)

# A program that never halts is given a generous slice instead: five seconds
# of emulated time is far more than any of these demos needs to finish
# drawing.
CPC_FREE_RUN_FRAMES = 250

# xcc's -D takes integers only, so these are the numeric values of
# GPXM_CPC_640X200 and GPXM_CPC_320X200.
CPC_MODES = (("640x200", 0), ("320x200", 1))

PARTNER_SHOTS = (
    ("demo1", "samples/demo1/src/main.c", "demo1-partner.png", True),
    ("demo2", "samples/demo2/src/main.c", "demo2-partner.png", False),
    ("panels", "samples/demo3/src/panels.c", "panels-partner.png", True),
    ("bounce", "samples/demo3/src/bounce.c", "bounce-partner.png", True),
)


def run_in(image, script):
    subprocess.run(
        ["docker", "run", "--rm", "-u", f"{os.getuid()}:{os.getgid()}",
         "-v", f"{ROOT}:/work", "-w", "/work", image, "sh", "-lc", script],
        check=True)


def build_cpc(name, source, mode, gpxmode):
    """Link one sample for the CPC, as a raw binary at 0x8000."""
    out = f"build/demo-shots/{name}-cpc-{mode}"
    run_in("wischner/xcc-z80", f"""set -e
        mkdir -p build/demo-shots
        xcc -mz80 -std=c11 -Os -Iinclude -DDEMO_MODE={gpxmode} \
            -c -o {out}.rel {source}
        xld --oformat=binary -b _CODE={LOAD:#x} -nostartfiles -o {out}.bin \
            build/cpc/crt0-cpc.rel {out}.rel \
            $(ls build/cpc/*.rel | grep -v crt0-cpc)""")
    return os.path.join(BUILD, f"{name}-cpc-{mode}")


def capture_cpc(mach, stem, png, wait_for_halt):
    """Run a CPC binary and save its real 640x200 display area."""
    mach.reset(clear_memory=True)
    mach.load_binary(stem + ".bin", LOAD, start=LOAD)
    mach.registers(pc=LOAD, iff1=False, iff2=False)
    if wait_for_halt:
        while True:
            r = mach.run(stop_on_halt=True, frames=4)
            if (r.get("reason") or "") == "halted":
                break
    else:
        mach.run(frames=CPC_FREE_RUN_FRAMES)
    mach.run(frames=2)                      # let a whole frame scan out
    full = stem + "-full.png"
    mach.call("screenshot", path=mach.guest_path(full),
              include_border=True, monitor="color")
    (Image.open(full).crop(CPC_DISPLAY_BOX)
     .resize(CPC_SAVE_SIZE, Image.NEAREST).save(png))
    print(f"  wrote {os.path.relpath(png, ROOT)}")


def build(name, source, machine):
    """Link one sample against one backend, halting after main()."""
    out = f"build/demo-shots/{name}-{machine}"
    if machine == "zx":
        image, libdir = "wischner/xcc-z80-zx-spectrum", "build/zx"
    else:
        image, libdir = "wischner/xcc-z80-idp", "build/partner-lib"
    run_in(image, f"""set -e
        mkdir -p build/demo-shots
        xas -o {out}-crt0.rel samples/demo3/src/crt0-shot.s
        xcc -mz80 -std=c11 -Os -Iinclude -c -o {out}.rel {source}
        xcc -mz80 -nostartfiles -o {out}.ihx {out}-crt0.rel {out}.rel {libdir}/*.rel \
            -Wl,--oformat=ihx -Wl,-b,_CODE={LOAD:#x} -Wl,-Map={out}.map""")
    return os.path.join(BUILD, f"{name}-{machine}")


def capture(mach, stem, png, is_zx, wait_for_halt):
    base, image = read_ihx(stem + ".ihx")
    entry = read_entry(stem + ".map", "init")
    binp = stem + ".bin"
    open(binp, "wb").write(image)
    mach.reset(clear_memory=True)
    mach.load_binary(binp, base)
    mach.registers(pc=entry, sp=0xFF00, iff1=False, iff2=False)
    while True:
        r = mach.run(stop_on_halt=True, tstates=SLICE)
        reason = r.get("reason") or r.get("run", {}).get("reason")
        if reason == "halted" or not wait_for_halt:
            break
    # A screenshot shows the last frame the video hardware finished, not the
    # bytes currently in display memory. main() almost always ends part-way
    # through a frame, so whatever it drew last is still missing from that
    # frame and would be cropped out of the PNG. Let one more frame scan out
    # with the CPU already halted so the picture is whole.
    mach.run(stop_on_halt=False, tstates=SETTLE)
    # guest_path maps into the container mount when the server runs in
    # Docker, and leaves the path alone for a local build.
    args = {"path": mach.guest_path(png), "include_border": False}
    if is_zx:
        args["scale"] = 2
    mach.call("screenshot", **args)
    print(f"  wrote {os.path.relpath(png, ROOT)}")


def main():
    os.makedirs(BUILD, exist_ok=True)
    os.makedirs(IMAGES, exist_ok=True)
    # Build exactly what the links below consume. "build" is not enough: it
    # makes the ZX objects but only the Partner *test* image, leaving
    # build/partner-lib/*.rel however stale it happened to be, so a change to
    # src/partner would silently not reach the Partner screenshots.
    subprocess.run(["make", "-C", os.path.join(ROOT, "src"),
                    "zx-lib-objs", "partner-lib-objs", "cpc-lib-objs"],
                   check=True, stdout=subprocess.DEVNULL)

    zx_stems = {
        name: build(name, source, "zx")
        for name, source, _png, _wait in ZX_SHOTS
    }
    partner_stems = {
        name: build(name, source, "partner")
        for name, source, _png, _wait in PARTNER_SHOTS
    }

    print("ZX Spectrum:")
    with Spectrum() as zx:
        for name, _source, png, wait in ZX_SHOTS:
            capture(zx, zx_stems[name], os.path.join(IMAGES, png), True, wait)
    print("Iskra Delta Partner:")
    with Partner(rom=False) as gdp:
        for name, _source, png, wait in PARTNER_SHOTS:
            capture(gdp, partner_stems[name], os.path.join(IMAGES, png),
                    False, wait)

    print("Amstrad CPC:")
    for mode, gpxmode in CPC_MODES:
        stems = {name: build_cpc(name, source, mode, gpxmode)
                 for name, source, _png, _wait in CPC_SHOTS}
        with Cpc() as cpc:
            for name, _source, png, wait in CPC_SHOTS:
                capture_cpc(cpc, stems[name],
                            os.path.join(IMAGES, png.format(mode=mode)), wait)
    return 0


if __name__ == "__main__":
    sys.exit(main())
