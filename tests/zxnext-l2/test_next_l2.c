#include "libgpx.h"

volatile uint16_t next_l2_geometry[2];

void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_ZXNEXT_L2);
    rect_t fill = {8, 8, 631, 247};
    static uint8_t pattern = 0xff;

    next_l2_geometry[0] = gpx->width;
    next_l2_geometry[1] = gpx->height;
    gpx_draw_pixel(gpx, 0, 0, CO_FORE, BM_CPY, NULL);
    gpx_draw_pixel(gpx, 639, 255, CO_FORE, BM_CPY, NULL);
    gpx_fill_rectangle(gpx, &fill, CO_FORE, BM_CPY, &pattern, 1, NULL);
    __asm__("halt");
}
