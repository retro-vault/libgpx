#include "zxtest.h"

/* Circles that leave the screen on every side, then the same shapes held
 * inside a clip window. A whole-screen clip must behave exactly like NULL. */
void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    rect_t full = FULL_SCREEN_RECT;
    rect_t win;
    uint8_t solid[1];

    solid[0] = 0xFF;
    seed_screen_wash();

    /* Straddling each edge, and one centred off-screen entirely. */
    gpx_draw_circle(gpx, 0, 0, 25, CO_FORE, BM_CPY, (const rect_t *)0);
    gpx_draw_circle(gpx, 255, 0, 25, CO_FORE, BM_CPY, (const rect_t *)0);
    gpx_draw_circle(gpx, 0, 191, 25, CO_FORE, BM_CPY, (const rect_t *)0);
    gpx_draw_circle(gpx, 255, 191, 25, CO_FORE, BM_CPY, (const rect_t *)0);
    gpx_draw_circle(gpx, -40, 96, 30, CO_FORE, BM_CPY, (const rect_t *)0);
    gpx_draw_circle(gpx, 128, 250, 40, CO_FORE, BM_CPY, (const rect_t *)0);

    /* A whole-screen clip is the same as no clip. */
    gpx_draw_circle(gpx, 60, 60, 18, CO_FORE, BM_CPY, &full);
    gpx_fill_circle(gpx, 200, 60, 18, CO_FORE, BM_CPY, solid, 1, &full);

    /* A window: outline and fill are both cut to it, and the pattern phase
     * must not shift because of the cut. */
    win.x0 = 100;
    win.y0 = 110;
    win.x1 = 160;
    win.y1 = 175;
    gpx_draw_circle(gpx, 130, 140, 45, CO_FORE, BM_CPY, &win);
    gpx_fill_circle(gpx, 130, 140, 28, CO_FORE, BM_CPY, patt_bytes[2], 1, &win);

    /* Clipped away entirely. */
    gpx_draw_circle(gpx, 20, 20, 10, CO_FORE, BM_CPY, &win);
    gpx_fill_circle(gpx, 20, 20, 10, CO_FORE, BM_CPY, solid, 1, &win);

    TEST_END();
}
