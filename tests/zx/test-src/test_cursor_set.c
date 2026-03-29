#include "libgpx.h"

extern bmp_t *_gpx_cursor_current;

void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    rect_t full = {0, 0, 255, 191};
    bmp_t *arrow = gpx_get_cursor(GPX_CURSOR_ARROW);
    bmp_t *hand = gpx_get_cursor(GPX_CURSOR_HAND);

    uint8_t s0[2] = {BMP_SIG(BMP_ENC_1BPP), 0};
    uint8_t s1[2] = {BMP_SIG(BMP_ENC_1BPP_MASK), 0};
    uint8_t s2[2] = {BMP_SIG(BMP_ENC_1BPP_COMPACT), 0};
    uint8_t s3[2] = {BMP_SIG(BMP_ENC_1BPP_MASK_COMPACT), 0};
    uint8_t bad[2] = {0xF0, 0x00};

    uint8_t ok = 1;

    gpx_cursor_set(hand);
    if (_gpx_cursor_current != hand) ok = 0;
    else gpx_draw_pixel(gpx, 0, 190, CO_FORE, BM_CPY, &full);

    gpx_cursor_set((bmp_t *)s0);
    if (_gpx_cursor_current != arrow) ok = 0;
    else gpx_draw_pixel(gpx, 1, 190, CO_FORE, BM_CPY, &full);

    gpx_cursor_set((bmp_t *)s1);
    if (_gpx_cursor_current != (bmp_t *)s1) ok = 0;
    else gpx_draw_pixel(gpx, 2, 190, CO_FORE, BM_CPY, &full);

    gpx_cursor_set((bmp_t *)s2);
    if (_gpx_cursor_current != arrow) ok = 0;
    else gpx_draw_pixel(gpx, 3, 190, CO_FORE, BM_CPY, &full);

    gpx_cursor_set((bmp_t *)s3);
    if (_gpx_cursor_current != (bmp_t *)s3) ok = 0;
    else gpx_draw_pixel(gpx, 4, 190, CO_FORE, BM_CPY, &full);

    gpx_cursor_set((bmp_t *)bad);
    if (_gpx_cursor_current != arrow) ok = 0;
    else gpx_draw_pixel(gpx, 5, 190, CO_FORE, BM_CPY, &full);

    gpx_cursor_set((bmp_t *)0);
    if (_gpx_cursor_current != arrow) ok = 0;
    else gpx_draw_pixel(gpx, 6, 190, CO_FORE, BM_CPY, &full);

    if (ok)
        gpx_draw_pixel(gpx, 5, 191, CO_FORE, BM_CPY, &full);

    __asm
        halt
    __endasm;
}
