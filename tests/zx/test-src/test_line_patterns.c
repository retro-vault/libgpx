#include "libgpx.h"

/* Patterned lines and pattern-phase chaining across segments. */
void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    rect_t full = {0, 0, 255, 191};
    uint8_t p;

    /* chained polyline keeps pattern phase */
    p = 0xF0;
    p = gpx_draw_line(gpx, 0, 0, 60, 0, CO_FORE, BM_CPY, p, &full);
    p = gpx_draw_line(gpx, 60, 0, 60, 30, CO_FORE, BM_CPY, p, &full);
    p = gpx_draw_line(gpx, 60, 30, 0, 30, CO_FORE, BM_CPY, p, &full);

    /* various dash patterns, sloped */
    gpx_draw_line(gpx, 0, 40, 80, 60, CO_FORE, BM_CPY, 0xAA, &full);
    gpx_draw_line(gpx, 0, 50, 80, 70, CO_FORE, BM_CPY, 0xCC, &full);
    gpx_draw_line(gpx, 0, 60, 80, 80, CO_FORE, BM_CPY, 0x81, &full);
    gpx_draw_line(gpx, 0, 70, 80, 90, CO_FORE, BM_CPY, 0x01, &full);

    /* steep patterned */
    gpx_draw_line(gpx, 120, 0, 130, 80, CO_FORE, BM_CPY, 0xAA, &full);
    gpx_draw_line(gpx, 140, 0, 130, 80, CO_FORE, BM_CPY, 0x33, &full);

    __asm
        halt
    __endasm;
}
