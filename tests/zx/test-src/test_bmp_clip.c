#include "libgpx.h"

/* 1bpp bitmap clipped against sub-rectangles on each edge. */

static const uint8_t solid16[] = {
    BMP_SIG_STRIDE(BMP_ENC_1BPP, 2), 16, 12, 24, 0,
    0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
    0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
    0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
};

void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    gpx_clrscr();

    /* clip cuts top-left */
    rect_t c1 = {20, 20, 28, 26};
    gpx_draw_bmp(gpx, 16, 16, (bmp_t *)solid16, &c1);

    /* clip cuts bottom-right */
    rect_t c2 = {64, 40, 72, 47};
    gpx_draw_bmp(gpx, 60, 36, (bmp_t *)solid16, &c2);

    /* clip strictly inside the bitmap */
    rect_t c3 = {104, 64, 110, 70};
    gpx_draw_bmp(gpx, 100, 60, (bmp_t *)solid16, &c3);

    /* clip fully excludes the bitmap */
    rect_t c4 = {0, 0, 5, 5};
    gpx_draw_bmp(gpx, 150, 100, (bmp_t *)solid16, &c4);

    __asm
        halt
    __endasm;
}
