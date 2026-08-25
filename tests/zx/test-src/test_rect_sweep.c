#include "zxtest.h"

/* Rectangle outlines across a wide range of sizes and positions. The four
 * edges use the horizontal and vertical span paths, so a rectangle sweep
 * doubles as a span-alignment sweep with both endpoints pinned. */
void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    rect_t r;
    coord w, h, x;

    /* Every width 1..16 at every start phase, stacked down the screen. */
    for (w = 1; w <= 16; ++w) {
        for (x = 0; x < 8; ++x) {
            r.x0 = (coord)(x * 16 + (w & 7));
            r.y0 = (coord)((w - 1) * 6);
            r.x1 = (coord)(r.x0 + w - 1);
            r.y1 = (coord)(r.y0 + 4);
            gpx_draw_rectangle(gpx, &r, CO_FORE, BM_CPY, 0xFF,
                (const rect_t *)0);
        }
    }

    /* Tall and wide extremes, including the full screen and a one-pixel
     * border inside it. */
    r.x0 = 0; r.y0 = 100; r.x1 = 255; r.y1 = 191;
    gpx_draw_rectangle(gpx, &r, CO_FORE, BM_CPY, 0xFF, (const rect_t *)0);
    r.x0 = 1; r.y0 = 101; r.x1 = 254; r.y1 = 190;
    gpx_draw_rectangle(gpx, &r, CO_FORE, BM_CPY, 0xFF, (const rect_t *)0);
    r.x0 = 120; r.y0 = 102; r.x1 = 121; r.y1 = 189;
    gpx_draw_rectangle(gpx, &r, CO_FORE, BM_CPY, 0xFF, (const rect_t *)0);

    /* Heights 1..8 so the top and bottom edges meet and overlap. */
    for (h = 1; h <= 8; ++h) {
        r.x0 = (coord)(150 + h * 12);
        r.y0 = 104;
        r.x1 = (coord)(r.x0 + 9);
        r.y1 = (coord)(r.y0 + h - 1);
        gpx_draw_rectangle(gpx, &r, CO_FORE, BM_CPY, 0xFF,
            (const rect_t *)0);
    }

    TEST_END();
}
