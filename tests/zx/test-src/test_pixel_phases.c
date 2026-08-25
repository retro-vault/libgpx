#include "zxtest.h"

/* Every x bit-phase and every y band. The ZX display file interleaves
 * y as (third, row-in-char, char-row), so a wrong address calculation
 * usually shows up only at a band boundary. */
void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    coord x, y;

    /* All 256 columns on one row: covers every bit phase and byte. */
    for (x = 0; x < ZX_W; ++x)
        gpx_draw_pixel(gpx, x, 8, CO_FORE, BM_CPY, (const rect_t *)0);

    /* All 192 rows on one column: covers every third and char row. */
    for (y = 0; y < ZX_H; ++y)
        gpx_draw_pixel(gpx, 3, y, CO_FORE, BM_CPY, (const rect_t *)0);

    /* Diagonal walk touches every (x&7, y&7) pair. */
    for (y = 20; y < 84; ++y)
        gpx_draw_pixel(gpx, (coord)(40 + ((y * 5) & 63)), y,
            CO_FORE, BM_CPY, (const rect_t *)0);

    /* The four corners and the pixels just inside them. */
    gpx_draw_pixel(gpx, 0, 0, CO_FORE, BM_CPY, (const rect_t *)0);
    gpx_draw_pixel(gpx, ZX_W - 1, 0, CO_FORE, BM_CPY, (const rect_t *)0);
    gpx_draw_pixel(gpx, 0, ZX_H - 1, CO_FORE, BM_CPY, (const rect_t *)0);
    gpx_draw_pixel(gpx, ZX_W - 1, ZX_H - 1, CO_FORE, BM_CPY, (const rect_t *)0);
    gpx_draw_pixel(gpx, 1, 1, CO_FORE, BM_CPY, (const rect_t *)0);
    gpx_draw_pixel(gpx, ZX_W - 2, ZX_H - 2, CO_FORE, BM_CPY, (const rect_t *)0);

    /* Band boundaries: last/first row of each third and each character row. */
    for (y = 0; y < ZX_H; y += 8) {
        gpx_draw_pixel(gpx, 200, y, CO_FORE, BM_CPY, (const rect_t *)0);
        gpx_draw_pixel(gpx, 201, (coord)(y + 7), CO_FORE, BM_CPY,
            (const rect_t *)0);
    }
    gpx_draw_pixel(gpx, 210, 63, CO_FORE, BM_CPY, (const rect_t *)0);
    gpx_draw_pixel(gpx, 211, 64, CO_FORE, BM_CPY, (const rect_t *)0);
    gpx_draw_pixel(gpx, 212, 127, CO_FORE, BM_CPY, (const rect_t *)0);
    gpx_draw_pixel(gpx, 213, 128, CO_FORE, BM_CPY, (const rect_t *)0);

    TEST_END();
}
