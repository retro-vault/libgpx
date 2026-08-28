#include "bench.h"

BENCH_MAIN()

/* Circles: the outline stepper, which costs one gpx_draw_pixel per plotted
 * point, and the fill, which costs one row-fill per scanline. Radii are the
 * ones a UI actually draws, plus a big one to show how the cost scales. */
void bench_body(gpx_t *gpx)
{
    static uint8_t solid[1] = {0xFF};
    static uint8_t dash[2] = {0xAA, 0x55};
    static uint8_t p5[5] = {0xF0, 0xE1, 0xC3, 0x87, 0x0F};
    rect_t clip = {40, 40, 215, 151};
    coord r;
    uint8_t i;

    /* outlines, small to large */
    for (i = 0; i < 4; ++i)
        for (r = 4; r <= 64; r = (coord)(r + 10))
            gpx_draw_circle(gpx, 128, 96, r, CO_FORE, BM_CPY,
                (const rect_t *)0);

    /* the same outlines in XOR, the cursor/rubber-band case */
    for (i = 0; i < 4; ++i)
        for (r = 4; r <= 64; r = (coord)(r + 10))
            gpx_draw_circle(gpx, 128, 96, r, CO_FORE, BM_XOR,
                (const rect_t *)0);

    /* solid fills */
    for (i = 0; i < 4; ++i)
        for (r = 4; r <= 64; r = (coord)(r + 10))
            gpx_fill_circle(gpx, 128, 96, r, CO_FORE, BM_CPY, solid, 1,
                (const rect_t *)0);

    /* patterned fills: a masked length and one that goes through the divide */
    for (i = 0; i < 4; ++i)
        gpx_fill_circle(gpx, 128, 96, 64, CO_FORE, BM_CPY, dash, 2,
            (const rect_t *)0);
    for (i = 0; i < 4; ++i)
        gpx_fill_circle(gpx, 128, 96, 64, CO_FORE, BM_CPY, p5, 5,
            (const rect_t *)0);

    /* clipped, and XOR */
    for (i = 0; i < 4; ++i)
        gpx_fill_circle(gpx, 128, 96, 64, CO_FORE, BM_CPY, solid, 1, &clip);
    for (i = 0; i < 4; ++i)
        gpx_fill_circle(gpx, 128, 96, 64, CO_FORE, BM_XOR, solid, 1,
            (const rect_t *)0);
}
