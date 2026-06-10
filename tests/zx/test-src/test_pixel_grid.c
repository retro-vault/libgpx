#include "libgpx.h"

/* Pixels across every x bit-alignment, set/clear/xor, plus screen corners. */
void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    rect_t full = {0, 0, 255, 191};

    /* every x alignment on one row (crosses several VRAM bytes) */
    for (coord x = 0; x < 40; ++x)
        gpx_draw_pixel(gpx, x, 20, CO_FORE, BM_CPY, &full);

    /* xor every other pixel on next row */
    for (coord x = 0; x < 40; ++x)
        if (x & 1)
            gpx_draw_pixel(gpx, x, 21, CO_FORE, BM_XOR, &full);

    /* punch holes (CO_BACK) out of a solid run */
    {
        rect_t solid = {100, 30, 139, 30};
        uint8_t fp = 0xFF;
        gpx_fill_rectangle(gpx, &solid, CO_FORE, BM_CPY, &fp, 1, &full);
        for (coord x = 100; x < 140; x += 3)
            gpx_draw_pixel(gpx, x, 30, CO_BACK, BM_CPY, &full);
    }

    /* screen corners */
    gpx_draw_pixel(gpx, 0, 0, CO_FORE, BM_CPY, &full);
    gpx_draw_pixel(gpx, 255, 0, CO_FORE, BM_CPY, &full);
    gpx_draw_pixel(gpx, 0, 191, CO_FORE, BM_CPY, &full);
    gpx_draw_pixel(gpx, 255, 191, CO_FORE, BM_CPY, &full);

    /* xor twice restores */
    gpx_draw_pixel(gpx, 50, 50, CO_FORE, BM_XOR, &full);
    gpx_draw_pixel(gpx, 50, 50, CO_FORE, BM_XOR, &full);

    /* off-screen rejects */
    gpx_draw_pixel(gpx, -1, 50, CO_FORE, BM_CPY, &full);
    gpx_draw_pixel(gpx, 256, 50, CO_FORE, BM_CPY, &full);
    gpx_draw_pixel(gpx, 50, -1, CO_FORE, BM_CPY, &full);
    gpx_draw_pixel(gpx, 50, 192, CO_FORE, BM_CPY, &full);

    __asm
        halt
    __endasm;
}
