#include "zxtest.h"

/* Rectangles clipped on each side, each corner, and both at once. */
void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    rect_t clip = {60, 50, 190, 140};
    rect_t r;
    coord i;

    seed_screen_wash();

    /* Slide a fixed box across the clip window so every edge and corner
     * combination of partial visibility occurs. */
    for (i = 0; i < 12; ++i) {
        r.x0 = (coord)(30 + i * 16);
        r.y0 = (coord)(30 + i * 10);
        r.x1 = (coord)(r.x0 + 45);
        r.y1 = (coord)(r.y0 + 30);
        gpx_draw_rectangle(gpx, &r, CO_FORE, BM_CPY, 0xFF, &clip);
    }

    /* A box strictly larger than the clip: only the clip interior is
     * touched, and none of its own edges are visible. */
    r.x0 = 0; r.y0 = 0; r.x1 = 255; r.y1 = 191;
    gpx_draw_rectangle(gpx, &r, CO_FORE, BM_CPY, 0xAA, &clip);

    /* A box exactly equal to the clip: all four edges must survive. */
    r = clip;
    gpx_draw_rectangle(gpx, &r, CO_BACK, BM_CPY, 0xFF, &clip);

    /* A box one pixel outside the clip on each side: nothing survives. */
    r.x0 = 59; r.y0 = 49; r.x1 = 59; r.y1 = 49;
    gpx_draw_rectangle(gpx, &r, CO_FORE, BM_CPY, 0xFF, &clip);
    r.x0 = 191; r.y0 = 141; r.x1 = 191; r.y1 = 141;
    gpx_draw_rectangle(gpx, &r, CO_FORE, BM_CPY, 0xFF, &clip);

    /* Swapped clip: nothing at all. */
    {
        rect_t swapped = {190, 140, 60, 50};
        r.x0 = 0; r.y0 = 0; r.x1 = 255; r.y1 = 191;
        gpx_draw_rectangle(gpx, &r, CO_FORE, BM_XOR, 0xFF, &swapped);
    }

    /* Clip rect hanging off the screen edge only narrows to the screen. */
    {
        rect_t straddle = {-20, 160, 40, 260};
        r.x0 = -40; r.y0 = 150; r.x1 = 80; r.y1 = 191;
        gpx_draw_rectangle(gpx, &r, CO_FORE, BM_CPY, 0xFF, &straddle);
    }

    TEST_END();
}
