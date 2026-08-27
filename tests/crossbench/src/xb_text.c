#include "xbench.h"
BENCH_MAIN()

/* 20 lines of 24 characters, opaque in both colours and then XORed. */
void bench_body(gpx_t *gpx)
{
    const font_t *sys = gpx_get_system_font();
    coord i;

    for (i = 0; i < 20; ++i)
        gpx_draw_text(gpx, 0, (coord)(i * 9), "libgpx 0123456789 ABCDEF",
                      sys, CO_FORE, BM_CPY, 0);
    for (i = 0; i < 20; ++i)
        gpx_draw_text(gpx, 0, (coord)(i * 9), "libgpx 0123456789 ABCDEF",
                      sys, CO_BACK, BM_CPY, 0);
    for (i = 0; i < 20; ++i)
        gpx_draw_text(gpx, 0, (coord)(i * 9), "libgpx 0123456789 ABCDEF",
                      sys, CO_FORE, BM_XOR, 0);
}
