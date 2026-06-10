#include "libgpx.h"

/* Horizontal lines (dispatched to hline) across many byte-boundary layouts. */
void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    rect_t full = {0, 0, 255, 191};
    coord y = 10;

    /* every start alignment, single-byte and multi-byte spans, solid */
    for (coord x0 = 0; x0 < 8; ++x0) {
        gpx_draw_line(gpx, x0, y, x0 + 1, y, CO_FORE, BM_CPY, 0xFF, &full);
        gpx_draw_line(gpx, x0 + 16, y, x0 + 16, y, CO_FORE, BM_CPY, 0xFF, &full);
        gpx_draw_line(gpx, x0 + 32, y, x0 + 50, y, CO_FORE, BM_CPY, 0xFF, &full);
        y += 2;
    }

    /* full-width row */
    gpx_draw_line(gpx, 0, 60, 255, 60, CO_FORE, BM_CPY, 0xFF, &full);

    /* patterned spans, reversed endpoints */
    gpx_draw_line(gpx, 100, 70, 40, 70, CO_FORE, BM_CPY, 0xAA, &full);
    gpx_draw_line(gpx, 40, 72, 100, 72, CO_FORE, BM_CPY, 0xCC, &full);

    /* xor over solid */
    {
        rect_t solid = {10, 80, 90, 80};
        uint8_t fp = 0xFF;
        gpx_fill_rectangle(gpx, &solid, CO_FORE, BM_CPY, &fp, 1, &full);
        gpx_draw_line(gpx, 10, 80, 90, 80, CO_FORE, BM_XOR, 0xAA, &full);
    }

    __asm
        halt
    __endasm;
}
