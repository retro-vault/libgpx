#include "libgpx.h"

static const uint8_t bmp_data[] = {
    S_BMP,
    8,
    4,
    4, 0,
    0xF0, 0x0F, 0xAA, 0x55
};

void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    gpx_clrscr();

    rect_t clip = {8, 4, 22, 12};
    gpx_draw_bmp(gpx, 10, 5, (bmp_t *)bmp_data, &clip);

    __asm
        halt
    __endasm;
}
