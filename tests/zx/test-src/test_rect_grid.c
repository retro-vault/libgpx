#include "libgpx.h"

/* Rectangle outlines: sizes, patterns, swapped corners, thin shapes. */
void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    rect_t full = {0, 0, 255, 191};

    rect_t a = {2, 2, 60, 40};
    gpx_draw_rectangle(gpx, &a, CO_FORE, BM_CPY, 0xFF, &full);

    rect_t b = {70, 5, 120, 45};
    gpx_draw_rectangle(gpx, &b, CO_FORE, BM_CPY, 0xAA, &full);

    rect_t c = {130, 50, 130, 90};   /* vertical degenerate */
    gpx_draw_rectangle(gpx, &c, CO_FORE, BM_CPY, 0xFF, &full);

    rect_t d = {140, 50, 200, 50};   /* horizontal degenerate */
    gpx_draw_rectangle(gpx, &d, CO_FORE, BM_CPY, 0xCC, &full);

    rect_t e = {200, 100, 150, 70};  /* swapped corners */
    gpx_draw_rectangle(gpx, &e, CO_FORE, BM_CPY, 0xF0, &full);

    rect_t f = {10, 100, 11, 101};   /* 2x2 */
    gpx_draw_rectangle(gpx, &f, CO_FORE, BM_CPY, 0xFF, &full);

    rect_t g = {20, 100, 20, 100};   /* single point */
    gpx_draw_rectangle(gpx, &g, CO_FORE, BM_CPY, 0xFF, &full);

    __asm
        halt
    __endasm;
}
