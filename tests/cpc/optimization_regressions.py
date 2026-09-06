#!/usr/bin/env python3
"""Independent byte-level CPC regression checks on the MCP emulator.

Run after ``make -C tests/cpc build``. Exercises bitmap compositors over
both bit planes, line chunk boundaries, bank transitions and large clipped
fill phases. Expected memory is generated per pixel, without libgpx calls.
"""
import random
import struct
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tests/mcp"))
from cpcmcp import Cpc, cpc_offset  # noqa: E402
from run_cpc_tests import read_symbol  # noqa: E402


def word(value):
    return struct.pack("<H", value & 65535)


def write(machine, address, data):
    machine.call("write_memory", address=address, data=bytes(data).hex())


def invoke(machine, image, name, args=b"", **registers):
    write(machine, 0x1000, b"\x76")
    write(machine, 0x7F00, word(0x1000) + args)
    machine.registers(pc=read_symbol(image.with_suffix(".map"), name),
                      sp=0x7F00, iff1=False, iff2=False, **registers)
    result = machine.run(stop_on_halt=True, tstates=40_000_000)
    assert result.get("reason") == "halted", (name, result)
    regs = machine.registers()
    assert regs["sp"] == 0x7F02 + len(args), (name, regs["sp"])
    return regs


def pixel(memory, per_byte, x, y, value):
    index = cpc_offset(x // per_byte, y)
    mask = 0x80 >> (x % per_byte)
    old = bool(memory[index] & mask)
    new = value(old)
    memory[index] = (memory[index] & ~mask) | (mask if new else 0)


def check(machine, expected, context):
    actual = machine.screen()
    if actual != expected:
        index = next(i for i, pair in enumerate(zip(actual, expected))
                     if pair[0] != pair[1])
        raise AssertionError(f"{context}: address {0xC000+index:#06x}: "
                             f"{actual[index]:02x} != {expected[index]:02x}")


def main():
    rng = random.Random(0xC0C)
    for mode, per_byte in ((0, 8), (1, 4)):
        width = per_byte * 80
        tag = f"{width}x200"
        image = ROOT / "build/cpc-tests" / f"cpc_prims-{tag}.bin"
        with Cpc() as machine:
            machine.reset(clear_memory=True)
            machine.load_binary(image, 0x8000)
            invoke(machine, image, "_gpx_create", af=mode << 8)

            edges = (-32768, -32767, -256, -255, -129, -128, -1,
                     0, 1, 127, 128, 255, 256, 32766, 32767)
            for left in edges:
                for right in edges:
                    result = invoke(machine, image, "__rect_cmp16s_lt",
                                    hl=left & 65535, de=right & 65535, bc=0xA55A)
                    assert bool(result["af"] & 1) == (left < right)
                    assert result["hl"] == left & 65535
                    assert result["de"] == right & 65535
                    assert result["bc"] == 0xA55A

            # The low nibble is deliberately nonzero in mode 1. Bitmap
            # rendering must preserve that second plane, as well as every
            # unused byte between the eight display banks.
            expected = bytearray(rng.randbytes(16384))
            write(machine, 0xC000, expected)
            for trial in range(112):
                bw = rng.choice((1, 3, 7, 8, 9, 15, 16, 17, 31, 32))
                bh = rng.randrange(1, 17)
                stride = (bw + 7) // 8
                masked = trial % 2
                payload = rng.randbytes(stride * bh * (1 + masked))
                blob = bytes((stride - 1 + 16 * masked, bw, bh))
                blob += word(len(payload)) + payload
                write(machine, 0x2000, blob)
                x = rng.choice((-7, -1, width - 3, width - bw, 250,
                                280, 8 + trial % 8))
                y = rng.choice((-3, 0, 7, 15, 31, 190, 199))
                clip = (x + 2, y + 1, x + bw - 2, y + bh - 1) if trial % 3 == 0 else None
                if clip:
                    write(machine, 0x2100, b"".join(map(word, clip)))
                draw_mode = (0x80, 0, 1, 0x40)[(trial // 2) % 4]
                color = (trial // 8) & 1
                invoke(machine, image, "_gpx_draw_bmp_clip",
                       word(y) + word(0x2000) + word(0x2100 if clip else 0),
                       hl=0, de=x & 65535, bc=(draw_mode << 8) | color)
                for sy in range(bh):
                    for sx in range(bw):
                        px, py = x + sx, y + sy
                        if not (0 <= px < width and 0 <= py < 200):
                            continue
                        if clip and not (clip[0] <= px <= clip[2] and clip[1] <= py <= clip[3]):
                            continue
                        base = sy * stride * (1 + masked)
                        mask = 0x80 >> (sx % 8)
                        source = bool(payload[base + masked * stride + sx // 8] & mask)
                        keep = bool(payload[base + sx // 8] & mask)
                        if draw_mode == 0x80:
                            op = lambda old, s=source, k=keep: (old and k or s) if masked else old or s
                        elif draw_mode == 1:
                            op = lambda old, s=source: old != s
                        elif draw_mode == 0x40:
                            op = lambda old, s=source, c=color: bool(c) if s else old
                        else:
                            op = lambda old, s=source, c=color: s if c else not s
                        pixel(expected, per_byte, px, py, op)
                check(machine, expected, (tag, "bitmap", trial))

            # Horizontal reversal enters Bresenham. Exact 256-step chunks
            # and transitions between CPC banks are included explicitly.
            expected = bytearray(16384)
            write(machine, 0xC000, expected)
            for trial, length in enumerate((1, 7, 8, 15, 255, 256, 257,
                                             319, 511, 512, 639)):
                end = min(length, width - 1)
                for reverse in (False, True):
                    x0, x1 = (end, 0) if reverse else (0, end)
                    y = 7 + trial * 8 + reverse
                    pattern = (0xFF, 0xA5, 0x36)[trial % 3]
                    result = invoke(machine, image, "_gpx_draw_line",
                                    word(y) + word(x1) + word(y) + b"\x01\x01" + bytes((pattern,)) + word(0),
                                    hl=0, de=x0)
                    for x in range(end + 1):
                        if pattern & (1 << (abs(x - x0) % 8)):
                            pixel(expected, per_byte, x, y, lambda old: not old)
                    shift = end % 8
                    want_pattern = ((pattern >> shift) | (pattern << (8 - shift))) & 255
                    assert result["af"] >> 8 == want_pattern
                    check(machine, expected, (tag, "line", length, reverse))

            for trial in range(64):
                x0, x1 = rng.randrange(width), rng.randrange(width)
                y0, y1 = rng.randrange(200), rng.randrange(200)
                pattern = rng.randrange(256)
                result = invoke(machine, image, "_gpx_draw_line",
                                word(y0) + word(x1) + word(y1) + b"\x01\x01" + bytes((pattern,)) + word(0),
                                hl=0, de=x0)
                dx, dy = abs(x1 - x0), abs(y1 - y0)
                sx, sy = 1 if x1 >= x0 else -1, 1 if y1 >= y0 else -1
                x, y = x0, y0
                error = dx // 2 if dx >= dy else -(dy // 2)
                for step in range(max(dx, dy) + 1):
                    if pattern & (1 << (step % 8)):
                        pixel(expected, per_byte, x, y, lambda old: not old)
                    if dx >= dy:
                        error -= dy
                        if error < 0:
                            y += sy
                            error += dx
                        x += sx
                    else:
                        error += dx
                        if error > 0:
                            x += sx
                            error -= dy
                        y += sy
                shift = max(dx, dy) % 8
                want_pattern = ((pattern >> shift) | (pattern << (8 - shift))) & 255
                assert result["af"] >> 8 == want_pattern
                check(machine, expected, (tag, "diagonal", trial))

            # Both clipping edges lie above 255: an x-intersection must
            # retain the clip coordinate's high byte when computing y.
            expected = bytearray(16384)
            write(machine, 0xC000, expected)
            if mode == 0:
                start, end, low, high = 200, 600, 400, 500
                first_y, last_y = 50, 75
            else:
                start, end, low, high = 200, 400, 256, 310
                first_y, last_y = 28, 55
            write(machine, 0x2100, b"".join(map(word, (low, 0, high, 199))))
            pattern = 0xA5
            result = invoke(machine, image, "_gpx_draw_line",
                            word(0) + word(end) + word(100) + b"\x01\x01" + bytes((pattern,)) + word(0x2100),
                            hl=0, de=start)
            dx, dy = high - low, last_y - first_y
            y, error = first_y, dx // 2
            for x in range(low, high + 1):
                if pattern & (1 << ((x - start) % 8)):
                    pixel(expected, per_byte, x, y, lambda old: not old)
                error -= dy
                if error < 0:
                    y += 1
                    error += dx
            shift = (high - start) % 8
            assert result["af"] >> 8 == ((pattern >> shift) | (pattern << (8 - shift))) & 255
            check(machine, expected, (tag, "16-bit clipping edge"))

            # Large original y coordinates used to require up to 32,768
            # repeated subtractions before a single visible row was drawn.
            for origin in (-32768, -32767, -257, -1, 0):
                for count in (1, 3, 5, 127, 128, 255):
                    expected = bytearray(16384)
                    write(machine, 0xC000, expected)
                    pattern = bytes((i * 73 + 0x96) & 255 for i in range(count))
                    write(machine, 0x2000, pattern)
                    write(machine, 0x2100, b"".join(map(word, (13, origin, 25, 4))))
                    invoke(machine, image, "_gpx_fill_rectangle",
                           b"\x01\x00" + word(0x2000) + bytes((count,)) + word(0),
                           hl=0, de=0x2100)
                    for y in range(5):
                        for x in range(13, 26):
                            if pattern[(y - origin) % count] & (0x80 >> ((x - 13) % 8)):
                                pixel(expected, per_byte, x, y, lambda old: True)
                    check(machine, expected, (tag, "fill phase", origin, count))
            print(f"{tag}: 225 compare, 112 bitmap, 87 line and 30 fill cases passed")


if __name__ == "__main__":
    main()
