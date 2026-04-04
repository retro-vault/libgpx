#include "libgpx.h"

void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    const font_t *sys = gpx_get_system_font();
    const font_t *tiny = gpx_get_tiny_font();
    rect_t clip = {9, 8, 10, 12};

    gpx_clrscr();

    gpx_draw_text(gpx, 0, 0, (const char *)0, sys, CO_FORE, BM_CPY, (const rect_t *)0);
    gpx_draw_text(gpx, 0, 0, "AB", (const font_t *)0, CO_FORE, BM_CPY, (const rect_t *)0);

    gpx_draw_text(gpx, 0, 0, "A B", sys, CO_FORE, BM_CPY, (const rect_t *)0);
    gpx_draw_text(gpx, 0, 16, "H", sys, CO_FORE, BM_CPY, (const rect_t *)0);
    gpx_draw_text(gpx, 8, 8, "Z", tiny, CO_FORE, BM_CPY, &clip);
    gpx_draw_text(gpx, 0, 0, "A", sys, CO_FORE, BM_XOR, (const rect_t *)0);
    gpx_draw_text(gpx, 252, 190, "A", sys, CO_FORE, BM_CPY, (const rect_t *)0);

    __asm
        halt
    __endasm;
}
