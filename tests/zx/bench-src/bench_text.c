#include "bench.h"

BENCH_MAIN()

/* Text rendering and measurement through both stock fonts. */
void bench_body(gpx_t *gpx)
{
    const font_t *sys = gpx_get_system_font();
    const font_t *tiny = gpx_get_tiny_font();
    static const char line[] = "The quick brown fox jumps over 0123456789";
    rect_t clip = {20, 20, 200, 170};
    coord y;
    uint8_t i;

    for (y = 0; y < 180; y += 12)
        gpx_draw_text(gpx, 0, y, line, sys, CO_FORE, BM_CPY,
            (const rect_t *)0);
    for (y = 0; y < 180; y += 10)
        gpx_draw_text(gpx, 0, y, line, tiny, CO_FORE, BM_CPY,
            (const rect_t *)0);
    for (y = 0; y < 180; y += 12)
        gpx_draw_text(gpx, 3, y, line, sys, CO_FORE, BM_XOR, &clip);

    for (i = 0; i < 40; ++i) {
        gpx_measure_text(line, sys);
        gpx_measure_text(line, tiny);
    }
}
