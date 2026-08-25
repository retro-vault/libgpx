#include "zxtest.h"

/* The whole printable range through both stock fonts, plus characters the
 * font does not define. Every glyph lands at a different bit phase because
 * the fonts are proportional, so this also sweeps the glyph blitter. */
void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    const font_t *sys = gpx_get_system_font();
    const font_t *tiny = gpx_get_tiny_font();
    char line[17];
    uint8_t ch, i;
    coord y;

    /* 95 printable characters, 16 to a line. */
    y = 0;
    for (ch = 32; ch < 127; ch += 16) {
        for (i = 0; i < 16 && (uint8_t)(ch + i) < 127; ++i)
            line[i] = (char)(ch + i);
        line[i] = '\0';
        gpx_draw_text(gpx, 0, y, line, sys, CO_FORE, BM_CPY,
            (const rect_t *)0);
        y = (coord)(y + sys->glyph_height + 2);
    }

    /* The same through the tiny font. */
    for (ch = 32; ch < 127; ch += 16) {
        for (i = 0; i < 16 && (uint8_t)(ch + i) < 127; ++i)
            line[i] = (char)(ch + i);
        line[i] = '\0';
        gpx_draw_text(gpx, 0, y, line, tiny, CO_FORE, BM_CPY,
            (const rect_t *)0);
        y = (coord)(y + tiny->glyph_height + 2);
    }

    /* Characters below and above the font range fall back to the empty
     * advance rather than reading outside the glyph table. */
    gpx_draw_text(gpx, 0, y, "\x01\x02\x1F ~\x7F\x80\xFF", sys, CO_FORE,
        BM_CPY, (const rect_t *)0);
    y = (coord)(y + sys->glyph_height + 2);

    /* Empty string and a NULL string draw nothing; a NULL font too. */
    gpx_draw_text(gpx, 0, y, "", sys, CO_FORE, BM_CPY, (const rect_t *)0);
    gpx_draw_text(gpx, 0, y, (const char *)0, sys, CO_FORE, BM_CPY,
        (const rect_t *)0);
    gpx_draw_text(gpx, 0, y, "xx", (const font_t *)0, CO_FORE, BM_CPY,
        (const rect_t *)0);

    /* Runs of spaces exercise the empty-width advance and the gap fill
     * between glyphs. */
    gpx_draw_text(gpx, 0, y, "A   B  C D", sys, CO_FORE, BM_CPY,
        (const rect_t *)0);

    TEST_END();
}
