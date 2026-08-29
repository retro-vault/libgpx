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

    /* Every pixel of an outline is drawn exactly once. A one-row
     * rectangle has a single horizontal edge and a one-column rectangle a
     * single vertical one, so neither may be emitted twice. Drawing an
     * edge twice is invisible under BM_CPY and cancels under BM_XOR, which
     * is what makes XOR the mode that pins this down. */
    r.x0 = 20; r.y0 = 100; r.x1 = 90; r.y1 = 100;
    gpx_draw_rectangle(gpx, &r, CO_FORE, BM_XOR, 0x38, (const rect_t *)0);
    r.x0 = 20; r.y0 = 104; r.x1 = 90; r.y1 = 104;
    gpx_draw_rectangle(gpx, &r, CO_FORE, BM_XOR, 0xFF, (const rect_t *)0);
    r.x0 = 100; r.y0 = 100; r.x1 = 100; r.y1 = 130;
    gpx_draw_rectangle(gpx, &r, CO_FORE, BM_XOR, 0xFF, (const rect_t *)0);
    r.x0 = 110; r.y0 = 100; r.x1 = 110; r.y1 = 130;
    gpx_draw_rectangle(gpx, &r, CO_FORE, BM_XOR, 0x6D, (const rect_t *)0);
    r.x0 = 120; r.y0 = 100; r.x1 = 120; r.y1 = 100;
    gpx_draw_rectangle(gpx, &r, CO_FORE, BM_XOR, 0xFF, (const rect_t *)0);

    /* The same two shapes through a clip that keeps only part of them,
     * which is how a window decoration reaches them. */
    {
        rect_t clip = {40, 90, 70, 135};
        r.x0 = 20; r.y0 = 108; r.x1 = 90; r.y1 = 108;
        gpx_draw_rectangle(gpx, &r, CO_FORE, BM_XOR, 0x38, &clip);
        r.x0 = 60; r.y0 = 95; r.x1 = 60; r.y1 = 140;
        gpx_draw_rectangle(gpx, &r, CO_FORE, BM_XOR, 0xFF, &clip);
    }

    /* A row of one-pixel rectangles at every bit phase along a byte. */
    for (i = 0; i < 16; ++i) {
        r.x0 = (coord)(160 + i); r.y0 = 150;
        r.x1 = r.x0; r.y1 = r.y0;
        gpx_draw_rectangle(gpx, &r, CO_FORE, BM_CPY, 0xFF,
            (const rect_t *)0);
    }

    TEST_END();
}
