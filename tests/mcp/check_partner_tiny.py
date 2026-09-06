#!/usr/bin/env python3
"""Exercise every Tiny move byte on the real Partner GDP.

Checks compact/legacy headers, Tiny/Tiny-mask signatures, copy/XOR, inverted
colours, 256/512-line modes, connected strokes, zero-length and pen-up moves, and whole/partial
clipping. A marker after each stream catches leaked pen-up state. The first
eight phases in each display mode have an independent scalar raster oracle. In the clipped phases,
the oracle covers contained/excluded streams and markers; --baseline ROOT
also compares every pixel, including Cohen-Sutherland's partial strokes.
"""
import argparse
import hashlib
from pathlib import Path
import subprocess

from idpmcp import Partner, raster_from_png, raster_packed
from ihx import read_entry, read_ihx

ROOT = Path(__file__).resolve().parents[2]


def build(root):
    subprocess.run(['make', '-C', str(root / 'tests/partner'), 'gdp-bench'],
                   check=True, stdout=subprocess.DEVNULL)
    dest = root / 'build/partner-tiny'
    dest.mkdir(parents=True, exist_ok=True)
    (dest / 'tiny_streams.c').write_bytes(
        (ROOT / 'tests/partner/bitmap-src/tiny_streams.c').read_bytes())
    (dest / 'tiny_modes.s').write_bytes(
        (ROOT / 'tests/partner/bitmap-src/tiny_modes.s').read_bytes())
    objects = sorted(p.relative_to(root).as_posix()
                     for p in (root / 'build/partner-tests').glob('*.rel')
                     if p.stem.startswith(('gpx_', '_')))
    command = ('xas -o build/partner-tiny/tiny_modes.rel '
               'build/partner-tiny/tiny_modes.s && '
               'xcc -mz80 -std=c11 -Os -Iinclude -Itests/partner/gdp-src '
               '-c -o build/partner-tiny/tiny_streams.rel '
               'build/partner-tiny/tiny_streams.c && '
               'xcc -mz80 -nostartfiles -o build/partner-tiny/tiny_streams.ihx '
               'build/partner-tiny/tiny_streams.rel build/partner-tiny/tiny_modes.rel ' + ' '.join(objects) +
               ' -Wl,--oformat=ihx -Wl,-b,_CODE=0x8000 '
               '-Wl,-Map=build/partner-tiny/tiny_streams.map')
    from idpmcp import DOCKER_IDP
    import os
    subprocess.run(['docker', 'run', '--rm', '-u', f'{os.getuid()}:{os.getgid()}',
                    '-v', f'{root}:/work', '-w', '/work', DOCKER_IDP,
                    'sh', '-lc', command], check=True)
    return dest


def line(x0, y0, x1, y1):
    dx, dy = abs(x1 - x0), -abs(y1 - y0)
    sx, sy = (1 if x0 < x1 else -1), (1 if y0 < y1 else -1)
    error = dx + dy
    while True:
        yield x0, y0
        if (x0, y0) == (x1, y1):
            return
        twice = 2 * error
        if twice >= dy:
            error += dy
            x0 += sx
        if twice <= dx:
            error += dx
            y0 += sy


def expected(phase):
    height = 512 if phase & 16 else 256
    cell_height = 60 if phase & 16 else 30
    rows = [bytearray((0xA5 >> (x & 7)) & 1 for x in range(1024))
            for _ in range(height)]
    ignored = set()
    markers = []
    for code in range(256):
        ox, oy = 3 + (code & 31) * 32, 3 + (code >> 5) * cell_height
        if phase & 8 and code & 3 == 1:
            # Retain the platform's established endpoint clipping semantics.
            ignored.update((x, y) for y in range(oy - 3, oy + cell_height - 3)
                           for x in range(ox - 3, ox + 29))
        x, y = ox, oy
        for move in [0x78, code, 0x80, code ^ 6, 0x80,
                     code, 0, code ^ 6, 0]:
            nx = x + ((move >> 5) & 3) * (-1 if move & 2 else 1)
            ny = y + ((move >> 3) & 3) * (-1 if move & 4 else 1)
            if move & 0x81 and not (phase & 8 and code & 3 == 2):
                colour = (0 if move & 1 else 1) ^ bool(phase & 4)
                for px, py in line(x, y, nx, ny):
                    rows[py][px] = rows[py][px] ^ 1 if phase & 1 else colour
            x, y = nx, ny
        rows[oy + 10][ox + 10] = 1
        markers.append((ox + 10, oy + 10))
    return rows, ignored, markers


def capture(root):
    dest = build(root)
    base, blob = read_ihx(str(dest / 'tiny_streams.ihx'))
    entry = read_entry(str(dest / 'tiny_streams.map'))
    sentinel = read_entry(str(dest / 'tiny_streams.map'), '_gdp_finished')
    image = dest / 'tiny_streams.bin'
    image.write_bytes(blob)
    result, checked = [], 0
    with Partner(rom=False, workdir=str(root)) as gdp:
        gdp.load_binary(str(image), base)
        gdp.registers(pc=entry, sp=0xFF00, iff1=False, iff2=False)
        for phase in range(32):
            while True:
                state = gdp.run(tstates=60_000_000, stop_on_halt=True)
                if state.get('run', {}).get('reason') == 'halted':
                    break
                if state['tstates'] > 4_000_000_000:
                    raise RuntimeError('Tiny scenario did not complete')
            gdp.run(tstates=8192, stop_on_halt=False)
            shot = dest / 'tiny_streams.png'
            gdp.screenshot(str(shot))
            height = 512 if phase & 16 else 256
            rows = raster_from_png(str(shot), 1024, height)
            want, ignored, markers = expected(phase)
            bad = [(x, y) for y in range(height) for x in range(1024)
                   if (x, y) not in ignored and rows[y][x] != want[y][x]]
            assert not bad, f'{root.name}: phase {phase}: {len(bad)} pixels, {bad[:8]}'
            assert all(rows[y][x] for x, y in markers), 'pen-up state leaked'
            checked += 1024 * height - len(ignored)
            result.append(raster_packed(rows))
            print(f'{root.name}: Tiny phase {phase:2}: oracle passed', flush=True)
            if phase == 31:
                assert gdp.read_memory(sentinel, 1) == b'\xa5'
            else:
                gdp.registers(pc=state['cpu']['pc'] + 1)
    print(f'{checked:,} scalar pixel checks and 8,192 following-primitive markers')
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--baseline', type=Path)
    args = parser.parse_args()
    actual = capture(ROOT)
    if args.baseline:
        baseline = capture(args.baseline.resolve())
        assert actual == baseline, 'Tiny bitmap raster regression'
        print('All 32 Tiny phase rasters exactly match baseline.')
    print('Tiny raster SHA256:', hashlib.sha256(b''.join(actual)).hexdigest())


if __name__ == '__main__':
    main()
