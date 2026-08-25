#include "zxtest.h"

/* Coordinates outside the screen, with and without a clip rect. The screen
 * is always an implicit clip, so nothing here may touch VRAM outside the
 * display file -- the seeded wash makes any stray byte visible, and the
 * attribute area is compared too. */
void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    rect_t full_screen = FULL_SCREEN_RECT;
    coord i;

    seed_screen_wash();

    /* Horizontal spans one row outside each edge: the byte-span path used
     * to write straight past the display file here. */
    gpx_draw_line(gpx, 0, -1, 255, -1, CO_FORE, BM_CPY, 0xFF,
        (const rect_t *)0);
    gpx_draw_line(gpx, 0, 192, 255, 192, CO_FORE, BM_CPY, 0xFF,
        (const rect_t *)0);
    gpx_draw_line(gpx, 0, 200, 255, 200, CO_FORE, BM_CPY, 0xFF,
        (const rect_t *)0);
    gpx_draw_line(gpx, 0, -100, 255, -100, CO_FORE, BM_CPY, 0xFF,
        (const rect_t *)0);
    gpx_draw_line(gpx, 0, 192, 255, 192, CO_FORE, BM_CPY, 0xFF, &full_screen);

    /* Horizontal spans that start or end outside the left/right edge must
     * be clamped, not wrapped. */
    gpx_draw_line(gpx, -50, 20, 100, 20, CO_FORE, BM_CPY, 0xFF,
        (const rect_t *)0);
    gpx_draw_line(gpx, 150, 22, 400, 22, CO_FORE, BM_CPY, 0xFF,
        (const rect_t *)0);
    gpx_draw_line(gpx, -300, 24, 500, 24, CO_FORE, BM_CPY, 0xFF,
        (const rect_t *)0);
    gpx_draw_line(gpx, -400, 26, -100, 26, CO_FORE, BM_CPY, 0xFF,
        (const rect_t *)0);
    gpx_draw_line(gpx, 300, 28, 600, 28, CO_FORE, BM_CPY, 0xFF,
        (const rect_t *)0);

    /* The same, vertically. */
    gpx_draw_line(gpx, -1, 0, -1, 191, CO_FORE, BM_CPY, 0xFF,
        (const rect_t *)0);
    gpx_draw_line(gpx, 256, 0, 256, 191, CO_FORE, BM_CPY, 0xFF,
        (const rect_t *)0);
    gpx_draw_line(gpx, 40, -60, 40, 60, CO_FORE, BM_CPY, 0xFF,
        (const rect_t *)0);
    gpx_draw_line(gpx, 42, 130, 42, 400, CO_FORE, BM_CPY, 0xFF,
        (const rect_t *)0);
    gpx_draw_line(gpx, 44, -200, 44, 400, CO_FORE, BM_CPY, 0xFF,
        (const rect_t *)0);

    /* Diagonals crossing the screen from far outside, at several slopes. */
    for (i = 0; i < 6; ++i) {
        gpx_draw_line(gpx, -200, (coord)(-100 + i * 60), 500,
            (coord)(300 - i * 60), CO_FORE, BM_CPY, 0xFF,
            (const rect_t *)0);
    }

    /* Entirely outside, in each direction. */
    gpx_draw_line(gpx, -400, -400, -10, -10, CO_FORE, BM_CPY, 0xFF,
        (const rect_t *)0);
    gpx_draw_line(gpx, 300, 300, 600, 600, CO_FORE, BM_CPY, 0xFF,
        (const rect_t *)0);
    gpx_draw_line(gpx, -400, 300, -10, 600, CO_FORE, BM_CPY, 0xFF,
        (const rect_t *)0);

    /* Coordinate-type extremes on every path. */
    gpx_draw_line(gpx, -32768, 100, 32767, 100, CO_FORE, BM_CPY, 0xFF,
        (const rect_t *)0);
    gpx_draw_line(gpx, 100, -32768, 100, 32767, CO_FORE, BM_CPY, 0xFF,
        (const rect_t *)0);
    gpx_draw_line(gpx, -32768, -32768, 32767, 32767, CO_FORE, BM_CPY, 0xFF,
        (const rect_t *)0);
    gpx_draw_line(gpx, 32767, -32768, -32768, 32767, CO_FORE, BM_CPY, 0xFF,
        (const rect_t *)0);

    TEST_END();
}
