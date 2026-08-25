#include "zxtest.h"

/* Slide lines across a clip window one pixel at a time. Each step moves the
 * entry and exit points by a sub-pixel amount of slope, so the clipped
 * rasterisation is checked against the oracle at every intersection. */
void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    rect_t clip = {70, 60, 130, 120};
    coord i;

    /* Shallow diagonals sweeping down through the window. */
    for (i = 0; i < 40; ++i)
        gpx_draw_line(gpx, 0, (coord)(40 + i * 3), 255, (coord)(60 + i * 3),
            CO_FORE, BM_CPY, 0xFF, &clip);

    /* Steep diagonals sweeping across the window. */
    for (i = 0; i < 40; ++i)
        gpx_draw_line(gpx, (coord)(50 + i * 3), 0, (coord)(70 + i * 3), 191,
            CO_FORE, BM_CPY, 0xFF, &clip);

    /* Horizontal and vertical spans crossing the window at every row and
     * column of its border plus one outside each end. */
    for (i = 58; i <= 122; ++i)
        gpx_draw_line(gpx, 0, i, 255, i, CO_FORE, BM_CPY, 0x55, &clip);
    for (i = 68; i <= 132; ++i)
        gpx_draw_line(gpx, i, 0, i, 191, CO_FORE, BM_CPY, 0x33, &clip);

    /* A clip window with zero width and zero height. */
    {
        rect_t line_clip = {100, 20, 100, 40};
        rect_t point_clip = {200, 160, 200, 160};
        gpx_draw_line(gpx, 0, 30, 255, 30, CO_FORE, BM_CPY, 0xFF, &line_clip);
        gpx_draw_line(gpx, 100, 0, 100, 191, CO_FORE, BM_CPY, 0xFF,
            &line_clip);
        gpx_draw_line(gpx, 0, 160, 255, 160, CO_FORE, BM_CPY, 0xFF,
            &point_clip);
        gpx_draw_line(gpx, 150, 150, 250, 170, CO_FORE, BM_CPY, 0xFF,
            &point_clip);
    }

    TEST_END();
}
