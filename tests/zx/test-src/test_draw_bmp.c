#include "libgpx.h"
#include "test_bitmaps.h"

void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    gpx_clrscr();

    gpx_draw_bmp(gpx, 7, 3, (bmp_t *)bmp_checker, (const rect_t *)0);

    rect_t clip_a = {10, 6, 17, 13};
    gpx_draw_bmp(gpx, 12, 8, (bmp_t *)bmp_diagonal, &clip_a);

    gpx_draw_bmp(gpx, -2, 190, (bmp_t *)bmp_checker, (const rect_t *)0);

    rect_t clip_b = {252, 188, 255, 191};
    gpx_draw_bmp(gpx, 254, 189, (bmp_t *)bmp_diagonal, &clip_b);

    __asm
        halt
    __endasm;
}
