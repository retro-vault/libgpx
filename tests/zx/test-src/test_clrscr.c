#include "libgpx.h"

void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    rect_t full = {0, 0, 255, 191};

    gpx_draw_pixel(gpx, 3, 3, CO_FORE, BM_CPY, &full);
    gpx_draw_pixel(gpx, 10, 10, CO_FORE, BM_CPY, &full);
    gpx_clrscr();

    gpx_draw_pixel(gpx, 255, 191, CO_FORE, BM_CPY, &full);
    gpx_clrscr();

    __asm
        halt
    __endasm;
}
