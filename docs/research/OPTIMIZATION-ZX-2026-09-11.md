# ZX size/speed pass, 11 September 2026

The ZX backend saves **420 bytes**, from **9,406 to 8,986 bytes** (4.47%).
All nine existing ZX microbenchmarks are unchanged or faster. Their combined
time falls by **10.93%**. Bitmap/font formats, stock
artwork, public signatures and drawing semantics are unchanged.

The baseline is the working tree immediately before this pass, already
containing opaque patterned fills, BM_OR and selected-edge boxes. It is **not**
the older committed baseline used by the [6 September report](OPTIMIZATION-2026-09.md).
A local copy of the original source, objects, library, benchmark images and
screenshots is retained at `build/zx-size-pass-J0078z/`.

## Size

Counts are uncompressed assembler `_CODE` bytes summed across library members,
including embedded fonts/cursors, not the on-disk archive size. No library
member or feature was removed. A particular application saves only the
differences in the members it links.

| Changed member | Before | After | Saved |
|---|---:|---:|---:|
| `gpx_bmp` | 923 | 842 | 81 |
| `gpx_show_sprite` | 264 | 193 | 71 |
| `gpx_draw_box` | 449 | 393 | 56 |
| `gpx_fill_rectangle` | 397 | 341 | 56 |
| `gpx_draw_rectangle` | 57 | 9 | 48 |
| `_rect_helpers` | 161 | 126 | 35 |
| `_gpx_sprite_blit_raw` | 424 | 397 | 27 |
| `_gpx_hline` | 472 | 455 | 17 |
| `gpx_draw_pixel` | 159 | 144 | 15 |
| `gpx_draw_text` | 501 | 487 | 14 |
| **Whole library** | **9,406** | **8,986** | **420** |

The unchanged advanced members total 2,170 bytes. Core-only code therefore
falls from 7,236 to 6,816 bytes. Writable static data stays at 8 bytes; stock
font and cursor data stay at 1,592 bytes.

Private workspace also shrinks: bitmap 38 → 32 bytes, rectangle fill 22 → 17,
text 20 → 16, box 13 → 9, sprite-show locals 4 → 0. These are local workspace
sizes, not peak stack usage. Horizontal lines, rectangle fills and text now
explicitly preserve caller IY, in addition to IX; that cost is included above.

## What changed

- Rectangle normalization reads each endpoint once, sorts in registers and
  writes a conventional little-endian private rectangle. Serialized formats
  are untouched.
- Bitmap clipping computes screen extents in registers. Sprite setup retains
  dimensions in registers and eliminates its redundant IX/local frame.
- Opaque spans handle masked edge bytes separately and write fully covered
  middle bytes directly. OR/XOR retain their existing byte-span compositors.
  There is no clear-then-redraw pass on the Spectrum.
- The horizontal-line tail entry uses the X endpoint already loaded by the ZX
  dispatcher and keeps the destination byte offset in a register.
- Box argument setup uses the alternate register bank. The existing rectangle
  entry becomes a 9-byte all-edges tail call to the existing box engine.
- Text advances its callee-owned pointer argument directly and resolves the
  transparent/XOR spacing policy once per string. Pixel clipping uses fewer
  sign/high-byte tests.

All library edits in this pass are hand-written assembly under `src/zx`.
No common/backend adapter, new library module, lookup table, global scratch
buffer, decoded asset format or per-pixel replacement for a byte renderer was
introduced. The existing general-line and shape algorithms remain in place.

## Speed

Measured in T-states using the same installed
`wischner/xcc-z80-zx-spectrum` toolchain and its MCP emulator. Both preserved
baseline and final benchmark images were measured again side by side.
Benchmark setup before `bench_body` is excluded.

| Workload | Before | After | Less time |
|---|---:|---:|---:|
| `bench_bmp` | 19,574,709 | 19,418,980 | 0.8% |
| `bench_circle` | 27,429,930 | 23,712,582 | 13.6% |
| `bench_clrscr` | 1,993,306 | 1,993,306 | 0.0% |
| `bench_fill` | 13,632,352 | 6,162,660 | 54.8% |
| `bench_line` | 16,677,941 | 15,557,027 | 6.7% |
| `bench_pixel` | 6,226,827 | 5,981,875 | 3.9% |
| `bench_rect` | 10,458,270 | 9,980,618 | 4.6% |
| `bench_sprite` | 7,793,466 | 7,700,593 | 1.2% |
| `bench_text` | 21,707,567 | 21,267,754 | 2.0% |
| **Total** | **125,494,368** | **111,775,395** | **10.93%** |

These are the measured workloads, not a claim that every individual early
return has identical cycle cost. The fill benchmark mixes full-screen opaque,
patterned, clipped, XOR and small rectangles.

## Validation

The standard commands are:

```sh
make lib
make zx-tests
make zx-bench
make conformance
python3 tests/size/lib_size.py
```

All 54 ZX scenarios passed against the independent C oracle, followed by
362 bitmap cases, 1,037 sprite cases and the new 408 span/box/public-entry cases.
The additional tests check COPY/OR/XOR pixels, all edge masks, pattern
continuation, reversed/extreme coordinates, inverted clipping, attributes,
memory guards and IX/IY/stack preservation. The per-pixel models exist only in
the tests, not in library drawing paths.

The assembly style check passes across all 101 assembly files. After final
comment alignment, the library was rebuilt and every object hash was checked
against the tested build; all objects were byte-identical.

All six cross-backend conformance scenarios pass under the existing documented
Partner hardware/font/artwork exceptions. Both CPC modes match exactly.
No golden images or exception budgets were changed for this optimization.

All six ZX documentation screenshots were rebuilt and captured from the final
library using `scripts/docs/capture-manual-shots.py`'s ZX capture functions.
Every PNG is byte-identical to its pre-pass capture. Other backends were not
changed by this pass.

Raw per-member sizes, T-state counts and unchanged asset-source hashes are in
[optimization-zx-2026-09-11.json](optimization-zx-2026-09-11.json).
The historical benchmark/size baseline files remain unchanged.
