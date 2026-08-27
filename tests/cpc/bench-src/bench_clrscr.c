#include "bench.h"

BENCH_MAIN()

/* Screen clear: 16 KiB, the single biggest write the library ever does. */
void bench_body(gpx_t *gpx)
{
    uint8_t i;
    (void)gpx;
    for (i = 0; i < 8; ++i)
        gpx_clrscr();
}
