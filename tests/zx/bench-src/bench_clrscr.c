#include "bench.h"

BENCH_MAIN()

/* Full-screen clear, the cheapest operation to get wrong. */
void bench_body(gpx_t *gpx)
{
    uint8_t i;
    (void)gpx;
    for (i = 0; i < 20; ++i)
        gpx_clrscr();
}
