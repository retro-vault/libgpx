#include "zxtest.h"

/* CO_BACK and BM_XOR on every raster path, over seeded content. */
void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    coord i;

    seed_screen(0xFF);

    /* Erase with CO_BACK: horizontal, vertical, diagonal. */
    for (i = 0; i < 8; ++i) {
        gpx_draw_line(gpx, (coord)i, (coord)(4 + i), (coord)(200 + i),
            (coord)(4 + i), CO_BACK, BM_CPY, 0xFF, (const rect_t *)0);
        gpx_draw_line(gpx, (coord)(20 + i), 20, (coord)(20 + i), 60,
            CO_BACK, BM_CPY, 0xFF, (const rect_t *)0);
        gpx_draw_line(gpx, 60, (coord)(20 + i * 4), 200,
            (coord)(60 + i * 4), CO_BACK, BM_CPY, 0xFF, (const rect_t *)0);
    }

    /* Erase with a dash: only the pattern-1 pixels clear. */
    for (i = 0; i < 8; ++i)
        gpx_draw_line(gpx, 0, (coord)(70 + i), 255, (coord)(70 + i),
            CO_BACK, BM_CPY, patt_bytes[i], (const rect_t *)0);

    /* XOR inverts; XOR twice restores. Both colours must behave the same. */
    for (i = 0; i < 8; ++i) {
        gpx_draw_line(gpx, 0, (coord)(90 + i), 255, (coord)(90 + i),
            CO_FORE, BM_XOR, patt_bytes[i], (const rect_t *)0);
        gpx_draw_line(gpx, 0, (coord)(100 + i), 255, (coord)(100 + i),
            CO_BACK, BM_XOR, patt_bytes[i], (const rect_t *)0);
    }
    for (i = 0; i < 40; ++i) {
        gpx_draw_line(gpx, 10, (coord)(120 + i), 240, (coord)(130 + i),
            CO_FORE, BM_XOR, 0xFF, (const rect_t *)0);
        gpx_draw_line(gpx, 10, (coord)(120 + i), 240, (coord)(130 + i),
            CO_FORE, BM_XOR, 0xFF, (const rect_t *)0);
    }

    /* Clear then set the same span: the span ends up set either way. */
    gpx_draw_line(gpx, 30, 180, 220, 180, CO_BACK, BM_CPY, 0xFF,
        (const rect_t *)0);
    gpx_draw_line(gpx, 30, 180, 220, 180, CO_FORE, BM_CPY, 0xFF,
        (const rect_t *)0);

    TEST_END();
}
