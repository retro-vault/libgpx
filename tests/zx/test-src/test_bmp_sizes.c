#include "zxtest.h"
#include "test_bitmaps.h"

/* Widths that do not fill their stride, so the unused low bits of the last
 * source byte must be discarded rather than blitted. Each fixture is drawn
 * over content at two phases so a leaked bit is visible either way. */
void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    coord phase;

    seed_screen(0xFF);

    for (phase = 0; phase < 8; ++phase) {
        gpx_draw_bmp(gpx, (coord)(4 + phase), (coord)(phase * 5),
            (bmp_t *)bmp_w1, (const rect_t *)0);
        gpx_draw_bmp(gpx, (coord)(20 + phase), (coord)(phase * 5),
            (bmp_t *)bmp_w3, (const rect_t *)0);
        gpx_draw_bmp(gpx, (coord)(40 + phase), (coord)(phase * 5),
            (bmp_t *)bmp_w12, (const rect_t *)0);
        gpx_draw_bmp(gpx, (coord)(70 + phase), (coord)(phase * 5),
            (bmp_t *)bmp_w20, (const rect_t *)0);
    }

    seed_screen(0x00);

    for (phase = 0; phase < 8; ++phase) {
        gpx_draw_bmp(gpx, (coord)(120 + phase), (coord)(phase * 5),
            (bmp_t *)bmp_w3, (const rect_t *)0);
        gpx_draw_bmp(gpx, (coord)(140 + phase), (coord)(phase * 5),
            (bmp_t *)bmp_w12, (const rect_t *)0);
        gpx_draw_bmp(gpx, (coord)(170 + phase), (coord)(phase * 5),
            (bmp_t *)bmp_w20, (const rect_t *)0);
        gpx_draw_bmp(gpx, (coord)(210 + phase), (coord)(phase * 5),
            (bmp_t *)bmp_mask8, (const rect_t *)0);
    }

    /* Repeated blits of the same bitmap must be idempotent for the plain
     * encoding and for the masked one alike. */
    gpx_draw_bmp(gpx, 100, 160, (bmp_t *)bmp_w20, (const rect_t *)0);
    gpx_draw_bmp(gpx, 100, 160, (bmp_t *)bmp_w20, (const rect_t *)0);
    gpx_draw_bmp(gpx, 100, 175, (bmp_t *)bmp_mask12, (const rect_t *)0);
    gpx_draw_bmp(gpx, 100, 175, (bmp_t *)bmp_mask12, (const rect_t *)0);

    TEST_END();
}
