#include "libgpx.h"

static const uint8_t bmp_data[] = {
    S_BMP,
    8,
    4,
    4, 0,
    0xF0, 0x0F, 0xAA, 0x55
};

static const uint8_t tiny_data[] = {
    0x20, /* tiny signature/class marker */
    8,    /* width */
    8,    /* height */
    3, 0, /* number of move bytes (uint16 little-endian) */
    0xE0, /* fore: +3, +0 */
    0x90, /* fore: +0, +2 */
    0x57  /* back: -2, -2 */
};

void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    gpx_clrscr();

    /* Partner backend supports tiny/vector streams only; raster is ignored. */
    rect_t clip_bmp = {8, 4, 22, 12};
    gpx_draw_bmp(gpx, 10, 5, (bmp_t *)bmp_data, &clip_bmp);

    rect_t clip_tiny = {20, 20, 23, 22};
    gpx_draw_bmp(gpx, 20, 20, (bmp_t *)tiny_data, &clip_tiny);

    /* Large clip still needs to prepare a relative tiny clip window. */
    rect_t clip_large = {-10, -10, 300, 200};
    gpx_draw_bmp(gpx, 40, 30, (bmp_t *)tiny_data, &clip_large);

    __asm
        halt
    __endasm;
}
