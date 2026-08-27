#include "xbench.h"
BENCH_MAIN()

/* 64 solid rays through every octant, inside 256x192. Solid vectors are
 * exactly what the Partner's GDP exists to draw. */
void bench_body(gpx_t *gpx)
{
    coord i;

    for (i = 0; i < 16; ++i) {
        gpx_draw_line(gpx, 0, 0, 255, (coord)(i * 12), CO_FORE, BM_CPY, 0xFF, 0);
        gpx_draw_line(gpx, 255, 0, 0, (coord)(i * 12), CO_FORE, BM_CPY, 0xFF, 0);
        gpx_draw_line(gpx, 128, 0, (coord)(i * 16), 191, CO_FORE, BM_CPY, 0xFF, 0);
        gpx_draw_line(gpx, 128, 191, (coord)(i * 16), 0, CO_FORE, BM_CPY, 0xFF, 0);
    }
}
