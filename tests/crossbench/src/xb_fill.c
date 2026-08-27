#include "xbench.h"
BENCH_MAIN()

/* 8 solid fills of the same 248x184 area. Solid is the case a blitter
 * hardware-accelerates if it can, so this is where the Partner's GDP is
 * played to its strength; see xb_fillpat for the other half. */
void bench_body(gpx_t *gpx)
{
    static uint8_t solid[1] = {0xFF};
    rect_t r;
    uint8_t i;

    r.x0 = 4; r.y0 = 4; r.x1 = 251; r.y1 = 187;
    for (i = 0; i < 4; ++i)
        gpx_fill_rectangle(gpx, &r, CO_FORE, BM_CPY, solid, 1, 0);
    for (i = 0; i < 4; ++i)
        gpx_fill_rectangle(gpx, &r, CO_BACK, BM_CPY, solid, 1, 0);
}
