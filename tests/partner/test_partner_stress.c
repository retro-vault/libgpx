#include "libgpx.h"

static const uint8_t bmp_raster[] = {
    BMP_SIG_STRIDE(BMP_ENC_1BPP, 1),
    8,
    8,
    8, 0,
    0x81,
    0x42,
    0x24,
    0x18,
    0x18,
    0x24,
    0x42,
    0x81
};

static const uint8_t bmp_masked[] = {
    BMP_SIG_STRIDE(BMP_ENC_1BPP_MASK, 1),
    8,
    4,
    8, 0,
    0x00, 0x81,
    0x00, 0x42,
    0x00, 0x24,
    0x00, 0x18,
    0x00, 0x00
};

static const uint8_t bmp_tiny_compact[] = {
    BMP_SIG(BMP_ENC_TINY),
    8,
    8,
    3, 0,
    0xE0,
    0x90,
    0x57
};

static const uint8_t bmp_tiny_legacy[] = {
    BMP_SIG(BMP_ENC_TINY),
    8,
    8,
    3,
    0xE0,
    0x90,
    0x57
};

void main(void)
{
    gpx_t *gpx = gpx_create((gmode)1);
    uint8_t p;

    rect_t clip_one = {3, 0, 3, 0};
    rect_t clip_core = {100, 100, 300, 300};
    rect_t clip_rect = {340, 80, 430, 110};
    rect_t clip_fill = {500, 60, 650, 140};
    rect_t clip_bmp = {52, 321, 58, 326};
    rect_t clip_tiny = {101, 321, 104, 324};
    rect_t clip_text = {20, 370, 140, 390};

    uint8_t fp0[3] = {0x96, 0x69, 0x3C};
    uint8_t fp1[1] = {0xFF};

    rect_t r0 = {300, 50, 260, 20};
    rect_t r1 = {350, 60, 420, 120};
    rect_t fr0 = {450, 40, 700, 160};
    rect_t fr1 = {710, 40, 900, 100};
    rect_t fr2 = {920, 40, 930, 50};

    const font_t *font;

    if (!gpx)
        goto done;

    gpx_clrscr();

    gpx_draw_pixel(gpx, 0, 0, CO_FORE, BM_CPY, (const rect_t *)0);
    gpx_draw_pixel(gpx, 1, 0, CO_FORE, BM_XOR, (const rect_t *)0);
    gpx_draw_pixel(gpx, 1, 0, CO_FORE, BM_XOR, (const rect_t *)0);
    gpx_draw_pixel(gpx, 3, 0, CO_FORE, BM_CPY, &clip_one);
    gpx_draw_pixel(gpx, 4, 0, CO_FORE, BM_CPY, &clip_one);

    gpx_draw_line(gpx, 0, 100, 900, 450, CO_FORE, BM_CPY, 0xFF, (const rect_t *)0);
    gpx_draw_line(gpx, 900, 450, 0, 100, CO_FORE, BM_CPY, 0xFF, (const rect_t *)0);
    gpx_draw_line(gpx, 200, 10, 200, 300, CO_FORE, BM_CPY, 0xFF, (const rect_t *)0);
    gpx_draw_line(gpx, 50, 250, 700, 250, CO_FORE, BM_CPY, 0xFF, (const rect_t *)0);
    gpx_draw_line(gpx, 500, 500, 500, 500, CO_FORE, BM_CPY, 0xFF, (const rect_t *)0);

    gpx_draw_line(gpx, -200, 220, 200, 220, CO_FORE, BM_CPY, 0xFF, &clip_core);
    gpx_draw_line(gpx, 210, -200, 210, 200, CO_FORE, BM_CPY, 0xFF, &clip_core);
    gpx_draw_line(gpx, 200, 210, 600, 210, CO_FORE, BM_CPY, 0xFF, &clip_core);
    gpx_draw_line(gpx, 220, 200, 220, 600, CO_FORE, BM_CPY, 0xFF, &clip_core);
    gpx_draw_line(gpx, 900, 10, 950, 20, CO_FORE, BM_CPY, 0xFF, &clip_core);

    gpx_draw_line(gpx, 20, 480, 120, 480, CO_FORE, BM_CPY, 0xA5, (const rect_t *)0);
    gpx_draw_line(gpx, 20, 481, 120, 481, CO_FORE, BM_CPY, 0x33, (const rect_t *)0);
    gpx_draw_line(gpx, 20, 482, 120, 482, CO_FORE, BM_CPY, 0xF0, (const rect_t *)0);
    gpx_draw_line(gpx, 20, 483, 120, 483, CO_FORE, BM_CPY, 0xE4, (const rect_t *)0);

    p = gpx_draw_line(gpx, 150, 480, 170, 480, CO_FORE, BM_CPY, 0xA5, (const rect_t *)0);
    gpx_draw_line(gpx, 171, 480, 191, 480, CO_FORE, BM_CPY, p, (const rect_t *)0);

    gpx_draw_rectangle(gpx, &r0, CO_FORE, BM_CPY, 0x33, (const rect_t *)0);
    gpx_draw_rectangle(gpx, &r1, CO_FORE, BM_CPY, 0xFF, &clip_rect);

    gpx_fill_rectangle(gpx, &fr0, CO_FORE, BM_CPY, fp0, 3, &clip_fill);
    gpx_fill_rectangle(gpx, &fr1, CO_FORE, BM_CPY, fp1, 1, (const rect_t *)0);
    gpx_fill_rectangle(gpx, &fr2, CO_FORE, BM_CPY, (uint8_t *)0, 1, (const rect_t *)0);
    gpx_fill_rectangle(gpx, &fr2, CO_FORE, BM_CPY, fp1, 0, (const rect_t *)0);

    gpx_draw_bmp(gpx, 50, 320, (bmp_t *)bmp_raster, (const rect_t *)0);
    gpx_draw_bmp(gpx, 50, 320, (bmp_t *)bmp_masked, &clip_bmp);
    gpx_draw_bmp(gpx, 100, 320, (bmp_t *)bmp_tiny_compact, (const rect_t *)0);
    gpx_draw_bmp(gpx, 100, 320, (bmp_t *)bmp_tiny_legacy, &clip_tiny);

    font = gpx_get_system_font();
    gpx_draw_text(gpx, 20, 350, "HELLO WORLD", font, CO_FORE, BM_CPY, (const rect_t *)0);
    gpx_draw_text(gpx, 20, 370, "CLIP", font, CO_FORE, BM_CPY, &clip_text);

    (void)gpx_measure_text("HELLO WORLD", font);

done:
    gpx_destroy(gpx);

    __asm
        halt
    __endasm;
}
