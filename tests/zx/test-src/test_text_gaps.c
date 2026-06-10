#include "libgpx.h"

/* Oracle-compared text test focused on the GAP FILL invariant: inter-character
 * and missing-glyph gaps must be filled with opaque inverse color, NOT left
 * transparent.
 *
 * To keep this independent of glyph-over-background compositing (font glyphs
 * render opaque on the real backend but transparent in the stub -- a separate,
 * pre-existing divergence), glyphs are only drawn on a CLEARED area (where
 * opaque and transparent are identical), and the gap fill is validated over a
 * solid band using MISSING glyphs, which produce a pure empty_width gap fill
 * with no glyph compositing. The advance gap uses the same fill code path.
 *
 * NOTE: no helper functions before main() (emulator enters at lowest address).
 */

void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    const font_t *font = gpx_get_system_font();
    rect_t band = {4, 80, 220, 104};
    rect_t clip = {40, 84, 120, 100};
    uint8_t fp = 0xFF;
    char miss[9];
    int i;

    gpx_clrscr();

    /* glyph rendering on a cleared background (opaque==transparent here) */
    gpx_draw_text(gpx, 8, 20, "Hagi 123", font, CO_FORE, BM_CPY, (const rect_t *)0);
    gpx_draw_text(gpx, 8, 40, "WMil.,!?", font, CO_FORE, BM_CPY, (const rect_t *)0);

    /* a string of missing glyphs (control chars) -> pure empty_width gap fill */
    for (i = 0; i < 8; ++i)
        miss[i] = (char)0x01;          /* outside printable range */
    miss[8] = 0;

    /* missing-glyph gap fill on a cleared background (clear over clear = no-op) */
    gpx_draw_text(gpx, 8, 60, miss, font, CO_FORE, BM_CPY, (const rect_t *)0);

    /* gap fill visible: missing-glyph gaps clear columns out of a solid band */
    gpx_fill_rectangle(gpx, &band, CO_FORE, BM_CPY, &fp, 1, (const rect_t *)0);
    gpx_draw_text(gpx, 8, 82, miss, font, CO_FORE, BM_CPY, (const rect_t *)0);

    /* real glyphs over the solid band: opaque CPY render must knock out the
     * background (glyph zero-bits cleared), and gaps cleared too */
    gpx_draw_text(gpx, 8, 92, "Opaque!", font, CO_FORE, BM_CPY, (const rect_t *)0);

    /* clipped gap fill must respect the clip rect */
    gpx_draw_text(gpx, 8, 100, miss, font, CO_FORE, BM_CPY, &clip);

    __asm
        halt
    __endasm;
}
