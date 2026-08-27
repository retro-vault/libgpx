#include "libgpx.h"

static void mark(gpx_t *gpx, coord x, coord y);
static uint8_t has_hotspot(const bmp_t *b);

void main(void)
{
    uint8_t ok = 1;
    uint8_t mode0_ok = 0;
    uint8_t mode2_ok = 0;
    uint8_t mode1_ok = 0;
    gpx_t *gpx;
    const font_t *sys;
    const font_t *tiny;
    coord w;
    bmp_t *classic;
    bmp_t *std;
    bmp_t *hourglass;
    bmp_t *caret;
    bmp_t *hand;
    bmp_t *invalid;

    gpx = gpx_create((gmode)0);
    if (gpx &&
        gpx->width == 1024 &&
        gpx->height == 256 &&
        gpx->pages == 2 &&
        gpx->text_background == GPX_TEXT_BG_OPAQUE &&
        (gpx->width >> 3) == 128 &&
        (uint32_t)(gpx->width >> 3) * (uint32_t)gpx->height == 32768u &&
        gpx_width() == 1024 &&
        gpx_height() == 256) {
        mode0_ok = 1;
    } else {
        ok = 0;
    }

    gpx = gpx_create((gmode)2);
    if (gpx &&
        gpx->width == 1024 &&
        gpx->height == 256 &&
        gpx->pages == 2 &&
        gpx->text_background == GPX_TEXT_BG_OPAQUE &&
        (gpx->width >> 3) == 128 &&
        (uint32_t)(gpx->width >> 3) * (uint32_t)gpx->height == 32768u &&
        gpx_height() == 256) {
        mode2_ok = 1;
    } else {
        ok = 0;
    }

    gpx = gpx_create((gmode)1);
    if (gpx &&
        gpx->width == 1024 &&
        gpx->height == 512 &&
        gpx->pages == 2 &&
        gpx->text_background == GPX_TEXT_BG_OPAQUE &&
        (gpx->width >> 3) == 128 &&
        (uint32_t)(gpx->width >> 3) * (uint32_t)gpx->height == 65536u &&
        gpx_width() == 1024 &&
        gpx_height() == 512) {
        mode1_ok = 1;
    } else {
        ok = 0;
    }

    if (mode0_ok) mark(gpx, 1, 0);
    if (mode2_ok) mark(gpx, 2, 0);
    if (mode1_ok) mark(gpx, 3, 0);

    /* Verify mode 1 allows drawing beyond y=255. */
    mark(gpx, 10, 400);

    sys = gpx_get_system_font();
    tiny = gpx_get_tiny_font();
    if (sys != (const font_t *)0 && tiny != (const font_t *)0 &&
        sys == tiny && sys->max_glyph_width == 8 &&
        sys->glyph_height == 9)
        mark(gpx, 4, 0);
    else
        ok = 0;

    w = gpx_measure_text("AB", sys);
    if (w == 16)
        mark(gpx, 5, 0);
    else
        ok = 0;

    /* Draw the same foreground glyph over solid ink. Opaque mode must clear
     * the cell's paper; transparent mode must leave the solid cell intact. */
    {
        static uint8_t solid[1] = {0xFF};
        rect_t opaque_cell = {20, 20, 35, 28};
        rect_t transparent_cell = {40, 20, 55, 28};

        gpx_fill_rectangle(gpx, &opaque_cell, CO_FORE, BM_CPY,
                           solid, 1, (const rect_t *)0);
        gpx_fill_rectangle(gpx, &transparent_cell, CO_FORE, BM_CPY,
                           solid, 1, (const rect_t *)0);

        gpx_set_text_background(gpx, GPX_TEXT_BG_TRANSPARENT);
        if (gpx->text_background != GPX_TEXT_BG_TRANSPARENT)
            ok = 0;
        gpx_draw_text(gpx, 40, 20, "AA", sys, CO_FORE, BM_CPY,
                      (const rect_t *)0);

        gpx_set_text_background(gpx, GPX_TEXT_BG_OPAQUE);
        if (gpx->text_background != GPX_TEXT_BG_OPAQUE)
            ok = 0;
        gpx_draw_text(gpx, 20, 20, "AA", sys, CO_FORE, BM_CPY,
                      (const rect_t *)0);
        gpx_set_text_background((gpx_t *)0, GPX_TEXT_BG_TRANSPARENT);
    }

    classic = gpx_get_stock_bmp(GPXSB_CURSOR_CLASSIC);
    std = gpx_get_stock_bmp(GPXSB_CURSOR_STD);
    hourglass = gpx_get_stock_bmp(GPXSB_CURSOR_HOURGLASS);
    caret = gpx_get_stock_bmp(GPXSB_CURSOR_CARET);
    hand = gpx_get_stock_bmp(GPXSB_CURSOR_HAND);
    invalid = gpx_get_stock_bmp(0xFF);

    if (classic && std && hourglass && caret && hand && !invalid &&
        has_hotspot(classic) &&
        has_hotspot(std) &&
        has_hotspot(hourglass) &&
        has_hotspot(caret) &&
        has_hotspot(hand)) {
        mark(gpx, 6, 0);
    } else {
        ok = 0;
    }

    gpx_set_page(PG_WRITE, 1);
    mark(gpx, 7, 0);
    gpx_set_page(PG_DISPLAY, 0);
    mark(gpx, 8, 0);
    gpx_set_page(PG_DISPLAY | PG_WRITE, 0);
    mark(gpx, 9, 0);

    /* XOR sprite semantics: show draws the tiny-vector bitmap in XOR,
     * hide draws it again — show+hide must leave the screen untouched.
     * Three identical backdrops: A gets a lasting sprite, B gets
     * show+hide (must equal C, the pure backdrop). */
    {
        sprite_t spr;
        rect_t win_d = {905, 140, 920, 158};
        rect_t win_e = {905, 180, 920, 198};
        spr.bitmap = gpx_get_stock_bmp(GPXSB_CURSOR_STD);
        spr.background = (bmp_t *)0;
        spr.clip = (const rect_t *)0;
        gpx_draw_line(gpx, 800, 150, 840, 150, CO_FORE, BM_CPY, 0xFF,
                      (const rect_t *)0);
        gpx_draw_line(gpx, 800, 190, 840, 190, CO_FORE, BM_CPY, 0xFF,
                      (const rect_t *)0);
        gpx_draw_line(gpx, 800, 230, 840, 230, CO_FORE, BM_CPY, 0xFF,
                      (const rect_t *)0);
        spr.x = 810;
        spr.y = 144;
        gpx_show_sprite(gpx, &spr);            /* A: lasting sprite */
        spr.y = 184;
        gpx_show_sprite(gpx, &spr);
        gpx_hide_sprite(gpx, &spr);            /* B: net identity */

        /* window-clipped sprites: strokes restricted to sprite->clip */
        gpx_draw_line(gpx, 900, 150, 940, 150, CO_FORE, BM_CPY, 0xFF,
                      (const rect_t *)0);
        gpx_draw_line(gpx, 900, 190, 940, 190, CO_FORE, BM_CPY, 0xFF,
                      (const rect_t *)0);
        gpx_draw_line(gpx, 900, 230, 940, 230, CO_FORE, BM_CPY, 0xFF,
                      (const rect_t *)0);
        spr.x = 910;
        spr.y = 144;
        spr.clip = &win_d;
        gpx_show_sprite(gpx, &spr);            /* D: lasting, clipped */
        spr.y = 184;
        spr.clip = &win_e;
        gpx_show_sprite(gpx, &spr);
        gpx_hide_sprite(gpx, &spr);            /* E: identity under clip */
    }

    if (ok)
        mark(gpx, 10, 0);

    __asm__("halt");
}

static void mark(gpx_t *gpx, coord x, coord y)
{
    gpx_draw_pixel(gpx, x, y, CO_FORE, BM_CPY, (const rect_t *)0);
}

static uint8_t has_hotspot(const bmp_t *b)
{
    uint8_t hx;
    uint8_t hy;
    if (!b)
        return 0;
    hx = b->bitmap[b->size + 0];
    hy = b->bitmap[b->size + 1];
    return (uint8_t)((hx < b->w) && (hy < b->h));
}
