#!/usr/bin/env python3
import pathlib
import struct
import subprocess
import zlib

ROOT = pathlib.Path(__file__).resolve().parents[3]
OUT_DIR = ROOT / "bin" / "stub-visuals"
RAW_DIR = OUT_DIR / "raw"
HARNESS = ROOT / "build" / "tests" / "generate_stub_visuals"
SCALE = 2

SCENES = {
    "gpx_create": [
        "Expected: completely empty screen.",
        "This API initializes context only; no pixels should be set.",
    ],
    "gpx_destroy": [
        "Expected: completely empty screen.",
        "This API tears down context only; no pixels should be set.",
    ],
    "gpx_width": [
        "Expected: completely empty screen.",
        "Getter call only; no framebuffer write is expected.",
    ],
    "gpx_height": [
        "Expected: completely empty screen.",
        "Getter call only; no framebuffer write is expected.",
    ],
    "gpx_clrscr": [
        "Expected: completely empty screen.",
        "Scene draws one pixel then clears; final frame must be blank.",
    ],
    "gpx_draw_pixel": [
        "Expected: one foreground pixel at (16,16).",
        "All other pixels should remain clear.",
    ],
    "gpx_draw_line": [
        "Expected: one solid line from (8,8) to (120,80).",
        "All non-line pixels should remain clear.",
    ],
    "gpx_draw_rectangle": [
        "Expected: one rectangle outline with corners (20,20) and (100,70).",
        "Interior should be empty.",
    ],
    "gpx_fill_rectangle": [
        "Expected: one filled rectangle from (20,20) to (100,70).",
        "Fill uses alternating row pattern bytes 0xAA/0x55.",
    ],
    "gpx_draw_bmp": [
        "Expected: one 8x8 checker bitmap at (30,30).",
        "All other pixels should remain clear.",
    ],
    "gpx_get_system_font": [
        "Expected: completely empty screen.",
        "Getter call only; no framebuffer write is expected.",
    ],
    "gpx_get_tiny_font": [
        "Expected: completely empty screen.",
        "Getter call only; no framebuffer write is expected.",
    ],
    "gpx_get_stock_bmp": [
        "Expected: completely empty screen.",
        "Getter call only; no framebuffer write is expected.",
    ],
    "gpx_set_page": [
        "Expected: completely empty screen.",
        "Page-selection calls are no-ops in ZX stub and should not touch VRAM.",
    ],
    "gpx_measure_text": [
        "Expected: completely empty screen.",
        "Measurement call only; no framebuffer write is expected.",
    ],
    "gpx_draw_text": [
        "Expected: one glyph for 'A' at (20,20) using stub font renderer.",
        "All other pixels should remain clear.",
    ],
}


def zx_pixel(raw: bytes, x: int, y: int) -> int:
    off = ((y & 0x07) << 8) + ((y & 0x38) << 2) + ((y & 0xC0) << 5) + (x >> 3)
    bit = 0x80 >> (x & 7)
    return 1 if (raw[off] & bit) else 0


def raw_to_pixels(raw: bytes):
    if len(raw) != 6144:
        raise ValueError(f"expected 6144 bytes, got {len(raw)}")
    w, h = 256, 192
    out = [0] * (w * h)
    for y in range(h):
        base = y * w
        for x in range(w):
            out[base + x] = zx_pixel(raw, x, y)
    return w, h, out


def scale_pixels(w: int, h: int, pixels, scale: int):
    if scale <= 1:
        return w, h, pixels
    sw, sh = w * scale, h * scale
    spx = [0] * (sw * sh)
    for y in range(h):
        for x in range(w):
            v = pixels[y * w + x]
            for yy in range(scale):
                row = (y * scale + yy) * sw
                start = row + x * scale
                for xx in range(scale):
                    spx[start + xx] = v
    return sw, sh, spx


def png_chunk(tag: bytes, data: bytes) -> bytes:
    return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)


def write_png(path: pathlib.Path, w: int, h: int, pixels):
    rows = bytearray()
    for y in range(h):
        rows.append(0)
        row_base = y * w
        for x in range(w):
            on = pixels[row_base + x]
            c = 0 if on else 255
            rows.extend((c, c, c))

    ihdr = struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0)
    idat = zlib.compress(bytes(rows), level=9)

    out = bytearray()
    out.extend(b"\x89PNG\r\n\x1a\n")
    out.extend(png_chunk(b"IHDR", ihdr))
    out.extend(png_chunk(b"IDAT", idat))
    out.extend(png_chunk(b"IEND", b""))
    path.write_bytes(out)


def build_and_run_harness():
    RAW_DIR.mkdir(parents=True, exist_ok=True)
    HARNESS.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(
        [
            "gcc",
            "-std=c11",
            "-DGPX_STUB_HOST",
            "-Iinclude",
            "-O0",
            "-Wall",
            "-Wextra",
            "-o",
            str(HARNESS),
            "tests/zx/stub/generate_stub_visuals.c",
            "tests/zx/stub/gpx_stub.c",
        ],
        check=True,
        cwd=ROOT,
    )
    subprocess.run([str(HARNESS), str(RAW_DIR)], check=True, cwd=ROOT)


def write_scene_md(name: str, png_name: str):
    notes = SCENES[name]
    md = []
    md.append(f"# {name}")
    md.append("")
    md.append(f"Image: `{png_name}`")
    md.append("")
    md.append("What to look for:")
    for note in notes:
        md.append(f"- {note}")
    (OUT_DIR / f"{name}.md").write_text("\n".join(md) + "\n", encoding="utf-8")


def write_scene_txt(name: str, vram_writes: int, passed: bool, expected: str, actual: str):
    lines = [
        f"{name}",
        "",
        "No framebuffer drawing artifact generated.",
        f"ZX video-memory writes detected: {vram_writes}",
        f"Expected: {expected}",
        f"Actual:   {actual}",
        f"Result:   {'PASS' if passed else 'FAIL'}",
        "",
        "Interpretation: this API did not touch ZX video RAM in this scene.",
    ]
    (OUT_DIR / f"{name}.txt").write_text("\n".join(lines) + "\n", encoding="utf-8")


def write_index(generated):
    lines = [
        "# Stub Visual Report",
        "",
        "Generated visuals for public `gpx_` APIs implemented in `tests/zx/stub/gpx_stub.c`.",
        "",
    ]
    for name, artifact in generated:
        lines.append(f"- `{name}`: {artifact}")
    (OUT_DIR / "README.md").write_text("\n".join(lines) + "\n", encoding="utf-8")


def read_vram_writes(meta_path: pathlib.Path) -> int:
    values = {}
    for line in meta_path.read_text(encoding="utf-8").splitlines():
        if "=" in line:
            k, v = line.split("=", 1)
            values[k.strip()] = v.strip()
    if "vram_writes" not in values:
        raise ValueError(f"bad meta file: {meta_path}")
    return int(values["vram_writes"])


def read_meta(meta_path: pathlib.Path):
    values = {}
    for line in meta_path.read_text(encoding="utf-8").splitlines():
        if "=" in line:
            k, v = line.split("=", 1)
            values[k.strip()] = v.strip()
    return {
        "vram_writes": int(values.get("vram_writes", "0")),
        "pass": values.get("pass", "0") == "1",
        "expected": values.get("expected", ""),
        "actual": values.get("actual", ""),
    }


def cleanup_scene_outputs():
    for name in SCENES:
        for ext in (".png", ".md", ".txt"):
            p = OUT_DIR / f"{name}{ext}"
            if p.exists():
                p.unlink()


def main():
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    build_and_run_harness()
    cleanup_scene_outputs()

    generated = []
    for name in SCENES:
        raw_path = RAW_DIR / f"{name}.raw"
        meta_path = RAW_DIR / f"{name}.meta"
        if not raw_path.exists():
            raise FileNotFoundError(raw_path)
        if not meta_path.exists():
            raise FileNotFoundError(meta_path)

        meta = read_meta(meta_path)
        vram_writes = meta["vram_writes"]
        raw = raw_path.read_bytes()
        if vram_writes == 0:
            write_scene_txt(
                name,
                vram_writes,
                meta["pass"],
                meta["expected"],
                meta["actual"],
            )
            generated.append((name, f"`{name}.txt`"))
        else:
            w, h, px = raw_to_pixels(raw)
            sw, sh, spx = scale_pixels(w, h, px, scale=SCALE)
            png_name = f"{name}.png"
            write_png(OUT_DIR / png_name, sw, sh, spx)
            write_scene_md(name, png_name)
            generated.append((name, f"`{name}.png`, `{name}.md`"))

    write_index(generated)
    print(f"generated {len(generated)} scene artifacts under {OUT_DIR}")


if __name__ == "__main__":
    main()
