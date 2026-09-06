#!/usr/bin/env python3
"""Check pixel ABI, signed clips and circles on all five display modes.

Run after ``make -C tests/crossbench build``. Pixel expectations are computed
independently; circle expectations follow the C oracle's midpoint recurrence.
The Partner checks read the actual MCP GDP raster, including its 512-row mode.
"""
import argparse
import struct
from pathlib import Path

from cpcmcp import Cpc, cpc_offset
from idpmcp import Partner
from ihx import read_entry, read_ihx
from zxmcp import Spectrum, zx_offset

ROOT = Path(__file__).resolve().parents[2]
SCRATCH = ROOT / "build/pixel-core"


def word(value):
    return struct.pack("<H", value & 65535)


def signed(value):
    return (value + 32768) % 65536 - 32768


def circle_points(x, y, radius):
    if radius < 0:
        return
    if radius == 0:
        yield x, y
        return
    yield from ((x, y + radius), (x, y - radius),
                (x + radius, y), (x - radius, y))
    xn, yn = 0, radius
    error, ddx, ddy = 1 - radius, 1, -2 * radius
    while xn < yn:
        xn += 1
        ddx = signed(ddx + 2)
        error = signed(error + ddx)
        if error >= 0:
            yn -= 1
            ddy = signed(ddy + 2)
            error = signed(error + ddy)
        if xn <= yn:
            yield from ((x + xn, y + yn), (x - xn, y + yn),
                        (x + xn, y - yn), (x - xn, y - yn))
        if xn < yn:
            yield from ((x + yn, y + xn), (x - yn, y + xn),
                        (x + yn, y - xn), (x - yn, y - xn))


def run_backend(backend, mode):
    width, height = {"zx": (256, 192), "cpc": (320 if mode else 640, 200),
                     "partner": (1024, 512 if mode else 256)}[backend]
    tag = backend if backend != "cpc" else f"cpc-{width}x200"
    image = ROOT / "bin/xbench" / f"xb_circle_{tag}"
    symbols = image.with_suffix(".map")
    address = lambda name: read_entry(symbols, name)
    factory = {"zx": Spectrum, "cpc": Cpc, "partner": Partner}[backend]
    with factory(**({"rom": False} if backend == "partner" else {})) as machine:
        machine.reset(clear_memory=True)
        if backend == "cpc":
            machine.load_binary(image.with_suffix(".bin"), 0x8000)
        else:
            base, binary = read_ihx(image.with_suffix(".ihx"))
            path = SCRATCH / f"{backend}.bin"
            path.write_bytes(binary)
            machine.load_binary(path, base)

        def write(where, data):
            machine.call("write_memory", address=where, data=bytes(data).hex())

        def invoke(name, args=b"", **registers):
            write(0x7000, b"\x76")
            write(0x7F00, word(0x7000) + args)
            machine.registers(pc=address(name), sp=0x7F00, ix=0x1357, iy=0x2468,
                              iff1=False, iff2=False, **registers)
            result = machine.run(stop_on_halt=True, tstates=40_000_000)
            assert result.get("reason", result.get("run", {}).get("reason")) == "halted", result
            regs = machine.registers()
            assert regs["sp"] == 0x7F02 + len(args), (name, regs["sp"])
            if name in ("__gpx_plot_raw", "_gpx_draw_pixel"):
                assert (regs["ix"], regs["iy"]) == (0x1357, 0x2468), (name, regs)

        invoke("_gpx_create", af=mode << 8)
        count = 0
        size = {"zx": 6144, "cpc": 16384, "partner": width * height}[backend]
        expected = bytearray(size)

        def plot(x, y, color, mode, clip):
            x, y = signed(x), signed(y)
            if not (0 <= x < width and 0 <= y < height):
                return
            if clip and not (clip[0] <= x <= clip[2] and clip[1] <= y <= clip[3]):
                return
            if backend == "partner":
                offset, mask = y * width + x, 1
            elif backend == "zx":
                offset, mask = zx_offset(x, y), 0x80 >> (x % 8)
            else:
                per_byte = 4 if mode_display else 8
                offset, mask = cpc_offset(x // per_byte, y), 0x80 >> (x % per_byte)
            if mode:
                expected[offset] ^= mask
            elif color:
                expected[offset] |= mask
            else:
                expected[offset] &= 255 ^ mask

        def check(context):
            if backend == "partner":
                invoke("__ef9367_wait_ready")
                actual = b"".join(machine.raster(SCRATCH / "partner.png", width, height))
            else:
                actual = machine.screen()
            assert actual == expected, (backend, width, height, context,
                                       sum(a != b for a, b in zip(actual, expected)))

        mode_display = mode
        edges = (-32768, -1, 0, 1, 127, 255, 256, 511, 512, 639, 1023, 1024, 32767)
        cases = []
        for axis in range(4):
            for edge in edges:
                clip = [-32768, -32768, 32767, 32767]
                clip[axis] = edge
                trial = len(cases)
                cases.append(((37 * trial + 3) % width, (17 * trial + 5) % height, clip))
        cases += [(x, y, None) for x, y in ((-32768, 0), (-1, 0), (0, -1),
                  (width, 0), (0, height), (32767, 32767), (0, 0),
                  (width - 1, height - 1), (256, 255), (512, 256))]
        # Each batch uses distinct pixels, so later calls cannot hide an
        # incorrect clip decision. The erase pass starts with the set pass.
        for color, draw_mode in ((1, 0), (0, 0), (0, 1), (1, 1)):
            for trial, (x, y, clip) in enumerate(cases):
                clip_address = 0x7100 if clip else 0
                if clip:
                    write(clip_address, b"".join(map(word, clip)))
                if (trial + draw_mode) & 1:
                    invoke("__gpx_plot_raw", de=x & 65535, hl=y & 65535,
                           bc=clip_address, af=(color | draw_mode << 1) << 8)
                else:
                    invoke("_gpx_draw_pixel", word(y) + bytes((color, draw_mode)) + word(clip_address),
                           de=x & 65535, hl=0)
                plot(x, y, color, draw_mode, clip)
                count += 1
                if trial % 16 == 15 or trial == len(cases) - 1:
                    check(("pixels", count))

        for trial in range(24):
            x, y = ((width // 2, height // 2), (0, 0),
                    (width - 1, height - 1), (-12, height // 2),
                    (32767, -32768), (256, 256))[trial % 6]
            radius = (-1, 0, 1, 2, 5, 33, 110, 257)[trial % 8]
            clip = ((-32768, -32768, 32767, 32767), (9, 7, width - 10, height - 8),
                    (width - 1, height - 1, 0, 0), None)[trial % 4]
            clip_address = 0x7100 if clip else 0
            if clip:
                write(clip_address, b"".join(map(word, clip)))
            color, draw_mode = trial & 1, (trial >> 1) & 1
            invoke("_gpx_draw_circle", word(y) + word(radius) + bytes((color, draw_mode)) + word(clip_address),
                   de=x & 65535, hl=0)
            for px, py in circle_points(x, y, radius):
                plot(px, py, color, draw_mode, clip)
            check(("circle", trial))
        print(f"{backend} {width}x{height}: {count} pixel ABI/clip and 24 circle cases passed", flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("backends", nargs="*", choices=("zx", "partner", "cpc"))
    args = parser.parse_args()
    SCRATCH.mkdir(parents=True, exist_ok=True)
    for backend in args.backends or ("zx", "partner", "cpc"):
        for mode in ((0,) if backend == "zx" else (0, 1)):
            run_backend(backend, mode)


if __name__ == "__main__":
    main()
