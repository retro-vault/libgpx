#ifndef ZX_TEST_BITMAPS_H
#define ZX_TEST_BITMAPS_H

#include "libgpx.h"

/* Fixtures cover every stride the header can encode in practice: stride 1
 * (widths 1..8), stride 2 (9..16) and stride 3 (17..24), in both the plain
 * and the masked encoding. Payload bytes are deliberately asymmetric so a
 * mirrored or rotated blit cannot pass by accident. */

static const uint8_t bmp_checker[] = {
    S_BMP, 8, 4, 4, 0,
    0xF0, 0x0F, 0xAA, 0x55
};

static const uint8_t bmp_diagonal[] = {
    S_BMP, 8, 8, 8, 0,
    0x80, 0x40, 0x20, 0x10, 0x08, 0x04, 0x02, 0x01
};

/* 1 pixel wide: the narrowest legal bitmap. */
static const uint8_t bmp_w1[] = {
    S_BMP, 1, 5, 5, 0,
    0x80, 0x00, 0x80, 0x00, 0x80
};

/* 3 pixels wide: a partial byte with junk in the unused low bits, which
 * must never reach the screen. */
static const uint8_t bmp_w3[] = {
    S_BMP, 3, 4, 4, 0,
    0xE0 | 0x1F, 0xA0 | 0x1F, 0xE0 | 0x1F, 0x40 | 0x1F
};

/* 12 pixels wide, stride 2. */
static const uint8_t bmp_w12[] = {
    BMP_SIG_STRIDE(BMP_ENC_1BPP, 2), 12, 6, 12, 0,
    0xFF, 0xF0,
    0x80, 0x10,
    0xBE, 0xD0,
    0xA2, 0x50,
    0x80, 0x10,
    0xFF, 0xF0
};

/* 20 pixels wide, stride 3. */
static const uint8_t bmp_w20[] = {
    BMP_SIG_STRIDE(BMP_ENC_1BPP, 3), 20, 5, 15, 0,
    0xFF, 0xFF, 0xF0,
    0x92, 0x49, 0x20,
    0xA5, 0xA5, 0xA0,
    0xC3, 0xC3, 0xC0,
    0xFF, 0xFF, 0xF0
};

/* Masked 8x6: AND plane then OR plane per row. An AND bit of 0 punches a
 * hole, so a masked blit both clears and sets. */
static const uint8_t bmp_mask8[] = {
    BMP_SIG_STRIDE(BMP_ENC_1BPP_MASK, 1), 8, 6, 12, 0,
    0x00, 0x3C,
    0x81, 0x7E,
    0xC3, 0x3C,
    0xC3, 0x3C,
    0x81, 0x7E,
    0x00, 0x3C
};

/* Masked 12x5, stride 2: exercises the cross-source-byte carry that a
 * non-byte-aligned left edge exposes. */
static const uint8_t bmp_mask12[] = {
    BMP_SIG_STRIDE(BMP_ENC_1BPP_MASK, 2), 12, 5, 20, 0,
    0x00, 0x00, 0xFF, 0xF0,
    0x0F, 0x00, 0xF0, 0xF0,
    0x33, 0x30, 0xCC, 0xC0,
    0x0F, 0x00, 0xF0, 0xF0,
    0x00, 0x00, 0xAA, 0xA0
};

#endif /* ZX_TEST_BITMAPS_H */
