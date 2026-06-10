#include "libgpx.h"

/* XOR lines over a patterned background. */
void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    rect_t full = {0, 0, 255, 191};
    uint8_t fp[2] = {0xAA, 0x55};

    rect_t bg = {0, 0, 120, 90};
    gpx_fill_rectangle(gpx, &bg, CO_FORE, BM_CPY, fp, 2, &full);

    /* xor lines crossing the patterned field */
    gpx_draw_line(gpx, 0, 0, 120, 90, CO_FORE, BM_XOR, 0xFF, &full);
    gpx_draw_line(gpx, 0, 90, 120, 0, CO_FORE, BM_XOR, 0xFF, &full);
    gpx_draw_line(gpx, 0, 45, 120, 45, CO_FORE, BM_XOR, 0xFF, &full);
    gpx_draw_line(gpx, 60, 0, 60, 90, CO_FORE, BM_XOR, 0xFF, &full);

    /* xor a line twice to restore */
    gpx_draw_line(gpx, 10, 10, 100, 80, CO_FORE, BM_XOR, 0xCC, &full);
    gpx_draw_line(gpx, 10, 10, 100, 80, CO_FORE, BM_XOR, 0xCC, &full);

    __asm
        halt
    __endasm;
}
