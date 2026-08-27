/* Bitmap blits: wide strides, odd widths, clipping on every edge. */
#include "gdptest.h"

/* 16x8, stride 2. */
static const uint8_t glyph[] = {
    BMP_SIG_STRIDE(BMP_ENC_1BPP, 2), 16, 8, 16, 0,
    0xFF, 0xFF, 0x80, 0x01, 0xBE, 0x7D, 0xA2, 0x45,
    0xA2, 0x45, 0xBE, 0x7D, 0x80, 0x01, 0xFF, 0xFF
};

/* 5x5, stride 1: width not a byte multiple. */
static const uint8_t odd[] = {
    BMP_SIG_STRIDE(BMP_ENC_1BPP, 1), 5, 5, 5, 0,
    0x88, 0x50, 0x20, 0x50, 0x88
};

void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    coord x, y;

    gpx_clrscr();
    for (x = 0; x < 6; x++)
        gpx_draw_bmp(gpx, (coord)(40 + x * 40), 30, (bmp_t *)glyph, 0);
    for (x = 0; x < 6; x++)
        gpx_draw_bmp(gpx, (coord)(41 + x * 40), 60, (bmp_t *)glyph, 0);
    for (y = 0; y < 5; y++)
        gpx_draw_bmp(gpx, (coord)(400 + y * 12), (coord)(30 + y * 11),
                     (bmp_t *)odd, 0);
    gdp_phase();

    gpx_clrscr();
    {
        /* Clipped on all four edges and both corners. */
        static rect_t win = {300, 80, 700, 200};
        gpx_draw_rectangle(gpx, &win, CO_FORE, BM_CPY, 0xAA, 0);
        gpx_draw_bmp(gpx, 292, 130, (bmp_t *)glyph, &win);
        gpx_draw_bmp(gpx, 692, 130, (bmp_t *)glyph, &win);
        gpx_draw_bmp(gpx, 500, 76, (bmp_t *)glyph, &win);
        gpx_draw_bmp(gpx, 500, 196, (bmp_t *)glyph, &win);
        gpx_draw_bmp(gpx, 294, 78, (bmp_t *)glyph, &win);
        gpx_draw_bmp(gpx, 694, 194, (bmp_t *)glyph, &win);
        /* Entirely outside: must draw nothing. */
        gpx_draw_bmp(gpx, 100, 100, (bmp_t *)glyph, &win);
        gpx_draw_bmp(gpx, 800, 220, (bmp_t *)glyph, &win);
    }
    gdp_done();
}
