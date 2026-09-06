#!/usr/bin/env python3
"""Check every horizontal pattern byte against a scalar oracle on idp-mcp.

The 32-phase scenario covers both colors, both modes, both directions,
short spans, 255/256 chunk boundaries, long spans, and clipping phase.
Optionally --baseline ROOT also compares all rasters and returned pattern
bytes to a separately built tree, including its hardware solid behavior.
"""
import argparse
import hashlib
from pathlib import Path

from idpmcp import Partner, raster_from_png, raster_packed
from ihx import read_entry, read_ihx

ROOT = Path(__file__).resolve().parents[2]


def rotate(p, n):
    n &= 7
    return ((p >> n) | (p << ((8 - n) & 7))) & 255


def expected(phase):
    span_range, setting = divmod(phase, 8)
    rows = []
    returns = []
    for p in range(256):
        span = (p & 63) if span_range == 0 else (
            248 + (p & 15) if span_range == 1 else 768 + p)
        x0 = 0 if p & 1 else 1023 - span
        x1 = x0 + span
        if span_range == 3:
            x0, x1 = -p, 1031 + p
        start, end = (x1, x0) if setting & 4 else (x0, x1)
        first = min(1023, max(0, start))
        last = min(1023, max(0, end))
        step = 1 if first <= last else -1
        skip = abs(first - start)
        row = bytearray((0xA5 >> (x & 7)) & 1 for x in range(1024))
        for n, x in enumerate(range(first, last + step, step)):
            if (p >> ((skip + n) & 7)) & 1:
                row[x] = row[x] ^ 1 if setting & 2 else setting & 1
        rows.append(bytes(row))
        returns.append(rotate(p, skip + abs(last - first)))
    return rows, bytes(returns)


def capture(root, validate_solid=True):
    image_dir = root / 'bin/partner-gdp'
    scratch = root / 'build/pattern-composition'
    scratch.mkdir(parents=True, exist_ok=True)
    base, blob = read_ihx(str(image_dir / 'test_gdp_patterns.ihx'))
    map_path = str(image_dir / 'test_gdp_patterns.map')
    entry = read_entry(map_path)
    sentinel = read_entry(map_path, '_gdp_finished')
    ret_addr = read_entry(map_path, '_pattern_returns')
    image = scratch / 'patterns.bin'
    image.write_bytes(blob)
    result = []
    with Partner(rom=False, workdir=str(root)) as gdp:
        gdp.load_binary(str(image), base)
        gdp.registers(pc=entry, sp=0xFF00, iff1=False, iff2=False)
        for phase in range(32):
            while True:
                state = gdp.run(tstates=60_000_000, stop_on_halt=True)
                if state.get('run', {}).get('reason') == 'halted':
                    break
                if state['tstates'] > 4_000_000_000:
                    raise RuntimeError('scenario never completed')
            # Public drawing can leave a GDP command in flight. Run the
            # halted CPU long enough to finish it before sampling pixels.
            gdp.run(tstates=8192, stop_on_halt=False)
            shot = scratch / 'patterns.png'
            gdp.screenshot(str(shot))
            rows = raster_from_png(str(shot))
            returns = gdp.read_memory(ret_addr, 256)
            result.append((rows, returns))
            want_rows, want_returns = expected(phase)
            # Baseline solid XOR vectors repeated split endpoints. The
            # candidate also validates FF against the independent oracle.
            height = 256 if validate_solid else 255
            bad = [(x, y) for y in range(height) for x in range(1024)
                   if rows[y][x] != want_rows[y][x]]
            if bad or returns != want_returns:
                raise AssertionError(f'{root}: phase {phase}: '
                    f'{len(bad)} wrong pixels, first {bad[:8]}; '
                    f'return mismatches {[i for i in range(256) if returns[i] != want_returns[i]][:16]}')
            print(f'{root.name}: phase {phase:2}: oracle passed', flush=True)
            if gdp.read_memory(sentinel, 1) == b'\xa5':
                break
            gdp.registers(pc=state['cpu']['pc'] + 1)
        assert len(result) == 32
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--baseline', type=Path)
    args = parser.parse_args()
    actual = capture(ROOT)
    if args.baseline:
        baseline = capture(args.baseline.resolve(), validate_solid=False)
        assert all(a[0][:255] == b[0][:255] and a[1] == b[1]
                   for a, b in zip(actual, baseline)), 'pattern regression'
        print('All 32 patterned rasters and 8192 returned bytes equal baseline; '
              'solid XOR endpoints additionally pass the scalar oracle.')
    digest = hashlib.sha256(b''.join(raster_packed(r) + p for r, p in actual)).hexdigest()
    print(f'8,192 calls; 8,388,608 independent pixel checks; digest {digest}')


if __name__ == '__main__':
    main()
