#include "libgpx.h"

/* Fills at every left/right byte alignment and width, single & multi byte. */
void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    rect_t full = {0, 0, 255, 191};
    uint8_t pf = 0xFF;
    coord y = 0;

    /* widths 1..16 starting at x0=3 (unaligned) */
    for (coord w = 1; w <= 16; ++w) {
        rect_t r = {3, y, (coord)(3 + w - 1), y};
        gpx_fill_rectangle(gpx, &r, CO_FORE, BM_CPY, &pf, 1, &full);
        y += 1;
    }

    /* every start alignment, fixed width 10 */
    for (coord x0 = 0; x0 < 8; ++x0) {
        rect_t r = {x0, (coord)(40 + x0), (coord)(x0 + 9), (coord)(40 + x0)};
        gpx_fill_rectangle(gpx, &r, CO_FORE, BM_CPY, &pf, 1, &full);
    }

    /* a tall aligned block */
    rect_t blk = {120, 60, 135, 120};
    uint8_t p2[2] = {0xF0, 0x0F};
    gpx_fill_rectangle(gpx, &blk, CO_FORE, BM_CPY, p2, 2, &full);

    __asm
        halt
    __endasm;
}
