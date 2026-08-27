#include "xbench.h"
BENCH_MAIN()

/* 16 full clears. This is the one benchmark whose work is NOT identical
 * across backends: gpx_clrscr() clears the whole display, and the displays
 * are different sizes (6912 bytes on the ZX, 16 KiB on the CPC). It is here
 * to show what a full repaint costs on each machine, not to rank them. */
void bench_body(gpx_t *gpx)
{
    uint8_t i;

    (void)gpx;
    for (i = 0; i < 16; ++i)
        gpx_clrscr();
}
