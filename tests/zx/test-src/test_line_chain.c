#include "zxtest.h"

/* gpx_draw_line returns the rotated pattern so callers can chain segments
 * without the dash restarting. Both the pixels and the returned bytes are
 * compared, which pins the phase arithmetic on every path. */
void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    rect_t clip = {40, 40, 200, 150};
    uint8_t patt;
    uint8_t i;

    /* A polyline whose segments alternate between the horizontal, vertical
     * and diagonal paths: the phase must carry across the joins. */
    patt = 0xC3;
    patt = gpx_draw_line(gpx, 10, 10, 90, 10, CO_FORE, BM_CPY, patt,
        (const rect_t *)0);
    record(patt);
    patt = gpx_draw_line(gpx, 90, 10, 90, 60, CO_FORE, BM_CPY, patt,
        (const rect_t *)0);
    record(patt);
    patt = gpx_draw_line(gpx, 90, 60, 150, 100, CO_FORE, BM_CPY, patt,
        (const rect_t *)0);
    record(patt);
    patt = gpx_draw_line(gpx, 150, 100, 30, 100, CO_FORE, BM_CPY, patt,
        (const rect_t *)0);
    record(patt);
    patt = gpx_draw_line(gpx, 30, 100, 30, 10, CO_FORE, BM_CPY, patt,
        (const rect_t *)0);
    record(patt);

    /* One long span drawn in eight pieces must equal the same span drawn
     * whole, because the returned phase feeds the next piece. */
    patt = 0x39;
    for (i = 0; i < 8; ++i)
        patt = gpx_draw_line(gpx, (coord)(i * 32), 120,
            (coord)(i * 32 + 31), 120, CO_FORE, BM_CPY, patt,
            (const rect_t *)0);
    record(patt);
    record(gpx_draw_line(gpx, 0, 121, 255, 121, CO_FORE, BM_CPY, 0x39,
        (const rect_t *)0));

    /* A rejected line returns its pattern unchanged. */
    record(gpx_draw_line(gpx, -50, -50, -10, -10, CO_FORE, BM_CPY, 0x5A,
        (const rect_t *)0));
    record(gpx_draw_line(gpx, 300, 10, 320, 40, CO_FORE, BM_CPY, 0x5A,
        (const rect_t *)0));

    /* A clipped line returns the phase at the clipped end, not the
     * unclipped one. */
    record(gpx_draw_line(gpx, 0, 45, 255, 45, CO_FORE, BM_CPY, 0x99, &clip));
    record(gpx_draw_line(gpx, 0, 0, 255, 191, CO_FORE, BM_CPY, 0x99, &clip));
    record(gpx_draw_line(gpx, 100, 0, 100, 191, CO_FORE, BM_CPY, 0x99, &clip));

    TEST_END();
}
