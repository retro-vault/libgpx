#include "bench.h"

BENCH_MAIN()

/* Text: opaque in both colours (which exercises the advance-gap fill), the
 * transparent policy, and XOR. */
void bench_body(gpx_t *gpx)
{
    const font_t *sys = gpx_get_system_font();
    const font_t *tiny = gpx_get_tiny_font();
    coord i;

    for (i = 0; i < 20; ++i)
        gpx_draw_text(gpx, 0, (coord)(i * 9), "Amstrad CPC libgpx 0123456789",
                      sys, CO_FORE, BM_CPY, 0);
    for (i = 0; i < 20; ++i)
        gpx_draw_text(gpx, 0, (coord)(i * 9), "Amstrad CPC libgpx 0123456789",
                      sys, CO_BACK, BM_CPY, 0);
    gpx_set_text_background(gpx, GPX_TEXT_BG_TRANSPARENT);
    for (i = 0; i < 20; ++i)
        gpx_draw_text(gpx, 0, (coord)(i * 9), "Amstrad CPC libgpx 0123456789",
                      tiny, CO_FORE, BM_CPY, 0);
    gpx_set_text_background(gpx, GPX_TEXT_BG_OPAQUE);
    for (i = 0; i < 20; ++i)
        gpx_draw_text(gpx, 0, (coord)(i * 9), "Amstrad CPC libgpx 0123456789",
                      sys, CO_FORE, BM_XOR, 0);
}
