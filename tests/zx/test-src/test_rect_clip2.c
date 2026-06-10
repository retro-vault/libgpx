#include "libgpx.h"

/* Rectangle outlines clipped against sub-rectangles on each edge. */
void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);

    rect_t r = {20, 20, 80, 70};

    rect_t clip_tl = {0, 0, 40, 40};
    gpx_draw_rectangle(gpx, &r, CO_FORE, BM_CPY, 0xFF, &clip_tl);

    rect_t r2 = {120, 20, 180, 70};
    rect_t clip_br = {150, 45, 255, 191};
    gpx_draw_rectangle(gpx, &r2, CO_FORE, BM_CPY, 0xFF, &clip_br);

    rect_t r3 = {20, 100, 200, 150};
    rect_t clip_mid = {60, 110, 160, 140};
    gpx_draw_rectangle(gpx, &r3, CO_FORE, BM_CPY, 0xAA, &clip_mid);

    /* outline fully outside clip => nothing */
    rect_t r4 = {0, 180, 10, 191};
    rect_t clip_far = {100, 100, 120, 120};
    gpx_draw_rectangle(gpx, &r4, CO_FORE, BM_CPY, 0xFF, &clip_far);

    __asm
        halt
    __endasm;
}
