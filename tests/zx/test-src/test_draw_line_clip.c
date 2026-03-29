#include "libgpx.h"

void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    rect_t clipA = {4, 4, 11, 11};
    rect_t clipB = {0, 0, 5, 5};

    gpx_draw_line(gpx, 0, 0, 15, 15, CO_FORE, BM_CPY, 0xF0, &clipA);
    gpx_draw_line(gpx, 15, 4, 0, 4, CO_FORE, BM_CPY, 0xAA, &clipA);
    gpx_draw_line(gpx, 8, 0, 8, 15, CO_FORE, BM_CPY, 0xCC, &clipA);
    gpx_draw_line(gpx, 20, 20, 25, 25, CO_FORE, BM_CPY, 0xFF, &clipA);
    gpx_draw_line(gpx, 11, 11, 11, 11, CO_FORE, BM_CPY, 0x80, &clipA);
    gpx_draw_line(gpx, 3, 3, 3, 3, CO_FORE, BM_CPY, 0x80, &clipA);
    gpx_draw_line(gpx, 5, 0, 0, 5, CO_FORE, BM_CPY, 0xFF, &clipB);
    gpx_draw_line(gpx, 4, 11, 11, 4, CO_FORE, BM_CPY, 0x00, &clipA);
    gpx_draw_line(gpx, 0, 11, 15, 11, CO_FORE, BM_CPY, 0xFF, &clipA);
    gpx_draw_line(gpx, 4, 0, 4, 15, CO_FORE, BM_CPY, 0xFF, &clipA);

    __asm
        halt
    __endasm;
}
