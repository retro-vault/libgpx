#include "libgpx.h"

#define PARTNER_VRAM_BASE 0x8000
#define PARTNER_WIDTH 1024
#define PARTNER_HEIGHT 256
#define PARTNER_STRIDE (PARTNER_WIDTH / 8)
#define PARTNER_SIZE (PARTNER_STRIDE * PARTNER_HEIGHT)

static gpx_t partner_gpx;

static int partner_in_clip(coord x, coord y, const rect_t *clip)
{
    if (x < 0 || x >= PARTNER_WIDTH || y < 0 || y >= PARTNER_HEIGHT)
        return 0;
    if (clip) {
        if (x < clip->x0 || x > clip->x1 || y < clip->y0 || y > clip->y1)
            return 0;
    }
    return 1;
}

static uint8_t *partner_vram(void)
{
    return (uint8_t *)PARTNER_VRAM_BASE;
}

static void partner_set_pixel(coord x, coord y, color c, bmode m)
{
    uint8_t *vram = partner_vram();
    uint16_t offset = (uint16_t)(y * PARTNER_STRIDE + (x >> 3));
    uint8_t mask = (uint8_t)(0x80 >> (x & 7));
    uint8_t current = vram[offset];

    if (m == BM_XOR) {
        vram[offset] = current ^ mask;
        return;
    }

    if (c == CO_FORE)
        vram[offset] = current | mask;
    else
        vram[offset] = current & (uint8_t)~mask;
}

static rect_t partner_default_clip(void)
{
    rect_t r;
    r.x0 = 0;
    r.y0 = 0;
    r.x1 = PARTNER_WIDTH - 1;
    r.y1 = PARTNER_HEIGHT - 1;
    return r;
}

static const rect_t *partner_clip_or_default(const rect_t *clip)
{
    static rect_t full;
    if (clip)
        return clip;
    full = partner_default_clip();
    return &full;
}

gpx_t *gpx_create(gmode mode)
{
    partner_gpx.width = PARTNER_WIDTH;
    partner_gpx.height = PARTNER_HEIGHT;
    partner_gpx.stride = PARTNER_STRIDE;
    partner_gpx.size = PARTNER_SIZE;
    gpx_clrscr();
    return &partner_gpx;
}

void gpx_destroy(gpx_t *gpx)
{
    (void)gpx;
}

dim gpx_width(void)
{
    return PARTNER_WIDTH;
}

dim gpx_height(void)
{
    return PARTNER_HEIGHT;
}

void gpx_clrscr(void)
{
    uint8_t *vram = partner_vram();
    for (uint32_t i = 0; i < PARTNER_SIZE; ++i)
        vram[i] = 0;
}

void gpx_draw_pixel(
    gpx_t *gpx, coord x, coord y,
    color c, bmode m, const rect_t *clip)
{
    (void)gpx;
    if (!partner_in_clip(x, y, clip))
        return;
    partner_set_pixel(x, y, c, m);
}

void gpx_draw_bmp(
    gpx_t *gpx, coord x, coord y,
    bmp_t *b, const rect_t *clip)
{
    (void)gpx;
    const rect_t *cl = partner_clip_or_default(clip);
    coord w = b->w;
    coord h = b->h;
    int16_t stride = b->stride;
    for (coord row = 0; row < h; ++row) {
        uint16_t row_offset = (uint16_t)(row * stride);
        for (coord col = 0; col < w; ++col) {
            uint8_t byte = b->bitmap[row_offset + (col >> 3)];
            uint8_t mask = (uint8_t)(0x80 >> (col & 7));
            if (byte & mask)
                gpx_draw_pixel(gpx, x + col, y + row, CO_FORE, BM_CPY, cl);
        }
    }
}
