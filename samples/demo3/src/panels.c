/*
 * panels.c
 *
 * libgpx manual example 1: a static screen that exercises most of the
 * drawing API -- frames, pattern fills, line styles, both stock fonts,
 * XOR text over ink, clipping, and a stock cursor sprite.
 *
 * The same source builds for the ZX Spectrum (256x192), the Iskra Delta
 * Partner (1024x256) and the Amstrad CPC (640x200 or 320x200), so every
 * coordinate is derived from gpx_width() and gpx_height() rather than
 * hard-coded.
 *
 * GPL2 License (see: LICENSE)
 * Copyright (C) 2026 Tomaz Stih
 */
#include "libgpx.h"

/* The Amstrad CPC has two display modes and one library, so the manual's
 * screenshots are taken twice from this one source. Everything below is
 * derived from gpx_width()/gpx_height(), so only this line changes. */
#ifndef DEMO_MODE
#define DEMO_MODE GPXM_DEFAULT
#endif

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
    gpx_t *gpx = gpx_create(DEMO_MODE);
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
