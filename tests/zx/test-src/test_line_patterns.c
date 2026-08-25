#include "zxtest.h"

/* Dash patterns over content, on all three raster paths. A pattern 0-bit
 * must leave the destination alone, so drawing over a seeded screen is the
 * only way to tell "skipped" from "cleared". */
void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    uint8_t p;
    coord y;

    seed_screen_wash();

    /* Each pattern on a horizontal span (byte path), starting at a
     * different phase so the rotation is exercised too. */
    for (p = 0; p < 8; ++p) {
        y = (coord)(4 + p * 2);
        gpx_draw_line(gpx, (coord)p, y, (coord)(200 + p), y,
            CO_FORE, BM_CPY, patt_bytes[p], (const rect_t *)0);
    }

    /* Same patterns on vertical spans. */
    for (p = 0; p < 8; ++p) {
        gpx_draw_line(gpx, (coord)(20 + p * 3), 30, (coord)(20 + p * 3), 90,
            CO_FORE, BM_CPY, patt_bytes[p], (const rect_t *)0);
    }

    /* Same patterns on shallow and steep diagonals (Bresenham path). */
    for (p = 0; p < 8; ++p) {
        gpx_draw_line(gpx, 60, (coord)(100 + p * 4), 200,
            (coord)(110 + p * 4), CO_FORE, BM_CPY, patt_bytes[p],
            (const rect_t *)0);
        gpx_draw_line(gpx, (coord)(210 + p * 5), 100, (coord)(215 + p * 5),
            180, CO_FORE, BM_CPY, patt_bytes[p], (const rect_t *)0);
    }

    /* Every one-bit pattern: exactly one pixel in eight, at eight phases. */
    for (p = 0; p < 8; ++p) {
        gpx_draw_line(gpx, 0, (coord)(160 + p), 255, (coord)(160 + p),
            CO_FORE, BM_CPY, (uint8_t)(0x80 >> p), (const rect_t *)0);
    }

    /* An all-zero pattern must not touch a single pixel anywhere. */
    gpx_draw_line(gpx, 0, 170, 255, 170, CO_FORE, BM_CPY, 0x00,
        (const rect_t *)0);
    gpx_draw_line(gpx, 0, 171, 255, 178, CO_FORE, BM_CPY, 0x00,
        (const rect_t *)0);
    gpx_draw_line(gpx, 128, 170, 128, 191, CO_FORE, BM_CPY, 0x00,
        (const rect_t *)0);

    TEST_END();
}
