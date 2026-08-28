#include "xbench.h"
BENCH_MAIN()

/* 8 fills of the same ten-point star. Every scanline pays for walking ten
 * edge records and sorting the crossings before its runs are drawn, so this
 * is the scanline bookkeeping rather than raw fill throughput. */
static point_t star[10] = {
    {128, 8}, {148, 69}, {212, 69}, {160, 107}, {180, 167},
    {128, 130}, {76, 167}, {96, 107}, {44, 69}, {108, 69}
};

void bench_body(gpx_t *gpx)
{
    static uint8_t solid[1] = {0xFF};
    uint8_t i;

    for (i = 0; i < 4; ++i)
        gpx_fill_polygon(gpx, star, 10, CO_FORE, BM_CPY, solid, 1, 0);
    for (i = 0; i < 4; ++i)
        gpx_fill_polygon(gpx, star, 10, CO_BACK, BM_CPY, solid, 1, 0);
}
