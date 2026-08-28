/* Cross-backend conformance for the ADVANCED circle primitives. The stepper
 * and the pattern anchoring live in one portable module, so any difference
 * here is the backend underneath it: gpx_draw_pixel for the outline and
 * gpx_fill_rectangle for the fill. Everything stays inside 256x192. */
#include "libgpx.h"

#ifndef DEMO_MODE
#define DEMO_MODE GPXM_DEFAULT
#endif

uint8_t gdp_finished;
#define phase() __asm__("halt")
#define done()  do { gdp_finished = 0xA5; __asm__("halt"); } while (0)

void main(void)
{
    gpx_t *gpx = gpx_create(DEMO_MODE);
    coord r;

    /* --- outlines: the small radii, where the octant walk meets the
     * diagonal, and a few large ones --- */
    gpx_clrscr();
    for (r = 0; r < 12; ++r)
        gpx_draw_circle(gpx, (coord)(14 + r * 20), 20, r,
                        CO_FORE, BM_CPY, 0);
    gpx_draw_circle(gpx, 60, 120, 45, CO_FORE, BM_CPY, 0);
    gpx_draw_circle(gpx, 170, 120, 60, CO_FORE, BM_CPY, 0);
    gpx_draw_circle(gpx, 128, 96, -4, CO_FORE, BM_CPY, 0);
    phase();

    /* --- solid fills, and the outline of the same radius laid on top: the
     * outline has to land on the disc's own edge --- */
    gpx_clrscr();
    {
        static uint8_t solid[1] = {0xFF};
        for (r = 0; r < 9; ++r)
            gpx_fill_circle(gpx, (coord)(12 + r * 22), 16, r,
                            CO_FORE, BM_CPY, solid, 1, 0);
        gpx_fill_circle(gpx, 70, 110, 50, CO_FORE, BM_CPY, solid, 1, 0);
        gpx_fill_circle(gpx, 180, 110, 40, CO_FORE, BM_CPY, solid, 1, 0);
        gpx_draw_circle(gpx, 180, 110, 40, CO_BACK, BM_CPY, 0);
    }
    phase();

    /* --- patterned fills: a masked length, two that go through the
     * divide, and the eight-byte case --- */
    gpx_clrscr();
    {
        static uint8_t check[2] = {0xAA, 0x55};
        static uint8_t three[3] = {0xF0, 0x0F, 0xAA};
        static uint8_t five[5] = {0x80, 0x40, 0x20, 0x10, 0x08};
        static uint8_t brick[8] = {0xFF, 0x88, 0x88, 0x88,
                                   0xFF, 0x08, 0x08, 0x08};
        gpx_fill_circle(gpx, 40, 50, 35, CO_FORE, BM_CPY, check, 2, 0);
        gpx_fill_circle(gpx, 130, 50, 35, CO_FORE, BM_CPY, three, 3, 0);
        gpx_fill_circle(gpx, 215, 50, 35, CO_FORE, BM_CPY, five, 5, 0);
        gpx_fill_circle(gpx, 60, 145, 40, CO_FORE, BM_CPY, brick, 8, 0);
        gpx_fill_circle(gpx, 170, 145, 20, CO_FORE, BM_CPY, check, 0, 0);
    }
    phase();

    /* --- the fill pattern is anchored to the disc's bounding box, exactly
     * as a rectangle fill is anchored to its rectangle. The disc and the
     * band share a left edge and a row grid, so the stripes have to run
     * straight through both on every backend. --- */
    gpx_clrscr();
    {
        static rect_t band = {20, 20, 119, 119};
        static uint8_t stripe[4] = {0xF0, 0xF0, 0x0F, 0x0F};
        gpx_fill_rectangle(gpx, &band, CO_FORE, BM_CPY, stripe, 4, 0);
        gpx_fill_circle(gpx, 190, 70, 50, CO_FORE, BM_CPY, stripe, 4, 0);
    }
    phase();

    /* --- clipping: outline and fill cut by a window, and the pattern
     * phase must not shift because of the cut --- */
    gpx_clrscr();
    {
        static rect_t win = {60, 50, 190, 150};
        static uint8_t check[2] = {0xCC, 0x33};
        gpx_draw_rectangle(gpx, &win, CO_FORE, BM_CPY, 0xFF, 0);
        gpx_draw_circle(gpx, 125, 100, 80, CO_FORE, BM_CPY, &win);
        gpx_fill_circle(gpx, 125, 100, 60, CO_FORE, BM_CPY, check, 2, &win);
        gpx_draw_circle(gpx, 20, 20, 12, CO_FORE, BM_CPY, &win);
        gpx_fill_circle(gpx, 20, 20, 12, CO_FORE, BM_CPY, check, 2, &win);
        gpx_draw_circle(gpx, 0, 191, 30, CO_FORE, BM_CPY, 0);
        gpx_draw_circle(gpx, 255, 0, 30, CO_FORE, BM_CPY, 0);
    }
    phase();

    /* --- XOR: drawing either shape twice restores what was under it, and
     * the colour argument is ignored --- */
    gpx_clrscr();
    {
        static rect_t band = {0, 0, 250, 90};
        static uint8_t solid[1] = {0xFF};
        gpx_fill_rectangle(gpx, &band, CO_FORE, BM_CPY, solid, 1, 0);
        gpx_fill_circle(gpx, 50, 45, 35, CO_FORE, BM_XOR, solid, 1, 0);
        gpx_fill_circle(gpx, 150, 45, 35, CO_BACK, BM_XOR, solid, 1, 0);
        gpx_draw_circle(gpx, 220, 45, 30, CO_FORE, BM_XOR, 0);

        gpx_fill_circle(gpx, 60, 140, 40, CO_FORE, BM_XOR, solid, 1, 0);
        gpx_fill_circle(gpx, 60, 140, 40, CO_FORE, BM_XOR, solid, 1, 0);
        gpx_draw_circle(gpx, 180, 140, 40, CO_FORE, BM_XOR, 0);
        gpx_draw_circle(gpx, 180, 140, 40, CO_FORE, BM_XOR, 0);
    }
    done();
}
