#include "zxtest.h"

/* Clipped fills. The pattern stays anchored to the rectangle, so a clipped
 * fill must show the same phase it would have shown unclipped -- the clip
 * only removes pixels, it never shifts them. */
void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    static uint8_t p3[3] = {0xFF, 0x18, 0x81};
    static uint8_t solid[1] = {0xFF};
    rect_t clip = {70, 50, 180, 130};
    rect_t r;
    coord i;

    seed_screen_wash();

    /* Slide a block across the window from top-left to bottom-right. */
    for (i = 0; i < 10; ++i) {
        r.x0 = (coord)(40 + i * 18);
        r.y0 = (coord)(30 + i * 12);
        r.x1 = (coord)(r.x0 + 40);
        r.y1 = (coord)(r.y0 + 26);
        gpx_fill_rectangle(gpx, &r, CO_FORE, BM_CPY, p3, 3, &clip);
    }

    /* A fill bigger than the clip on every side. */
    r.x0 = 0; r.y0 = 0; r.x1 = 255; r.y1 = 191;
    gpx_fill_rectangle(gpx, &r, CO_BACK, BM_CPY, solid, 1, &clip);

    /* Clip rects that hang off the screen only narrow to the screen. */
    {
        rect_t straddle_lo = {-30, -30, 40, 40};
        rect_t straddle_hi = {220, 160, 300, 260};
        r.x0 = -60; r.y0 = -60; r.x1 = 80; r.y1 = 80;
        gpx_fill_rectangle(gpx, &r, CO_FORE, BM_CPY, p3, 3, &straddle_lo);
        r.x0 = 200; r.y0 = 140; r.x1 = 320; r.y1 = 280;
        gpx_fill_rectangle(gpx, &r, CO_FORE, BM_CPY, p3, 3, &straddle_hi);
    }

    /* Swapped clip: nothing. */
    {
        rect_t swapped = {180, 130, 70, 50};
        r.x0 = 0; r.y0 = 0; r.x1 = 255; r.y1 = 191;
        gpx_fill_rectangle(gpx, &r, CO_FORE, BM_XOR, solid, 1, &swapped);
    }

    /* One-pixel and one-line clips. */
    {
        rect_t dot = {20, 170, 20, 170};
        rect_t row = {0, 180, 255, 180};
        rect_t col = {100, 0, 100, 191};
        r.x0 = 0; r.y0 = 160; r.x1 = 255; r.y1 = 191;
        gpx_fill_rectangle(gpx, &r, CO_FORE, BM_CPY, solid, 1, &dot);
        gpx_fill_rectangle(gpx, &r, CO_FORE, BM_CPY, p3, 3, &row);
        gpx_fill_rectangle(gpx, &r, CO_FORE, BM_CPY, p3, 3, &col);
    }

    TEST_END();
}
