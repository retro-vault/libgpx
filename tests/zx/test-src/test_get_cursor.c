#include "libgpx.h"

void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    rect_t full = {0, 0, 255, 191};
    bmp_t *classic = gpx_get_stock_bmp(GPXSB_CURSOR_CLASSIC);
    bmp_t *std = gpx_get_stock_bmp(GPXSB_CURSOR_STD);
    bmp_t *wait = gpx_get_stock_bmp(GPXSB_CURSOR_HOURGLASS);
    bmp_t *text = gpx_get_stock_bmp(GPXSB_CURSOR_CARET);
    bmp_t *hand = gpx_get_stock_bmp(GPXSB_CURSOR_HAND);
    bmp_t *fallback = gpx_get_stock_bmp(0xFF);

    if (classic && std && wait && text && hand && !fallback) {
        gpx_draw_pixel(gpx, 4, 191, CO_FORE, BM_CPY, &full);
    }

    __asm
        halt
    __endasm;
}
