#include "libgpx.h"

/* 1bpp bitmaps of various widths/strides blitted at various x alignments. */

static const uint8_t bmp_w1[] = {
    BMP_SIG_STRIDE(BMP_ENC_1BPP, 1), 1, 6, 6, 0,
    0x80, 0x80, 0x80, 0x80, 0x80, 0x80
};

static const uint8_t bmp_w8[] = {
    BMP_SIG_STRIDE(BMP_ENC_1BPP, 1), 8, 5, 5, 0,
    0x81, 0x42, 0x24, 0x18, 0xFF
};

static const uint8_t bmp_w9[] = {
    BMP_SIG_STRIDE(BMP_ENC_1BPP, 2), 9, 4, 8, 0,
    0xFF, 0x80, 0x80, 0x80, 0x80, 0x80, 0xFF, 0x80
};

static const uint8_t bmp_w16[] = {
    BMP_SIG_STRIDE(BMP_ENC_1BPP, 2), 16, 4, 8, 0,
    0xAA, 0x55, 0x55, 0xAA, 0xFF, 0xFF, 0x01, 0x80
};

void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    gpx_clrscr();

    for (coord x = 0; x < 10; ++x)
        gpx_draw_bmp(gpx, x * 3, 10, (bmp_t *)bmp_w1, (const rect_t *)0);

    for (coord x = 0; x < 8; ++x)
        gpx_draw_bmp(gpx, x * 10, 30, (bmp_t *)bmp_w8, (const rect_t *)0);

    for (coord x = 0; x < 6; ++x)
        gpx_draw_bmp(gpx, x * 12, 50, (bmp_t *)bmp_w9, (const rect_t *)0);

    for (coord x = 0; x < 5; ++x)
        gpx_draw_bmp(gpx, x * 20, 70, (bmp_t *)bmp_w16, (const rect_t *)0);

    /* partly off the right/bottom edges (clipped to screen) */
    gpx_draw_bmp(gpx, 250, 90, (bmp_t *)bmp_w16, (const rect_t *)0);
    gpx_draw_bmp(gpx, 100, 189, (bmp_t *)bmp_w8, (const rect_t *)0);

    __asm
        halt
    __endasm;
}
