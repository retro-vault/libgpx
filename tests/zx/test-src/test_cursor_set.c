#include "libgpx.h"

void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    rect_t full = {0, 0, 255, 191};
    uint8_t ok = 1;

    gpx_set_page(PG_DISPLAY, 0);
    if (gpx->pages < 1) ok = 0;
    else gpx_draw_pixel(gpx, 0, 190, CO_FORE, BM_CPY, &full);

    gpx_set_page(PG_WRITE, 0);
    if (gpx->pages < 1) ok = 0;
    else gpx_draw_pixel(gpx, 1, 190, CO_FORE, BM_CPY, &full);

    gpx_set_page(PG_DISPLAY | PG_WRITE, 0);
    if (gpx->pages < 1) ok = 0;
    else gpx_draw_pixel(gpx, 2, 190, CO_FORE, BM_CPY, &full);

    gpx_set_page(PG_DISPLAY, 1);
    if (gpx->pages < 1) ok = 0;
    else gpx_draw_pixel(gpx, 3, 190, CO_FORE, BM_CPY, &full);

    gpx_set_page(PG_WRITE, 1);
    if (gpx->pages < 1) ok = 0;
    else gpx_draw_pixel(gpx, 4, 190, CO_FORE, BM_CPY, &full);

    gpx_set_page(PG_DISPLAY | PG_WRITE, 1);
    if (gpx->pages < 1) ok = 0;
    else gpx_draw_pixel(gpx, 5, 190, CO_FORE, BM_CPY, &full);

    if (ok)
        gpx_draw_pixel(gpx, 5, 191, CO_FORE, BM_CPY, &full);

    __asm
        halt
    __endasm;
}
