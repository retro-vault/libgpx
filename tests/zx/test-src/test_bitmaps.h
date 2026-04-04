#ifndef ZX_TEST_BITMAPS_H
#define ZX_TEST_BITMAPS_H

#include "libgpx.h"

static const uint8_t bmp_checker[] = {
    S_BMP,
    8,
    4,
    4, 0,
    0xF0, 0x0F, 0xAA, 0x55
};

static const uint8_t bmp_diagonal[] = {
    S_BMP,
    8,
    4,
    8, 0,
    0x80, 0x40, 0x20, 0x10, 0x08, 0x04, 0x02, 0x01
};

static const uint8_t bmp_masked_test[] = {
    BMP_SIG_STRIDE(BMP_ENC_1BPP_MASK, 1),
    8,
    1,
    2, 0,
    0x25, 0x42
};

#endif // ZX_TEST_BITMAPS_H
