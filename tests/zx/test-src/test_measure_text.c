#include "libgpx.h"

void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    const font_t *font = gpx_get_system_font();
    char mixed[4] = {'A', 1, 'B', 0};
    rect_t full = {0, 0, 255, 191};

    coord w1 = gpx_measure_text("A", font);
    coord w2 = gpx_measure_text(mixed, font);
    coord w3 = gpx_measure_text("", font);
    coord w4 = gpx_measure_text("  ", font);
    coord w5 = gpx_measure_text((const char *)0, font);
    coord w6 = gpx_measure_text("A", (const font_t *)0);
    coord w7 = gpx_measure_text((const char *)0, (const font_t *)0);

    if (w1 > 0 && w2 >= w1 && w3 == 0 && w4 >= 0 &&
        w5 == 0 && w6 == 0 && w7 == 0) {
        gpx_draw_pixel(gpx, 1, 191, CO_FORE, BM_CPY, &full);
    }

    __asm
        halt
    __endasm;
}
