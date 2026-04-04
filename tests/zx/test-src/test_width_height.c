#include "libgpx.h"

void main(void)
{
    gpx_t *gpx0 = gpx_create(GPXM_DEFAULT);
    gpx_t *gpx1 = gpx_create((gmode)7);
    dim w = gpx_width();
    dim h = gpx_height();
    rect_t full = {0, 0, 255, 191};

    if (gpx0 && gpx1 && gpx0 == gpx1 &&
        gpx0->width == 256 && gpx0->height == 192 &&
        gpx0->pages == 1 &&
        (gpx0->width >> 3) == 32 &&
        (uint32_t)(gpx0->width >> 3) * (uint32_t)gpx0->height == 6144 &&
        w == 256 && h == 192) {
        gpx_draw_pixel(gpx0, w - 1, h - 1, CO_FORE, BM_CPY, &full);
    }

    gpx_destroy(gpx0);
    gpx_destroy((gpx_t *)0);

    __asm
        halt
    __endasm;
}
