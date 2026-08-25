#include "zxtest.h"

/* Degenerate, inverted and off-screen fills. */
void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    static uint8_t solid[1] = {0xFF};
    static uint8_t p2[2] = {0xAA, 0x55};
    rect_t r;

    seed_screen_wash();

    /* Inverted in each axis and both: all four spellings fill the same box. */
    r.x0 = 60; r.y0 = 10; r.x1 = 20; r.y1 = 30;
    gpx_fill_rectangle(gpx, &r, CO_BACK, BM_CPY, solid, 1,
        (const rect_t *)0);
    r.x0 = 80; r.y0 = 30; r.x1 = 120; r.y1 = 10;
    gpx_fill_rectangle(gpx, &r, CO_BACK, BM_CPY, solid, 1,
        (const rect_t *)0);
    r.x0 = 180; r.y0 = 30; r.x1 = 140; r.y1 = 10;
    gpx_fill_rectangle(gpx, &r, CO_BACK, BM_CPY, solid, 1,
        (const rect_t *)0);

    /* Hanging off each edge. */
    r.x0 = -40; r.y0 = 40; r.x1 = 40; r.y1 = 60;
    gpx_fill_rectangle(gpx, &r, CO_FORE, BM_CPY, p2, 2, (const rect_t *)0);
    r.x0 = 220; r.y0 = 40; r.x1 = 320; r.y1 = 60;
    gpx_fill_rectangle(gpx, &r, CO_FORE, BM_CPY, p2, 2, (const rect_t *)0);
    r.x0 = 60; r.y0 = -20; r.x1 = 120; r.y1 = 20;
    gpx_fill_rectangle(gpx, &r, CO_FORE, BM_CPY, p2, 2, (const rect_t *)0);
    r.x0 = 60; r.y0 = 170; r.x1 = 120; r.y1 = 240;
    gpx_fill_rectangle(gpx, &r, CO_FORE, BM_CPY, p2, 2, (const rect_t *)0);

    /* Entirely off-screen and full coordinate range. */
    r.x0 = -300; r.y0 = -300; r.x1 = -200; r.y1 = -200;
    gpx_fill_rectangle(gpx, &r, CO_FORE, BM_CPY, solid, 1,
        (const rect_t *)0);
    r.x0 = 400; r.y0 = 400; r.x1 = 500; r.y1 = 500;
    gpx_fill_rectangle(gpx, &r, CO_FORE, BM_CPY, solid, 1,
        (const rect_t *)0);
    r.x0 = -32768; r.y0 = 100; r.x1 = 32767; r.y1 = 102;
    gpx_fill_rectangle(gpx, &r, CO_FORE, BM_CPY, solid, 1,
        (const rect_t *)0);
    r.x0 = 150; r.y0 = -32768; r.x1 = 152; r.y1 = 32767;
    gpx_fill_rectangle(gpx, &r, CO_FORE, BM_CPY, solid, 1,
        (const rect_t *)0);

    /* NULL rect pointer must be ignored, not dereferenced. */
    gpx_fill_rectangle(gpx, (rect_t *)0, CO_FORE, BM_CPY, solid, 1,
        (const rect_t *)0);

    TEST_END();
}
