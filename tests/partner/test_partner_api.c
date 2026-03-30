#include "libgpx.h"

extern bmp_t *_gpx_cursor_current;

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
    bmp_t *cursor_hand;
    bmp_t *cursor_wait;
    bmp_t *cursor_text;
    bmp_t *cursor_arrow;
    uint8_t bad_sig[2] = {0xF0, 0x00};

    gpx = gpx_create((gmode)0);
    if (gpx &&
        gpx->width == 1024 &&
        gpx->height == 256 &&
        gpx->stride == 128 &&
        gpx->size == 32768u &&
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
        gpx->stride == 128 &&
        gpx->size == 32768u &&
        gpx_height() == 256) {
        mode2_ok = 1;
    } else {
        ok = 0;
    }

    gpx = gpx_create((gmode)1);
    if (gpx &&
        gpx->width == 1024 &&
        gpx->height == 512 &&
        gpx->stride == 128 &&
        gpx->size == 65536u &&
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
    if (sys != (const font_t *)0 && tiny != (const font_t *)0 && sys == tiny)
        mark(gpx, 4, 0);
    else
        ok = 0;

    w = gpx_measure_text("AB", sys);
    if (w > 0)
        mark(gpx, 5, 0);
    else
        ok = 0;

    gpx_draw_text(gpx, 20, 20, "A", sys, CO_FORE, BM_CPY, (const rect_t *)0);

    classic = gpx_get_stock_bmp(GPXSB_CURSOR_CLASSIC);
    std = gpx_get_stock_bmp(GPXSB_CURSOR_STD);
    hourglass = gpx_get_stock_bmp(GPXSB_CURSOR_HOURGLASS);
    caret = gpx_get_stock_bmp(GPXSB_CURSOR_CARET);
    hand = gpx_get_stock_bmp(GPXSB_CURSOR_HAND);
    invalid = gpx_get_stock_bmp(0xFF);

    cursor_arrow = gpx_get_cursor(GPX_CURSOR_ARROW);
    cursor_hand = gpx_get_cursor(GPX_CURSOR_HAND);
    cursor_wait = gpx_get_cursor(GPX_CURSOR_WAIT);
    cursor_text = gpx_get_cursor(GPX_CURSOR_TEXT);

    if (classic && std && hourglass && caret && hand && !invalid &&
        has_hotspot(classic) &&
        has_hotspot(std) &&
        has_hotspot(hourglass) &&
        has_hotspot(caret) &&
        has_hotspot(hand) &&
        cursor_arrow == classic &&
        cursor_hand == hand &&
        cursor_wait == hourglass &&
        cursor_text == caret) {
        mark(gpx, 6, 0);
    } else {
        ok = 0;
    }

    gpx_cursor_set(hand);
    if (_gpx_cursor_current == hand)
        mark(gpx, 7, 0);
    else
        ok = 0;

    gpx_cursor_set((bmp_t *)bad_sig);
    if (_gpx_cursor_current == classic)
        mark(gpx, 8, 0);
    else
        ok = 0;

    gpx_cursor_set((bmp_t *)0);
    if (_gpx_cursor_current == classic)
        mark(gpx, 9, 0);
    else
        ok = 0;

    if (ok)
        mark(gpx, 10, 0);

    __asm
        halt
    __endasm;
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
