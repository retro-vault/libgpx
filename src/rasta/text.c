/* Proportional serialized raster fonts with opaque/transparent text cells.
 * GPL2 License (see: LICENSE), Copyright (C) 2026 tomaz stih. */
#include "rasta_internal.h"
#include <limits.h>

static const uint8_t *font_glyph(const font_t *font, uint8_t ch)
{
    const uint8_t *raw = (const uint8_t *)font;
    const uint8_t *entry;
    unsigned offset;
    if (ch < font->first_ascii || ch > font->last_ascii ||
        (font->flags & FONT_FLAG_VECTOR))
        return NULL;
    entry = raw + 8 + (ch - font->first_ascii) * 2;
    offset = (font->flags & FONT_FLAG_OFFSETS_BE)
        ? ((unsigned)entry[0] << 8) | entry[1]
        : entry[0] | ((unsigned)entry[1] << 8);
    if (!offset || BMP_ENC(raw[offset]) > BMP_ENC_1BPP_MASK)
        return NULL;
    return raw + offset;
}

coord gpx_measure_text(const char *text, const font_t *font)
{
    int32_t width = 0;
    if (!text || !font)
        return 0;
    while (*text) {
        const uint8_t *glyph = font_glyph(font, (uint8_t)*text++);
        width += glyph && glyph[1]
            ? glyph[1] + font->advance : font->empty_width;
        if (width > INT16_MAX)
            return INT16_MAX;
    }
    return (coord)width;
}

static void text_gap(gpx_t *gpx, int32_t x, int32_t y,
    unsigned width, unsigned height, color c, const rect_t *clip)
{
    unsigned row;
    for (row = 0; row < height; ++row)
        rasta_pattern_span(gpx, x, x + (int32_t)width - 1, y + (int32_t)row,
            x, 0xff, (color)((c ^ 1) & 1), BM_CPY, clip);
}

void gpx_draw_text(gpx_t *gpx, coord x, coord y,
    const char *text, const font_t *font,
    color c, bmode m, const rect_t *clip)
{
    int32_t pen = x;
    int opaque = (!gpx || gpx->text_background == GPX_TEXT_BG_OPAQUE)
        && m != BM_XOR;
    if (!text || !font)
        return;
    while (*text && pen < RASTA_WIDTH) {
        const uint8_t *glyph = font_glyph(font, (uint8_t)*text++);
        unsigned row, col, stride, planes, size;
        if (!glyph || !glyph[1]) {
            if (opaque)
                text_gap(gpx, pen, y, font->empty_width,
                    font->glyph_height, c, clip);
            pen += font->empty_width;
            continue;
        }
        stride = BMP_STRIDE(glyph[0]);
        planes = BMP_ENC(glyph[0]) == BMP_ENC_1BPP_MASK ? 2 : 1;
        size = glyph[3] | ((unsigned)glyph[4] << 8);
        if (glyph[1] > stride * 8 || size < glyph[2] * stride * planes)
            return;
        for (row = 0; row < glyph[2]; ++row) {
            const uint8_t *data = glyph + 5 +
                (row * planes + planes - 1) * stride;
            for (col = 0; col < glyph[1]; ++col) {
                int bit = (data[col / 8] & (0x80u >> (col & 7))) != 0;
                if (bit || opaque)
                    rasta_pixel(gpx, pen + (int32_t)col,
                        (int32_t)y + (int32_t)row,
                        bit ? c : (color)((c ^ 1) & 1), m, clip);
            }
        }
        pen += glyph[1];
        if (opaque)
            text_gap(gpx, pen, y, font->advance, font->glyph_height, c, clip);
        pen += font->advance;
    }
}
