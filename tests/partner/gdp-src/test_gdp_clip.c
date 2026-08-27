/* Cohen-Sutherland clipping: lines crossing every window edge and corner,
 * plus fully-inside and fully-rejected cases. */
#include "gdptest.h"

void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    static rect_t win = {200, 60, 600, 190};
    coord k;

    gpx_clrscr();
    gpx_draw_rectangle(gpx, &win, CO_FORE, BM_CPY, 0xAA, 0);

    /* Fan of lines from a point outside the window, sweeping across it. */
    for (k = 0; k <= 250; k += 25)
        gpx_draw_line(gpx, 50, 10, (coord)(300 + k * 3), (coord)(20 + k),
                      CO_FORE, BM_CPY, 0xFF, &win);
    for (k = 0; k <= 250; k += 25)
        gpx_draw_line(gpx, 1000, 250, (coord)(700 - k * 3), (coord)(240 - k),
                      CO_FORE, BM_CPY, 0xFF, &win);

    /* Fully inside, and fully outside on each side. */
    gpx_draw_line(gpx, 300, 100, 500, 150, CO_FORE, BM_CPY, 0xFF, &win);
    gpx_draw_line(gpx, 0, 0, 100, 40, CO_FORE, BM_CPY, 0xFF, &win);
    gpx_draw_line(gpx, 700, 0, 900, 40, CO_FORE, BM_CPY, 0xFF, &win);
    gpx_draw_line(gpx, 0, 220, 100, 250, CO_FORE, BM_CPY, 0xFF, &win);
    gdp_phase();

    gpx_clrscr();
    /* Clip window pinned to the screen edges: exercises the boundary paths. */
    {
        static rect_t edge = {0, 0, 1023, 255};
        gpx_draw_line(gpx, -400, -200, 1400, 500, CO_FORE, BM_CPY, 0xFF, &edge);
        gpx_draw_line(gpx, -400, 500, 1400, -200, CO_FORE, BM_CPY, 0xFF, &edge);
        gpx_draw_line(gpx, -100, 128, 1200, 128, CO_FORE, BM_CPY, 0xFF, &edge);
        gpx_draw_line(gpx, 512, -100, 512, 400, CO_FORE, BM_CPY, 0xFF, &edge);
    }
    gdp_done();
}
