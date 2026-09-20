/* Timex 512x192 address-layout regression. */
#include "libgpx.h"

volatile uint16_t timex_results[2];

void main(void)
{
    static uint8_t pattern = 0xaa;
    static uint8_t bitmap[] = {
        BMP_SIG_STRIDE(BMP_ENC_1BPP, 2), 16, 3, 6, 0,
        0xa5, 0x5a, 0x81, 0x7e, 0xff, 0x01
    };
    static const point_t points[] = {
        {0, 0}, {7, 0}, {8, 0}, {15, 0}, {16, 0}, {255, 0},
        {256, 0}, {511, 0}, {9, 1}, {17, 7}, {25, 8}, {33, 63},
        {41, 64}, {49, 191}
    };
    rect_t fill = {248, 70, 272, 72};
    gpx_t *gpx = gpx_create(GPXM_TIMEX_HIRES);
    uint8_t i;

    timex_results[0] = gpx->width;
    timex_results[1] = gpx->height;

    for (i = 0; i < sizeof(points) / sizeof(points[0]); ++i)
        gpx_draw_pixel(gpx, points[i].x, points[i].y,
                       CO_FORE, BM_CPY, NULL);

    gpx_draw_line(gpx, 0, 10, 511, 10,
                  CO_FORE, BM_CPY, GPX_LP_SOLID, NULL);
    gpx_draw_line(gpx, 240, 20, 280, 60,
                  CO_FORE, BM_CPY, GPX_LP_SOLID, NULL);
    gpx_fill_rectangle(gpx, &fill, CO_FORE, BM_CPY,
                       &pattern, 1, NULL);
    gpx_draw_bmp(gpx, 252, 80, (bmp_t *)bitmap, NULL);

    __asm__("halt");
}
