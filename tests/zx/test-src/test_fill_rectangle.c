#include "libgpx.h"

void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    rect_t full = {0, 0, 255, 191};

    rect_t a = {3, 3, 12, 9};
    uint8_t pa[2] = {0xAA, 0x55};
    gpx_fill_rectangle(gpx, &a, CO_FORE, BM_CPY, pa, 2, &full);

    rect_t b = {20, 12, 14, 8};
    uint8_t pb[1] = {0xF0};
    gpx_fill_rectangle(gpx, &b, CO_FORE, BM_CPY, pb, 1, &full);

    rect_t c = {30, 4, 38, 10};
    rect_t clip = {32, 5, 36, 8};
    uint8_t pc[3] = {0xFF, 0x18, 0x81};
    gpx_fill_rectangle(gpx, &c, CO_FORE, BM_CPY, pc, 3, &clip);

    gpx_draw_pixel(gpx, 60, 10, CO_FORE, BM_CPY, &full);
    rect_t d = {58, 9, 62, 11};
    gpx_fill_rectangle(gpx, &d, CO_FORE, BM_CPY, pa, 0, &full);

    __asm
        halt
    __endasm;
}
