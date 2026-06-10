#include "libgpx.h"

/* Broad sweep of the bmp compositor's cross-source-byte window: multi-byte
 * (stride-2) bitmaps, unmasked and masked, drawn at every sub-byte source
 * alignment via non-aligned left clips and negative x. Real backend is compared
 * byte-for-byte against the per-pixel oracle, so any window error is caught. */

static const uint8_t u16[] = {
    BMP_SIG_STRIDE(BMP_ENC_1BPP, 2), 16, 5, 10, 0,
    0xF0, 0x0F,
    0xC3, 0xC3,
    0x01, 0x80,
    0xAA, 0x55,
    0xFF, 0xFF
};

static const uint8_t m16[] = {
    BMP_SIG_STRIDE(BMP_ENC_1BPP_MASK, 2), 16, 5, 20, 0,
    0x00, 0x00, 0xFF, 0xFF,
    0x0F, 0xF0, 0xF0, 0x0F,
    0xFF, 0xF0, 0x00, 0x0F,
    0xAA, 0x55, 0x55, 0xAA,
    0x33, 0xCC, 0x66, 0x99
};

void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    gpx_clrscr();

    /* Non-aligned left clips: clip x0 = base + dx gives srcbit = (base+dx - x)&7. */
    for (coord dx = 0; dx < 8; ++dx) {
        coord y = (coord)(2 + dx * 6);
        coord bx = 40;
        rect_t cu = {(coord)(bx + dx), y, 120, (coord)(y + 4)};
        gpx_draw_bmp(gpx, bx, y, (bmp_t *)u16, &cu);
        rect_t cm = {(coord)(bx + dx), (coord)(y + 96), 120, (coord)(y + 100)};
        gpx_draw_bmp(gpx, bx, (coord)(y + 96), (bmp_t *)m16, &cm);
    }

    /* Negative x at every sub-byte alignment (srcbit = (-x)&7). */
    for (coord x = -7; x <= 0; ++x) {
        coord y = (coord)(60 + (x + 7) * 3);
        gpx_draw_bmp(gpx, x, y, (bmp_t *)u16, (const rect_t *)0);
        gpx_draw_bmp(gpx, x, (coord)(y + 40), (bmp_t *)m16, (const rect_t *)0);
    }

    /* Right edge trimmed mid-byte plus left non-aligned (both edges partial). */
    for (coord dx = 1; dx < 8; ++dx) {
        coord y = (coord)(150 + dx * 4);
        rect_t c = {(coord)(180 + dx), y, (coord)(190 + dx), (coord)(y + 3)};
        gpx_draw_bmp(gpx, (coord)(178 + dx), y, (bmp_t *)m16, &c);
    }

    __asm
        halt
    __endasm;
}
