#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "libgpx.h"

#define ZX_WIDTH 256
#define ZX_HEIGHT 192
#define ZX_STRIDE (ZX_WIDTH / 8)
#define ZX_SIZE (ZX_STRIDE * ZX_HEIGHT)

extern uint8_t *gpx_stub_host_screen(void);
extern void gpx_stub_host_reset_vram_writes(void);
extern uint32_t gpx_stub_host_get_vram_writes(void);
extern bmp_t *_gpx_cursor_current;

struct bmp8x8_s
{
    uint8_t signature;
    uint16_t w;
    uint16_t h;
    int16_t stride;
    uint16_t size;
    uint8_t bitmap[8];
};

static struct bmp8x8_s bmp_checker = {
    S_BMP,
    8,
    8,
    1,
    8,
    {0xAA, 0x55, 0xAA, 0x55, 0xAA, 0x55, 0xAA, 0x55}
};

static char g_meta_expected[256];
static char g_meta_actual[256];
static int g_meta_pass;

static void meta_set(const char *expected, const char *actual, int pass)
{
    snprintf(g_meta_expected, sizeof(g_meta_expected), "%s", expected ? expected : "");
    snprintf(g_meta_actual, sizeof(g_meta_actual), "%s", actual ? actual : "");
    g_meta_pass = pass ? 1 : 0;
}

static void dump_raw(const char *path)
{
    FILE *f = fopen(path, "wb");
    if (!f) {
        fprintf(stderr, "cannot open %s\n", path);
        exit(2);
    }
    fwrite(gpx_stub_host_screen(), 1, ZX_SIZE, f);
    fclose(f);
}

static void dump_meta(const char *path, uint32_t vram_writes)
{
    FILE *f = fopen(path, "w");
    if (!f) {
        fprintf(stderr, "cannot open %s\n", path);
        exit(2);
    }
    fprintf(f, "vram_writes=%u\n", (unsigned)vram_writes);
    fprintf(f, "pass=%d\n", g_meta_pass);
    fprintf(f, "expected=%s\n", g_meta_expected);
    fprintf(f, "actual=%s\n", g_meta_actual);
    fclose(f);
}

static void begin_scene(void)
{
    gpx_create(GPXM_DEFAULT);
    gpx_clrscr();
    gpx_stub_host_reset_vram_writes();
    meta_set("n/a", "n/a", 1);
}

static void sc_gpx_create(void)
{
    begin_scene();
    (void)gpx_create(GPXM_DEFAULT);
    meta_set("context width=256 height=192 stride=32 size=6144",
             "gpx_create called (also clears VRAM by design)",
             1);
}

static void sc_gpx_destroy(void)
{
    begin_scene();
    gpx_t *g = gpx_create(GPXM_DEFAULT);
    gpx_stub_host_reset_vram_writes();
    gpx_destroy(g);
    gpx_destroy((gpx_t *)0);
    meta_set("destroy should not touch VRAM",
             "gpx_destroy(g) and gpx_destroy(NULL) executed",
             1);
}

static void sc_gpx_width(void)
{
    begin_scene();
    dim w = gpx_width();
    char actual[128];
    snprintf(actual, sizeof(actual), "width=%u", (unsigned)w);
    meta_set("width=256", actual, w == 256);
}

static void sc_gpx_height(void)
{
    begin_scene();
    dim h = gpx_height();
    char actual[128];
    snprintf(actual, sizeof(actual), "height=%u", (unsigned)h);
    meta_set("height=192", actual, h == 192);
}

static void sc_gpx_clrscr(void)
{
    begin_scene();
    gpx_draw_pixel((gpx_t *)0, 10, 10, CO_FORE, BM_CPY, (const rect_t *)0);
    gpx_clrscr();
}

static void sc_gpx_draw_pixel(void)
{
    begin_scene();
    gpx_draw_pixel((gpx_t *)0, 16, 16, CO_FORE, BM_CPY, (const rect_t *)0);
}

static void sc_gpx_draw_line(void)
{
    begin_scene();
    gpx_draw_line((gpx_t *)0, 8, 8, 120, 80, CO_FORE, BM_CPY, 0xFF, (const rect_t *)0);
}

static void sc_gpx_draw_rectangle(void)
{
    begin_scene();
    rect_t r = {20, 20, 100, 70};
    gpx_draw_rectangle((gpx_t *)0, &r, CO_FORE, BM_CPY, 0xFF, (const rect_t *)0);
}

static void sc_gpx_fill_rectangle(void)
{
    begin_scene();
    rect_t r = {20, 20, 100, 70};
    uint8_t p[2] = {0xAA, 0x55};
    gpx_fill_rectangle((gpx_t *)0, &r, CO_FORE, BM_CPY, p, 2, (const rect_t *)0);
}

static void sc_gpx_draw_bmp(void)
{
    begin_scene();
    gpx_draw_bmp((gpx_t *)0, 30, 30, (bmp_t *)&bmp_checker, (const rect_t *)0);
}

static void sc_gpx_get_system_font(void)
{
    begin_scene();
    const font_t *f = gpx_get_system_font();
    char actual[200];
    int pass = 0;

    if (f) {
        snprintf(actual, sizeof(actual),
                 "font bytes=%02X %02X %02X %02X %02X %02X %02X %02X",
                 f->flags, f->first_ascii, f->last_ascii, f->empty_width,
                 f->max_glyph_width, f->glyph_height, f->advance, f->descent);
        pass = (f->flags == 0x00 && f->first_ascii == 32 && f->last_ascii == 126 &&
                f->empty_width == 2 && f->max_glyph_width == 3 &&
                f->glyph_height == 5 && f->advance == 1 && f->descent == 0);
    } else {
        snprintf(actual, sizeof(actual), "font=NULL");
    }

    meta_set("font bytes=00 20 7E 02 03 05 01 00", actual, pass);
}

static void sc_gpx_get_tiny_font(void)
{
    begin_scene();
    const font_t *f = gpx_get_tiny_font();
    char actual[200];
    int pass = 0;

    if (f) {
        snprintf(actual, sizeof(actual),
                 "font bytes=%02X %02X %02X %02X %02X %02X %02X %02X",
                 f->flags, f->first_ascii, f->last_ascii, f->empty_width,
                 f->max_glyph_width, f->glyph_height, f->advance, f->descent);
        pass = (f->flags == 0x00 && f->first_ascii == 32 && f->last_ascii == 126 &&
                f->empty_width == 2 && f->max_glyph_width == 3 &&
                f->glyph_height == 5 && f->advance == 1 && f->descent == 0);
    } else {
        snprintf(actual, sizeof(actual), "font=NULL");
    }

    meta_set("font bytes=00 20 7E 02 03 05 01 00", actual, pass);
}

static void sc_gpx_get_stock_bmp(void)
{
    begin_scene();
    bmp_t *c = gpx_get_stock_bmp(GPXSB_CURSOR_CLASSIC);
    bmp_t *s = gpx_get_stock_bmp(GPXSB_CURSOR_STD);
    bmp_t *h = gpx_get_stock_bmp(GPXSB_CURSOR_HOURGLASS);
    bmp_t *t = gpx_get_stock_bmp(GPXSB_CURSOR_CARET);
    bmp_t *hand = gpx_get_stock_bmp(GPXSB_CURSOR_HAND);
    bmp_t *bad = gpx_get_stock_bmp(0xFF);
    int pass = (c && s && h && t && hand && !bad &&
                c->bitmap[0] == 0x80 && s->bitmap[0] == 0x40 &&
                h->bitmap[0] == 0x20 && t->bitmap[0] == 0x10 &&
                hand->bitmap[0] == 0x08);
    char actual[220];
    snprintf(actual, sizeof(actual),
             "classic=%02X std=%02X hourglass=%02X caret=%02X hand=%02X bad=%s",
             c ? c->bitmap[0] : 0, s ? s->bitmap[0] : 0, h ? h->bitmap[0] : 0,
             t ? t->bitmap[0] : 0, hand ? hand->bitmap[0] : 0, bad ? "nonnull" : "null");
    meta_set("classic=80 std=40 hourglass=20 caret=10 hand=08 bad=null", actual, pass);
}

static void sc_gpx_get_cursor(void)
{
    begin_scene();
    bmp_t *classic = gpx_get_stock_bmp(GPXSB_CURSOR_CLASSIC);
    bmp_t *hand = gpx_get_stock_bmp(GPXSB_CURSOR_HAND);
    bmp_t *hourglass = gpx_get_stock_bmp(GPXSB_CURSOR_HOURGLASS);
    bmp_t *caret = gpx_get_stock_bmp(GPXSB_CURSOR_CARET);

    bmp_t *a = gpx_get_cursor(GPX_CURSOR_ARROW);
    bmp_t *h = gpx_get_cursor(GPX_CURSOR_HAND);
    bmp_t *w = gpx_get_cursor(GPX_CURSOR_WAIT);
    bmp_t *t = gpx_get_cursor(GPX_CURSOR_TEXT);
    bmp_t *u = gpx_get_cursor(0xFF);
    int pass = (a == classic && h == hand && w == hourglass && t == caret && u == classic);
    char actual[220];
    snprintf(actual, sizeof(actual),
             "arrow=%s hand=%s wait=%s text=%s invalid=%s",
             (a == classic) ? "classic" : "other",
             (h == hand) ? "hand" : "other",
             (w == hourglass) ? "hourglass" : "other",
             (t == caret) ? "caret" : "other",
             (u == classic) ? "classic" : "other");
    meta_set("arrow->classic hand->hand wait->hourglass text->caret invalid->classic",
             actual, pass);
}

static void sc_gpx_cursor_set(void)
{
    begin_scene();
    bmp_t *classic = gpx_get_stock_bmp(GPXSB_CURSOR_CLASSIC);
    bmp_t *hand = gpx_get_stock_bmp(GPXSB_CURSOR_HAND);
    uint8_t sig_ok[2] = {BMP_SIG(BMP_ENC_1BPP), 0};
    uint8_t bad_sig[2] = {0xF0, 0};
    int p1, p2, p3, p4;
    char actual[220];

    gpx_cursor_set(hand);
    p1 = (_gpx_cursor_current == hand);

    gpx_cursor_set((bmp_t *)sig_ok);
    p2 = (_gpx_cursor_current == (bmp_t *)sig_ok);

    gpx_cursor_set((bmp_t *)bad_sig);
    p3 = (_gpx_cursor_current == classic);

    gpx_cursor_set((bmp_t *)0);
    p4 = (_gpx_cursor_current == classic);

    snprintf(actual, sizeof(actual), "hand=%s sig_ok=%s bad=%s null=%s",
             p1 ? "ok" : "fail", p2 ? "ok" : "fail", p3 ? "ok" : "fail", p4 ? "ok" : "fail");
    meta_set("set hand; accept 1BPP signature; invalid->classic; null->classic",
             actual, p1 && p2 && p3 && p4);
}

static void sc_gpx_measure_text(void)
{
    begin_scene();
    const font_t *f = gpx_get_system_font();
    char mixed[4] = {'A', 1, 'B', 0};
    coord w1 = gpx_measure_text("A", f);
    coord w2 = gpx_measure_text("AB", f);
    coord w3 = gpx_measure_text(mixed, f);
    char actual[220];
    int pass = (w1 == 4 && w2 == 8 && w3 == 10);

    snprintf(actual, sizeof(actual), "A=%d AB=%d A\\\\x01B=%d", (int)w1, (int)w2, (int)w3);
    meta_set("A=4 AB=8 A\\x01B=10", actual, pass);
}

static void sc_gpx_draw_text(void)
{
    begin_scene();
    gpx_draw_text((gpx_t *)0, 20, 20, "A", gpx_get_system_font(), CO_FORE, BM_CPY, (const rect_t *)0);
}

struct scene_s
{
    const char *name;
    void (*fn)(void);
};

static const struct scene_s scenes[] = {
    {"gpx_create", sc_gpx_create},
    {"gpx_destroy", sc_gpx_destroy},
    {"gpx_width", sc_gpx_width},
    {"gpx_height", sc_gpx_height},
    {"gpx_clrscr", sc_gpx_clrscr},
    {"gpx_draw_pixel", sc_gpx_draw_pixel},
    {"gpx_draw_line", sc_gpx_draw_line},
    {"gpx_draw_rectangle", sc_gpx_draw_rectangle},
    {"gpx_fill_rectangle", sc_gpx_fill_rectangle},
    {"gpx_draw_bmp", sc_gpx_draw_bmp},
    {"gpx_get_system_font", sc_gpx_get_system_font},
    {"gpx_get_tiny_font", sc_gpx_get_tiny_font},
    {"gpx_get_stock_bmp", sc_gpx_get_stock_bmp},
    {"gpx_get_cursor", sc_gpx_get_cursor},
    {"gpx_cursor_set", sc_gpx_cursor_set},
    {"gpx_measure_text", sc_gpx_measure_text},
    {"gpx_draw_text", sc_gpx_draw_text},
};

int main(int argc, char **argv)
{
    const char *out_dir = "bin/stub-visuals/raw";
    char path[512];
    char meta_path[512];

    if (argc > 1)
        out_dir = argv[1];

    for (size_t i = 0; i < sizeof(scenes) / sizeof(scenes[0]); ++i) {
        scenes[i].fn();
        snprintf(path, sizeof(path), "%s/%s.raw", out_dir, scenes[i].name);
        dump_raw(path);
        snprintf(meta_path, sizeof(meta_path), "%s/%s.meta", out_dir, scenes[i].name);
        dump_meta(meta_path, gpx_stub_host_get_vram_writes());
        printf("wrote %s\n", path);
    }

    return 0;
}
