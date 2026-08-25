#include "libgpx.h"

void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);

    rect_t clip = {10, 10, 20, 20};

    /* Hardware solid line. */
    gpx_draw_line(gpx, 2, 2, 20, 2, CO_FORE, BM_CPY, 0xFF, (const rect_t *)0);

    /* Hardware solid with clipping. */
    gpx_draw_line(gpx, 0, 0, 30, 30, CO_FORE, BM_CPY, 0xFF, &clip);

    /* Custom pattern should use Bresenham fallback. */
    gpx_draw_line(gpx, 40, 10, 47, 10, CO_FORE, BM_CPY, 0xA5, (const rect_t *)0);

    /* Hardware dashed style. */
    gpx_draw_line(gpx, 60, 10, 67, 10, CO_FORE, BM_CPY, 0xF0, (const rect_t *)0);

    /* Long solid line (>256 px) to force recursive vector splitting. */
    gpx_draw_line(gpx, 100, 50, 500, 50, CO_FORE, BM_CPY, 0xFF, (const rect_t *)0);

    /* Long clipped solid line (>256 px after clipping), also recursive. */
    rect_t clip_long = {50, 80, 400, 80};
    gpx_draw_line(gpx, -100, 80, 500, 80, CO_FORE, BM_CPY, 0xFF, &clip_long);

    /* Pattern matrix: recognized hardware groups + software fallback. */
    gpx_draw_line(gpx, 10, 100, 25, 100, CO_FORE, BM_CPY, 0xFF, (const rect_t *)0);
    gpx_draw_line(gpx, 10, 101, 25, 101, CO_FORE, BM_CPY, 0x33, (const rect_t *)0);
    gpx_draw_line(gpx, 10, 102, 25, 102, CO_FORE, BM_CPY, 0x66, (const rect_t *)0);
    gpx_draw_line(gpx, 10, 103, 25, 103, CO_FORE, BM_CPY, 0xCC, (const rect_t *)0);
    gpx_draw_line(gpx, 10, 104, 25, 104, CO_FORE, BM_CPY, 0x99, (const rect_t *)0);
    gpx_draw_line(gpx, 10, 105, 25, 105, CO_FORE, BM_CPY, 0xAA, (const rect_t *)0);
    gpx_draw_line(gpx, 10, 106, 25, 106, CO_FORE, BM_CPY, 0x55, (const rect_t *)0);
    gpx_draw_line(gpx, 10, 107, 25, 107, CO_FORE, BM_CPY, 0xF0, (const rect_t *)0);
    gpx_draw_line(gpx, 10, 108, 25, 108, CO_FORE, BM_CPY, 0x3C, (const rect_t *)0);
    gpx_draw_line(gpx, 10, 109, 25, 109, CO_FORE, BM_CPY, 0xE4, (const rect_t *)0);
    gpx_draw_line(gpx, 10, 110, 25, 110, CO_FORE, BM_CPY, 0x72, (const rect_t *)0);
    gpx_draw_line(gpx, 10, 111, 25, 111, CO_FORE, BM_CPY, 0xA5, (const rect_t *)0);

    __asm__("halt");
}
