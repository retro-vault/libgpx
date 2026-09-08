/* Differential raster tests plus native ABI, Full HD and lifecycle checks.
 * GPL2 License (see: LICENSE), Copyright (C) 2026 tomaz stih. */
#define _POSIX_C_SOURCE 200809L
#include "libgpx.h"
#include "reference.h"
#include <assert.h>
#include <errno.h>
#include <fcntl.h>
#include <stddef.h>
#include <stdio.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <unistd.h>

#define FB_SIZE 259200
static uint8_t *screen;
static gpx_t *ctx;
static gpx_t *reference;
static uint32_t seed = 0x12345678;

static unsigned random_value(unsigned limit)
{
    seed = seed * 1664525u + 1013904223u;
    return (seed >> 8) % limit;
}

static int pixel(int x, int y)
{
    return (screen[y * 240 + x / 8] & (0x80u >> (x & 7))) != 0;
}

static void compare(const char *operation, unsigned iteration)
{
    uint8_t *ref = gpx_stub_host_screen();
    int x, y;
    for (y = 0; y < 192; ++y)
        for (x = 0; x < 256; ++x) {
            unsigned offset = ((y & 7) << 8) + ((y & 0x38) << 2) +
                ((y & 0xc0) << 5) + x / 8;
            int expected = (ref[offset] & (0x80u >> (x & 7))) != 0;
            if (pixel(x, y) != expected) {
                fprintf(stderr, "%s iteration %u mismatch at %d,%d\n",
                    operation, iteration, x, y);
                abort();
            }
        }
}

static void differential(void)
{
    unsigned i;
    rect_t clip = {7, 5, 247, 185};
    for (i = 0; i < 160; ++i) {
        coord x = (coord)((int)random_value(450) - 100);
        coord y = (coord)((int)random_value(350) - 80);
        coord x1 = (coord)((int)random_value(450) - 100);
        coord y1 = (coord)((int)random_value(350) - 80);
        color c = (color)random_value(2);
        bmode m = (bmode)random_value(2);
        uint8_t patt = (uint8_t)random_value(256);
        uint8_t fill[] = {0xa5, 0x33, 0xf0};
        rect_t rect = {x, y, x1, y1};
        gpx_clrscr();
        ref_gpx_clrscr();
        gpx_draw_pixel(ctx, x, y, c, m, &clip);
        ref_gpx_draw_pixel(reference, x, y, c, m, &clip);
        assert(gpx_draw_line(ctx, x, y, x1, y1, c, m, patt, &clip) ==
            ref_gpx_draw_line(reference, x, y, x1, y1, c, m, patt, &clip));
        compare("pixel/line", i);
        gpx_draw_rectangle(ctx, &rect, c, m, patt, &clip);
        ref_gpx_draw_rectangle(reference, &rect, c, m, patt, &clip);
        compare("rectangle", i);
        /* Positive origins avoid the oracle's unsigned row-phase bug. */
        rect.y0 = (coord)random_value(100);
        rect.y1 = (coord)(rect.y0 + random_value(100));
        gpx_fill_rectangle(ctx, &rect, c, m, fill, 3, &clip);
        ref_gpx_fill_rectangle(reference, &rect, c, m, fill, 3, &clip);
        compare("fill rectangle", i);
#if GPX_ADVANCED
        {
            coord radius = (coord)random_value(95);
            point_t points[5] = {{25, 10}, {235, 165}, {40, 175},
                {220, 20}, {x, y}};
            gpx_draw_circle(ctx, x, y, radius, c, m, &clip);
            ref_gpx_draw_circle(reference, x, y, radius, c, m, &clip);
            compare("circle", i);
            gpx_fill_circle(ctx, 120, 95, radius, c, m, fill, 3, &clip);
            ref_gpx_fill_circle(reference, 120, 95, radius, c, m, fill, 3, &clip);
            compare("fill circle", i);
            gpx_draw_polygon(ctx, points, 5, c, m, patt, &clip);
            ref_gpx_draw_polygon(reference, points, 5, c, m, patt, &clip);
            compare("polygon", i);
            gpx_fill_polygon(ctx, points, 5, c, m, fill, 3, &clip);
            ref_gpx_fill_polygon(reference, points, 5, c, m, fill, 3, &clip);
            compare("fill polygon", i);
        }
#endif
        {
            const font_t *font = gpx_get_system_font();
            bmp_t *bmp = gpx_get_stock_bmp((uint8_t)(i % 5));
            textbg bg = (textbg)(i % 2);
            gpx_draw_bmp(ctx, x, y, bmp, &clip);
            ref_gpx_draw_bmp(reference, x, y, bmp, &clip);
            compare("masked bitmap", i);
            gpx_set_text_background(ctx, bg);
            ref_gpx_set_text_background(reference, bg);
            assert(gpx_measure_text("Hello! 123 ~", font) ==
                ref_gpx_measure_text("Hello! 123 ~", font));
            gpx_draw_text(ctx, x, y, "Hello! 123 ~", font, c, m, &clip);
            ref_gpx_draw_text(reference, x, y, "Hello! 123 ~", font, c, m, &clip);
            compare("text", i);
        }
    }
}

static void native_cases(void)
{
    uint8_t bg[GPX_SPRITE_BG_SIZE];
    uint8_t snapshot[FB_SIZE];
    uint8_t solid = 0xff;
    uint8_t pattern[] = {0x80, 0x40, 0x20};
    uint8_t raw[] = {0, 8, 1, 1, 0, 0xa5};
    rect_t full = {0, 0, 1919, 1079};
    rect_t negative = {-3, -2, 12, 10};
    rect_t invalid = {100, 100, 20, 20};
    rect_t clip = {1909, 1068, 1914, 1076};
    sprite_t sprite = {1907, 1067, gpx_get_stock_bmp(0), (bmp_t *)bg, &clip};
    int x, y;

    assert(offsetof(bmp_t, size) == 3 && offsetof(bmp_t, bitmap) == 5);
    assert(gpx_width() == 1920 && gpx_height() == 1080 && ctx->pages == 1);
    assert(gpx_get_tiny_font() && !gpx_get_stock_bmp(255));
    assert(gpx_measure_text(NULL, gpx_get_system_font()) == 0);
    gpx_clrscr();
    gpx_fill_rectangle(ctx, &negative, CO_FORE, BM_CPY, pattern, 3, NULL);
    for (y = 0; y <= 10; ++y)
        for (x = 0; x <= 12; ++x)
            assert(pixel(x, y) == ((pattern[(y + 2) % 3] &
                (0x80u >> ((x + 3) & 7))) != 0));
    gpx_draw_bmp(ctx, 1800, 900, (bmp_t *)raw, NULL);
    assert(pixel(1800, 900) && !pixel(1801, 900));
    /* A declared payload smaller than its dimensions is rejected. */
    raw[3] = 0;
    gpx_draw_bmp(ctx, 1800, 901, (bmp_t *)raw, NULL);
    assert(!pixel(1800, 901));
    gpx_draw_pixel(ctx, 1919, 1079, CO_FORE, BM_CPY, NULL);
    assert(screen[FB_SIZE - 1] & 1);
    gpx_set_page(PG_DISPLAY | PG_WRITE, 0);
    assert(pixel(1919, 1079));
    gpx_fill_rectangle(ctx, &full, CO_FORE, BM_CPY, pattern, 3, NULL);
    memcpy(snapshot, screen, FB_SIZE);
    gpx_show_sprite(ctx, &sprite);
    gpx_hide_sprite(ctx, &sprite);
    assert(memcmp(snapshot, screen, FB_SIZE) == 0);
    sprite.x = 1917;
    sprite.y = 1077;
    sprite.clip = NULL;
    gpx_show_sprite(ctx, &sprite);
    gpx_hide_sprite(ctx, &sprite);
    assert(memcmp(snapshot, screen, FB_SIZE) == 0);
    gpx_fill_rectangle(ctx, &full, CO_FORE, BM_XOR, &solid, 1, &invalid);
    assert(memcmp(snapshot, screen, FB_SIZE) == 0);
    gpx_draw_line(ctx, INT16_MIN, INT16_MIN, INT16_MAX, INT16_MAX,
        CO_FORE, BM_CPY, 0xff, NULL);
    assert(pixel(0, 0) && pixel(1079, 1079));
#if GPX_ADVANCED
    {
        point_t box[] = {{-3, -2}, {12, -2}, {12, 10}, {-3, 10}};
        gpx_clrscr();
        gpx_fill_polygon(ctx, box, 4, CO_FORE, BM_CPY, pattern, 3, NULL);
        memcpy(snapshot, screen, FB_SIZE);
        gpx_clrscr();
        gpx_fill_rectangle(ctx, &negative, CO_FORE, BM_CPY, pattern, 3, NULL);
        assert(memcmp(snapshot, screen, FB_SIZE) == 0);
        gpx_draw_circle(ctx, 960, 540, 520, CO_FORE, BM_XOR, NULL);
        gpx_draw_circle(ctx, 960, 540, 520, CO_FORE, BM_XOR, NULL);
        assert(memcmp(snapshot, screen, FB_SIZE) == 0);
        gpx_fill_circle(ctx, 960, 540, 520, CO_FORE, BM_XOR, pattern, 3, NULL);
        gpx_fill_circle(ctx, 960, 540, 520, CO_FORE, BM_XOR, pattern, 3, NULL);
        assert(memcmp(snapshot, screen, FB_SIZE) == 0);
        /* Full-range coordinates must neither wrap nor overflow. */
        gpx_draw_circle(ctx, INT16_MIN, INT16_MIN, INT16_MAX,
            CO_FORE, BM_CPY, NULL);
        assert(memcmp(snapshot, screen, FB_SIZE) == 0);
        gpx_fill_circle(ctx, INT16_MIN, INT16_MIN, INT16_MAX,
            CO_FORE, BM_CPY, &solid, 1, NULL);
        assert(memcmp(snapshot, screen, FB_SIZE) == 0);
    }
#endif
    gpx_fill_rectangle(ctx, NULL, CO_FORE, BM_CPY, NULL, 0, NULL);
    gpx_show_sprite(ctx, NULL);
    gpx_hide_sprite(ctx, NULL);
}

int main(void)
{
    const char *path = getenv("GPX_RASTA_FRAMEBUFFER");
    int fd;
    struct stat st;
    assert(path);
    ctx = gpx_create(GPXM_DEFAULT);
    assert(ctx);
    assert(!gpx_create(GPXM_DEFAULT) && errno == EBUSY);
    fd = open(path, O_RDONLY);
    assert(fd >= 0 && fstat(fd, &st) == 0 && st.st_size == FB_SIZE);
    screen = (uint8_t *)mmap(NULL, FB_SIZE, PROT_READ, MAP_SHARED, fd, 0);
    assert(screen != MAP_FAILED);
    close(fd);
    reference = ref_gpx_create(GPXM_DEFAULT);
    differential();
    native_cases();
    gpx_clrscr();
    for (size_t i = 0; i < FB_SIZE; ++i) assert(screen[i] == 0);
    gpx_destroy(ctx);
    gpx_draw_pixel(ctx, 0, 0, CO_FORE, BM_CPY, NULL);
    gpx_destroy(ctx);
    ctx = gpx_create(GPXM_DEFAULT);
    assert(ctx);
    gpx_destroy(ctx);
    assert(setenv("GPX_RASTA_FRAMEBUFFER", "/no/such/directory/screen.fb", 1) == 0);
    assert(!gpx_create(GPXM_DEFAULT));
    munmap(screen, FB_SIZE);
    puts("Rasta: differential, Full HD, ABI and lifecycle tests passed");
    return 0;
}
