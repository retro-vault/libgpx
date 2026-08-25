#include "zxtest.h"

/* CO_FORE / CO_BACK / BM_XOR over content that is already there.
 * On a blank screen a clear is indistinguishable from a no-op, so the
 * screen is seeded first. */
void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    coord x, y;
    uint8_t phase;

    seed_screen_wash();

    /* Each mode swept across all 8 bit phases, on both set and clear
     * background bits. */
    for (phase = 0; phase < 8; ++phase) {
        for (x = (coord)phase; x < 128; x += 8) {
            gpx_draw_pixel(gpx, x, (coord)(30 + phase), CO_FORE, BM_CPY,
                (const rect_t *)0);
            gpx_draw_pixel(gpx, x, (coord)(45 + phase), CO_BACK, BM_CPY,
                (const rect_t *)0);
            gpx_draw_pixel(gpx, x, (coord)(60 + phase), CO_FORE, BM_XOR,
                (const rect_t *)0);
            /* BM_XOR ignores the colour: this must match the row above. */
            gpx_draw_pixel(gpx, x, (coord)(75 + phase), CO_BACK, BM_XOR,
                (const rect_t *)0);
        }
    }

    /* XOR twice restores the original pixel. */
    for (y = 100; y < 116; ++y) {
        for (x = 150; x < 200; ++x) {
            gpx_draw_pixel(gpx, x, y, CO_FORE, BM_XOR, (const rect_t *)0);
            gpx_draw_pixel(gpx, x, y, CO_FORE, BM_XOR, (const rect_t *)0);
        }
    }

    /* Set then clear leaves the pixel clear regardless of what was there. */
    for (x = 0; x < 64; ++x) {
        gpx_draw_pixel(gpx, x, 130, CO_FORE, BM_CPY, (const rect_t *)0);
        gpx_draw_pixel(gpx, x, 130, CO_BACK, BM_CPY, (const rect_t *)0);
    }

    TEST_END();
}
