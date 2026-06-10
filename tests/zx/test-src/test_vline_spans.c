#include "libgpx.h"

/* Vertical lines (dispatched to vline), patterns, reversed endpoints, xor. */
void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    rect_t full = {0, 0, 255, 191};

    /* columns at every x alignment, solid */
    for (coord x = 0; x < 16; ++x)
        gpx_draw_line(gpx, x, 10, x, 40, CO_FORE, BM_CPY, 0xFF, &full);

    /* full-height column */
    gpx_draw_line(gpx, 40, 0, 40, 191, CO_FORE, BM_CPY, 0xFF, &full);

    /* patterned, reversed endpoints */
    gpx_draw_line(gpx, 60, 40, 60, 10, CO_FORE, BM_CPY, 0xAA, &full);
    gpx_draw_line(gpx, 62, 10, 62, 40, CO_FORE, BM_CPY, 0xCC, &full);
    gpx_draw_line(gpx, 64, 10, 64, 40, CO_FORE, BM_CPY, 0x80, &full);

    /* single pixel via vertical */
    gpx_draw_line(gpx, 70, 20, 70, 20, CO_FORE, BM_CPY, 0xFF, &full);

    /* xor column over solid block */
    {
        rect_t solid = {100, 10, 100, 40};
        uint8_t fp = 0xFF;
        gpx_fill_rectangle(gpx, &solid, CO_FORE, BM_CPY, &fp, 1, &full);
        gpx_draw_line(gpx, 100, 10, 100, 40, CO_FORE, BM_XOR, 0xF0, &full);
    }

    __asm
        halt
    __endasm;
}
