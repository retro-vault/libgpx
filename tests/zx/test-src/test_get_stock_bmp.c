#include "libgpx.h"

void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    rect_t full = {0, 0, 255, 191};

    if (gpx_get_stock_bmp(GPXSB_CURSOR_CLASSIC))
        gpx_draw_pixel(gpx, 3, 191, CO_FORE, BM_CPY, &full);
    if (gpx_get_stock_bmp(GPXSB_CURSOR_STD))
        gpx_draw_pixel(gpx, 4, 191, CO_FORE, BM_CPY, &full);
    if (gpx_get_stock_bmp(GPXSB_CURSOR_HOURGLASS))
        gpx_draw_pixel(gpx, 5, 191, CO_FORE, BM_CPY, &full);
    if (gpx_get_stock_bmp(GPXSB_CURSOR_CARET))
        gpx_draw_pixel(gpx, 6, 191, CO_FORE, BM_CPY, &full);
    if (gpx_get_stock_bmp(GPXSB_CURSOR_HAND))
        gpx_draw_pixel(gpx, 7, 191, CO_FORE, BM_CPY, &full);
    if (gpx_get_stock_bmp(0xFF) == (bmp_t *)0)
        gpx_draw_pixel(gpx, 8, 191, CO_FORE, BM_CPY, &full);

    __asm
        halt
    __endasm;
}
