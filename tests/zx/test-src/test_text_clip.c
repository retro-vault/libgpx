#include "zxtest.h"

/* Clipped text: a clip window that cuts glyphs part-way, on every side,
 * and text pushed past each screen edge. */
void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    const font_t *sys = gpx_get_system_font();
    rect_t clip;
    coord k;

    seed_screen_wash();

    /* Left clip moving one pixel at a time through the first glyphs. */
    for (k = 0; k < 12; ++k) {
        clip.x0 = (coord)(10 + k);
        clip.y0 = (coord)(k * 13);
        clip.x1 = 120;
        clip.y1 = (coord)(clip.y0 + 11);
        gpx_draw_text(gpx, 10, clip.y0, "MMMM", sys, CO_FORE, BM_CPY,
            &clip);
    }

    /* Right clip moving one pixel at a time. */
    for (k = 0; k < 12; ++k) {
        clip.x0 = 140;
        clip.y0 = (coord)(k * 13);
        clip.x1 = (coord)(140 + k);
        clip.y1 = (coord)(clip.y0 + 11);
        gpx_draw_text(gpx, 140, clip.y0, "MMMM", sys, CO_FORE, BM_CPY,
            &clip);
    }

    /* Vertical clips that cut glyphs across the middle. */
    for (k = 0; k < 8; ++k) {
        clip.x0 = 10; clip.x1 = 120;
        clip.y0 = (coord)(160 + k);
        clip.y1 = (coord)(160 + 8);
        gpx_draw_text(gpx, 10, 160, "Ay", sys, CO_FORE, BM_CPY, &clip);
    }

    /* Past each screen edge with no clip at all. */
    gpx_draw_text(gpx, -20, 150, "edge", sys, CO_FORE, BM_CPY,
        (const rect_t *)0);
    gpx_draw_text(gpx, 240, 150, "edge", sys, CO_FORE, BM_CPY,
        (const rect_t *)0);
    gpx_draw_text(gpx, 100, -4, "edge", sys, CO_FORE, BM_CPY,
        (const rect_t *)0);
    gpx_draw_text(gpx, 100, 186, "edge", sys, CO_FORE, BM_CPY,
        (const rect_t *)0);
    gpx_draw_text(gpx, -300, 100, "gone", sys, CO_FORE, BM_CPY,
        (const rect_t *)0);
    gpx_draw_text(gpx, 300, 100, "gone", sys, CO_FORE, BM_CPY,
        (const rect_t *)0);

    /* Swapped clip draws nothing. */
    clip.x0 = 200; clip.y0 = 60; clip.x1 = 100; clip.y1 = 40;
    gpx_draw_text(gpx, 100, 40, "hidden", sys, CO_FORE, BM_CPY, &clip);

    TEST_END();
}
