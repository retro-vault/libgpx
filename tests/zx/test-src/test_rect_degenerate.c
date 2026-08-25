#include "zxtest.h"

/* Degenerate and inverted rectangles, plus rectangles pushed off every
 * edge of the screen. */
void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    rect_t r;
    coord i;

    seed_screen_wash();

    /* Single pixel, one-pixel row, one-pixel column. */
    r.x0 = 10; r.y0 = 10; r.x1 = 10; r.y1 = 10;
    gpx_draw_rectangle(gpx, &r, CO_FORE, BM_CPY, 0xFF, (const rect_t *)0);
    r.x0 = 20; r.y0 = 10; r.x1 = 60; r.y1 = 10;
    gpx_draw_rectangle(gpx, &r, CO_FORE, BM_CPY, 0xFF, (const rect_t *)0);
    r.x0 = 20; r.y0 = 20; r.x1 = 20; r.y1 = 60;
    gpx_draw_rectangle(gpx, &r, CO_FORE, BM_CPY, 0xFF, (const rect_t *)0);

    /* Swapped corners in each axis and both: the rectangle is normalised,
     * so all four spellings of the same box must draw identically. */
    r.x0 = 100; r.y0 = 20; r.x1 = 60; r.y1 = 50;
    gpx_draw_rectangle(gpx, &r, CO_FORE, BM_CPY, 0xFF, (const rect_t *)0);
    r.x0 = 60; r.y0 = 50; r.x1 = 100; r.y1 = 20;
    gpx_draw_rectangle(gpx, &r, CO_BACK, BM_CPY, 0xFF, (const rect_t *)0);
    r.x0 = 60; r.y0 = 20; r.x1 = 100; r.y1 = 50;
    gpx_draw_rectangle(gpx, &r, CO_FORE, BM_CPY, 0xFF, (const rect_t *)0);
    r.x0 = 100; r.y0 = 50; r.x1 = 60; r.y1 = 20;
    gpx_draw_rectangle(gpx, &r, CO_FORE, BM_CPY, 0xFF, (const rect_t *)0);

    /* Hanging off each edge and each corner. */
    r.x0 = -20; r.y0 = 70; r.x1 = 40; r.y1 = 90;
    gpx_draw_rectangle(gpx, &r, CO_FORE, BM_CPY, 0xFF, (const rect_t *)0);
    r.x0 = 220; r.y0 = 70; r.x1 = 300; r.y1 = 90;
    gpx_draw_rectangle(gpx, &r, CO_FORE, BM_CPY, 0xFF, (const rect_t *)0);
    r.x0 = 100; r.y0 = -20; r.x1 = 140; r.y1 = 20;
    gpx_draw_rectangle(gpx, &r, CO_FORE, BM_CPY, 0xFF, (const rect_t *)0);
    r.x0 = 100; r.y0 = 175; r.x1 = 140; r.y1 = 240;
    gpx_draw_rectangle(gpx, &r, CO_FORE, BM_CPY, 0xFF, (const rect_t *)0);
    r.x0 = -30; r.y0 = -30; r.x1 = 30; r.y1 = 30;
    gpx_draw_rectangle(gpx, &r, CO_FORE, BM_CPY, 0xFF, (const rect_t *)0);
    r.x0 = 230; r.y0 = 170; r.x1 = 320; r.y1 = 260;
    gpx_draw_rectangle(gpx, &r, CO_FORE, BM_CPY, 0xFF, (const rect_t *)0);

    /* Entirely off-screen in every direction: no pixel may change. */
    r.x0 = -200; r.y0 = -200; r.x1 = -100; r.y1 = -100;
    gpx_draw_rectangle(gpx, &r, CO_FORE, BM_CPY, 0xFF, (const rect_t *)0);
    r.x0 = 300; r.y0 = 300; r.x1 = 400; r.y1 = 400;
    gpx_draw_rectangle(gpx, &r, CO_FORE, BM_CPY, 0xFF, (const rect_t *)0);
    r.x0 = -32768; r.y0 = -32768; r.x1 = 32767; r.y1 = 32767;
    gpx_draw_rectangle(gpx, &r, CO_FORE, BM_CPY, 0xFF, (const rect_t *)0);

    /* A row of one-pixel rectangles at every bit phase along a byte. */
    for (i = 0; i < 16; ++i) {
        r.x0 = (coord)(160 + i); r.y0 = 150;
        r.x1 = r.x0; r.y1 = r.y0;
        gpx_draw_rectangle(gpx, &r, CO_FORE, BM_CPY, 0xFF,
            (const rect_t *)0);
    }

    TEST_END();
}
