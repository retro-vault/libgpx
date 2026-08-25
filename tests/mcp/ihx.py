"""Intel HEX reader: returns (base_address, contiguous_bytes)."""


def read_ihx(path):
    lo = None
    hi = 0
    chunks = []
    with open(path, "r") as fh:
        for line in fh:
            line = line.strip()
            if not line.startswith(":"):
                continue
            raw = bytes.fromhex(line[1:])
            count, addr_hi, addr_lo, rtype = raw[0], raw[1], raw[2], raw[3]
            if rtype != 0x00:
                continue  # EOF / segment records: this linker emits neither
            addr = (addr_hi << 8) | addr_lo
            data = raw[4:4 + count]
            chunks.append((addr, data))
            lo = addr if lo is None else min(lo, addr)
            hi = max(hi, addr + count)
    if lo is None:
        raise ValueError(f"{path}: no data records")
    image = bytearray(hi - lo)
    for addr, data in chunks:
        image[addr - lo:addr - lo + len(data)] = data
    return lo, bytes(image)


def write_bin(ihx_path, bin_path):
    base, image = read_ihx(ihx_path)
    with open(bin_path, "wb") as fh:
        fh.write(image)
    return base, len(image)


def read_entry(map_path, symbol="_main"):
    """Return the address of `symbol` from an xld memory map."""
    import re
    want = re.compile(r"^([0-9A-Fa-f]{8})\s+" + re.escape(symbol) + r"\s*$")
    with open(map_path) as fh:
        for line in fh:
            m = want.match(line.strip())
            if m:
                return int(m.group(1), 16)
    raise ValueError(f"{map_path}: no symbol {symbol}")
