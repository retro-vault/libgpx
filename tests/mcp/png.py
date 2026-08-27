"""Tiny PNG reader for emulator screenshots (8-bit truecolour, no interlace).

The GDP raster is 1bpp, so a screenshot only ever needs "is this pixel lit",
which keeps this far smaller than a Pillow dependency in the test image.
"""

import struct
import zlib


def read_rgb(path):
    """Return (width, height, rows) with rows[y][x] = (r, g, b)."""
    data = open(path, "rb").read()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError(f"{path}: not a PNG")
    pos = 8
    hdr = None
    idat = bytearray()
    palette = b""
    while pos < len(data):
        (length,) = struct.unpack(">I", data[pos:pos + 4])
        kind = data[pos + 4:pos + 8]
        body = data[pos + 8:pos + 8 + length]
        pos += 12 + length
        if kind == b"IHDR":
            hdr = struct.unpack(">IIBBBBB", body)
        elif kind == b"PLTE":
            palette = body
        elif kind == b"IDAT":
            idat += body
        elif kind == b"IEND":
            break
    w, h, depth, colour, comp, filt, interlace = hdr
    if depth != 8 or interlace:
        raise ValueError(f"{path}: only 8-bit non-interlaced PNGs are read")
    channels = {0: 1, 2: 3, 3: 1, 4: 2, 6: 4}[colour]
    raw = zlib.decompress(bytes(idat))
    stride = w * channels
    out = []
    prev = bytearray(stride)
    pos = 0
    for _ in range(h):
        ftype = raw[pos]
        pos += 1
        line = bytearray(raw[pos:pos + stride])
        pos += stride
        for i in range(stride):
            a = line[i - channels] if i >= channels else 0
            b = prev[i]
            c = prev[i - channels] if i >= channels else 0
            if ftype == 1:
                line[i] = (line[i] + a) & 0xFF
            elif ftype == 2:
                line[i] = (line[i] + b) & 0xFF
            elif ftype == 3:
                line[i] = (line[i] + ((a + b) >> 1)) & 0xFF
            elif ftype == 4:
                p = a + b - c
                pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                pr = a if (pa <= pb and pa <= pc) else (b if pb <= pc else c)
                line[i] = (line[i] + pr) & 0xFF
        row = []
        for x in range(w):
            i = x * channels
            if colour == 3:
                idx = line[i] * 3
                row.append(tuple(palette[idx:idx + 3]))
            elif colour in (0, 4):
                row.append((line[i],) * 3)
            else:
                row.append((line[i], line[i + 1], line[i + 2]))
        out.append(row)
        prev = line
    return w, h, out


def lit_mask(path, threshold=64):
    """Return (width, height, rows) with rows[y][x] = True when lit."""
    w, h, rows = read_rgb(path)
    return w, h, [[max(px) >= threshold for px in row] for row in rows]
