#include "xbench.h"
BENCH_MAIN()

/* 8 outlines of a ten-point star: 80 slanted edges, which is the case the
 * Partner's vector generator is built for. */
static point_t star[10] = {
    {128, 8}, {148, 69}, {212, 69}, {160, 107}, {180, 167},
    {128, 130}, {76, 167}, {96, 107}, {44, 69}, {108, 69}
};

void bench_body(gpx_t *gpx)
{
    uint8_t i;

    for (i = 0; i < 8; ++i)
        gpx_draw_polygon(gpx, star, 10, CO_FORE, BM_CPY, 0xFF, 0);
}
