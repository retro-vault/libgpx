/* Single pixels: colours, XOR, clipping and off-screen rejection. */
#include "gdptest.h"

void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    static uint8_t solid[1] = {0xFF};
    static rect_t band = {40, 40, 600, 60};
    static rect_t win = {700, 100, 800, 160};
    coord i;

    gpx_clrscr();
    /* A dotted diagonal, then the same run in CO_BACK through a filled band. */
    for (i = 0; i < 200; i++)
        gpx_draw_pixel(gpx, (coord)(40 + i * 2), (coord)(100 + (i & 31)),
                       CO_FORE, BM_CPY, 0);
    gpx_fill_rectangle(gpx, &band, CO_FORE, BM_CPY, solid, 1, 0);
    for (i = 0; i < 200; i++)
        gpx_draw_pixel(gpx, (coord)(50 + i * 2), 50, CO_BACK, BM_CPY, 0);
    /* XOR pass twice over the same pixels must leave the band untouched. */
    for (i = 0; i < 100; i++) {
        gpx_draw_pixel(gpx, (coord)(45 + i), 45, CO_FORE, BM_XOR, 0);
        gpx_draw_pixel(gpx, (coord)(45 + i), 45, CO_FORE, BM_XOR, 0);
    }
    /* Clipped and off-screen writes must not escape. */
    for (i = -20; i < 200; i++) {
        gpx_draw_pixel(gpx, (coord)(690 + i), (coord)(90 + (i & 63)),
                       CO_FORE, BM_CPY, &win);
        gpx_draw_pixel(gpx, (coord)(-i), (coord)(200 + (i & 7)),
                       CO_FORE, BM_CPY, 0);
        gpx_draw_pixel(gpx, (coord)(1000 + i), 230, CO_FORE, BM_CPY, 0);
    }
    gdp_done();
}
