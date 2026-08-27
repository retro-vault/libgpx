# Demo 3 — portable example programs

Demo 3 contains two complete programs written to adapt to the active screen.
Unlike the fixed-size comparison scenes in Demo 1 and Demo 2, every important
coordinate is derived from `gpx_width()` and `gpx_height()`. The same source
therefore fills a 256x192 ZX Spectrum display, a 1024x256 Iskra Delta Partner
display, and either of the Amstrad CPC's two modes sensibly.

## Panels

`panels.c` is a static tour of the drawing API: frames, three fill patterns,
four line styles, reverse and XOR text, a clipped fan, both stock fonts, and a
stock cursor sprite.

### ZX Spectrum 48K

![Panels on the ZX Spectrum](../../docs/images/screenshots/panels-zx.png)

### Iskra Delta Partner

![Panels on the Iskra Delta Partner](../../docs/images/screenshots/panels-partner.png)

### Amstrad CPC — 640 x 200

![Panels on the Amstrad CPC at 640x200](../../docs/images/screenshots/panels-cpc-640x200.png)

### Amstrad CPC — 320 x 200

![Panels on the Amstrad CPC at 320x200](../../docs/images/screenshots/panels-cpc-320x200.png)


The layout is the same, but it expands with the display. Fonts and stock
cursors use each backend's native artwork. Slanted solid lines can choose
slightly different interior pixels because the Partner uses the EF9367 vector
generator while the Spectrum uses a software rasterizer.

### Main program

```c
/*
 * panels.c
 *
 * libgpx manual example 1: a static screen that exercises most of the
 * drawing API -- frames, pattern fills, line styles, both stock fonts,
 * XOR text over ink, clipping, and a stock cursor sprite.
 *
 * The same source builds for the ZX Spectrum (256x192) and the Iskra
 * Delta Partner (1024x256), so every coordinate is derived from
 * gpx_width() and gpx_height() rather than hard-coded.
 *
 * GPL2 License (see: LICENSE)
 * Copyright (C) 2026 Tomaz Stih
 */
#include "libgpx.h"

static uint8_t patt_solid[1] = {0xFF};
static uint8_t patt_half[2]  = {0xAA, 0x55};
static uint8_t patt_brick[4] = {0xFF, 0x88, 0x88, 0x88};

/* Save-under storage for the sprite. The Partner never reads it -- it has
 * no readable display memory and XORs the sprite instead -- but the ZX
 * needs it, so a portable program always supplies one. */
static uint8_t under[GPX_SPRITE_BG_SIZE];

/* Draw a framed box and fill it with a pattern. */
static void panel(gpx_t *gpx, coord x0, coord y0, coord x1, coord y1,
                  uint8_t *patt, uint8_t len)
{
    rect_t r;

    r.x0 = x0; r.y0 = y0; r.x1 = x1; r.y1 = y1;
    gpx_fill_rectangle(gpx, &r, CO_FORE, BM_CPY, patt, len, 0);
    gpx_draw_rectangle(gpx, &r, CO_FORE, BM_CPY, 0xFF, 0);
}

void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    const font_t *font = gpx_get_system_font();
    dim w = gpx_width();
    dim h = gpx_height();
    coord pad = (coord)(w / 32);          /* keeps the layout proportional */
    coord bar = (coord)(font->glyph_height + 4);
    sprite_t cursor;
    rect_t r;
    coord i;

    gpx_clrscr();

    /* Outer frame, one pixel in from every edge. */
    r.x0 = 0; r.y0 = 0; r.x1 = (coord)(w - 1); r.y1 = (coord)(h - 1);
    gpx_draw_rectangle(gpx, &r, CO_FORE, BM_CPY, 0xFF, 0);

    /* Title bar: solid ink with the caption drawn in CO_BACK, which is
     * the usual way to get reverse video -- the glyphs come out in paper
     * and the gaps between them stay ink. */
    r.x0 = 2; r.y0 = 2; r.x1 = (coord)(w - 3); r.y1 = (coord)(bar + 2);
    gpx_fill_rectangle(gpx, &r, CO_FORE, BM_CPY, patt_solid, 1, 0);
    gpx_draw_text(gpx, (coord)(pad), 4, "libgpx", font, CO_BACK, BM_CPY, 0);

    /* Three pattern panels across the middle. */
    {
        coord top = (coord)(bar + 8);
        coord bot = (coord)(top + h / 4);
        coord cw = (coord)((w - 4 * pad) / 3);

        panel(gpx, pad, top, (coord)(pad + cw), bot, patt_half, 2);
        panel(gpx, (coord)(2 * pad + cw), top,
              (coord)(2 * pad + 2 * cw), bot, patt_brick, 4);
        panel(gpx, (coord)(3 * pad + 2 * cw), top,
              (coord)(3 * pad + 3 * cw), bot, patt_solid, 1);

        /* Caption inverted out of the solid panel with BM_XOR, which
         * ignores the colour argument and flips whatever it lands on. */
        gpx_draw_text(gpx, (coord)(3 * pad + 2 * cw + 4), (coord)(top + 4),
                      "XOR", font, CO_FORE, BM_XOR, 0);
    }

    /* A ruled block: each line uses a different dash pattern. Patterns
     * are applied one bit per pixel, LSB first from the start point. */
    {
        coord y = (coord)(bar + 12 + h / 4);
        static const uint8_t styles[4] = {0xFF, 0xAA, 0xF0, 0xE4};

        for (i = 0; i < 4; i++)
            gpx_draw_line(gpx, pad, (coord)(y + i * 4),
                          (coord)(w - pad), (coord)(y + i * 4),
                          CO_FORE, BM_CPY, styles[i], 0);
    }

    /* A clipped fan: the window rect keeps the rays inside the box,
     * and the box itself is drawn dotted so the edge is visible. */
    {
        static rect_t win;
        coord y = (coord)(bar + 32 + h / 4);

        win.x0 = pad;
        win.y0 = y;
        win.x1 = (coord)(w / 2);
        win.y1 = (coord)(h - pad - 1);
        gpx_draw_rectangle(gpx, &win, CO_FORE, BM_CPY, 0xAA, 0);
        for (i = 0; i <= 8; i++)
            gpx_draw_line(gpx, 0, (coord)(y - 8),
                          (coord)(w / 3 + i * (w / 24)), (coord)(h + 8),
                          CO_FORE, BM_CPY, 0xFF, &win);
    }

    /* Both stock fonts, and a cursor sprite parked beside them. */
    {
        coord y = (coord)(bar + 36 + h / 4);
        coord x = (coord)(w / 2 + pad);

        const font_t *tiny = gpx_get_tiny_font();

        /* glyph_height is the cell height; advance is the gap between
         * characters, so line spacing comes from the former. */
        gpx_draw_text(gpx, x, y, "System font", font, CO_FORE, BM_CPY, 0);
        gpx_draw_text(gpx, x, (coord)(y + font->glyph_height + 4),
                      "Tiny font", tiny, CO_FORE, BM_CPY, 0);

        cursor.bitmap = gpx_get_stock_bmp(GPXSB_CURSOR_CLASSIC);
        cursor.background = (bmp_t *)under;
        cursor.clip = 0;
        cursor.x = (coord)(x + 4);
        cursor.y = (coord)(y + 2 * (font->glyph_height + 4) + 4);
        gpx_show_sprite(gpx, &cursor);
        gpx_draw_text(gpx, (coord)(cursor.x + 16),
                      (coord)(cursor.y), "sprite", tiny, CO_FORE, BM_CPY, 0);
    }

    gpx_destroy(gpx);
}
```

The program reads the active width and height once, then derives padding,
panel widths, title height, clipping bounds, and text positions from them. The
`panel` helper keeps the three fill examples consistent by filling and framing
the same rectangle. The title demonstrates reverse video with `CO_BACK`, while
the third panel demonstrates destination inversion with `BM_XOR`.

Four horizontal rules pass distinct bit patterns to `gpx_draw_line`. The fan
starts outside its window, so every visible ray proves that clipping found the
correct entry and exit points. The last block obtains both stock fonts and a
stock cursor from the active backend; providing `under` keeps the sprite
definition portable even on a backend that does not need save-under storage.

## Bounce

`bounce.c` walks a cursor across a busy scene. Every fourth position is left
visible; all other positions are hidden again. The untouched half-tone slab,
solid block, and hairlines prove that hiding the sprite restores what was
underneath.

### ZX Spectrum 48K

![Bounce on the ZX Spectrum](../../docs/images/screenshots/bounce-zx.png)

### Iskra Delta Partner

![Bounce on the Iskra Delta Partner](../../docs/images/screenshots/bounce-partner.png)

### Amstrad CPC — 640 x 200

![Bounce on the Amstrad CPC at 640x200](../../docs/images/screenshots/bounce-cpc-640x200.png)

### Amstrad CPC — 320 x 200

![Bounce on the Amstrad CPC at 320x200](../../docs/images/screenshots/bounce-cpc-320x200.png)


This is the same public contract implemented two different ways. The Spectrum
saves and restores framebuffer pixels through `sprite.background`; the Partner
cannot read display memory, so its backend XOR-draws the sprite a second time.

### Main program

```c
/*
 * bounce.c
 *
 * libgpx manual example 2: a sprite moved across a busy background.
 *
 * Shows the show/hide contract. gpx_show_sprite draws the sprite and
 * gpx_hide_sprite puts back exactly what was underneath, so a moving
 * object leaves the scene it travels over untouched. How that is done
 * is the backend's business: the ZX saves the pixels under the sprite
 * into sprite->background, while the Partner has no readable display
 * memory and instead XOR-draws the sprite, which undoes itself when
 * drawn a second time.
 *
 * GPL2 License (see: LICENSE)
 * Copyright (C) 2026 Tomaz Stih
 */
#include "libgpx.h"

static uint8_t patt_half[2]  = {0xAA, 0x55};
static uint8_t patt_solid[1] = {0xFF};

/* Background storage for the ZX save-under. The Partner ignores it. */
static uint8_t under[GPX_SPRITE_BG_SIZE];

static void scene(gpx_t *gpx, dim w, dim h)
{
    rect_t r;
    coord i;

    gpx_clrscr();

    r.x0 = 0; r.y0 = 0; r.x1 = (coord)(w - 1); r.y1 = (coord)(h - 1);
    gpx_draw_rectangle(gpx, &r, CO_FORE, BM_CPY, 0xFF, 0);

    /* A half-tone slab and a solid slab, so the sprite crosses both
     * set and clear pixels on its way across. */
    r.x0 = (coord)(w / 16); r.y0 = (coord)(h / 3);
    r.x1 = (coord)(w / 2);  r.y1 = (coord)(h - h / 4);
    gpx_fill_rectangle(gpx, &r, CO_FORE, BM_CPY, patt_half, 2, 0);

    r.x0 = (coord)(w / 2 + w / 16); r.y0 = (coord)(h / 3);
    r.x1 = (coord)(w - w / 16);     r.y1 = (coord)(h / 2);
    gpx_fill_rectangle(gpx, &r, CO_FORE, BM_CPY, patt_solid, 1, 0);

    /* Hairlines fanning across the whole width. */
    for (i = 0; i < 6; i++)
        gpx_draw_line(gpx, 0, (coord)(i * (h / 6)),
                      (coord)(w - 1), (coord)(h - 1 - i * (h / 6)),
                      CO_FORE, BM_CPY, 0xFF, 0);
}

void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    dim w = gpx_width();
    dim h = gpx_height();
    sprite_t sp;
    coord step = (coord)(w / 24);
    coord i;

    scene(gpx, w, h);

    sp.bitmap = gpx_get_stock_bmp(GPXSB_CURSOR_CLASSIC);
    sp.background = (bmp_t *)under;
    sp.clip = 0;

    /* Walk it across the artwork. Every fourth position is left on
     * screen and the rest are hidden again, so the picture shows both
     * halves of the contract at once: the trail proves the sprite was
     * drawn at each step, and the untouched artwork between the marks
     * proves hide put back exactly what was underneath. */
    for (i = 0; i < 20; i++) {
        sp.x = (coord)(w / 16 + i * step);
        sp.y = (coord)(h / 8 + i * (h / 32));
        gpx_show_sprite(gpx, &sp);
        if (i % 4 != 0)
            gpx_hide_sprite(gpx, &sp);
    }

    gpx_destroy(gpx);
}
```

`scene` derives every shape from the current display dimensions. It combines
set and clear pixels—checker fill, solid fill, empty areas, and diagonal
hairlines—so the cursor crosses difficult restoration boundaries rather than a
blank background. `main` obtains the stock cursor, supplies its background
buffer, and chooses horizontal and vertical steps proportional to the screen.

Each loop iteration shows the sprite. Positions whose index is not divisible
by four are immediately hidden, while indices 0, 4, 8, 12, and 16 remain as a
visible trail. Correct output therefore demonstrates both halves of the sprite
contract at once: the five retained cursors were drawn, and every intervening
position was restored without damaging the underlying scene.

## Build

From the repository root:

```bash
make -C samples/demo3 build       # every program for both targets
make -C samples/demo3 zx          # bin/demo3/panels.tap, bounce.tap
make -C samples/demo3 partner     # bin/demo3/panels.com, bounce.com
```

All compilation happens in the pinned Docker toolchain images. Spectrum tapes
load at `0x8000`; Partner programs are CP/M transient programs at `0x0100`.

## Run

Load either `.tap` in a 48K Spectrum emulator, or run the corresponding `.com`
from CP/M on the Partner. For example:

```bash
scripts/run/run-fuse-demo1.sh bin/demo3/panels.tap
```

To rebuild all sample screenshots and run them through both headless MCP
emulators:

```bash
python3 scripts/docs/capture-manual-shots.py
```
