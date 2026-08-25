#include "zxtest.h"

/* Clip-rect handling for the single-pixel path: the boundary is inclusive,
 * a swapped rect rejects everything, and a rect that hangs off-screen only
 * narrows the visible window. */
void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    rect_t full_screen = FULL_SCREEN_RECT;
    rect_t window = {40, 40, 60, 60};
    rect_t point = {100, 100, 100, 100};
    rect_t swapped_x = {70, 20, 50, 40};
    rect_t swapped_y = {20, 70, 40, 50};
    rect_t offscreen_lo = {-40, -40, -10, -10};
    rect_t offscreen_hi = {300, 220, 400, 300};
    rect_t straddle = {-8, -8, 8, 8};
    rect_t straddle_hi = {248, 184, 300, 260};
    coord x, y;

    seed_screen_wash();

    /* Sweep a block that overlaps the window on every side and corner.
     * Only pixels inside the inclusive window may change. */
    for (y = 36; y <= 64; ++y)
        for (x = 36; x <= 64; ++x)
            gpx_draw_pixel(gpx, x, y, CO_FORE, BM_CPY, &window);

    /* A one-pixel clip: exactly one pixel of the sweep survives. */
    for (y = 98; y <= 102; ++y)
        for (x = 98; x <= 102; ++x)
            gpx_draw_pixel(gpx, x, y, CO_BACK, BM_CPY, &point);

    /* Swapped corners: nothing at all, on either axis. */
    for (y = 18; y <= 72; ++y)
        for (x = 18; x <= 72; ++x) {
            gpx_draw_pixel(gpx, x, y, CO_FORE, BM_XOR, &swapped_x);
            gpx_draw_pixel(gpx, x, y, CO_FORE, BM_XOR, &swapped_y);
        }

    /* Clip rects entirely off-screen: nothing survives. */
    for (y = 0; y < 20; ++y)
        for (x = 0; x < 20; ++x) {
            gpx_draw_pixel(gpx, x, y, CO_FORE, BM_CPY, &offscreen_lo);
            gpx_draw_pixel(gpx, x, y, CO_FORE, BM_CPY, &offscreen_hi);
        }

    /* Clip rects that straddle a screen edge clamp to the screen. */
    for (y = -4; y <= 12; ++y)
        for (x = -4; x <= 12; ++x)
            gpx_draw_pixel(gpx, x, y, CO_FORE, BM_CPY, &straddle);
    for (y = 180; y < ZX_H + 4; ++y)
        for (x = 244; x < ZX_W + 4; ++x)
            gpx_draw_pixel(gpx, x, y, CO_FORE, BM_CPY, &straddle_hi);

    /* A clip covering the whole screen must behave exactly like NULL. */
    for (x = 0; x < ZX_W; x += 3)
        gpx_draw_pixel(gpx, x, 150, CO_FORE, BM_CPY, &full_screen);
    for (x = 1; x < ZX_W; x += 3)
        gpx_draw_pixel(gpx, x, 150, CO_FORE, BM_CPY, (const rect_t *)0);

    TEST_END();
}
