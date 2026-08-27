#include "xbench.h"
BENCH_MAIN()

/* The same 64 rays, dashed. A dash pattern cannot be expressed as an EF9367
 * vector style without losing phase across segments, so the Partner walks
 * these in software too. */
void bench_body(gpx_t *gpx)
{
    coord i;

    for (i = 0; i < 16; ++i) {
        gpx_draw_line(gpx, 0, 0, 255, (coord)(i * 12), CO_FORE, BM_CPY, 0xAA, 0);
        gpx_draw_line(gpx, 255, 0, 0, (coord)(i * 12), CO_FORE, BM_CPY, 0xAA, 0);
        gpx_draw_line(gpx, 128, 0, (coord)(i * 16), 191, CO_FORE, BM_CPY, 0xAA, 0);
        gpx_draw_line(gpx, 128, 191, (coord)(i * 16), 0, CO_FORE, BM_CPY, 0xAA, 0);
    }
}
