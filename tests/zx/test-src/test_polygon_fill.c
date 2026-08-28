#include "zxtest.h"

/* Patterns, clipping and XOR on polygon fills. The pattern is anchored to
 * the polygon's bounding box, so it runs straight through the shape rather
 * than stepping with the edges. */
void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    uint8_t two[2];
    uint8_t three[3];
    uint8_t five[5];
    rect_t win;
    point_t hex[6];
    point_t tri[3];
    coord i;

    two[0] = 0xCC; two[1] = 0x33;
    three[0] = 0xF0; three[1] = 0x0F; three[2] = 0xAA;
    five[0] = 0x80; five[1] = 0x40; five[2] = 0x20; five[3] = 0x10;
    five[4] = 0x08;

    seed_screen_wash();

    /* A hexagon filled with three pattern lengths: one masked, two through
     * the divide. */
    for (i = 0; i < 3; ++i) {
        coord ox = (coord)(6 + i * 84);
        hex[0].x = (coord)(ox + 20); hex[0].y = 4;
        hex[1].x = (coord)(ox + 60); hex[1].y = 18;
        hex[2].x = (coord)(ox + 60); hex[2].y = 46;
        hex[3].x = (coord)(ox + 20); hex[3].y = 60;
        hex[4].x = (coord)(ox + 2);  hex[4].y = 46;
        hex[5].x = (coord)(ox + 2);  hex[5].y = 18;
        if (i == 0)
            gpx_fill_polygon(gpx, hex, 6, CO_FORE, BM_CPY, two, 2,
                (const rect_t *)0);
        else if (i == 1)
            gpx_fill_polygon(gpx, hex, 6, CO_FORE, BM_CPY, three, 3,
                (const rect_t *)0);
        else
            gpx_fill_polygon(gpx, hex, 6, CO_FORE, BM_CPY, five, 5,
                (const rect_t *)0);
    }

    /* Clipped: outline and fill both cut to the window, and the pattern
     * keeps the phase it would have had unclipped. */
    win.x0 = 20; win.y0 = 80; win.x1 = 110; win.y1 = 140;
    tri[0].x = 10;  tri[0].y = 70;
    tri[1].x = 130; tri[1].y = 100;
    tri[2].x = 40;  tri[2].y = 160;
    gpx_draw_rectangle(gpx, &win, CO_FORE, BM_CPY, 0xAA, (const rect_t *)0);
    gpx_fill_polygon(gpx, tri, 3, CO_FORE, BM_CPY, two, 2, &win);
    gpx_draw_polygon(gpx, tri, 3, CO_FORE, BM_CPY, 0xFF, &win);

    /* Clipped away entirely. */
    gpx_fill_polygon(gpx, tri, 3, CO_FORE, BM_CPY, two, 2, (const rect_t *)0);

    /* XOR: filling the same polygon twice restores what was under it. */
    tri[0].x = 150; tri[0].y = 120;
    tri[1].x = 240; tri[1].y = 140;
    tri[2].x = 170; tri[2].y = 185;
    gpx_fill_polygon(gpx, tri, 3, CO_FORE, BM_XOR, five, 5,
        (const rect_t *)0);
    gpx_fill_polygon(gpx, tri, 3, CO_FORE, BM_XOR, five, 5,
        (const rect_t *)0);

    /* And a solid XOR fill left in place, over the wash. */
    tri[0].x = 150; tri[0].y = 60;
    tri[1].x = 250; tri[1].y = 60;
    tri[2].x = 200; tri[2].y = 110;
    gpx_fill_polygon(gpx, tri, 3, CO_BACK, BM_XOR, three, 3,
        (const rect_t *)0);

    TEST_END();
}
