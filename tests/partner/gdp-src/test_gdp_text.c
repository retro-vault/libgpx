/* Text with both stock fonts, plus measurement and clipping. */
#include "gdptest.h"

static const char sample[] = "Iskra Delta Partner 0123456789";
static const char punct[]  = "!\"#$%&'()*+,-./:;<=>?@[\\]^_";

void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    const font_t *sys = gpx_get_system_font();
    const font_t *tiny = gpx_get_tiny_font();

    gpx_clrscr();
    gpx_draw_text(gpx, 20, 20, sample, sys, CO_FORE, BM_CPY, 0);
    gpx_draw_text(gpx, 20, 60, punct, sys, CO_FORE, BM_CPY, 0);
    gpx_draw_text(gpx, 20, 110, sample, tiny, CO_FORE, BM_CPY, 0);
    gpx_draw_text(gpx, 20, 150, punct, tiny, CO_FORE, BM_CPY, 0);
    gdp_phase();

    gpx_clrscr();
    {
        static rect_t win = {200, 40, 600, 140};
        gpx_draw_rectangle(gpx, &win, CO_FORE, BM_CPY, 0xAA, 0);
        gpx_draw_text(gpx, 100, 60, sample, sys, CO_FORE, BM_CPY, &win);
        gpx_draw_text(gpx, 100, 100, sample, tiny, CO_FORE, BM_CPY, &win);
        /* XOR over a filled band: text must knock through. */
        {
            static rect_t band = {200, 160, 800, 200};
            static uint8_t solid[1] = {0xFF};
            gpx_fill_rectangle(gpx, &band, CO_FORE, BM_CPY, solid, 1, 0);
            gpx_draw_text(gpx, 220, 168, sample, sys, CO_FORE, BM_XOR, 0);
        }
    }
    gdp_done();
}
