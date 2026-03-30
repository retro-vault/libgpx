#include "libgpx.h"

void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);

    rect_t dr0 = {8, 6, 15, 12};
    gpx_draw_rectangle(gpx, &dr0, CO_FORE, BM_CPY, 0x33, (const rect_t *)0);

    rect_t dr1 = {18, 4, 30, 14};
    rect_t dr1_clip = {20, 4, 30, 12};
    gpx_draw_rectangle(gpx, &dr1, CO_FORE, BM_CPY, 0xFF, &dr1_clip);

    uint8_t fp0[2] = {0x96, 0x3A};
    rect_t fr0 = {30, 20, 38, 24};
    gpx_fill_rectangle(gpx, &fr0, CO_FORE, BM_CPY, fp0, 2, (const rect_t *)0);

    uint8_t fp1[2] = {0x96, 0x3A};
    rect_t fr1 = {50, 30, 57, 34};
    rect_t fr1_clip = {53, 32, 57, 34};
    gpx_fill_rectangle(gpx, &fr1, CO_FORE, BM_CPY, fp1, 2, &fr1_clip);

    uint8_t fp2[4] = {0x96, 0x3A, 0xC5, 0x69};
    rect_t fr2 = {120, 40, 320, 190};
    gpx_fill_rectangle(gpx, &fr2, CO_FORE, BM_CPY, fp2, 4, (const rect_t *)0);

    uint8_t fp3[3] = {0x96, 0xA5, 0x69};
    rect_t fr3 = {300, 100, 900, 240};
    rect_t fr3_clip = {350, 120, 760, 210};
    gpx_fill_rectangle(gpx, &fr3, CO_FORE, BM_CPY, fp3, 3, &fr3_clip);

    __asm
        halt
    __endasm;
}
