#include "libgpx.h"

void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    rect_t full = {0, 0, 255, 191};

    gpx_draw_line(gpx, 0, 0, 7, 0, CO_FORE, BM_CPY, 0x81, &full);
    gpx_draw_line(gpx, 7, 2, 0, 2, CO_FORE, BM_CPY, 0x3C, &full);
    gpx_draw_line(gpx, 2, 3, 2, 9, CO_FORE, BM_CPY, 0xF0, &full);
    gpx_draw_line(gpx, 10, 5, 5, 10, CO_FORE, BM_CPY, 0xAA, &full);
    gpx_draw_line(gpx, 12, 12, 12, 12, CO_FORE, BM_CPY, 0x80, &full);

    __asm
        halt
    __endasm;
}
