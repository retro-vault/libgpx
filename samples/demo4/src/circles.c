/*
 * circles.c
 *
 * libgpx demo 4: the ADVANCED circle primitives -- outlines at growing
 * radii, pattern fills, a disc with a contrasting rim, XOR overlap and
 * a clipped circle.
 *
 * The same source builds for the ZX Spectrum (256x192), the Iskra Delta
 * Partner (1024x256) and the Amstrad CPC (640x200 or 320x200), so every
 * coordinate is derived from gpx_width() and gpx_height() rather than
 * hard-coded.
 *
 * Needs a library built with ADVANCED enabled, which is the default.
 *
 * GPL2 License (see: LICENSE)
 * Copyright (C) 2026 Tomaz Stih
 */
#include "libgpx.h"

/* The Amstrad CPC has two display modes and one library, so the demo's
 * screenshots are taken twice from this one source. Everything below is
 * derived from gpx_width()/gpx_height(), so only this line changes. */
#ifndef DEMO_MODE
#define DEMO_MODE GPXM_DEFAULT
#endif

static uint8_t patt_solid[1] = {0xFF};
static uint8_t patt_half[2]  = {0xAA, 0x55};
static uint8_t patt_brick[4] = {0xFF, 0x88, 0x88, 0x88};
static uint8_t patt_mesh[8]  = {0xFF, 0x81, 0x81, 0x81,
                                0xFF, 0x18, 0x18, 0x18};

/* Ring of concentric outlines, drawn from the outside in. */
static void bullseye(gpx_t *gpx, coord x, coord y, coord r, coord step)
{
    while (r > 0) {
        gpx_draw_circle(gpx, x, y, r, CO_FORE, BM_CPY, 0);
        r = (coord)(r - step);
    }
}

void main(void)
{
    gpx_t *gpx = gpx_create(DEMO_MODE);
    const font_t *font = gpx_get_system_font();
    dim w = gpx_width();
    dim h = gpx_height();
    coord bar = (coord)(font->glyph_height + 4);
    coord top = (coord)(bar + 6);
    coord band = (coord)((h - top - 3) / 3);   /* three rows of circles */
    coord step = (coord)(w / 7);               /* six across a row */
    coord rmax;
    rect_t r;
    coord i;

    /* The biggest circle that fits a cell, whichever way the display is
     * shaped: wide and short on the Partner, nearly square on the ZX. */
    rmax = (coord)(band / 2 - 2);
    if (rmax > (coord)(step / 2 - 2))
        rmax = (coord)(step / 2 - 2);

    gpx_clrscr();

    /* Outer frame and a reverse-video title bar. */
    r.x0 = 0; r.y0 = 0; r.x1 = (coord)(w - 1); r.y1 = (coord)(h - 1);
    gpx_draw_rectangle(gpx, &r, CO_FORE, BM_CPY, 0xFF, 0);
    r.x0 = 2; r.y0 = 2; r.x1 = (coord)(w - 3); r.y1 = (coord)(bar + 2);
    gpx_fill_rectangle(gpx, &r, CO_FORE, BM_CPY, patt_solid, 1, 0);
    gpx_draw_text(gpx, (coord)(step / 4), 4, "libgpx circles", font,
                  CO_BACK, BM_CPY, 0);

    /* Row 1: outlines, growing. The last cell holds a bullseye instead,
     * which is the same primitive called at four radii. */
    {
        coord cy = (coord)(top + band / 2);

        for (i = 0; i < 5; i++)
            gpx_draw_circle(gpx, (coord)(step * (i + 1)), cy,
                            (coord)(rmax * (i + 1) / 5),
                            CO_FORE, BM_CPY, 0);
        bullseye(gpx, (coord)(step * 6), cy, rmax, (coord)(rmax / 4 + 1));
    }

    /* Row 2: the same disc filled four ways, then one with a ring
     * knocked out of it in CO_BACK, then a patterned one closed with a
     * solid rim. The rim lands exactly on the disc's own edge -- the fill
     * and the outline walk the same stepper -- so a dithered disc can be
     * given a clean edge by drawing the outline over it. */
    {
        coord cy = (coord)(top + band + band / 2);

        gpx_fill_circle(gpx, (coord)(step * 1), cy, rmax,
                        CO_FORE, BM_CPY, patt_solid, 1, 0);
        gpx_fill_circle(gpx, (coord)(step * 2), cy, rmax,
                        CO_FORE, BM_CPY, patt_half, 2, 0);
        gpx_fill_circle(gpx, (coord)(step * 3), cy, rmax,
                        CO_FORE, BM_CPY, patt_brick, 4, 0);
        gpx_fill_circle(gpx, (coord)(step * 4), cy, rmax,
                        CO_FORE, BM_CPY, patt_mesh, 8, 0);

        gpx_fill_circle(gpx, (coord)(step * 5), cy, rmax,
                        CO_FORE, BM_CPY, patt_solid, 1, 0);
        gpx_draw_circle(gpx, (coord)(step * 5), cy, (coord)(rmax * 2 / 3),
                        CO_BACK, BM_CPY, 0);

        /* An outline over a patterned fill: the rim is the disc's edge. */
        gpx_fill_circle(gpx, (coord)(step * 6), cy, rmax,
                        CO_FORE, BM_CPY, patt_half, 2, 0);
        gpx_draw_circle(gpx, (coord)(step * 6), cy, rmax,
                        CO_FORE, BM_CPY, 0);
    }

    /* Row 3: three discs XOR'd over each other, so every overlap comes
     * back out again -- each row of a fill is painted exactly once, which
     * is what makes that work -- and a circle far too big for the window
     * it is clipped to. */
    {
        coord cy = (coord)(top + 2 * band + band / 2);
        coord ox = (coord)(rmax * 2 / 3);

        for (i = 0; i < 3; i++)
            gpx_fill_circle(gpx, (coord)(step * 2 + i * ox), cy, rmax,
                            CO_FORE, BM_XOR, patt_solid, 1, 0);

        {
            static rect_t win;

            win.x0 = (coord)(step * 4);
            win.y0 = (coord)(cy - band / 3);
            win.x1 = (coord)(step * 6);
            win.y1 = (coord)(cy + band / 3);
            gpx_draw_rectangle(gpx, &win, CO_FORE, BM_CPY, 0xAA, 0);
            gpx_fill_circle(gpx, (coord)(step * 5), cy, (coord)(rmax * 2),
                            CO_FORE, BM_CPY, patt_brick, 4, &win);
            gpx_draw_circle(gpx, (coord)(step * 5), cy, (coord)(rmax * 2),
                            CO_FORE, BM_CPY, &win);
        }
    }

    gpx_destroy(gpx);
}
