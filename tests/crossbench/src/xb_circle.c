#include "xbench.h"
BENCH_MAIN()

/* 16 circle outlines at four radii. The outline is one gpx_draw_pixel per
 * plotted point, so this is the per-pixel path on every backend -- the
 * Partner included, which cannot hand a circle to its vector generator. */
void bench_body(gpx_t *gpx)
{
    uint8_t i;

    for (i = 0; i < 4; ++i) {
        gpx_draw_circle(gpx, 128, 96, 90, CO_FORE, BM_CPY, 0);
        gpx_draw_circle(gpx, 128, 96, 66, CO_FORE, BM_CPY, 0);
        gpx_draw_circle(gpx, 128, 96, 42, CO_FORE, BM_CPY, 0);
        gpx_draw_circle(gpx, 128, 96, 18, CO_FORE, BM_CPY, 0);
    }
}
