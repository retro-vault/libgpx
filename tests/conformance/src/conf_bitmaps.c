/* Cross-backend conformance: clipped bitmap blits.
 *
 * Nothing else in the suite draws a bitmap through a clip rect, so the
 * blitter's general clipping path -- the one that works out how much of the
 * source is skipped off the left and top -- went untested. Every other
 * scenario draws bitmaps that are wholly visible, which on the CPC takes a
 * dedicated fast path and never touches the general one at all.
 *
 * Clipping is expressed as a rect rather than as an off-screen position, so
 * the same source clips identically on a 256-wide ZX and a 640-wide CPC.
 *
 * The stock cursors are the artwork: the ZX and CPC ship the same rasters,
 * so those two must match exactly. The Partner draws bitmaps as vector
 * move-streams and its artwork differs by design, which is the standing
 * bitmap-payload exception.
 */
#include "libgpx.h"

#ifndef DEMO_MODE
#define DEMO_MODE GPXM_DEFAULT
#endif

uint8_t gdp_finished;
#define phase() __asm__("halt")
#define done()  do { gdp_finished = 0xA5; __asm__("halt"); } while (0)

static uint8_t under[GPX_SPRITE_BG_SIZE];

/* Put a cursor at each of the four edges of the window and at its corners,
 * so every combination of left/right/top/bottom clipping is drawn. */
static void ring(gpx_t *gpx, const rect_t *win, coord cx, coord cy, coord r)
{
    static const signed char off[8][2] = {
        {-1, 0}, {1, 0}, {0, -1}, {0, 1},
        {-1, -1}, {1, -1}, {-1, 1}, {1, 1}
    };
    uint8_t i;

    for (i = 0; i < 8; i++)
        gpx_draw_bmp(gpx, (coord)(cx + off[i][0] * r),
                     (coord)(cy + off[i][1] * r),
                     gpx_get_stock_bmp(GPXSB_CURSOR_CLASSIC), win);
}

void main(void)
{
    gpx_t *gpx = gpx_create(DEMO_MODE);
    static rect_t win = {40, 40, 200, 150};
    coord i;

    /* --- cut on every edge and corner of a clip rect --- */
    gpx_clrscr();
    gpx_draw_rectangle(gpx, &win, CO_FORE, BM_CPY, 0xFF, 0);
    ring(gpx, &win, 120, 95, 60);
    phase();

    /* --- the same over solid ink, so a mask that is ignored shows up --- */
    gpx_clrscr();
    {
        static rect_t band = {30, 30, 210, 160};
        static uint8_t solid[1] = {0xFF};
        gpx_fill_rectangle(gpx, &band, CO_FORE, BM_CPY, solid, 1, 0);
        ring(gpx, &win, 120, 95, 60);
    }
    phase();

    /* --- clipped right down to a sliver, and past it to nothing --- */
    gpx_clrscr();
    {
        static rect_t slit = {100, 90, 104, 94};
        gpx_draw_bmp(gpx, 96, 86, gpx_get_stock_bmp(GPXSB_CURSOR_CLASSIC),
                     &slit);
        /* Entirely outside: must draw nothing at all. */
        gpx_draw_bmp(gpx, 10, 10, gpx_get_stock_bmp(GPXSB_CURSOR_CLASSIC),
                     &slit);
        gpx_draw_bmp(gpx, 200, 170, gpx_get_stock_bmp(GPXSB_CURSOR_CLASSIC),
                     &slit);
    }
    phase();

    /* --- every stock cursor, unclipped, as the fast-path control --- */
    gpx_clrscr();
    for (i = 0; i < 5; i++) {
        sprite_t s;
        s.bitmap = gpx_get_stock_bmp((uint8_t)i);
        s.background = (bmp_t *)under;
        s.clip = 0;
        s.x = (coord)(20 + i * 40);
        s.y = 100;
        gpx_show_sprite(gpx, &s);
    }
    done();
}
