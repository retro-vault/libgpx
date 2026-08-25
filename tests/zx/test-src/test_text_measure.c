#include "zxtest.h"

/* gpx_measure_text must agree with where gpx_draw_text actually stops.
 * Each string is measured (recorded) and then drawn with a marker pixel at
 * the measured advance, so a disagreement shows up in the pixels too. */
void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    const font_t *sys = gpx_get_system_font();
    const font_t *tiny = gpx_get_tiny_font();
    static const char *samples[8] = {
        "", " ", "i", "W", "iiii", "WWWW", "Hello, world!",
        "The quick brown fox"
    };
    coord w;
    uint8_t i;
    coord y = 0;

    for (i = 0; i < 8; ++i) {
        w = gpx_measure_text(samples[i], sys);
        record16((uint16_t)w);
        gpx_draw_text(gpx, 0, y, samples[i], sys, CO_FORE, BM_CPY,
            (const rect_t *)0);
        gpx_draw_pixel(gpx, w, y, CO_FORE, BM_CPY, (const rect_t *)0);
        y = (coord)(y + sys->glyph_height + 1);
    }

    for (i = 0; i < 8; ++i) {
        w = gpx_measure_text(samples[i], tiny);
        record16((uint16_t)w);
        gpx_draw_text(gpx, 0, y, samples[i], tiny, CO_FORE, BM_CPY,
            (const rect_t *)0);
        gpx_draw_pixel(gpx, w, y, CO_FORE, BM_CPY, (const rect_t *)0);
        y = (coord)(y + tiny->glyph_height + 1);
    }

    /* Measuring is independent of position and must handle degenerate
     * inputs without drawing anything. */
    record16((uint16_t)gpx_measure_text((const char *)0, sys));
    record16((uint16_t)gpx_measure_text("abc", (const font_t *)0));
    record16((uint16_t)gpx_measure_text("\x01\xFF", sys));

    /* Concatenation: measuring the parts must add up to measuring the
     * whole, which pins the per-glyph advance. */
    record16((uint16_t)(gpx_measure_text("abc", sys)
        + gpx_measure_text("def", sys)));
    record16((uint16_t)gpx_measure_text("abcdef", sys));

    TEST_END();
}
