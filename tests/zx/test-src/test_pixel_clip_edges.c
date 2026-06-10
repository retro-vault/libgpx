#include "libgpx.h"

/* Pixel clipping right on / just outside every clip edge, incl. negative edge. */
void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);

    rect_t clip = {10, 10, 20, 20};
    for (coord y = 8; y <= 22; ++y)
        for (coord x = 8; x <= 22; ++x)
            gpx_draw_pixel(gpx, x, y, CO_FORE, BM_CPY, &clip);

    /* clip whose left edge is negative: left side passes, screen still bounds */
    rect_t clipn = {-5, 30, 5, 40};
    for (coord x = -2; x <= 8; ++x)
        gpx_draw_pixel(gpx, x, 35, CO_FORE, BM_CPY, &clipn);

    /* clip with x1 beyond screen */
    rect_t clipw = {250, 50, 300, 60};
    for (coord x = 248; x <= 255; ++x)
        gpx_draw_pixel(gpx, x, 55, CO_FORE, BM_CPY, &clipw);

    /* 1x1 clip */
    rect_t dot = {100, 100, 100, 100};
    gpx_draw_pixel(gpx, 99, 100, CO_FORE, BM_CPY, &dot);
    gpx_draw_pixel(gpx, 100, 100, CO_FORE, BM_CPY, &dot);
    gpx_draw_pixel(gpx, 101, 100, CO_FORE, BM_CPY, &dot);

    __asm
        halt
    __endasm;
}
