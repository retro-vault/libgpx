#include "zxtest.h"

/* Horizontal and vertical lines take dedicated byte-span paths, so every
 * combination of start phase, end phase and span length matters: spans
 * inside one byte, spans touching two bytes, and long multi-byte spans. */
void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    coord x0, len, y;

    /* Every start phase x every length 1..24: covers single-byte spans,
     * first/last-byte-only spans, and spans with middle bytes. */
    y = 0;
    for (x0 = 0; x0 < 8; ++x0) {
        for (len = 1; len <= 24; ++len) {
            gpx_draw_line(gpx, x0, y, (coord)(x0 + len - 1), y,
                CO_FORE, BM_CPY, 0xFF, (const rect_t *)0);
            ++y;
        }
    }

    /* Full-width and near-full-width rows. */
    gpx_draw_line(gpx, 0, 191, 255, 191, CO_FORE, BM_CPY, 0xFF,
        (const rect_t *)0);
    gpx_draw_line(gpx, 1, 190, 254, 190, CO_FORE, BM_CPY, 0xFF,
        (const rect_t *)0);
    gpx_draw_line(gpx, 0, 189, 0, 189, CO_FORE, BM_CPY, 0xFF,
        (const rect_t *)0);
    gpx_draw_line(gpx, 255, 188, 255, 188, CO_FORE, BM_CPY, 0xFF,
        (const rect_t *)0);

    /* Reversed endpoints must produce the same span. */
    gpx_draw_line(gpx, 200, 186, 100, 186, CO_FORE, BM_CPY, 0xFF,
        (const rect_t *)0);
    gpx_draw_line(gpx, 100, 185, 200, 185, CO_FORE, BM_CPY, 0xFF,
        (const rect_t *)0);

    /* Vertical lines at every bit phase, spanning all three screen thirds
     * so the row-address arithmetic is crossed repeatedly. */
    for (x0 = 0; x0 < 8; ++x0) {
        gpx_draw_line(gpx, (coord)(220 + x0), 0, (coord)(220 + x0), 191,
            CO_FORE, BM_CPY, 0xFF, (const rect_t *)0);
        gpx_draw_line(gpx, (coord)(230 + x0), 60, (coord)(230 + x0), 70,
            CO_FORE, BM_CPY, 0xFF, (const rect_t *)0);
        gpx_draw_line(gpx, (coord)(240 + x0), 130, (coord)(240 + x0), 120,
            CO_FORE, BM_CPY, 0xFF, (const rect_t *)0);
    }

    /* Exact 45-degree diagonals in all four directions. */
    gpx_draw_line(gpx, 10, 100, 60, 150, CO_FORE, BM_CPY, 0xFF,
        (const rect_t *)0);
    gpx_draw_line(gpx, 60, 100, 10, 150, CO_FORE, BM_CPY, 0xFF,
        (const rect_t *)0);
    gpx_draw_line(gpx, 10, 150, 60, 100, CO_FORE, BM_CPY, 0xFF,
        (const rect_t *)0);
    gpx_draw_line(gpx, 60, 150, 10, 100, CO_FORE, BM_CPY, 0xFF,
        (const rect_t *)0);

    TEST_END();
}
