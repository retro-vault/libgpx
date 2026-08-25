#include "zxtest.h"
#include "test_bitmaps.h"

/* Bitmaps hanging off each edge and corner, at every bit phase, plus
 * positions entirely outside the screen. A negative x is the case where
 * the source has to be advanced by a non-byte-aligned amount. */
void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    coord i;

    seed_screen_wash();

    /* Off the left edge, every phase of overlap. */
    for (i = 1; i <= 20; ++i)
        gpx_draw_bmp(gpx, (coord)-i, (coord)(i * 3),
            (bmp_t *)bmp_w20, (const rect_t *)0);

    /* Off the right edge, every phase of overlap. */
    for (i = 1; i <= 20; ++i)
        gpx_draw_bmp(gpx, (coord)(256 - i), (coord)(70 + i * 3),
            (bmp_t *)bmp_w20, (const rect_t *)0);

    /* Off the top and bottom. */
    for (i = 1; i <= 5; ++i) {
        gpx_draw_bmp(gpx, (coord)(140 + i * 12), (coord)-i,
            (bmp_t *)bmp_w12, (const rect_t *)0);
        gpx_draw_bmp(gpx, (coord)(140 + i * 12), (coord)(192 - i),
            (bmp_t *)bmp_w12, (const rect_t *)0);
    }

    /* Corners. */
    gpx_draw_bmp(gpx, -3, -2, (bmp_t *)bmp_w12, (const rect_t *)0);
    gpx_draw_bmp(gpx, 250, -2, (bmp_t *)bmp_w12, (const rect_t *)0);
    gpx_draw_bmp(gpx, -3, 188, (bmp_t *)bmp_w12, (const rect_t *)0);
    gpx_draw_bmp(gpx, 250, 188, (bmp_t *)bmp_w12, (const rect_t *)0);

    /* Entirely outside: nothing may change. */
    gpx_draw_bmp(gpx, -40, 50, (bmp_t *)bmp_w20, (const rect_t *)0);
    gpx_draw_bmp(gpx, 300, 50, (bmp_t *)bmp_w20, (const rect_t *)0);
    gpx_draw_bmp(gpx, 50, -40, (bmp_t *)bmp_w20, (const rect_t *)0);
    gpx_draw_bmp(gpx, 50, 220, (bmp_t *)bmp_w20, (const rect_t *)0);
    gpx_draw_bmp(gpx, -32768, -32768, (bmp_t *)bmp_w20, (const rect_t *)0);
    gpx_draw_bmp(gpx, 32767, 32767, (bmp_t *)bmp_w20, (const rect_t *)0);

    /* A NULL bitmap must be ignored. */
    gpx_draw_bmp(gpx, 100, 100, (bmp_t *)0, (const rect_t *)0);

    TEST_END();
}
