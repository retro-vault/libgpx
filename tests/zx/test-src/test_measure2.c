#include "libgpx.h"

/* Plot a pixel at the measured width of several strings, so any width
 * divergence between backend and oracle shows as a pixel-position diff. */
void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    const font_t *font = gpx_get_system_font();
    rect_t full = {0, 0, 255, 191};

    const char *samples[6];
    samples[0] = "A";
    samples[1] = "AB";
    samples[2] = "HELLO";
    samples[3] = "libgpx";
    samples[4] = "  ";
    samples[5] = "Wq.,!";

    for (uint8_t i = 0; i < 6; ++i) {
        coord w = gpx_measure_text(samples[i], font);
        if (w > 0 && w < 256)
            gpx_draw_pixel(gpx, w, (coord)(10 + i * 4), CO_FORE, BM_CPY, &full);
    }

    /* tiny font too */
    const font_t *tiny = gpx_get_tiny_font();
    coord wt = gpx_measure_text("libgpx", tiny);
    if (wt > 0 && wt < 256)
        gpx_draw_pixel(gpx, wt, 60, CO_FORE, BM_CPY, &full);

    __asm
        halt
    __endasm;
}
