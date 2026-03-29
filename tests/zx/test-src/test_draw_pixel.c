#include "libgpx.h"

void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);

    gpx_draw_pixel(gpx, 0, 0, CO_FORE, BM_CPY, (const rect_t *)0);

    gpx_draw_pixel(gpx, 1, 0, CO_FORE, BM_CPY, (const rect_t *)0);
    gpx_draw_pixel(gpx, 1, 0, CO_FORE, BM_XOR, (const rect_t *)0);

    gpx_draw_pixel(gpx, 2, 0, CO_FORE, BM_CPY, (const rect_t *)0);
    gpx_draw_pixel(gpx, 2, 0, CO_BACK, BM_CPY, (const rect_t *)0);

    rect_t clip_a = {4, 4, 5, 5};
    gpx_draw_pixel(gpx, 4, 4, CO_FORE, BM_CPY, &clip_a);
    gpx_draw_pixel(gpx, 5, 5, CO_FORE, BM_CPY, &clip_a);
    gpx_draw_pixel(gpx, 6, 5, CO_FORE, BM_CPY, &clip_a);
    gpx_draw_pixel(gpx, 4, 4, CO_FORE, BM_XOR, &clip_a);

    rect_t clip_b = {0, 0, 0, 0};
    gpx_draw_pixel(gpx, 0, 1, CO_FORE, BM_CPY, &clip_b);

    gpx_draw_pixel(gpx, -1, 0, CO_FORE, BM_CPY, (const rect_t *)0);
    gpx_draw_pixel(gpx, 256, 0, CO_FORE, BM_CPY, (const rect_t *)0);
    gpx_draw_pixel(gpx, 0, 192, CO_FORE, BM_CPY, (const rect_t *)0);

    gpx_draw_pixel(gpx, 255, 191, CO_FORE, BM_CPY, (const rect_t *)0);
    gpx_draw_pixel(gpx, 255, 191, CO_BACK, BM_CPY, (const rect_t *)0);
    gpx_draw_pixel(gpx, 255, 191, CO_FORE, BM_XOR, (const rect_t *)0);

    __asm
        halt
    __endasm;
}
