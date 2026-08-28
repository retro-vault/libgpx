#include "xbench.h"
BENCH_MAIN()

/* 8 solid discs, r=90. Each scanline is one horizontal run, so this is the
 * same span machinery xb_fill measures, asked for varying widths. */
void bench_body(gpx_t *gpx)
{
    static uint8_t solid[1] = {0xFF};
    uint8_t i;

    for (i = 0; i < 4; ++i)
        gpx_fill_circle(gpx, 128, 96, 90, CO_FORE, BM_CPY, solid, 1, 0);
    for (i = 0; i < 4; ++i)
        gpx_fill_circle(gpx, 128, 96, 90, CO_BACK, BM_CPY, solid, 1, 0);
}
