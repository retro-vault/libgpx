#include "zxtest.h"

/* Text in every colour and blit mode over content. Glyph rendering fills
 * the gap between glyphs as well as the glyph box, so the mode has to apply
 * consistently across both. */
void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    const font_t *sys = gpx_get_system_font();
    const font_t *tiny = gpx_get_tiny_font();
    coord phase;

    seed_screen_wash();

    for (phase = 0; phase < 8; ++phase) {
        gpx_draw_text(gpx, (coord)phase, (coord)(phase * 13),
            "Modes", sys, CO_FORE, BM_CPY, (const rect_t *)0);
        gpx_draw_text(gpx, (coord)(70 + phase), (coord)(phase * 13),
            "Modes", sys, CO_BACK, BM_CPY, (const rect_t *)0);
        gpx_draw_text(gpx, (coord)(140 + phase), (coord)(phase * 13),
            "Modes", sys, CO_FORE, BM_XOR, (const rect_t *)0);
        gpx_draw_text(gpx, (coord)(200 + phase), (coord)(phase * 13),
            "Modes", sys, CO_BACK, BM_XOR, (const rect_t *)0);
    }

    /* XOR twice restores the content underneath. */
    gpx_draw_text(gpx, 10, 120, "restore me", sys, CO_FORE, BM_XOR,
        (const rect_t *)0);
    gpx_draw_text(gpx, 10, 120, "restore me", sys, CO_FORE, BM_XOR,
        (const rect_t *)0);

    /* Tiny font in each mode. */
    gpx_draw_text(gpx, 10, 140, "tiny cpy", tiny, CO_FORE, BM_CPY,
        (const rect_t *)0);
    gpx_draw_text(gpx, 10, 155, "tiny back", tiny, CO_BACK, BM_CPY,
        (const rect_t *)0);
    gpx_draw_text(gpx, 10, 170, "tiny xor", tiny, CO_FORE, BM_XOR,
        (const rect_t *)0);

    TEST_END();
}
