/* Raster bitmaps, masked AND/OR blits and 16x16 save-under sprites.
 * Serialized headers are decoded bytewise, including unaligned assets.
 * GPL2 License (see: LICENSE), Copyright (C) 2026 tomaz stih. */
#include "rasta_internal.h"
#include <string.h>

/* Validate dimensions against the encoded stride and declared payload. */
static int valid_bitmap(const bmp_t *b)
{
    const uint8_t *raw = (const uint8_t *)b;
    unsigned stride, planes, size;
    if (!b || BMP_ENC(raw[0]) > BMP_ENC_1BPP_MASK)
        return 0;
    stride = BMP_STRIDE(raw[0]);
    planes = BMP_ENC(raw[0]) == BMP_ENC_1BPP_MASK ? 2 : 1;
    size = raw[3] | ((unsigned)raw[4] << 8);
    return raw[1] && raw[2] && raw[1] <= stride * 8 &&
        size >= stride * raw[2] * planes;
}

void gpx_draw_bmp(gpx_t *gpx, coord x, coord y,
    bmp_t *b, const rect_t *clip)
{
    unsigned row, col, stride, planes;
    const uint8_t *raw = (const uint8_t *)b;
    if (!valid_bitmap(b))
        return;
    stride = BMP_STRIDE(raw[0]);
    planes = BMP_ENC(raw[0]) == BMP_ENC_1BPP_MASK ? 2 : 1;
    for (row = 0; row < raw[2]; ++row) {
        const uint8_t *data = raw + 5 + row * stride * planes;
        for (col = 0; col < raw[1]; ++col) {
            uint8_t mask = (uint8_t)(0x80u >> (col & 7));
            int ink = (data[(planes - 1) * stride + col / 8] & mask) != 0;
            if (ink || (planes == 2 && !(data[col / 8] & mask)))
                rasta_pixel(gpx, (int32_t)x + (int32_t)col,
                    (int32_t)y + (int32_t)row,
                    ink ? CO_FORE : CO_BACK, BM_CPY, clip);
        }
    }
}

void gpx_show_sprite(gpx_t *gpx, sprite_t *sprite)
{
    unsigned row, col, w, h;
    uint8_t *bg;
    if (!sprite || !sprite->background || !valid_bitmap(sprite->bitmap))
        return;
    w = sprite->bitmap->w;
    h = sprite->bitmap->h;
    if (w > 16 || h > 16 || sprite->x < 0 || sprite->y < 0 ||
        sprite->x >= RASTA_WIDTH || sprite->y >= RASTA_HEIGHT)
        return;
    bg = (uint8_t *)sprite->background;
    memset(bg, 0, GPX_SPRITE_BG_SIZE);
    bg[0] = BMP_SIG_STRIDE(BMP_ENC_1BPP, 2);
    bg[1] = (uint8_t)w;
    bg[2] = (uint8_t)h;
    bg[3] = (uint8_t)(h * 2);
    for (row = 0; row < h; ++row)
        for (col = 0; col < w; ++col)
            if (rasta_get_pixel(sprite->x + (int32_t)col,
                    sprite->y + (int32_t)row))
                bg[5 + row * 2 + col / 8] |= (uint8_t)(0x80u >> (col & 7));
    gpx_draw_bmp(gpx, sprite->x, sprite->y, sprite->bitmap, sprite->clip);
}

void gpx_hide_sprite(gpx_t *gpx, sprite_t *sprite)
{
    unsigned row, col;
    const uint8_t *bg;
    if (!sprite || !sprite->background)
        return;
    bg = (const uint8_t *)sprite->background;
    if (bg[0] != BMP_SIG_STRIDE(BMP_ENC_1BPP, 2) ||
        bg[1] > 16 || bg[2] > 16 || !valid_bitmap(sprite->background))
        return;
    /* Restore the entire captured box, including pixels outside the clip. */
    for (row = 0; row < bg[2]; ++row)
        for (col = 0; col < bg[1]; ++col)
            rasta_pixel(gpx, sprite->x + (int32_t)col,
                sprite->y + (int32_t)row,
                (bg[5 + row * 2 + col / 8] & (0x80u >> (col & 7)))
                    ? CO_FORE : CO_BACK, BM_CPY, NULL);
}
