#!/usr/bin/env python3
import pathlib
import struct
import subprocess
import zlib

ROOT = pathlib.Path(__file__).resolve().parents[3]
OUT_DIR = ROOT / "bin" / "lib-visuals"
RAW_DIR = OUT_DIR / "raw"
HARNESS = ROOT / "build" / "tests" / "export_lib_visuals"
SCALE = 2


def zx_pixel(raw: bytes, x: int, y: int) -> int:
    off = ((y & 0x07) << 8) + ((y & 0x38) << 2) + ((y & 0xC0) << 5) + (x >> 3)
    bit = 0x80 >> (x & 7)
    return 1 if (raw[off] & bit) else 0


def raw_to_pixels(raw: bytes):
    if len(raw) != 0x1800:
        raise ValueError(f"expected 0x1800 bytes, got {len(raw)}")
    w, h = 256, 192
    out = [0] * (w * h)
    for y in range(h):
        base = y * w
        for x in range(w):
            out[base + x] = zx_pixel(raw, x, y)
    return w, h, out


def stack_pixels(top, bottom, w=256, h=192):
    stacked = [0] * (w * (h * 2))
    stacked[0 : w * h] = top
    stacked[w * h : w * h * 2] = bottom
    return w, h * 2, stacked


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


def read_meta(meta_path: pathlib.Path):
    values = {}
    for line in meta_path.read_text(encoding="utf-8").splitlines():
        if "=" in line:
            k, v = line.split("=", 1)
            values[k.strip()] = v.strip()
    return values


def write_case_txt(name: str, values: dict):
    real_ok = values.get("real_ok", "0") == "1"
    oracle_ok = values.get("oracle_ok", "0") == "1"
    match = values.get("match", "0") == "1"
    diff_count = values.get("diff_count", "0")
    mismatch_addr = values.get("mismatch_addr", "n/a")

    lines = [
        name,
        "",
        "Expected: top image (libgpx) equals bottom image (oracle/stub).",
        f"Actual: real_ok={int(real_ok)} oracle_ok={int(oracle_ok)} match={int(match)}",
        f"Diff bytes: {diff_count}",
        f"First mismatch address: {mismatch_addr}",
        f"Result: {'PASS' if (real_ok and oracle_ok and match) else 'FAIL'}",
    ]
    (OUT_DIR / f"{name}.txt").write_text("\n".join(lines) + "\n", encoding="utf-8")


def cleanup_outputs(case_names):
    for name in case_names:
        for ext in (".png", ".txt"):
            p = OUT_DIR / f"{name}{ext}"
            if p.exists():
                p.unlink()


def main():
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    RAW_DIR.mkdir(parents=True, exist_ok=True)
    HARNESS.parent.mkdir(parents=True, exist_ok=True)

    run = subprocess.run([str(HARNESS), str(RAW_DIR)], cwd=ROOT, check=False)

    meta_files = sorted(RAW_DIR.glob("*.meta"))
    case_names = [p.stem for p in meta_files]
    cleanup_outputs(case_names)

    passed = 0
    failed = 0
    lines = [
        "# Lib Visual Compare",
        "",
        "Per test: stacked image with top=libgpx real backend, bottom=oracle.",
        "Logical size is 256x384, exported zoomed.",
        "",
    ]

    for meta_path in meta_files:
        name = meta_path.stem
        values = read_meta(meta_path)

        real_ok = values.get("real_ok", "0") == "1"
        oracle_ok = values.get("oracle_ok", "0") == "1"
        match = values.get("match", "0") == "1"

        write_case_txt(name, values)

        artifact = f"`{name}.txt`"
        if real_ok and oracle_ok:
            real_raw = RAW_DIR / f"{name}.real.raw"
            oracle_raw = RAW_DIR / f"{name}.oracle.raw"
            if real_raw.exists() and oracle_raw.exists():
                top = raw_to_pixels(real_raw.read_bytes())[2]
                bottom = raw_to_pixels(oracle_raw.read_bytes())[2]
                w, h, stacked = stack_pixels(top, bottom)
                sw, sh, spx = scale_pixels(w, h, stacked, SCALE)
                write_png(OUT_DIR / f"{name}.png", sw, sh, spx)
                artifact = f"`{name}.png`, `{name}.txt`"

        status = "PASS" if (real_ok and oracle_ok and match) else "FAIL"
        if status == "PASS":
            passed += 1
        else:
            failed += 1
        lines.append(f"- `{name}`: {status} | {artifact}")

    lines.append("")
    lines.append(f"Summary: PASS={passed} FAIL={failed}")
    lines.append(f"Capture runner exit code: {run.returncode}")

    (OUT_DIR / "README.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"generated {len(meta_files)} stacked compare artifacts under {OUT_DIR}")


if __name__ == "__main__":
    main()
