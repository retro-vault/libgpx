#include "bench.h"

BENCH_MAIN()

/* Pixel plotting: the clip-free path, the clipped path, and the rejected
 * path, in the proportions a UI redraw actually hits.
 *
 * Loop counters are 8-bit on purpose. With `coord` counters the benchmark's
 * own bookkeeping cost as much as the library call it was timing. */
void bench_body(gpx_t *gpx)
{
    rect_t clip = {32, 32, 223, 159};
    uint8_t x, y;
    uint16_t i;

    for (y = 0; y < 96; ++y)
        for (x = 0; x < 32; ++x)
            gpx_draw_pixel(gpx, (coord)x, (coord)y, CO_FORE, BM_CPY,
                (const rect_t *)0);

    for (y = 0; y < 96; ++y)
        for (x = 0; x < 32; ++x)
            gpx_draw_pixel(gpx, (coord)(x + 100), (coord)y, CO_FORE,
                BM_CPY, &clip);

    for (i = 0; i < 1000; ++i)
        gpx_draw_pixel(gpx, 300, 300, CO_FORE, BM_CPY, (const rect_t *)0);

    for (i = 0; i < 1000; ++i)
        gpx_draw_pixel(gpx, (coord)(i & 255), (coord)(i & 127), CO_FORE,
            BM_XOR, (const rect_t *)0);
}
