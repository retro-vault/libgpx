#include "libgpx.h"

void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    rect_t full = {0, 0, 255, 191};
    bmp_t *arrow = gpx_get_cursor(GPX_CURSOR_ARROW);
    bmp_t *hand = gpx_get_cursor(GPX_CURSOR_HAND);
    bmp_t *wait = gpx_get_cursor(GPX_CURSOR_WAIT);
    bmp_t *text = gpx_get_cursor(GPX_CURSOR_TEXT);
    bmp_t *fallback = gpx_get_cursor(0xFF);

    if (arrow == gpx_get_stock_bmp(GPXSB_CURSOR_CLASSIC) &&
        hand == gpx_get_stock_bmp(GPXSB_CURSOR_HAND) &&
        wait == gpx_get_stock_bmp(GPXSB_CURSOR_HOURGLASS) &&
        text == gpx_get_stock_bmp(GPXSB_CURSOR_CARET) &&
        fallback == arrow) {
        gpx_draw_pixel(gpx, 4, 191, CO_FORE, BM_CPY, &full);
    }

    __asm
        halt
    __endasm;
}
