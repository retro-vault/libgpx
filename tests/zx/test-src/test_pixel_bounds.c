#include "zxtest.h"

/* Off-screen coordinates must be dropped without touching VRAM. The screen
 * is seeded so that a stray write shows up anywhere in the display file. */
void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    coord i;

    seed_screen_wash();

    /* One step outside each edge. */
    gpx_draw_pixel(gpx, -1, 50, CO_FORE, BM_CPY, (const rect_t *)0);
    gpx_draw_pixel(gpx, ZX_W, 50, CO_FORE, BM_CPY, (const rect_t *)0);
    gpx_draw_pixel(gpx, 50, -1, CO_FORE, BM_CPY, (const rect_t *)0);
    gpx_draw_pixel(gpx, 50, ZX_H, CO_FORE, BM_CPY, (const rect_t *)0);

    /* Outside corners. */
    gpx_draw_pixel(gpx, -1, -1, CO_FORE, BM_CPY, (const rect_t *)0);
    gpx_draw_pixel(gpx, ZX_W, ZX_H, CO_FORE, BM_CPY, (const rect_t *)0);
    gpx_draw_pixel(gpx, -1, ZX_H, CO_FORE, BM_CPY, (const rect_t *)0);
    gpx_draw_pixel(gpx, ZX_W, -1, CO_FORE, BM_CPY, (const rect_t *)0);

    /* Extremes of the signed coordinate type, in every mode. */
    gpx_draw_pixel(gpx, 32767, 32767, CO_FORE, BM_CPY, (const rect_t *)0);
    gpx_draw_pixel(gpx, -32768, -32768, CO_BACK, BM_CPY, (const rect_t *)0);
    gpx_draw_pixel(gpx, 32767, 100, CO_FORE, BM_XOR, (const rect_t *)0);
    gpx_draw_pixel(gpx, -32768, 100, CO_FORE, BM_XOR, (const rect_t *)0);
    gpx_draw_pixel(gpx, 100, 32767, CO_BACK, BM_XOR, (const rect_t *)0);
    gpx_draw_pixel(gpx, 100, -32768, CO_FORE, BM_CPY, (const rect_t *)0);

    /* A ring just outside the screen edge, all the way round. */
    for (i = -2; i < (coord)(ZX_W + 2); ++i) {
        gpx_draw_pixel(gpx, i, -1, CO_FORE, BM_CPY, (const rect_t *)0);
        gpx_draw_pixel(gpx, i, ZX_H, CO_FORE, BM_CPY, (const rect_t *)0);
    }
    for (i = -2; i < (coord)(ZX_H + 2); ++i) {
        gpx_draw_pixel(gpx, -1, i, CO_FORE, BM_CPY, (const rect_t *)0);
        gpx_draw_pixel(gpx, ZX_W, i, CO_FORE, BM_CPY, (const rect_t *)0);
    }

    /* 255/191 are the last legal values and must still draw. */
    gpx_draw_pixel(gpx, ZX_W - 1, ZX_H - 1, CO_BACK, BM_CPY,
        (const rect_t *)0);

    TEST_END();
}
