#include "libgpx.h"

/* XOR fills, CO_BACK fills, and clipped fills. */
void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    rect_t full = {0, 0, 255, 191};
    uint8_t pf = 0xFF;
    uint8_t p2[2] = {0xAA, 0x55};

    /* solid block, then xor a sub-block out */
    rect_t a = {10, 10, 80, 50};
    gpx_fill_rectangle(gpx, &a, CO_FORE, BM_CPY, &pf, 1, &full);
    rect_t ax = {20, 20, 60, 40};
    gpx_fill_rectangle(gpx, &ax, CO_FORE, BM_XOR, &pf, 1, &full);

    /* CO_BACK clears holes in a pattern */
    rect_t b = {100, 10, 180, 50};
    gpx_fill_rectangle(gpx, &b, CO_FORE, BM_CPY, p2, 2, &full);
    rect_t bb = {120, 20, 160, 40};
    gpx_fill_rectangle(gpx, &bb, CO_BACK, BM_CPY, &pf, 1, &full);

    /* clipped fill (rect larger than clip) */
    rect_t c = {0, 80, 255, 140};
    rect_t clip = {50, 90, 150, 120};
    gpx_fill_rectangle(gpx, &c, CO_FORE, BM_CPY, p2, 2, &clip);

    /* fpatt_len 0 is a no-op */
    rect_t d = {200, 80, 230, 100};
    gpx_fill_rectangle(gpx, &d, CO_FORE, BM_CPY, &pf, 0, &full);

    __asm
        halt
    __endasm;
}
