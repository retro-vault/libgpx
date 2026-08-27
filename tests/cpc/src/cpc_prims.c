/* CPC primitive scenario: one picture per phase, captured and compared
 * against a golden raster in both display modes. */
#include "libgpx.h"
#include "cpctest.h"

/* The suite builds this twice, once per display mode. */
#ifndef DEMO_MODE
#define DEMO_MODE GPXM_DEFAULT
#endif

static uint8_t solid[1] = {0xFF};
static uint8_t half[2]  = {0xAA, 0x55};
static uint8_t brick[4] = {0xFF, 0x88, 0x88, 0x88};
static uint8_t under[GPX_SPRITE_BG_SIZE];

void main(void)
{
    gpx_t *gpx = gpx_create(DEMO_MODE);
    dim w = gpx_width();
    dim h = gpx_height();
    static rect_t win;
    rect_t r;
    sprite_t s;
    coord i;

    /* --- phase 0: spans, at every edge and every sub-byte offset --- */
    gpx_clrscr();
    r.x0 = 0; r.y0 = 0; r.x1 = (coord)(w - 1); r.y1 = 3;
    gpx_fill_rectangle(gpx, &r, CO_FORE, BM_CPY, solid, 1, 0);
    r.x0 = 0; r.y0 = (coord)(h - 4); r.x1 = (coord)(w - 1); r.y1 = (coord)(h - 1);
    gpx_fill_rectangle(gpx, &r, CO_FORE, BM_CPY, solid, 1, 0);
    for (i = 0; i < 8; i++) {
        r.x0 = (coord)(8 + i); r.y0 = (coord)(10 + i * 4);
        r.x1 = (coord)(w - 9 - i); r.y1 = (coord)(12 + i * 4);
        gpx_fill_rectangle(gpx, &r, CO_FORE, BM_CPY, solid, 1, 0);
    }
    r.x0 = 8; r.y0 = 50; r.x1 = (coord)(w / 2); r.y1 = 80;
    gpx_fill_rectangle(gpx, &r, CO_FORE, BM_CPY, half, 2, 0);
    r.x0 = (coord)(w / 2 + 8); r.y0 = 50; r.x1 = (coord)(w - 9); r.y1 = 80;
    gpx_fill_rectangle(gpx, &r, CO_FORE, BM_CPY, brick, 4, 0);
    cpc_phase();

    /* --- phase 1: lines in every octant, dashed, clipped --- */
    gpx_clrscr();
    r.x0 = 0; r.y0 = 0; r.x1 = (coord)(w - 1); r.y1 = (coord)(h - 1);
    gpx_draw_rectangle(gpx, &r, CO_FORE, BM_CPY, 0xFF, 0);
    {
        coord cx = (coord)(w / 2), cy = 60;
        gpx_draw_line(gpx, cx, cy, (coord)(cx + 100), cy, CO_FORE, BM_CPY, 0xFF, 0);
        gpx_draw_line(gpx, cx, cy, (coord)(cx + 100), (coord)(cy + 40), CO_FORE, BM_CPY, 0xFF, 0);
        gpx_draw_line(gpx, cx, cy, cx, (coord)(cy + 50), CO_FORE, BM_CPY, 0xFF, 0);
        gpx_draw_line(gpx, cx, cy, (coord)(cx - 100), (coord)(cy + 40), CO_FORE, BM_CPY, 0xFF, 0);
        gpx_draw_line(gpx, cx, cy, (coord)(cx - 100), cy, CO_FORE, BM_CPY, 0xFF, 0);
        gpx_draw_line(gpx, cx, cy, (coord)(cx - 100), (coord)(cy - 40), CO_FORE, BM_CPY, 0xFF, 0);
        gpx_draw_line(gpx, cx, cy, cx, (coord)(cy - 50), CO_FORE, BM_CPY, 0xFF, 0);
        gpx_draw_line(gpx, cx, cy, (coord)(cx + 100), (coord)(cy - 40), CO_FORE, BM_CPY, 0xFF, 0);
    }
    /* full-width shallow diagonals: dx past 255 in mode 2 */
    gpx_draw_line(gpx, 2, 118, (coord)(w - 3), 128, CO_FORE, BM_CPY, 0xFF, 0);
    gpx_draw_line(gpx, 2, 134, (coord)(w - 3), 134, CO_FORE, BM_CPY, 0xAA, 0);
    gpx_draw_line(gpx, 2, 138, (coord)(w - 3), 138, CO_FORE, BM_CPY, 0xE4, 0);
    win.x0 = 8; win.y0 = 150; win.x1 = (coord)(w / 2); win.y1 = 190;
    gpx_draw_rectangle(gpx, &win, CO_FORE, BM_CPY, 0xAA, 0);
    for (i = 0; i < 8; i++)
        gpx_draw_line(gpx, 0, 140, (coord)(w / 3 + i * (w / 24)), 199,
                      CO_FORE, BM_CPY, 0xFF, &win);
    cpc_phase();

    /* --- phase 2: text and bitmaps --- */
    gpx_clrscr();
    gpx_draw_text(gpx, 4, 4, "Amstrad CPC libgpx", gpx_get_system_font(),
                  CO_FORE, BM_CPY, 0);
    gpx_draw_text(gpx, 4, 16, "0123456789 !@#$%^&*()", gpx_get_tiny_font(),
                  CO_FORE, BM_CPY, 0);
    r.x0 = 4; r.y0 = 30; r.x1 = (coord)(w - 5); r.y1 = 42;
    gpx_fill_rectangle(gpx, &r, CO_FORE, BM_CPY, solid, 1, 0);
    gpx_draw_text(gpx, 8, 32, "reverse", gpx_get_system_font(),
                  CO_BACK, BM_CPY, 0);
    r.x0 = 4; r.y0 = 48; r.x1 = (coord)(w - 5); r.y1 = 60;
    gpx_fill_rectangle(gpx, &r, CO_FORE, BM_CPY, solid, 1, 0);
    gpx_draw_text(gpx, 8, 50, "xor", gpx_get_system_font(),
                  CO_FORE, BM_XOR, 0);
    /* Opaque text over solid ink, in BOTH colours. The advance gap between
     * characters is painted in the inverse colour, and CO_FORE is the case
     * where that differs from the background -- so this is what proves the
     * gap is filled, on every row of the band, and not just the first. */
    r.x0 = 4; r.y0 = 62; r.x1 = (coord)(w - 5); r.y1 = 68;
    gpx_fill_rectangle(gpx, &r, CO_FORE, BM_CPY, solid, 1, 0);
    gpx_draw_text(gpx, 8, 62, "IIIIIIII", gpx_get_system_font(),
                  CO_FORE, BM_CPY, 0);

    win.x0 = 20; win.y0 = 70; win.x1 = 100; win.y1 = 82;
    gpx_draw_rectangle(gpx, &win, CO_FORE, BM_CPY, 0xAA, 0);
    gpx_draw_text(gpx, 4, 72, "clipped text here", gpx_get_system_font(),
                  CO_FORE, BM_CPY, &win);
    cpc_phase();

    /* --- phase 3: sprites shown --- */
    gpx_clrscr();
    r.x0 = 4; r.y0 = 40; r.x1 = (coord)(w - 5); r.y1 = 70;
    gpx_fill_rectangle(gpx, &r, CO_FORE, BM_CPY, half, 2, 0);
    for (i = 0; i < 5; i++) {
        s.bitmap = gpx_get_stock_bmp((uint8_t)i);
        s.background = (bmp_t *)under;
        s.clip = 0;
        s.x = (coord)(11 + i * 30); s.y = 44;
        gpx_show_sprite(gpx, &s);
        gpx_hide_sprite(gpx, &s);
        s.y = 10;
        gpx_show_sprite(gpx, &s);
    }

    /* Sprites left VISIBLE over solid ink. The stock cursors are masked
     * bitmaps, so this is the only case that exercises the AND plane: on a
     * cleared screen an ignored mask looks exactly like a working one. */
    r.x0 = 4; r.y0 = 108; r.x1 = (coord)(w - 5); r.y1 = 128;
    gpx_fill_rectangle(gpx, &r, CO_FORE, BM_CPY, solid, 1, 0);
    for (i = 0; i < 5; i++) {
        s.bitmap = gpx_get_stock_bmp((uint8_t)i);
        s.background = (bmp_t *)under;
        s.clip = 0;
        s.x = (coord)(11 + i * 30); s.y = 110;
        gpx_show_sprite(gpx, &s);
    }

    gpx_destroy(gpx);
    cpc_finish();               /* the last picture is a phase too */
}
