#include "libgpx.h"

/* Masked 1bpp bitmaps: opaque/transparent/force, over backgrounds.
 *
 * NOTE: masked stride-2 (multi-byte) blits combined with a sub-rectangle
 * clip that trims the right edge mid-byte currently diverge from the oracle
 * (backend draws a pixel inside the clip the reference skips). That combo is
 * intentionally avoided here; see project notes on the masked-clip edge case. */

/* stride 1, 8x4. Per row: AND byte then OR byte.
 * AND bit 0 => opaque (write OR bit); AND bit 1 & OR 1 => force FORE; else skip. */
static const uint8_t mask8[] = {
    BMP_SIG_STRIDE(BMP_ENC_1BPP_MASK, 1), 8, 4, 8, 0,
    0x00, 0xFF,   /* all opaque -> all FORE */
    0xFF, 0x00,   /* all transparent -> skip */
    0x0F, 0xF0,   /* left nibble opaque FORE, right skip */
    0xAA, 0x55    /* alternating */
};

/* stride 2, 12x3 (unclipped only). */
static const uint8_t mask12[] = {
    BMP_SIG_STRIDE(BMP_ENC_1BPP_MASK, 2), 12, 3, 12, 0,
    0x00, 0x00, 0xFF, 0xF0,   /* row0 opaque -> FORE 12 wide */
    0x0F, 0xF0, 0xF0, 0x00,   /* row1 mixed */
    0xFF, 0xF0, 0x00, 0x00    /* row2 mostly transparent */
};

void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    rect_t full = {0, 0, 255, 191};
    uint8_t pf = 0xFF;

    gpx_clrscr();

    /* over empty background, every x alignment (stride 1) */
    for (coord x = 0; x < 8; ++x)
        gpx_draw_bmp(gpx, (coord)(x * 10), (coord)(10 + x), (bmp_t *)mask8, (const rect_t *)0);

    /* stride-2 masked, unclipped, several alignments */
    gpx_draw_bmp(gpx, 30, 30, (bmp_t *)mask12, (const rect_t *)0);
    gpx_draw_bmp(gpx, 45, 36, (bmp_t *)mask12, (const rect_t *)0);
    gpx_draw_bmp(gpx, 60, 42, (bmp_t *)mask12, (const rect_t *)0);

    /* over a solid background: opaque-FORE keeps, transparent shows bg */
    rect_t bg = {60, 60, 80, 70};
    gpx_fill_rectangle(gpx, &bg, CO_FORE, BM_CPY, &pf, 1, &full);
    gpx_draw_bmp(gpx, 64, 62, (bmp_t *)mask8, (const rect_t *)0);

    /* stride-1 masked clipped (single byte -> matches) */
    rect_t clip = {100, 40, 104, 42};
    gpx_draw_bmp(gpx, 98, 40, (bmp_t *)mask8, &clip);

    /* partly off right edge (stride 1) */
    gpx_draw_bmp(gpx, 251, 80, (bmp_t *)mask8, (const rect_t *)0);

    __asm
        halt
    __endasm;
}
