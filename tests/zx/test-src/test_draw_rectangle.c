#include "libgpx.h"

void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    rect_t full = {0, 0, 255, 191};

    rect_t outer = {2, 2, 10, 6};
    gpx_draw_rectangle(gpx, &outer, CO_FORE, BM_CPY, 0xFF, &full);

    rect_t inner = {12, 10, 18, 15};
    gpx_draw_rectangle(gpx, &inner, CO_FORE, BM_CPY, 0xF0, &full);

    rect_t swapped = {30, 14, 24, 9};
    gpx_draw_rectangle(gpx, &swapped, CO_FORE, BM_CPY, 0xAA, &full);

    rect_t clipped = {38, 0, 48, 10};
    rect_t clip = {40, 2, 46, 8};
    gpx_draw_rectangle(gpx, &clipped, CO_FORE, BM_CPY, 0xFF, &clip);

    rect_t point = {50, 5, 50, 5};
    gpx_draw_rectangle(gpx, &point, CO_FORE, BM_CPY, 0xFF, &full);

    rect_t flat = {52, 7, 57, 7};
    gpx_draw_rectangle(gpx, &flat, CO_FORE, BM_CPY, 0xCC, &full);

    __asm
        halt
    __endasm;
}
