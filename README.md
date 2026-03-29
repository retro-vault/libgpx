# libgpx

`libgpx` is a hand-optimized 1-bit-per-pixel graphics library for Z80 targets.

Primary target today is ZX Spectrum (`src/zx`).
Partner backend (`src/partner`) is still in progress.

The public API contract is defined in:
- `include/libgpx.h`

## What This Project Gives You

- A strict, portable drawing API for 1bpp framebuffers.
- A ZX Spectrum backend implemented in hand-written Z80 assembly.
- Emulator-based behavioral testing that compares:
  - real backend output
  - independent oracle/stub output
- Size-focused build flow (ROM-oriented).

## Repository Layout

- `include/libgpx.h`: public API and data formats.
- `src/zx/`: ZX Spectrum implementation.
- `src/partner/`: Partner WIP implementation.
- `tests/`: emulator harness, ZX tests, visuals, coverage, size entry.
- `archive/`: old snapshots (not used by current build).
- `build/`, `bin/`: generated artifacts.

## Build And Test Commands

- `make build -j1`: build library + partner sample + test binaries.
- `make tests -j1`: run full ZX real-vs-oracle emulator tests.
- `make stub-visuals -j1`: render stub API scene artifacts to `bin/stub-visuals/`.
- `make lib-visuals -j1`: render stacked real-vs-oracle comparisons to `bin/lib-visuals/`.
- `make coverage -j1`: run host coverage and write `.gcov` files to `build/coverage/`.
- `make lib-size -j1`: estimate library payload size using baseline subtraction.
- `make clean`: remove generated build artifacts.

## Platform Notes (ZX)

- Screen geometry: `256x192` pixels.
- Pixel VRAM: `0x4000..0x57ff` (6144 bytes).
- Attribute VRAM exists separately (`0x5800..`), but libgpx drawing primitives are 1bpp pixel operations.
- Coordinates are signed (`coord`), but visible screen space is `[0..255] x [0..191]`.

## API Conventions

- `clip` parameters are optional rectangles (`rect_t *`).
- `rect_t` corners are inclusive (`x0,y0` through `x1,y1`).
- `CO_FORE` means set pixel bit, `CO_BACK` means clear pixel bit.
- `BM_XOR` toggles destination bits regardless of `color`.
- All rendering is clipped to the physical screen in ZX backend.

## Types, Constants, And Structures

## Primitive Types

- `coord`: `int16_t` signed coordinate.
- `dim`: `uint16_t` dimension.
- `color`: `uint8_t` (`CO_FORE`, `CO_BACK`).
- `bmode`: `uint8_t` (`BM_CPY`, `BM_XOR`).
- `gmode`: `uint8_t` (`GPXM_DEFAULT` currently defined).

## Color And Blit Constants

- `CO_FORE = 0x01`
- `CO_BACK = 0xFE`
- `BM_CPY = 0x00`
- `BM_XOR = 0x01`

## Geometry Structures

```c
typedef struct point_s {
    coord x;
    coord y;
} point_t;

typedef struct rect_s {
    coord x0;
    coord y0;
    coord x1;
    coord y1;
} rect_t;
```

Structure plain samples:

```c
point_t p = { .x = 12, .y = 34 };
rect_t clip = { .x0 = 10, .y0 = 10, .x1 = 100, .y1 = 80 };
```

## Graphics Context (`gpx_t`)

```c
struct gpx_s {
    uint16_t width;
    uint16_t height;
    uint16_t stride;
    uint32_t size;
};
```

Meaning:
- `width`: pixel width.
- `height`: pixel height.
- `stride`: bytes per row.
- `size`: total framebuffer byte count.

On ZX this is `256, 192, 32, 6144`.

## Bitmap Encoding Constants

Signature helpers:
- `BMP_SIG(enc)`
- `BMP_ENC(sig)`

Encodings:
- `BMP_ENC_1BPP`
- `BMP_ENC_1BPP_MASK`
- `BMP_ENC_1BPP_COMPACT`
- `BMP_ENC_1BPP_MASK_COMPACT`

Backward aliases:
- `BMP_ENC_TINY_LINES`
- `BMP_ENC_TINY_LINES_MASK`
- `S_BMP` (standard 1bpp signature)

Bitmap structure:

```c
typedef struct bmp_s {
    uint8_t signature;
    dim w;
    dim h;
    int16_t stride;
    uint16_t size;
    uint8_t bitmap[];
} bmp_t;
```

Structure plain sample (static packed bitmap wrapper):

```c
struct bmp8x8_s {
    uint8_t signature;
    uint16_t w;
    uint16_t h;
    int16_t stride;
    uint16_t size;
    uint8_t bitmap[8];
};

static struct bmp8x8_s checker = {
    S_BMP, 8, 8, 1, 8,
    {0xAA,0x55,0xAA,0x55,0xAA,0x55,0xAA,0x55}
};
```

## Font Format (`font_t`)

Header fields:

- `flags`
- `first_ascii`
- `last_ascii`
- `empty_width`
- `max_glyph_width`
- `glyph_height`
- `advance`
- `descent`
- `data[]`

Flags:
- `FONT_FLAG_PROPORTIONAL`
- `FONT_FLAG_OFFSETS_BE`

Serialized layout:
- bytes `[0..7]`: header
- bytes `[8..]`: glyph offset table + glyph bitmap payloads

## Cursor/Stock IDs

Stock bitmap IDs:
- `GPXSB_CURSOR_CLASSIC`
- `GPXSB_CURSOR_STD`
- `GPXSB_CURSOR_HOURGLASS`
- `GPXSB_CURSOR_CARET`
- `GPXSB_CURSOR_HAND`

Generic cursor IDs:
- `GPX_CURSOR_ARROW`
- `GPX_CURSOR_HAND`
- `GPX_CURSOR_WAIT`
- `GPX_CURSOR_TEXT`

## Public API Reference (`include/libgpx.h`)

## Lifecycle

### `gpx_t *gpx_create(gmode mode)`

Purpose:
- Initialize graphics subsystem/context.

Parameters:
- `mode`: initialization mode (`GPXM_DEFAULT` available).

Returns:
- context pointer (`gpx_t *`).

Special cases:
- ZX backend currently uses a static singleton context.
- ZX backend currently clears screen during create.
- On ZX, `mode` is currently ignored.

Sample:

```c
gpx_t *g = gpx_create(GPXM_DEFAULT);
```

### `void gpx_destroy(gpx_t *gpx)`

Purpose:
- Tear down graphics context.

Parameters:
- `gpx`: context pointer.

Returns:
- no return value.

Special cases:
- ZX backend is static; destroy is effectively a no-op.
- Passing `NULL` is safe in current ZX behavior.

Sample:

```c
gpx_destroy(g);
gpx_destroy(NULL);
```

## Geometry/Screen

### `dim gpx_width(void)`

Purpose:
- Get current display width.

Returns:
- width in pixels.

Special cases:
- ZX: `256` after normal init.

### `dim gpx_height(void)`

Purpose:
- Get current display height.

Returns:
- height in pixels.

Special cases:
- ZX: `192` after normal init.

### `void gpx_clrscr(void)`

Purpose:
- Clear active screen/framebuffer.

Returns:
- no return value.

Special cases:
- ZX clears pixel VRAM and resets attributes/border to defaults.

Sample:

```c
gpx_clrscr();
```

## Cursor/Stock Assets

### `bmp_t *gpx_get_stock_bmp(uint8_t which)`

Purpose:
- Resolve stock bitmap by ID.

Parameters:
- `which`: one of `GPXSB_*` values.

Returns:
- bitmap pointer, or `NULL` if unsupported.

Special cases:
- Invalid IDs return `NULL`.

Sample:

```c
bmp_t *caret = gpx_get_stock_bmp(GPXSB_CURSOR_CARET);
```

### `bmp_t *gpx_get_cursor(uint8_t type)`

Purpose:
- Map generic cursor type to bitmap.

Parameters:
- `type`: one of `GPX_CURSOR_*`.

Returns:
- cursor bitmap pointer.

Special cases:
- ZX maps unknown values to default/classic cursor.

Sample:

```c
bmp_t *cursor = gpx_get_cursor(GPX_CURSOR_HAND);
```

### `void gpx_cursor_set(bmp_t *cursor)`

Purpose:
- Set active software cursor bitmap.

Parameters:
- `cursor`: pointer to bitmap.

Returns:
- no return value.

Special cases:
- Passing `NULL` selects platform default cursor.
- ZX validates cursor signature and falls back to default for unsupported formats.

Sample:

```c
gpx_cursor_set(gpx_get_cursor(GPX_CURSOR_TEXT));
gpx_cursor_set(NULL); // fallback/default
```

## Fonts/Text

### `const font_t *gpx_get_system_font(void)`

Purpose:
- Get default UI/system font.

Returns:
- font pointer.

Sample:

```c
const font_t *sys = gpx_get_system_font();
```

### `const font_t *gpx_get_tiny_font(void)`

Purpose:
- Get tiny font for compact labels.

Returns:
- font pointer.

Sample:

```c
const font_t *tiny = gpx_get_tiny_font();
```

### `coord gpx_measure_text(const char *text, const font_t *font)`

Purpose:
- Measure rendered text width in pixels.

Parameters:
- `text`: zero-terminated string.
- `font`: font blob pointer.

Returns:
- measured width.

Special cases:
- `text == NULL` or `font == NULL` returns `0`.
- Missing/non-representable glyphs use font `empty_width`.
- Width accumulation uses glyph width + font `advance` for drawn glyphs.

Sample:

```c
coord w = gpx_measure_text("HELLO", gpx_get_system_font());
```

### `void gpx_draw_text(gpx_t *gpx, coord x, coord y, const char *text, const font_t *font, color c, bmode m, const rect_t *clip)`

Purpose:
- Draw text using serialized font glyph bitmaps.

Parameters:
- `gpx`: graphics context.
- `x`, `y`: text baseline/start position used by backend renderer.
- `text`: zero-terminated string.
- `font`: serialized font data.
- `c`: draw color (`CO_FORE`/`CO_BACK`).
- `m`: mode (`BM_CPY`/`BM_XOR`).
- `clip`: optional clip rectangle.

Returns:
- no return value.

Special cases:
- `text == NULL` or `font == NULL` is a no-op.
- Unsupported/missing glyph entries advance by `empty_width`.
- Glyph draw path uses bitmap renderer (`gpx_draw_bmp`).

Sample:

```c
const font_t *f = gpx_get_system_font();
rect_t clip = {0, 0, 255, 191};
gpx_draw_text(g, 8, 16, "HELLO", f, CO_FORE, BM_CPY, &clip);
```

## Primitives And Shapes

### `void gpx_draw_pixel(gpx_t *gpx, coord x, coord y, color c, bmode m, const rect_t *clip)`

Purpose:
- Draw one pixel.

Parameters:
- `gpx`: graphics context.
- `x`, `y`: pixel position.
- `c`: `CO_FORE` to set, `CO_BACK` to clear.
- `m`: `BM_CPY` or `BM_XOR`.
- `clip`: optional clipping rectangle.

Returns:
- no return value.

Special cases:
- Out-of-screen coordinates are ignored.
- Clip rejection skips draw.
- In `BM_XOR`, color is ignored and destination is toggled.

Sample:

```c
gpx_draw_pixel(g, 10, 10, CO_FORE, BM_CPY, NULL);
```

### `uint8_t gpx_draw_line(gpx_t *gpx, coord x0, coord y0, coord x1, coord y1, color c, bmode m, uint8_t lpatt, const rect_t *clip)`

Purpose:
- Draw line segment with optional pattern.

Parameters:
- `gpx`: graphics context.
- `x0,y0,x1,y1`: endpoints.
- `c`, `m`: color and blend mode.
- `lpatt`: 8-bit line pattern (`0xFF` = solid).
- `clip`: optional clipping rectangle.

Returns:
- rotated pattern state after drawing, for chaining segments.

Special cases:
- Degenerate line (`x0==x1 && y0==y1`) draws at most one pixel.
- Internal dispatch uses optimized hline/vline/bresenham paths.

Sample:

```c
uint8_t patt = 0xF0;
patt = gpx_draw_line(g, 0, 0, 100, 30, CO_FORE, BM_CPY, patt, NULL);
patt = gpx_draw_line(g, 100, 30, 140, 50, CO_FORE, BM_CPY, patt, NULL);
```

### `void gpx_draw_rectangle(gpx_t *gpx, rect_t *r, color c, bmode m, uint8_t lpatt, const rect_t *clip)`

Purpose:
- Draw rectangle outline.

Parameters:
- `gpx`: graphics context.
- `r`: rectangle (inclusive corners).
- `c`, `m`: color and blend mode.
- `lpatt`: line pattern.
- `clip`: optional clipping rectangle.

Returns:
- no return value.

Special cases:
- ZX normalizes rectangle coordinates (`x0/x1`, `y0/y1`) internally.
- ZX top/bottom use `lpatt`; left/right are drawn solid in current backend.
- `r == NULL` is a no-op.

Sample:

```c
rect_t r = {40, 20, 120, 80};
gpx_draw_rectangle(g, &r, CO_FORE, BM_CPY, 0xFF, NULL);
```

### `void gpx_fill_rectangle(gpx_t *gpx, rect_t *r, color c, bmode m, uint8_t *fpatt, uint8_t fpatt_len, const rect_t *clip)`

Purpose:
- Fill rectangle using repeating row-pattern bytes.

Parameters:
- `gpx`: graphics context.
- `r`: rectangle (inclusive corners).
- `c`, `m`: color and blend mode.
- `fpatt`: row pattern table.
- `fpatt_len`: number of pattern rows.
- `clip`: optional clipping rectangle.

Returns:
- no return value.

Special cases:
- `fpatt_len == 0` is a no-op.
- ZX normalizes rectangle coordinates internally.
- Pattern is consumed MSB-first from `x0`, row-by-row.

Sample:

```c
uint8_t pat[2] = {0xAA, 0x55};
rect_t r = {10, 10, 60, 40};
gpx_fill_rectangle(g, &r, CO_FORE, BM_CPY, pat, 2, NULL);
```

### `void gpx_draw_bmp(gpx_t *gpx, coord x, coord y, bmp_t *b, const rect_t *clip)`

Purpose:
- Blit bitmap at position.

Parameters:
- `gpx`: graphics context.
- `x`, `y`: top-left destination.
- `b`: source bitmap.
- `clip`: optional clipping rectangle.

Returns:
- no return value.

Special cases:
- `b == NULL` is a no-op.
- ZX supports standard and compact 1bpp formats, including masked variants.
- Unclipped, in-range unmasked blits use a fast path; clipped/masked/edge cases use fallback.

Sample:

```c
gpx_draw_bmp(g, 32, 24, (bmp_t *)&checker, NULL);
```

## End-To-End Minimal Example

```c
#include "libgpx.h"

void main(void)
{
    gpx_t *g = gpx_create(GPXM_DEFAULT);
    rect_t clip = {0, 0, 255, 191};

    gpx_clrscr();
    gpx_draw_pixel(g, 10, 10, CO_FORE, BM_CPY, &clip);
    gpx_draw_line(g, 20, 20, 100, 40, CO_FORE, BM_CPY, 0xFF, &clip);

    rect_t box = {30, 50, 120, 90};
    gpx_draw_rectangle(g, &box, CO_FORE, BM_CPY, 0xFF, &clip);

    const font_t *font = gpx_get_system_font();
    gpx_draw_text(g, 8, 8, "libgpx", font, CO_FORE, BM_CPY, &clip);

    __asm
        halt
    __endasm;
}
```

## Compatibility/Scope Note

The header comment mentions additional primitive categories (for example circles/polygons), but the currently exported public API is exactly what is declared in `include/libgpx.h` and documented above.
