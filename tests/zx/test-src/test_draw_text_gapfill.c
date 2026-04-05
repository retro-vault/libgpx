#include "libgpx.h"

/* Test setup:
 * - Draw "AA" at (24,24) with system font.
 * - In this font, 'A' width is 5 and advance is 1, so the inter-letter
 *   gap column is x = 29.
 * - Probe pixel chosen: (29,28), byte 0x4463 mask 0x04.
 */

void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    const font_t *sys = gpx_get_system_font();
    volatile uint8_t *probe = (volatile uint8_t *)0x4463;
    uint8_t ok = 1;
    uint8_t fail_sys = 0;
    uint8_t fail_gap = 0;

    gpx_clrscr();

    if (sys == (const font_t *)0) {
        ok = 0;
        fail_sys = 1;
    } else {
        gpx_draw_pixel(gpx, 29, 28, CO_FORE, BM_CPY, (const rect_t *)0);
        gpx_draw_text(gpx, 24, 24, "A", sys, CO_FORE, BM_CPY, (const rect_t *)0);
        if ((*probe & 0x04u) != 0) {
            ok = 0;
            fail_gap = 1;
        }
    }

    gpx_clrscr();
    if (ok)
        gpx_draw_pixel(gpx, 6, 191, CO_FORE, BM_CPY, (const rect_t *)0);
    if (fail_sys)
        gpx_draw_pixel(gpx, 7, 191, CO_FORE, BM_CPY, (const rect_t *)0);
    if (fail_gap)
        gpx_draw_pixel(gpx, 8, 191, CO_FORE, BM_CPY, (const rect_t *)0);

    __asm
        halt
    __endasm;
}
