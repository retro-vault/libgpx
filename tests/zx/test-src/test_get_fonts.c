#include "libgpx.h"

void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    const font_t *sys = gpx_get_system_font();
    const font_t *tiny = gpx_get_tiny_font();
    rect_t full = {0, 0, 255, 191};

    if (sys && tiny && sys == tiny &&
        sys->first_ascii >= 32 &&
        sys->last_ascii >= sys->first_ascii &&
        sys->glyph_height > 0) {
        gpx_draw_pixel(gpx, 0, 191, CO_FORE, BM_CPY, &full);
    }

    __asm
        halt
    __endasm;
}
