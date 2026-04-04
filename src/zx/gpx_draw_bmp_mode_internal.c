#include "libgpx.h"

static const uint8_t *zx_mode_bitmap_ptr(
    const bmp_t *b, uint8_t *stride_out, uint8_t *row_step_out)
{
    const uint8_t *raw = (const uint8_t *)b;
    uint8_t sig;
    uint8_t stride;

    if (b == (const bmp_t *)0 ||
        stride_out == (uint8_t *)0 ||
        row_step_out == (uint8_t *)0)
        return (const uint8_t *)0;

    sig = (uint8_t)(raw[0] & 0xF0);
    stride = BMP_STRIDE(raw[0]);
    *stride_out = stride;

    switch (sig) {
    case BMP_SIG(BMP_ENC_1BPP):
        *row_step_out = stride;
        return &raw[5];
    case BMP_SIG(BMP_ENC_1BPP_MASK):
        *row_step_out = (uint8_t)(stride * 2);
        return &raw[5 + stride];
    default:
        return (const uint8_t *)0;
    }
}

void gpx_draw_bmp_masked_internal(
    gpx_t *gpx, coord x, coord y, bmp_t *b, const rect_t *clip)
{
    const uint8_t *raw = (const uint8_t *)b;
    uint8_t stride;
    uint8_t w;
    uint8_t h;
    uint8_t row;

    if (b == (bmp_t *)0)
        return;

    if ((raw[0] & 0xF0) != BMP_SIG(BMP_ENC_1BPP_MASK))
        return;

    stride = BMP_STRIDE(raw[0]);
    w = b->w;
    h = b->h;
    if (w == 0 || h == 0 || stride == 0)
        return;

    for (row = 0; row < h; ++row) {
        uint16_t row_offset = (uint16_t)row * (uint16_t)(stride * 2);
        const uint8_t *and_row = &raw[5 + row_offset];
        const uint8_t *or_row = and_row + stride;
        uint8_t col;
        for (col = 0; col < w; ++col) {
            uint8_t bit = (uint8_t)(0x80 >> (col & 7));
            uint8_t and_byte = and_row[(uint16_t)(col >> 3)];
            uint8_t or_byte = or_row[(uint16_t)(col >> 3)];
            uint8_t and_set = (uint8_t)(and_byte & bit);
            uint8_t or_set = (uint8_t)(or_byte & bit);

            if (!and_set) {
                gpx_draw_pixel(
                    gpx,
                    (coord)(x + (coord)col),
                    (coord)(y + (coord)row),
                    or_set ? CO_FORE : CO_BACK,
                    BM_CPY, clip);
            } else if (or_set) {
                gpx_draw_pixel(
                    gpx,
                    (coord)(x + (coord)col),
                    (coord)(y + (coord)row),
                    CO_FORE, BM_CPY, clip);
            }
        }

    }
}

void gpx_draw_bmp_mode_internal(
    gpx_t *gpx, coord x, coord y, bmp_t *b,
    color c, bmode m, const rect_t *clip)
{
    const uint8_t *bitmap;
    uint8_t stride;
    uint8_t row_step;
    uint8_t w;
    uint8_t h;
    uint8_t row;

    if (b == (bmp_t *)0)
        return;

    bitmap = zx_mode_bitmap_ptr(b, &stride, &row_step);
    if (bitmap == (const uint8_t *)0)
        return;

    w = b->w;
    h = b->h;
    if (w == 0 || h == 0 || stride == 0)
        return;

    for (row = 0; row < h; ++row) {
        uint16_t row_offset = (uint16_t)row * (uint16_t)row_step;
        uint8_t col;
        for (col = 0; col < w; ++col) {
            uint8_t byte = bitmap[row_offset + (uint16_t)(col >> 3)];
            uint8_t mask = (uint8_t)(0x80 >> (col & 7));
            if (byte & mask) {
                gpx_draw_pixel(
                    gpx,
                    (coord)(x + (coord)col),
                    (coord)(y + (coord)row),
                    c, m, clip);
            }
        }
    }
}
