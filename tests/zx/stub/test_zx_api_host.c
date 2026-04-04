#include <stdio.h>
#include <stdint.h>
#include <string.h>

#include "libgpx.h"
extern uint8_t *gpx_stub_host_screen(void);

static int failures = 0;

#define CHECK(cond, msg) \
    do { \
        if (!(cond)) { \
            ++failures; \
            printf("[fail] %s\n", msg); \
        } \
    } while (0)

static uint16_t screen_offset(int x, int y)
{
    return (uint16_t)(((y & 0x07) << 8)
        + ((y & 0x38) << 2)
        + ((y & 0xC0) << 5)
        + (x >> 3));
}

static int pixel_on(int x, int y)
{
    if (x < 0 || x >= 256 || y < 0 || y >= 192)
        return 0;
    uint8_t *screen = gpx_stub_host_screen();
    uint16_t off = screen_offset(x, y);
    uint8_t mask = (uint8_t)(0x80 >> (x & 7));
    return (screen[off] & mask) != 0;
}

static int pixel_count(void)
{
    int c = 0;
    uint8_t *screen = gpx_stub_host_screen();
    for (int i = 0; i < 0x1800; ++i) {
        uint8_t b = screen[i];
        for (int j = 0; j < 8; ++j)
            c += (b >> j) & 1;
    }
    return c;
}

static uint8_t rotr8(uint8_t v)
{
    return (uint8_t)((v >> 1) | (v << 7));
}

static uint8_t rotr_n(uint8_t v, int n)
{
    while (n-- > 0)
        v = rotr8(v);
    return v;
}

static uint8_t bmp_checker[] = {
    S_BMP,
    8,
    4,
    4, 0,
    0xF0, 0x0F, 0xAA, 0x55
};

static uint8_t bmp_masked_test[] = {
    BMP_SIG_STRIDE(BMP_ENC_1BPP_MASK, 1),
    8,
    1,
    2, 0,
    0x25, 0x42
};

static void test_context(void)
{
    gpx_t *gpx0 = gpx_create(GPXM_DEFAULT);
    gpx_t *gpx1 = gpx_create((gmode)7);

    CHECK(gpx0 != 0, "gpx_create should return context");
    CHECK(gpx0 == gpx1, "gpx_create should return singleton context");
    CHECK(gpx0->width == 256 && gpx0->height == 192, "context dimensions");
    CHECK(gpx0->pages == 1 &&
        (gpx0->width >> 3) == 32 &&
        (uint32_t)(gpx0->width >> 3) * (uint32_t)gpx0->height == 6144,
        "context pages/derived stride-size");
    CHECK(gpx_width() == 256 && gpx_height() == 192, "gpx_width/gpx_height values");

    gpx_destroy(gpx0);
    gpx_destroy((gpx_t *)0);
}

static void test_pixel(void)
{
    gpx_t *g = gpx_create(GPXM_DEFAULT);
    rect_t clip = {4, 4, 5, 5};

    gpx_clrscr();

    gpx_draw_pixel(g, 1, 1, CO_FORE, BM_CPY, (const rect_t *)0);
    CHECK(pixel_on(1, 1), "draw_pixel should set foreground");

    gpx_draw_pixel(g, 1, 1, CO_BACK, BM_CPY, (const rect_t *)0);
    CHECK(!pixel_on(1, 1), "draw_pixel should clear background");

    gpx_draw_pixel(g, 2, 2, CO_FORE, BM_CPY, (const rect_t *)0);
    gpx_draw_pixel(g, 2, 2, CO_FORE, BM_XOR, (const rect_t *)0);
    CHECK(!pixel_on(2, 2), "draw_pixel XOR should toggle");

    gpx_draw_pixel(g, 4, 4, CO_FORE, BM_CPY, &clip);
    gpx_draw_pixel(g, 6, 4, CO_FORE, BM_CPY, &clip);
    CHECK(pixel_on(4, 4), "draw_pixel clip inside");
    CHECK(!pixel_on(6, 4), "draw_pixel clip outside");

    int before = pixel_count();
    gpx_draw_pixel(g, -1, 0, CO_FORE, BM_CPY, (const rect_t *)0);
    gpx_draw_pixel(g, 256, 0, CO_FORE, BM_CPY, (const rect_t *)0);
    gpx_draw_pixel(g, 0, 192, CO_FORE, BM_CPY, (const rect_t *)0);
    CHECK(pixel_count() == before, "draw_pixel should ignore out-of-bounds");
}

static void test_line(void)
{
    gpx_t *g = gpx_create(GPXM_DEFAULT);
    rect_t clip = {1, 1, 3, 3};

    gpx_clrscr();

    uint8_t r = gpx_draw_line(g, 0, 0, 3, 0, CO_FORE, BM_CPY, 0x05, (const rect_t *)0);
    CHECK(pixel_on(0, 0) && pixel_on(2, 0), "draw_line patterned horizontal");
    CHECK(!pixel_on(1, 0) && !pixel_on(3, 0), "draw_line skips zero pattern bits");
    CHECK(r == rotr_n(0x05, 3), "draw_line should return rotated pattern");

    r = gpx_draw_line(g, 2, 2, 2, 2, CO_FORE, BM_CPY, 0x80, (const rect_t *)0);
    CHECK(r == 0x80, "draw_line degenerate return value");

    gpx_clrscr();
    r = gpx_draw_line(g, 0, 0, 4, 4, CO_FORE, BM_CPY, 0xFF, &clip);
    CHECK(pixel_on(1, 1) && pixel_on(2, 2) && pixel_on(3, 3), "draw_line clipped points");
    CHECK(!pixel_on(0, 0) && !pixel_on(4, 4), "draw_line clip exclusion");
    CHECK(r == rotr_n(0xFF, 4), "draw_line clipped return value");
}

static void test_rectangle_and_fill(void)
{
    gpx_t *g = gpx_create(GPXM_DEFAULT);
    rect_t rect = {6, 6, 2, 2};
    rect_t clip = {3, 2, 5, 5};

    gpx_clrscr();
    gpx_draw_rectangle(g, &rect, CO_FORE, BM_CPY, 0xFF, &clip);
    CHECK(pixel_on(3, 2) && pixel_on(4, 2) && pixel_on(5, 2), "draw_rectangle clipped top edge");
    CHECK(!pixel_on(2, 2), "draw_rectangle clip reject");

    uint8_t p1[2] = {0x80, 0x40};
    rect_t fill = {4, 4, 1, 2};
    gpx_fill_rectangle(g, &fill, CO_FORE, BM_CPY, p1, 2, (const rect_t *)0);
    CHECK(pixel_on(1, 2) && pixel_on(2, 3), "fill_rectangle pattern rows");
    CHECK(!pixel_on(2, 2), "fill_rectangle respects pattern bits");

    int before = pixel_count();
    gpx_fill_rectangle(g, &fill, CO_FORE, BM_CPY, p1, 0, (const rect_t *)0);
    CHECK(pixel_count() == before, "fill_rectangle fpatt_len=0 no-op");
}

static void test_bitmap(void)
{
    gpx_t *g = gpx_create(GPXM_DEFAULT);
    rect_t clip = {2, 1, 5, 3};

    gpx_clrscr();
    gpx_draw_bmp(g, 1, 1, (bmp_t *)&bmp_checker, &clip);

    CHECK(pixel_on(2, 1) && pixel_on(3, 1) && pixel_on(4, 1), "draw_bmp clipped row");
    CHECK(!pixel_on(1, 1) && !pixel_on(6, 1), "draw_bmp clip exclusion");

    gpx_clrscr();
    gpx_draw_bmp(g, -2, 190, (bmp_t *)&bmp_checker, (const rect_t *)0);
    CHECK(pixel_on(0, 190) || pixel_on(1, 190), "draw_bmp default clip with screen bounds");

    gpx_clrscr();
    rect_t clip_masked = {40, 20, 46, 20};
    gpx_draw_pixel(g, 42, 20, CO_FORE, BM_CPY, (const rect_t *)0);
    gpx_draw_pixel(g, 45, 20, CO_FORE, BM_CPY, (const rect_t *)0);
    gpx_draw_bmp(g, 40, 20, (bmp_t *)&bmp_masked_test, &clip_masked);
    CHECK(!pixel_on(40, 20), "masked draw_bmp should clear zero-masked pixel");
    CHECK(pixel_on(41, 20), "masked draw_bmp should set OR pixel");
    CHECK(pixel_on(42, 20) && pixel_on(45, 20), "masked draw_bmp should preserve kept pixels");
    CHECK(pixel_on(46, 20) && !pixel_on(47, 20), "masked draw_bmp should distinguish set vs transparent");
}

static void test_fonts_text_and_measure(void)
{
    gpx_t *g = gpx_create(GPXM_DEFAULT);
    const font_t *sys = gpx_get_system_font();
    const font_t *tiny = gpx_get_tiny_font();
    rect_t clip = {9, 8, 10, 12};

    CHECK(sys != 0 && tiny != 0, "font getters should return non-null");
    CHECK(sys == tiny, "stub fonts should point to same blob");
    CHECK(sys->first_ascii == 32 && sys->last_ascii == 126, "font ascii range");
    CHECK(sys->empty_width == 2, "font empty width");

    char mixed[4] = {'A', 1, 'B', 0};
    CHECK(gpx_measure_text("A", sys) == 4, "measure_text printable");
    CHECK(gpx_measure_text(mixed, sys) == 10, "measure_text mixed");
    CHECK(gpx_measure_text("", sys) == 0, "measure_text empty");
    CHECK(gpx_measure_text((const char *)0, sys) == 0, "measure_text null text");
    CHECK(gpx_measure_text("A", (const font_t *)0) == 0, "measure_text null font");

    gpx_clrscr();
    gpx_draw_text(g, 0, 0, (const char *)0, sys, CO_FORE, BM_CPY, (const rect_t *)0);
    gpx_draw_text(g, 0, 0, "AB", (const font_t *)0, CO_FORE, BM_CPY, (const rect_t *)0);
    CHECK(pixel_count() == 0, "draw_text null guards should no-op");

    gpx_draw_text(g, 0, 0, "A A", sys, CO_FORE, BM_CPY, (const rect_t *)0);
    coord third_a_x = gpx_measure_text("A ", sys);
    CHECK(pixel_on(1, 0) && pixel_on(0, 1), "draw_text draws first A");
    CHECK(pixel_on(third_a_x + 1, 0) && pixel_on(third_a_x + 0, 1),
          "draw_text space advance and third char");

    gpx_clrscr();
    gpx_draw_text(g, 8, 8, "A", tiny, CO_FORE, BM_CPY, &clip);
    CHECK(pixel_on(9, 8), "draw_text clip draw inside");
    CHECK(!pixel_on(8, 9) && !pixel_on(11, 9), "draw_text clip excludes outside");

    gpx_clrscr();
    gpx_draw_text(g, 0, 0, "A", sys, CO_FORE, BM_CPY, (const rect_t *)0);
    gpx_draw_text(g, 0, 0, "A", sys, CO_FORE, BM_XOR, (const rect_t *)0);
    CHECK(!pixel_on(1, 0) && !pixel_on(0, 1), "draw_text XOR toggles glyph");
}

static void test_stock_bitmaps_and_pages(void)
{
    gpx_t *g = gpx_create(GPXM_DEFAULT);
    (void)g;

    bmp_t *classic = gpx_get_stock_bmp(GPXSB_CURSOR_CLASSIC);
    bmp_t *std = gpx_get_stock_bmp(GPXSB_CURSOR_STD);
    bmp_t *hourglass = gpx_get_stock_bmp(GPXSB_CURSOR_HOURGLASS);
    bmp_t *caret = gpx_get_stock_bmp(GPXSB_CURSOR_CARET);
    bmp_t *hand = gpx_get_stock_bmp(GPXSB_CURSOR_HAND);

    CHECK(classic != 0 && std != 0 && hourglass != 0 && caret != 0 && hand != 0,
          "stock bitmap ids should resolve");
    CHECK(gpx_get_stock_bmp(0xFF) == 0, "stock bitmap invalid id should return null");

    int before = pixel_count();
    gpx_set_page(PG_DISPLAY, 0);
    gpx_set_page(PG_WRITE, 1);
    gpx_set_page(PG_DISPLAY | PG_WRITE, 0);
    CHECK(pixel_count() == before, "set_page should not touch VRAM in ZX stub");
}

int main(void)
{
    test_context();
    test_pixel();
    test_line();
    test_rectangle_and_fill();
    test_bitmap();
    test_fonts_text_and_measure();
    test_stock_bitmaps_and_pages();

    if (failures == 0) {
        printf("All host API coverage tests passed.\n");
        return 0;
    }

    printf("%d host API coverage test(s) failed.\n", failures);
    return 1;
}
