/*
 * polygons.c
 *
 * libgpx demo 5: the ADVANCED polygon primitives -- outlines with a dash
 * chained round the corners, convex and concave fills, the even-odd rule
 * on a self-intersecting pentagram, pattern fills anchored to the
 * bounding box, XOR and clipping.
 *
 * The same source builds for the ZX Spectrum (256x192), the Iskra Delta
 * Partner (1024x256) and the Amstrad CPC (640x200 or 320x200). Shapes are
 * held in a 0..64 unit square and scaled into cells derived from
 * gpx_width() and gpx_height(), so nothing is hard-coded.
 *
 * Needs a library built with ADVANCED enabled, which is the default.
 *
 * GPL2 License (see: LICENSE)
 * Copyright (C) 2026 Tomaz Stih
 */
#include "libgpx.h"

/* The Amstrad CPC has two display modes and one library, so the demo's
 * screenshots are taken twice from this one source. */
#ifndef DEMO_MODE
#define DEMO_MODE GPXM_DEFAULT
#endif

#define UNIT 64                         /* the shapes' own coordinate box */

static uint8_t patt_solid[1] = {0xFF};
static uint8_t patt_half[2]  = {0xAA, 0x55};
static uint8_t patt_brick[4] = {0xFF, 0x88, 0x88, 0x88};
static uint8_t patt_mesh[8]  = {0xFF, 0x81, 0x81, 0x81,
                                0xFF, 0x18, 0x18, 0x18};

/* Unit shapes, x then y, each inside 0..UNIT. */
static const uint8_t u_triangle[] = {32,0, 64,56, 0,56};
static const uint8_t u_hexagon[]  = {16,0, 48,0, 64,32, 48,64, 16,64, 0,32};
/* A ten-point star: outer and inner vertices alternate, so it does not
 * cross itself and fills solid. */
static const uint8_t u_star[]     = {32,0, 39,22, 62,22, 44,36, 51,58,
                                     32,44, 13,58, 20,36, 2,22, 25,22};
/* A pentagram: the same five outer points joined every other one, so the
 * edges cross and the even-odd rule leaves the middle hollow. */
static const uint8_t u_pentagram[] = {32,0, 51,58, 2,22, 62,22, 13,58};
/* A concave chevron: the notch has to stay empty. */
static const uint8_t u_chevron[]  = {0,0, 32,26, 64,0, 64,22, 32,48, 0,22};

static point_t pts[GPX_MAX_POLY_PTS];

/* Scale one unit shape into a cell and return its point count. */
static uint8_t place(const uint8_t *unit, uint8_t n, coord ox, coord oy,
                     coord size)
{
    uint8_t i;

    for (i = 0; i < n; ++i) {
        pts[i].x = (coord)(ox + ((coord)unit[i * 2] * size) / UNIT);
        pts[i].y = (coord)(oy + ((coord)unit[i * 2 + 1] * size) / UNIT);
    }
    return n;
}

void main(void)
{
    gpx_t *gpx = gpx_create(DEMO_MODE);
    const font_t *font = gpx_get_system_font();
    dim w = gpx_width();
    dim h = gpx_height();
    coord bar = (coord)(font->glyph_height + 4);
    coord top = (coord)(bar + 6);
    coord cw = (coord)(w / 4);            /* four shapes across a row */
    coord band = (coord)((h - top - 3) / 3);
    coord size;
    coord pad;
    coord row1;
    coord row2;
    coord row3;
    rect_t r;

    /* The biggest unit square that fits a cell, whichever way the display
     * is shaped: wide and short on the Partner, nearly square on the ZX. */
    size = (coord)(band - 4);
    if (size > (coord)(cw - 6))
        size = (coord)(cw - 6);
    pad = (coord)((cw - size) / 2);
    row1 = (coord)(top + (band - size) / 2);
    row2 = (coord)(top + band + (band - size) / 2);
    row3 = (coord)(top + 2 * band + (band - size) / 2);

    gpx_clrscr();

    /* Outer frame and a reverse-video title bar. */
    r.x0 = 0; r.y0 = 0; r.x1 = (coord)(w - 1); r.y1 = (coord)(h - 1);
    gpx_draw_rectangle(gpx, &r, CO_FORE, BM_CPY, 0xFF, 0);
    r.x0 = 2; r.y0 = 2; r.x1 = (coord)(w - 3); r.y1 = (coord)(bar + 2);
    gpx_fill_rectangle(gpx, &r, CO_FORE, BM_CPY, patt_solid, 1, 0);
    gpx_draw_text(gpx, pad, 4, "libgpx polygons", font, CO_BACK, BM_CPY, 0);

    /* Row 1: outlines. The dashed ones show the pattern carried from each
     * edge into the next, so the dashes run on round the corners. */
    {
        uint8_t n;

        n = place(u_triangle, 3, pad, row1, size);
        gpx_draw_polygon(gpx, pts, n, CO_FORE, BM_CPY, 0xFF, 0);

        n = place(u_hexagon, 6, (coord)(cw + pad), row1, size);
        gpx_draw_polygon(gpx, pts, n, CO_FORE, BM_CPY, 0xE4, 0);

        n = place(u_star, 10, (coord)(2 * cw + pad), row1, size);
        gpx_draw_polygon(gpx, pts, n, CO_FORE, BM_CPY, 0xFF, 0);

        n = place(u_pentagram, 5, (coord)(3 * cw + pad), row1, size);
        gpx_draw_polygon(gpx, pts, n, CO_FORE, BM_CPY, 0xAA, 0);
    }

    /* Row 2: fills. Concave, self-intersecting and patterned. */
    {
        uint8_t n;

        n = place(u_hexagon, 6, pad, row2, size);
        gpx_fill_polygon(gpx, pts, n, CO_FORE, BM_CPY, patt_solid, 1, 0);

        n = place(u_chevron, 6, (coord)(cw + pad), row2, size);
        gpx_fill_polygon(gpx, pts, n, CO_FORE, BM_CPY, patt_solid, 1, 0);

        /* Even-odd: the middle of a pentagram is outside the shape. */
        n = place(u_pentagram, 5, (coord)(2 * cw + pad), row2, size);
        gpx_fill_polygon(gpx, pts, n, CO_FORE, BM_CPY, patt_solid, 1, 0);

        n = place(u_star, 10, (coord)(3 * cw + pad), row2, size);
        gpx_fill_polygon(gpx, pts, n, CO_FORE, BM_CPY, patt_mesh, 8, 0);
    }

    /* Row 3: what the fill guarantees. A dithered fill closed with a solid
     * rim, an outline knocked out of a fill, an XOR pair whose overlap
     * comes back out, and a polygon clipped to a window. */
    {
        uint8_t n;

        n = place(u_hexagon, 6, pad, row3, size);
        gpx_fill_polygon(gpx, pts, n, CO_FORE, BM_CPY, patt_half, 2, 0);
        gpx_draw_polygon(gpx, pts, n, CO_FORE, BM_CPY, 0xFF, 0);

        /* An outline erases as readily as it draws: a solid star with a
         * smaller pentagram knocked out of it in CO_BACK. */
        n = place(u_star, 10, (coord)(cw + pad), row3, size);
        gpx_fill_polygon(gpx, pts, n, CO_FORE, BM_CPY, patt_solid, 1, 0);
        n = place(u_pentagram, 5,
                  (coord)(cw + pad + size / 5),
                  (coord)(row3 + size / 5), (coord)(size * 3 / 5));
        gpx_draw_polygon(gpx, pts, n, CO_BACK, BM_CPY, 0xFF, 0);

        n = place(u_triangle, 3, (coord)(2 * cw + pad), row3, size);
        gpx_fill_polygon(gpx, pts, n, CO_FORE, BM_XOR, patt_solid, 1, 0);
        n = place(u_triangle, 3, (coord)(2 * cw + pad + size / 3), row3,
                  size);
        gpx_fill_polygon(gpx, pts, n, CO_FORE, BM_XOR, patt_solid, 1, 0);

        {
            static rect_t win;

            win.x0 = (coord)(3 * cw + pad);
            win.y0 = (coord)(row3 + size / 4);
            win.x1 = (coord)(3 * cw + pad + size);
            win.y1 = (coord)(row3 + 3 * size / 4);
            gpx_draw_rectangle(gpx, &win, CO_FORE, BM_CPY, 0xAA, 0);
            n = place(u_chevron, 6, (coord)(3 * cw + pad),
                      (coord)(row3 - size / 4), (coord)(size + size / 2));
            gpx_fill_polygon(gpx, pts, n, CO_FORE, BM_CPY, patt_brick, 4,
                             &win);
            gpx_draw_polygon(gpx, pts, n, CO_FORE, BM_CPY, 0xFF, &win);
        }
    }

    gpx_destroy(gpx);
}
