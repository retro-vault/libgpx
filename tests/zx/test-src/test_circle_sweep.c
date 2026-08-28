#include "zxtest.h"

/* Outlines at every small radius, where the octant walk meets the 45-degree
 * diagonal and a step is easy to emit twice or not at all, plus a few large
 * ones. Radius 0 is a single pixel; a negative radius draws nothing. */
void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    coord r;

    seed_screen_wash();

    for (r = 0; r < 12; ++r)
        gpx_draw_circle(gpx, (coord)(14 + r * 20), 20, r,
            CO_FORE, BM_CPY, (const rect_t *)0);

    for (r = 0; r < 12; ++r)
        gpx_draw_circle(gpx, (coord)(14 + r * 20), 60, r,
            CO_BACK, BM_CPY, (const rect_t *)0);

    gpx_draw_circle(gpx, 55, 135, 40, CO_FORE, BM_CPY, (const rect_t *)0);
    gpx_draw_circle(gpx, 165, 135, 52, CO_BACK, BM_CPY, (const rect_t *)0);

    /* Nothing at all for a negative radius. */
    gpx_draw_circle(gpx, 128, 96, -7, CO_FORE, BM_CPY, (const rect_t *)0);

    TEST_END();
}
