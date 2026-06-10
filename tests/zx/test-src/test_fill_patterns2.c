#include "libgpx.h"

/* Filled rectangles with multi-row patterns and varied widths. */
void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    rect_t full = {0, 0, 255, 191};

    uint8_t p4[4] = {0x80, 0x40, 0x20, 0x10};
    rect_t a = {0, 0, 47, 20};
    gpx_fill_rectangle(gpx, &a, CO_FORE, BM_CPY, p4, 4, &full);

    uint8_t p3[3] = {0xFF, 0x00, 0x18};
    rect_t b = {60, 0, 130, 24};
    gpx_fill_rectangle(gpx, &b, CO_FORE, BM_CPY, p3, 3, &full);

    /* full-width fill crossing all bytes */
    uint8_t p2[2] = {0xAA, 0x55};
    rect_t c = {0, 40, 255, 60};
    gpx_fill_rectangle(gpx, &c, CO_FORE, BM_CPY, p2, 2, &full);

    /* swapped corners normalize */
    rect_t d = {120, 90, 40, 70};
    gpx_fill_rectangle(gpx, &d, CO_FORE, BM_CPY, p4, 4, &full);

    /* single column and single row */
    uint8_t pf = 0xFF;
    rect_t col = {200, 100, 200, 140};
    gpx_fill_rectangle(gpx, &col, CO_FORE, BM_CPY, &pf, 1, &full);
    rect_t row = {160, 150, 220, 150};
    gpx_fill_rectangle(gpx, &row, CO_FORE, BM_CPY, &pf, 1, &full);

    __asm
        halt
    __endasm;
}
