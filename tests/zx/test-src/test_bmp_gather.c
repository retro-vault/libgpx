#include "libgpx.h"

/* Complements test_bmp_leftclip from the other direction: drives the bmp
 * compositor's 2-byte source-window gather (gb_win, SUB = (8 - (x&7)) & 7)
 * through EVERY destination sub-byte alignment with NO clipping, so the gather
 * runs at every SUB value 0..7 for stride 1 and 2, masked and unmasked.
 * A non-multiple-of-8 width (13) forces a partial right edge, and the bottom
 * band trims the right mid-byte while the left is sub-byte shifted (both edges
 * partial + span boundary). Compared byte-for-byte vs the per-pixel oracle. */

/* stride 2, 13 wide (last 3 bits padding), 6 tall, unmasked. size = 2*6 */
static const uint8_t u13[] = {
    BMP_SIG_STRIDE(BMP_ENC_1BPP, 2), 13, 6, 12, 0,
    0xF8, 0x18,
    0xC3, 0xC0,
    0x01, 0x88,
    0xAA, 0x50,
    0x5A, 0xA8,
    0xFF, 0xF8
};

/* stride 2, 13 wide, 6 tall, masked. per row: AND0 AND1 OR0 OR1. size = 2*6*2 */
static const uint8_t m13[] = {
    BMP_SIG_STRIDE(BMP_ENC_1BPP_MASK, 2), 13, 6, 24, 0,
    0x00, 0x08, 0xFF, 0xF0,
    0x0F, 0xF8, 0xF0, 0x00,
    0xFF, 0xF8, 0x00, 0x00,
    0xAA, 0x58, 0x55, 0xA0,
    0x33, 0xC8, 0x66, 0x90,
    0x07, 0xF8, 0xF8, 0x00
};

/* stride 1, 8 wide, 5 tall, unmasked. size = 1*5 */
static const uint8_t u8[] = {
    BMP_SIG_STRIDE(BMP_ENC_1BPP, 1), 8, 5, 5, 0,
    0x81, 0xC3, 0xA5, 0x7E, 0xFF
};

/* stride 1, 8 wide, 5 tall, masked. per row: AND OR. size = 1*5*2 */
static const uint8_t m8[] = {
    BMP_SIG_STRIDE(BMP_ENC_1BPP_MASK, 1), 8, 5, 10, 0,
    0x00, 0xFF,
    0x0F, 0xF0,
    0xC3, 0x3C,
    0xAA, 0x55,
    0xFF, 0x81
};

void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    gpx_clrscr();

    /* Stride-2: every dest alignment x&7 = 0..7 (+ wrap at 8). 120&7 == 0,
     * so the right column repeats the same alignment in a different byte. */
    for (coord dx = 0; dx <= 8; ++dx) {
        coord y = (coord)(2 + dx * 8);
        gpx_draw_bmp(gpx, dx, y, (bmp_t *)u13, (const rect_t *)0);
        gpx_draw_bmp(gpx, (coord)(120 + dx), y, (bmp_t *)m13, (const rect_t *)0);
    }

    /* Stride-1 at every dest alignment. */
    for (coord dx = 0; dx <= 8; ++dx) {
        coord y = (coord)(74 + dx * 8);
        gpx_draw_bmp(gpx, dx, y, (bmp_t *)u8, (const rect_t *)0);
        gpx_draw_bmp(gpx, (coord)(120 + dx), y, (bmp_t *)m8, (const rect_t *)0);
    }

    /* Both edges partial: sub-byte left shift AND right edge trimmed mid-byte,
     * across every alignment (stresses span count vs gather). */
    for (coord dx = 0; dx < 8; ++dx) {
        coord y = (coord)(148 + dx * 5);
        rect_t c = {(coord)(60 + dx), y, (coord)(67 + dx), (coord)(y + 4)};
        gpx_draw_bmp(gpx, (coord)(60 + dx), y, (bmp_t *)m13, &c);
    }

    __asm__("halt");
}
