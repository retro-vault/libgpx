#!/usr/bin/env python3
"""Emit native byte arrays from libgpx's canonical Z80 raster assets."""
import re
import sys
from pathlib import Path


def read_arrays(path):
    arrays = {}
    current = None
    for line in path.read_text().splitlines():
        line = line.split(';', 1)[0].strip()
        label = re.fullmatch(r'(_gpx_\w+)::', line)
        if label:
            current = []
            arrays[label[1][1:]] = current
        data = re.match(r'\.(db|dw)\s+(.*)', line)
        if not data or current is None:
            continue
        for token in data[2].split(','):
            value = int(token.strip(), 0)
            current.append(value & 255)
            if data[1] == 'dw':
                current.append(value >> 8)
    return arrays


def main():
    root = Path(__file__).resolve().parents[2]
    arrays = read_arrays(root / 'src/zx/_gpx_font_envy.s')
    arrays.update(read_arrays(root / 'src/zx/_gpx_cursors.s'))
    output = ['/* Generated from src/zx raster assets; do not edit. */']
    for name, data in arrays.items():
        output.append(f'static const uint8_t {name}[] = {{')
        for start in range(0, len(data), 12):
            output.append('    ' + ', '.join(
                f'0x{byte:02x}' for byte in data[start:start + 12]) + ',')
        output.append('};')
    Path(sys.argv[1]).write_text('\n'.join(output) + '\n')


if __name__ == '__main__':
    main()
