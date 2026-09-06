#!/usr/bin/env python3
"""Independent CPC bitmap/sprite checks over arbitrary complete VRAM images.

Run after make -C tests/cpc build. --root selects a separately built checkout
for before/after measurements. Padding bytes and the mode 1 second plane
are checked as well as visible pixels; no libgpx renderer is used as oracle.
"""

import argparse
import json
import random
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tests/cpc"))
from optimization_regressions import Cpc, check, cpc_offset, invoke, pixel, word, write  # noqa: E402


def run(root):
    rng = random.Random(0x5A7E)
    results = {}
    for mode, ppb in [(0, 8), (1, 4)]:
        image = root / "build/cpc-tests" / f"cpc_prims-{ppb * 80}x200.bin"
        with Cpc(workdir=root) as m:
            m.reset(clear_memory=True)
            m.load_binary(image, 0x8000)
            invoke(m, image, "_gpx_create", af=mode << 8)
            memory = bytearray(rng.randbytes(16384))
            write(m, 0xC000, memory)
            total = 0
            for width in range(1, 17):
                for shift in range(8):
                    for edge in (False, True):
                        h = rng.randrange(1, 17)
                        y = rng.choice((0, 7, 8, 15, 183, 200 - h))
                        x = (ppb * 80 - 8 if edge else 32) + shift
                        expected = bytearray(32)
                        for ry in range(h):
                            for rx in range(width):
                                off = cpc_offset((x + rx) // ppb, y + ry)
                                mask = 0x80 >> ((x + rx) % ppb)
                                if memory[off] & mask:
                                    expected[ry * 2 + rx // 8] |= 0x80 >> (rx % 8)
                        write(m, 0x2200, b"\xa5" * 40)
                        start = m.status()["tstates"]
                        r = invoke(
                            m,
                            image,
                            "__gpx_store_background",
                            hl=0x2200,
                            de=x,
                            bc=(y << 8) | width,
                            af=h << 8,
                            ix=0x1234,
                            iy=0x5678,
                        )
                        total += m.status()["tstates"] - start
                        got = m.read_memory(0x2205, 32)
                        assert got == expected, (
                            mode,
                            width,
                            shift,
                            edge,
                            got.hex(),
                            expected.hex(),
                        )
                        assert r["ix"] == 0x1234 and r["iy"] == 0x5678, r
                        assert m.read_memory(0x2200, 5) == b"\xa5" * 5
                        assert m.read_memory(0x2225, 3) == b"\xa5" * 3
                        check(
                            m,
                            memory,
                            ("capture wrote screen", mode, width, shift, edge),
                        )
            results[f"capture-{ppb * 80}"] = total
            # Larger bitmap rows, all compositors, non-minimal strides and deep
            # clipping. The expected full VRAM image is composed one pixel at a time.
            expected = bytearray(memory)
            bitmap_tstates = 0
            for trial in range(384):
                bw = rng.choice((1, 7, 8, 9, 16, 31, 32, 63, 64, 127, 128))
                bh = rng.choice((1, 7, 8, 16, 32, 64, 255))
                stride = rng.randrange((bw + 7) // 8, 17)
                masked = trial % 2
                payload = rng.randbytes(stride * bh * (1 + masked))
                blob = (
                    bytes((stride - 1 + 16 * masked, bw, bh))
                    + word(len(payload))
                    + payload
                )
                write(m, 0x2000, blob)
                x = rng.choice(
                    (
                        -127,
                        -7,
                        -1,
                        0,
                        8 + trial % 8,
                        250,
                        280,
                        ppb * 80 - 3,
                        ppb * 80 - bw,
                    )
                )
                y = rng.choice((-254, -7, -1, 0, 7, 15, 190, 199))
                clip = (
                    (x + 2, y + 1, x + bw - 2, y + bh - 2) if trial % 3 == 0 else None
                )
                if clip:
                    write(m, 0x5000, b"".join(map(word, clip)))
                draw_mode = (0x80, 0, 1, 0x40)[(trial // 2) % 4]
                color = (trial // 8) & 1
                start = m.status()["tstates"]
                r = invoke(
                    m,
                    image,
                    "_gpx_draw_bmp_clip",
                    word(y) + word(0x2000) + word(0x5000 if clip else 0),
                    hl=0,
                    de=x & 65535,
                    bc=(draw_mode << 8) | color,
                    ix=0x1234,
                    iy=0x5678,
                )
                bitmap_tstates += m.status()["tstates"] - start
                assert r["ix"] == 0x1234 and r["iy"] == 0x5678, r
                for sy in range(max(0, -y), min(bh, 200 - y)):
                    for sx in range(max(0, -x), min(bw, ppb * 80 - x)):
                        px, py = x + sx, y + sy
                        if clip and not (
                            clip[0] <= px <= clip[2] and clip[1] <= py <= clip[3]
                        ):
                            continue
                        idx = sy * stride * (1 + masked) + sx // 8
                        mask = 0x80 >> (sx % 8)
                        source = bool(payload[idx + masked * stride] & mask)
                        keep = bool(payload[idx] & mask)

                        def op(old):
                            if draw_mode == 0x80:
                                return (
                                    (old and keep or source)
                                    if masked
                                    else old or source
                                )
                            if draw_mode == 1:
                                return old != source
                            if draw_mode == 0x40:
                                return bool(color) if source else old
                            return source if color else not source

                        pixel(expected, ppb, px, py, op)
                check(m, expected, ("wide bitmap", mode, trial))
            results[f"bitmap-{ppb * 80}"] = bitmap_tstates
            write(m, 0xC000, memory)
            # Save/show/hide independent full-screen oracle, including packed plane.
            for trial in range(192):
                w = rng.randrange(1, 17)
                h = rng.randrange(1, 17)
                stride = rng.randrange((w + 7) // 8, 4)
                masked = trial % 2
                payload = rng.randbytes(stride * h * (1 + masked))
                blob = (
                    bytes([stride - 1 + 16 * masked, w, h])
                    + word(len(payload))
                    + payload
                )
                write(m, 0x2000, blob)
                x = rng.choice(
                    (trial % 16, ppb * 80 - 1, ppb * 80 - 8, ppb * 80 - 16, 255, 256)
                )
                x = min(x, ppb * 80 - 1)
                y = rng.choice((0, 7, 15, 31, 183, 199))
                clip = (x + 1, y + 1, x + w - 2, y + h - 2) if trial % 3 == 0 else None
                if clip:
                    write(m, 0x2100, b"".join(map(word, clip)))
                spr = (
                    word(x)
                    + word(y)
                    + word(0x2000)
                    + word(0x2200)
                    + word(0x2100 if clip else 0)
                )
                write(m, 0x2300, spr)
                expected = bytearray(memory)
                for sy in range(h):
                    for sx in range(w):
                        px, py = x + sx, y + sy
                        if px >= ppb * 80 or py >= 200:
                            continue
                        if clip and not (
                            clip[0] <= px <= clip[2] and clip[1] <= py <= clip[3]
                        ):
                            continue
                        idx = sy * stride * (1 + masked) + sx // 8
                        mask = 0x80 >> (sx % 8)
                        src = bool(payload[idx + masked * stride] & mask)
                        keep = bool(payload[idx] & mask)
                        pixel(
                            expected,
                            ppb,
                            px,
                            py,
                            lambda old, s=src, k=keep: (old and k or s)
                            if masked
                            else old or s,
                        )
                invoke(m, image, "_gpx_show_sprite", de=0x2300, hl=0)
                check(m, expected, ("show", mode, trial))
                invoke(m, image, "_gpx_hide_sprite", de=0x2300, hl=0)
                check(m, memory, ("restore", mode, trial))
        print(mode, "256 captures, 384 bitmaps, 192 sprite pairs passed")
    print(json.dumps(results))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=ROOT)
    run(parser.parse_args().root.resolve())
