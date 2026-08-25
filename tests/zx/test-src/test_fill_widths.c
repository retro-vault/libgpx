#include "zxtest.h"

/* Every span width at every start phase. The fill path composes each row
 * from a first partial byte, whole middle bytes and a last partial byte,
 * so widths 1..24 across all 8 phases hit every combination of those. */
void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    uint8_t solid = 0xFF;
    rect_t r;
    coord w, phase, y;

    y = 0;
    for (phase = 0; phase < 8; ++phase) {
        for (w = 1; w <= 24; ++w) {
            r.x0 = (coord)(phase + 8);
            r.y0 = y;
            r.x1 = (coord)(r.x0 + w - 1);
            r.y1 = y;
            gpx_fill_rectangle(gpx, &r, CO_FORE, BM_CPY, &solid, 1,
                (const rect_t *)0);
            ++y;
        }
    }

    /* Full-width rows reaching the last line of the display. */
    r.x0 = 0; r.y0 = 188; r.x1 = 255; r.y1 = 191;
    gpx_fill_rectangle(gpx, &r, CO_FORE, BM_CPY, &solid, 1,
        (const rect_t *)0);

    /* A tall single-column fill through all three screen thirds. */
    r.x0 = 200; r.y0 = 0; r.x1 = 200; r.y1 = 191;
    gpx_fill_rectangle(gpx, &r, CO_FORE, BM_CPY, &solid, 1,
        (const rect_t *)0);

    /* Single pixel. */
    r.x0 = 210; r.y0 = 100; r.x1 = 210; r.y1 = 100;
    gpx_fill_rectangle(gpx, &r, CO_FORE, BM_CPY, &solid, 1,
        (const rect_t *)0);

    TEST_END();
}
