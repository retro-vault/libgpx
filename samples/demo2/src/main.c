#include "libgpx.h"

/*
 * demo2 -- Iskra Delta Partner hardware smoke test for libgpx.
 *
 * Exercises the whole public API in one picture, laid out so the screen
 * can be verified against this checklist on real hardware. The two
 * pattern squares double as a built-in self-check: a cursor sprite was
 * shown AND hidden over the RIGHT one, so both squares must look
 * pixel-for-pixel identical.
 *
 *   1. title text with an underline of the measured text width
 *   2. eight-way octant star (hardware vector generator, every quadrant)
 *   3. line style column: solid / dotted / dashed / dot-dash hardware
 *      styles plus an arbitrary 0xA5 pattern (software fallback)
 *   4. near-full-width solid line (vectors past 255 px must chain)
 *   5. a "window": outlined rect, two diagonals and a text string all
 *      clipped to it (exact Cohen-Sutherland + per-bitmap box pre-clip)
 *   6. two identical checker squares; sprite shown+hidden on the right
 *   7. a visible cursor sprite, plus a window-clipped sprite of which
 *      only the part inside its small outlined window may appear
 *   8. full-screen border
 *
 * Build:  make -C samples/demo2      -> bin/demo2/demo2.com (CP/M TPA)
 * Exit:   the demo parks in an endless loop; reset the machine.
 */

static uint8_t bg_shown[GPX_SPRITE_BG_SIZE];
static uint8_t bg_round[GPX_SPRITE_BG_SIZE];
static uint8_t bg_clip[GPX_SPRITE_BG_SIZE];

void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    const font_t *font = gpx_get_system_font();
    rect_t win = {620, 60, 940, 180};
    rect_t spr_win = {150, 196, 185, 220};
    rect_t border = {0, 0, 1023, 255};
    rect_t sq_l = {340, 60, 419, 139};
    rect_t sq_r = {460, 60, 539, 139};
    uint8_t checker[2];
    sprite_t shown;
    sprite_t round;
    sprite_t clipped;
    coord w;

    checker[0] = 0xAA;
    checker[1] = 0x55;

    /* 1: title + measured underline */
    gpx_draw_text(gpx, 20, 8, "ISKRA DELTA PARTNER + LIBGPX DEMO2", font,
                  CO_FORE, BM_CPY, (const rect_t *)0);
    w = gpx_measure_text("ISKRA DELTA PARTNER + LIBGPX DEMO2", font);
    gpx_draw_line(gpx, 20, 26, (coord)(20 + w - 1), 26, CO_FORE, BM_CPY,
                  0xFF, (const rect_t *)0);

    /* 2: octant star around (150, 110) */
    gpx_draw_line(gpx, 150, 110, 230, 110, CO_FORE, BM_CPY, 0xFF, (const rect_t *)0);
    gpx_draw_line(gpx, 150, 110, 230, 145, CO_FORE, BM_CPY, 0xFF, (const rect_t *)0);
    gpx_draw_line(gpx, 150, 110, 150, 165, CO_FORE, BM_CPY, 0xFF, (const rect_t *)0);
    gpx_draw_line(gpx, 150, 110, 70, 145, CO_FORE, BM_CPY, 0xFF, (const rect_t *)0);
    gpx_draw_line(gpx, 150, 110, 70, 110, CO_FORE, BM_CPY, 0xFF, (const rect_t *)0);
    gpx_draw_line(gpx, 150, 110, 70, 75, CO_FORE, BM_CPY, 0xFF, (const rect_t *)0);
    gpx_draw_line(gpx, 150, 110, 150, 55, CO_FORE, BM_CPY, 0xFF, (const rect_t *)0);
    gpx_draw_line(gpx, 150, 110, 230, 75, CO_FORE, BM_CPY, 0xFF, (const rect_t *)0);

    /* 3: style column (hardware styles, then software 0xA5 fallback) */
    gpx_draw_line(gpx, 260, 60, 320, 60, CO_FORE, BM_CPY, 0xFF, (const rect_t *)0);
    gpx_draw_line(gpx, 260, 70, 320, 70, CO_FORE, BM_CPY, 0xCC, (const rect_t *)0);
    gpx_draw_line(gpx, 260, 80, 320, 80, CO_FORE, BM_CPY, 0xAA, (const rect_t *)0);
    gpx_draw_line(gpx, 260, 90, 320, 90, CO_FORE, BM_CPY, 0xF0, (const rect_t *)0);
    gpx_draw_line(gpx, 260, 100, 320, 100, CO_FORE, BM_CPY, 0xE4, (const rect_t *)0);
    gpx_draw_line(gpx, 260, 110, 320, 110, CO_FORE, BM_CPY, 0xA5, (const rect_t *)0);

    /* 4: near-full-width line (chained vectors) */
    gpx_draw_line(gpx, 8, 240, 1015, 240, CO_FORE, BM_CPY, 0xFF, (const rect_t *)0);

    /* 5: the window -- everything inside is clipped to it */
    gpx_draw_rectangle(gpx, &win, CO_FORE, BM_CPY, 0xFF, (const rect_t *)0);
    gpx_draw_line(gpx, 560, 20, 1010, 220, CO_FORE, BM_CPY, 0xFF, &win);
    gpx_draw_line(gpx, 1010, 30, 560, 230, CO_FORE, BM_CPY, 0xFF, &win);
    gpx_draw_text(gpx, 600, 100, "CLIPPED WINDOW TEXT", font,
                  CO_FORE, BM_CPY, &win);

    /* 6: identical checker squares; right one gets a sprite round-trip */
    gpx_fill_rectangle(gpx, &sq_l, CO_FORE, BM_CPY, checker, 2, (const rect_t *)0);
    gpx_fill_rectangle(gpx, &sq_r, CO_FORE, BM_CPY, checker, 2, (const rect_t *)0);
    round.x = 490;
    round.y = 90;
    round.bitmap = gpx_get_stock_bmp(GPXSB_CURSOR_STD);
    round.background = (bmp_t *)bg_round;
    round.clip = (const rect_t *)0;
    gpx_show_sprite(gpx, &round);
    gpx_hide_sprite(gpx, &round);      /* squares must now match exactly */

    /* 7: a sprite left visible, and a window-clipped sprite */
    shown.x = 370;
    shown.y = 170;
    shown.bitmap = gpx_get_stock_bmp(GPXSB_CURSOR_STD);
    shown.background = (bmp_t *)bg_shown;
    shown.clip = (const rect_t *)0;
    gpx_show_sprite(gpx, &shown);

    gpx_draw_rectangle(gpx, &spr_win, CO_FORE, BM_CPY, 0xFF, (const rect_t *)0);
    clipped.x = 170;
    clipped.y = 205;
    clipped.bitmap = gpx_get_stock_bmp(GPXSB_CURSOR_HAND);
    clipped.background = (bmp_t *)bg_clip;
    clipped.clip = &spr_win;
    gpx_show_sprite(gpx, &clipped);    /* only ink inside the small box */

    /* 8: full-screen border */
    gpx_draw_rectangle(gpx, &border, CO_FORE, BM_CPY, 0xFF, (const rect_t *)0);

    for (;;) {
    }
}
