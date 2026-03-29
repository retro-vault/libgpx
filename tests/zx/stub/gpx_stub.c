#include "libgpx.h"

#define ZX_WIDTH 256
#define ZX_HEIGHT 192
#define ZX_STRIDE (ZX_WIDTH / 8)
#define ZX_SIZE (ZX_STRIDE * ZX_HEIGHT)

#ifndef GPX_STUB_HOST
#define ZX_SCREEN_BASE 0x4000
#else
static uint8_t zx_host_screen[ZX_SIZE];
static uint32_t zx_host_vram_writes;
uint8_t *gpx_stub_host_screen(void)
{
    return zx_host_screen;
}
void gpx_stub_host_reset_vram_writes(void)
{
    zx_host_vram_writes = 0;
}
uint32_t gpx_stub_host_get_vram_writes(void)
{
    return zx_host_vram_writes;
}
#endif

static gpx_t zx_gpx;

#ifndef GPX_STUB_HOST
extern const uint8_t gpx_font_envy[];
#else
#define ZX_FONT_FIRST_ASCII 32
#define ZX_FONT_LAST_ASCII 126
#define ZX_FONT_CHAR_COUNT ((ZX_FONT_LAST_ASCII - ZX_FONT_FIRST_ASCII) + 1)
#define ZX_FONT_TABLE_OFFSET 8
#define ZX_FONT_TABLE_BYTES (ZX_FONT_CHAR_COUNT * 2)
#define ZX_FONT_GLYPH_A_OFFSET (ZX_FONT_TABLE_OFFSET + ZX_FONT_TABLE_BYTES)
#define ZX_FONT_GLYPH_B_OFFSET (ZX_FONT_GLYPH_A_OFFSET + 14)
#define ZX_FONT_BLOB_SIZE (ZX_FONT_GLYPH_B_OFFSET + 14)
static uint8_t zx_font_blob[ZX_FONT_BLOB_SIZE];
static uint8_t zx_font_blob_ready;

static void zx_font_put_u16le(uint8_t *dst, uint16_t v)
{
    dst[0] = (uint8_t)(v & 0xFF);
    dst[1] = (uint8_t)((v >> 8) & 0xFF);
}

static void zx_host_init_font_blob(void)
{
    uint16_t i;
    uint8_t *a;
    uint8_t *b;

    if (zx_font_blob_ready)
        return;

    for (i = 0; i < ZX_FONT_BLOB_SIZE; ++i)
        zx_font_blob[i] = 0;

    zx_font_blob[0] = 0x00; /* flags (LE offsets). */
    zx_font_blob[1] = ZX_FONT_FIRST_ASCII;
    zx_font_blob[2] = ZX_FONT_LAST_ASCII;
    zx_font_blob[3] = 2;    /* empty width */
    zx_font_blob[4] = 3;    /* max glyph width */
    zx_font_blob[5] = 8;    /* glyph height */
    zx_font_blob[6] = 1;    /* advance */
    zx_font_blob[7] = 0;    /* descent */

    /* Offsets for 'A' and 'B'. All other glyph entries remain zero. */
    zx_font_put_u16le(&zx_font_blob[ZX_FONT_TABLE_OFFSET + (('A' - ZX_FONT_FIRST_ASCII) * 2)],
        ZX_FONT_GLYPH_A_OFFSET);
    zx_font_put_u16le(&zx_font_blob[ZX_FONT_TABLE_OFFSET + (('B' - ZX_FONT_FIRST_ASCII) * 2)],
        ZX_FONT_GLYPH_B_OFFSET);

    /* Compact 1bpp glyph 'A' (3x8). */
    a = &zx_font_blob[ZX_FONT_GLYPH_A_OFFSET];
    a[0] = BMP_SIG(BMP_ENC_1BPP_COMPACT);
    a[1] = 3;  /* width */
    a[2] = 8;  /* height */
    a[3] = 1;  /* stride */
    zx_font_put_u16le(&a[4], 8);
    a[6] = 0x40;
    a[7] = 0xA0;
    a[8] = 0xE0;
    a[9] = 0xA0;
    a[10] = 0xA0;
    a[11] = 0x00;
    a[12] = 0x00;
    a[13] = 0x00;

    /* Compact 1bpp glyph 'B' (3x8). */
    b = &zx_font_blob[ZX_FONT_GLYPH_B_OFFSET];
    b[0] = BMP_SIG(BMP_ENC_1BPP_COMPACT);
    b[1] = 3;  /* width */
    b[2] = 8;  /* height */
    b[3] = 1;  /* stride */
    zx_font_put_u16le(&b[4], 8);
    b[6] = 0xC0;
    b[7] = 0xA0;
    b[8] = 0xC0;
    b[9] = 0xA0;
    b[10] = 0xC0;
    b[11] = 0x00;
    b[12] = 0x00;
    b[13] = 0x00;

    zx_font_blob_ready = 1;
}
#endif

typedef struct stock_bmp_s
{
    uint8_t signature;
    uint16_t w;
    uint16_t h;
    int16_t stride;
    uint16_t size;
    uint8_t bitmap[1];
} stock_bmp_t;

static stock_bmp_t zx_stock_classic = {BMP_SIG(BMP_ENC_1BPP_MASK), 8, 1, 1, 1, {0x80}};
static stock_bmp_t zx_stock_std = {BMP_SIG(BMP_ENC_1BPP_MASK), 8, 1, 1, 1, {0x40}};
static stock_bmp_t zx_stock_hourglass = {BMP_SIG(BMP_ENC_1BPP_MASK), 8, 1, 1, 1, {0x20}};
static stock_bmp_t zx_stock_caret = {BMP_SIG(BMP_ENC_1BPP_MASK), 8, 1, 1, 1, {0x10}};
static stock_bmp_t zx_stock_hand = {BMP_SIG(BMP_ENC_1BPP_MASK), 8, 1, 1, 1, {0x08}};

bmp_t *_gpx_cursor_current = (bmp_t *)&zx_stock_classic;

static uint16_t zx_screen_offset(coord x, coord y)
{
    return (uint16_t)(((y & 0x07) << 8)
        + ((y & 0x38) << 2)
        + ((y & 0xC0) << 5)
        + (x >> 3));
}

static int zx_in_clip(coord x, coord y, const rect_t *clip)
{
    if (x < 0 || x >= ZX_WIDTH || y < 0 || y >= ZX_HEIGHT)
        return 0;
    if (clip) {
        if (x < clip->x0 || x > clip->x1 || y < clip->y0 || y > clip->y1)
            return 0;
    }
    return 1;
}

static uint8_t *zx_screen(void)
{
#ifdef GPX_STUB_HOST
    return zx_host_screen;
#else
    return (uint8_t *)ZX_SCREEN_BASE;
#endif
}

static void zx_set_pixel(coord x, coord y, color c, bmode m)
{
    uint8_t *screen = zx_screen();
    uint16_t offset = zx_screen_offset(x, y);
    uint8_t mask = (uint8_t)(0x80 >> (x & 7));
    uint8_t current = screen[offset];

    if (m == BM_XOR) {
        screen[offset] = current ^ mask;
#ifdef GPX_STUB_HOST
        ++zx_host_vram_writes;
#endif
        return;
    }

    if (c == CO_FORE)
        screen[offset] = current | mask;
    else
        screen[offset] = current & (uint8_t)~mask;
#ifdef GPX_STUB_HOST
    ++zx_host_vram_writes;
#endif
}

static rect_t zx_default_clip(void)
{
    rect_t r;
    r.x0 = 0;
    r.y0 = 0;
    r.x1 = ZX_WIDTH - 1;
    r.y1 = ZX_HEIGHT - 1;
    return r;
}

static const rect_t *zx_clip_or_default(const rect_t *clip)
{
    static rect_t full;
    if (clip)
        return clip;
    full = zx_default_clip();
    return &full;
}

gpx_t *gpx_create(gmode mode)
{
    (void)mode;
    zx_gpx.width = ZX_WIDTH;
    zx_gpx.height = ZX_HEIGHT;
    zx_gpx.stride = ZX_STRIDE;
    zx_gpx.size = ZX_SIZE;
    gpx_clrscr();
    return &zx_gpx;
}

void gpx_destroy(gpx_t *gpx)
{
    (void)gpx;
}

dim gpx_width(void)
{
    return ZX_WIDTH;
}

dim gpx_height(void)
{
    return ZX_HEIGHT;
}

void gpx_clrscr(void)
{
    uint8_t *screen = zx_screen();
    for (uint32_t i = 0; i < ZX_SIZE; ++i) {
        screen[i] = 0;
#ifdef GPX_STUB_HOST
        ++zx_host_vram_writes;
#endif
    }
}

void gpx_draw_pixel(
    gpx_t *gpx, coord x, coord y,
    color c, bmode m, const rect_t *clip)
{
    (void)gpx;
    if (!zx_in_clip(x, y, clip))
        return;
    zx_set_pixel(x, y, c, m);
}

static uint8_t zx_rotate_pattern(uint8_t lpatt)
{
    return (uint8_t)((lpatt >> 1) | (lpatt << 7));
}

static uint8_t zx_rotate_pattern_n(uint8_t lpatt, uint8_t n)
{
    while (n-- > 0)
        lpatt = zx_rotate_pattern(lpatt);
    return lpatt;
}

static int32_t zx_abs32(int32_t v)
{
    return (v < 0) ? -v : v;
}

#define ZX_OC_LEFT   0x01
#define ZX_OC_RIGHT  0x02
#define ZX_OC_TOP    0x04
#define ZX_OC_BOTTOM 0x08

static uint8_t zx_outcode(int32_t x, int32_t y, const rect_t *clip)
{
    uint8_t code = 0;
    if (x < clip->x0)
        code |= ZX_OC_LEFT;
    else if (x > clip->x1)
        code |= ZX_OC_RIGHT;

    if (y < clip->y0)
        code |= ZX_OC_TOP;
    else if (y > clip->y1)
        code |= ZX_OC_BOTTOM;
    return code;
}

static int zx_clip_line(
    coord *x0, coord *y0, coord *x1, coord *y1,
    const rect_t *clip)
{
    int32_t ax0 = *x0;
    int32_t ay0 = *y0;
    int32_t ax1 = *x1;
    int32_t ay1 = *y1;

    while (1) {
        uint8_t c0 = zx_outcode(ax0, ay0, clip);
        uint8_t c1 = zx_outcode(ax1, ay1, clip);
        uint8_t out;
        int32_t nx = 0;
        int32_t ny = 0;

        if ((c0 | c1) == 0) {
            *x0 = (coord)ax0;
            *y0 = (coord)ay0;
            *x1 = (coord)ax1;
            *y1 = (coord)ay1;
            return 1;
        }
        if (c0 & c1)
            return 0;

        out = c0 ? c0 : c1;
        if (out & ZX_OC_TOP) {
            if (ay1 == ay0)
                return 0;
            ny = clip->y0;
            nx = ax0 + (ax1 - ax0) * (ny - ay0) / (ay1 - ay0);
        } else if (out & ZX_OC_BOTTOM) {
            if (ay1 == ay0)
                return 0;
            ny = clip->y1;
            nx = ax0 + (ax1 - ax0) * (ny - ay0) / (ay1 - ay0);
        } else if (out & ZX_OC_RIGHT) {
            if (ax1 == ax0)
                return 0;
            nx = clip->x1;
            ny = ay0 + (ay1 - ay0) * (nx - ax0) / (ax1 - ax0);
        } else {
            if (ax1 == ax0)
                return 0;
            nx = clip->x0;
            ny = ay0 + (ay1 - ay0) * (nx - ax0) / (ax1 - ax0);
        }

        if (out == c0) {
            ax0 = nx;
            ay0 = ny;
        } else {
            ax1 = nx;
            ay1 = ny;
        }
    }
}

uint8_t gpx_draw_hline(
    gpx_t *gpx, coord x0, coord x1, coord y,
    color c, bmode m, uint8_t lpatt, const rect_t *clip)
{
    uint8_t original_lpatt = lpatt;

    if (x1 < x0) {
        coord temp = x0;
        x0 = x1;
        x1 = temp;
    }

    if (clip) {
        rect_t cl = *clip;
        if (cl.x0 > cl.x1) {
            coord t = cl.x0;
            cl.x0 = cl.x1;
            cl.x1 = t;
        }
        if (cl.y0 > cl.y1) {
            coord t = cl.y0;
            cl.y0 = cl.y1;
            cl.y1 = t;
        }

        if (y < cl.y0 || y > cl.y1 || x1 < cl.x0 || x0 > cl.x1)
            return original_lpatt;

        if (x0 < cl.x0) {
            lpatt = zx_rotate_pattern_n(lpatt, (uint8_t)((cl.x0 - x0) & 7));
            x0 = cl.x0;
        }
        if (x1 > cl.x1)
            x1 = cl.x1;
    }

    for (coord x = x0; x <= x1; ++x) {
        if (lpatt & 0x01)
            gpx_draw_pixel(gpx, x, y, c, m, clip);
        lpatt = zx_rotate_pattern(lpatt);
    }

    return lpatt;
}

uint8_t gpx_draw_line(
    gpx_t *gpx, coord x0, coord y0, coord x1, coord y1,
    color c, bmode m, uint8_t lpatt, const rect_t *clip)
{
    coord ox0 = x0;
    coord oy0 = y0;
    coord ox1 = x1;
    coord oy1 = y1;
    uint8_t original_lpatt = lpatt;
    int dx = x1 > x0 ? x1 - x0 : x0 - x1;
    int sx = x0 < x1 ? 1 : -1;
    int dy = y1 > y0 ? y1 - y0 : y0 - y1;
    int sy = y0 < y1 ? 1 : -1;
    int err = (dx > dy ? dx : -dy) / 2;
    int e2;

    if (x0 == x1 && y0 == y1) {
        if (lpatt & 0x01)
            gpx_draw_pixel(gpx, x0, y0, c, m, clip);
        return original_lpatt;
    }

    if (clip) {
        rect_t cl = *clip;
        int32_t odx;
        int32_t ody;
        int32_t skip;

        if (cl.x0 > cl.x1) {
            coord t = cl.x0;
            cl.x0 = cl.x1;
            cl.x1 = t;
        }
        if (cl.y0 > cl.y1) {
            coord t = cl.y0;
            cl.y0 = cl.y1;
            cl.y1 = t;
        }

        if (!zx_clip_line(&x0, &y0, &x1, &y1, &cl))
            return original_lpatt;

        odx = zx_abs32((int32_t)ox1 - (int32_t)ox0);
        ody = zx_abs32((int32_t)oy1 - (int32_t)oy0);
        if (odx >= ody)
            skip = zx_abs32((int32_t)x0 - (int32_t)ox0);
        else
            skip = zx_abs32((int32_t)y0 - (int32_t)oy0);
        lpatt = zx_rotate_pattern_n(lpatt, (uint8_t)(skip & 7));

        dx = x1 > x0 ? x1 - x0 : x0 - x1;
        sx = x0 < x1 ? 1 : -1;
        dy = y1 > y0 ? y1 - y0 : y0 - y1;
        sy = y0 < y1 ? 1 : -1;
        err = (dx > dy ? dx : -dy) / 2;
    }

    while (1) {
        if (lpatt & 0x01)
            gpx_draw_pixel(gpx, x0, y0, c, m, clip);
        if (x0 == x1 && y0 == y1)
            break;
        e2 = err;
        if (e2 > -dx) {
            err -= dy;
            x0 += sx;
        }
        if (e2 < dy) {
            err += dx;
            y0 += sy;
        }
        lpatt = zx_rotate_pattern(lpatt);
    }

    return lpatt;
}

void gpx_draw_rectangle(
    gpx_t *gpx, rect_t *r,
    color c, bmode m, uint8_t lpatt, const rect_t *clip)
{
    rect_t rect = *r;
    if (rect.x0 > rect.x1) {
        coord temp = rect.x0;
        rect.x0 = rect.x1;
        rect.x1 = temp;
    }
    if (rect.y0 > rect.y1) {
        coord temp = rect.y0;
        rect.y0 = rect.y1;
        rect.y1 = temp;
    }

    gpx_draw_hline(gpx, rect.x0, rect.x1, rect.y0, c, m, lpatt, clip);
    gpx_draw_hline(gpx, rect.x0, rect.x1, rect.y1, c, m, lpatt, clip);

    for (coord y = rect.y0 + 1; y < rect.y1; ++y) {
        gpx_draw_pixel(gpx, rect.x0, y, c, m, clip);
        gpx_draw_pixel(gpx, rect.x1, y, c, m, clip);
    }
}

void gpx_fill_rectangle(
    gpx_t *gpx, rect_t *r,
    color c, bmode m,
    uint8_t *fpatt, uint8_t fpatt_len, const rect_t *clip)
{
    if (fpatt_len == 0)
        return;

    rect_t rect = *r;
    if (rect.x0 > rect.x1) {
        coord temp = rect.x0;
        rect.x0 = rect.x1;
        rect.x1 = temp;
    }
    if (rect.y0 > rect.y1) {
        coord temp = rect.y0;
        rect.y0 = rect.y1;
        rect.y1 = temp;
    }

    for (coord y = rect.y0; y <= rect.y1; ++y) {
        uint8_t pattern = fpatt[(y - rect.y0) % fpatt_len];
        for (coord x = rect.x0; x <= rect.x1; ++x) {
            uint8_t mask = (uint8_t)(0x80 >> ((x - rect.x0) & 7));
            if (pattern & mask)
                gpx_draw_pixel(gpx, x, y, c, m, clip);
        }
    }
}

typedef struct zx_bmp_view_s
{
    uint8_t signature;
    uint16_t w;
    uint16_t h;
    uint16_t stride;
    uint16_t size;
    const uint8_t *bitmap;
} zx_bmp_view_t;

static int zx_parse_bmp(const bmp_t *b, zx_bmp_view_t *view)
{
    const uint8_t *raw = (const uint8_t *)b;
    uint8_t sig;

    if (b == (const bmp_t *)0 || view == (zx_bmp_view_t *)0)
        return 0;

    sig = (uint8_t)(raw[0] & 0xF0);
    view->signature = sig;
    switch (sig) {
    case BMP_SIG(BMP_ENC_1BPP):
    case BMP_SIG(BMP_ENC_1BPP_MASK):
        /* Prefer packed serialized layout, but accept aligned C structs
         * used by host-only harness helpers. */
        view->w = (uint16_t)(raw[1] | ((uint16_t)raw[2] << 8));
        view->h = (uint16_t)(raw[3] | ((uint16_t)raw[4] << 8));
        view->stride = (uint16_t)(raw[5] | ((uint16_t)raw[6] << 8));
        view->size = (uint16_t)(raw[7] | ((uint16_t)raw[8] << 8));
        view->bitmap = &raw[9];
        if (view->w == 0 || view->w > 512 || view->h == 0 || view->h > 256 ||
            view->stride == 0 || view->stride > 128) {
            if (b->stride <= 0)
                return 0;
            view->w = b->w;
            view->h = b->h;
            view->stride = (uint16_t)b->stride;
            view->size = b->size;
            view->bitmap = b->bitmap;
        }
        break;
    case BMP_SIG(BMP_ENC_1BPP_COMPACT):
    case BMP_SIG(BMP_ENC_1BPP_MASK_COMPACT):
        view->w = raw[1];
        view->h = raw[2];
        view->stride = raw[3];
        view->size = (uint16_t)(raw[4] | ((uint16_t)raw[5] << 8));
        view->bitmap = &raw[6];
        break;
    default:
        return 0;
    }

    if (view->w == 0 || view->h == 0 || view->stride == 0)
        return 0;

    return 1;
}

static uint16_t zx_glyph_width(const uint8_t *glyph)
{
    if (glyph == (const uint8_t *)0)
        return 0;

    switch (glyph[0] & 0xF0) {
    case BMP_SIG(BMP_ENC_1BPP):
    case BMP_SIG(BMP_ENC_1BPP_MASK):
        return (uint16_t)(glyph[1] | ((uint16_t)glyph[2] << 8));
    case BMP_SIG(BMP_ENC_1BPP_COMPACT):
    case BMP_SIG(BMP_ENC_1BPP_MASK_COMPACT):
        return glyph[1];
    default:
        return 0;
    }
}

static const uint8_t *zx_font_blob_ptr(void)
{
#ifdef GPX_STUB_HOST
    zx_host_init_font_blob();
    return zx_font_blob;
#else
    return gpx_font_envy;
#endif
}

static const uint8_t *zx_font_glyph_ptr(const font_t *font, uint8_t ch)
{
    const uint8_t *fraw = (const uint8_t *)font;
    uint8_t first;
    uint8_t last;
    uint8_t flags;
    uint16_t index;
    uint16_t table_offset;
    uint16_t glyph_offset;

    if (font == (const font_t *)0)
        return (const uint8_t *)0;

    flags = fraw[0];
    first = fraw[1];
    last = fraw[2];

    if (ch < first || ch > last)
        return (const uint8_t *)0;

    index = (uint16_t)(ch - first);
    table_offset = (uint16_t)(8 + index * 2);
    if (flags & FONT_FLAG_OFFSETS_BE)
        glyph_offset = (uint16_t)(((uint16_t)fraw[table_offset] << 8) | fraw[table_offset + 1]);
    else
        glyph_offset = (uint16_t)(fraw[table_offset] | ((uint16_t)fraw[table_offset + 1] << 8));

    if (glyph_offset == 0)
        return (const uint8_t *)0;
    return fraw + glyph_offset;
}

void gpx_draw_bmp(
    gpx_t *gpx, coord x, coord y,
    bmp_t *b, const rect_t *clip)
{
    zx_bmp_view_t view;
    const rect_t *cl = zx_clip_or_default(clip);
    uint16_t row;

    if (!zx_parse_bmp(b, &view))
        return;

    for (row = 0; row < view.h; ++row) {
        uint16_t col;
        uint16_t row_offset = (uint16_t)(row * view.stride);
        for (col = 0; col < view.w; ++col) {
            uint8_t byte = view.bitmap[row_offset + (uint16_t)(col >> 3)];
            uint8_t mask = (uint8_t)(0x80 >> (col & 7));
            if (byte & mask) {
                gpx_draw_pixel(gpx, (coord)(x + (coord)col), (coord)(y + (coord)row),
                    CO_FORE, BM_CPY, cl);
            }
        }
    }
}

static void zx_draw_bmp_mode(
    gpx_t *gpx, coord x, coord y, bmp_t *b,
    color c, bmode m, const rect_t *clip)
{
    zx_bmp_view_t view;
    const rect_t *cl = zx_clip_or_default(clip);
    uint16_t row;

    if (!zx_parse_bmp(b, &view))
        return;

    for (row = 0; row < view.h; ++row) {
        uint16_t col;
        uint16_t row_offset = (uint16_t)(row * view.stride);
        for (col = 0; col < view.w; ++col) {
            uint8_t byte = view.bitmap[row_offset + (uint16_t)(col >> 3)];
            uint8_t mask = (uint8_t)(0x80 >> (col & 7));
            if (byte & mask) {
                gpx_draw_pixel(gpx, (coord)(x + (coord)col), (coord)(y + (coord)row),
                    c, m, cl);
            }
        }
    }
}

const font_t *gpx_get_system_font(void)
{
    return (const font_t *)zx_font_blob_ptr();
}

const font_t *gpx_get_tiny_font(void)
{
    return (const font_t *)zx_font_blob_ptr();
}

bmp_t *gpx_get_stock_bmp(const uint8_t which)
{
    switch (which) {
    case GPXSB_CURSOR_CLASSIC:
        return (bmp_t *)&zx_stock_classic;
    case GPXSB_CURSOR_STD:
        return (bmp_t *)&zx_stock_std;
    case GPXSB_CURSOR_HOURGLASS:
        return (bmp_t *)&zx_stock_hourglass;
    case GPXSB_CURSOR_CARET:
        return (bmp_t *)&zx_stock_caret;
    case GPXSB_CURSOR_HAND:
        return (bmp_t *)&zx_stock_hand;
    default:
        return (bmp_t *)0;
    }
}

bmp_t *gpx_get_cursor(uint8_t type)
{
    switch (type) {
    case GPX_CURSOR_HAND:
        return gpx_get_stock_bmp(GPXSB_CURSOR_HAND);
    case GPX_CURSOR_WAIT:
        return gpx_get_stock_bmp(GPXSB_CURSOR_HOURGLASS);
    case GPX_CURSOR_TEXT:
        return gpx_get_stock_bmp(GPXSB_CURSOR_CARET);
    case GPX_CURSOR_ARROW:
    default:
        return gpx_get_stock_bmp(GPXSB_CURSOR_CLASSIC);
    }
}

void gpx_cursor_set(bmp_t *cursor)
{
    if (cursor == (bmp_t *)0) {
        _gpx_cursor_current = gpx_get_stock_bmp(GPXSB_CURSOR_CLASSIC);
        return;
    }

    if (cursor == gpx_get_stock_bmp(GPXSB_CURSOR_HAND)) {
        _gpx_cursor_current = cursor;
        return;
    }

    switch (cursor->signature & 0xF0) {
#ifdef GPX_STUB_HOST
    case BMP_SIG(BMP_ENC_1BPP):
    case BMP_SIG(BMP_ENC_1BPP_COMPACT):
#endif
    case BMP_SIG(BMP_ENC_1BPP_MASK):
    case BMP_SIG(BMP_ENC_1BPP_MASK_COMPACT):
        _gpx_cursor_current = cursor;
        return;
    default:
        _gpx_cursor_current = gpx_get_stock_bmp(GPXSB_CURSOR_CLASSIC);
        return;
    }
}

coord gpx_measure_text(const char *text, const font_t *font)
{
    const uint8_t *fraw = (const uint8_t *)font;
    uint16_t width = 0;
    uint8_t empty_width;
    uint8_t advance;

    if (text == (const char *)0 || font == (const font_t *)0)
        return 0;

    empty_width = fraw[3];
    advance = fraw[6];

    while (*text) {
        uint8_t ch = (uint8_t)*text;
        const uint8_t *glyph = zx_font_glyph_ptr(font, ch);
        uint16_t gw = zx_glyph_width(glyph);
        if (gw == 0)
            width = (uint16_t)(width + empty_width);
        else
            width = (uint16_t)(width + gw + advance);
        ++text;
    }
    return (coord)width;
}

void gpx_draw_text(
    gpx_t *gpx, coord x, coord y,
    const char *text, const font_t *font,
    color c, bmode m, const rect_t *clip)
{
    const uint8_t *fraw = (const uint8_t *)font;
    coord xcur = x;
    uint8_t empty_width;
    uint8_t advance;

    if (text == (const char *)0 || font == (const font_t *)0)
        return;

    empty_width = fraw[3];
    advance = fraw[6];

    while (*text) {
        uint8_t ch = (uint8_t)*text;
        const uint8_t *glyph = zx_font_glyph_ptr(font, ch);
        uint16_t gw = zx_glyph_width(glyph);

        if (gw == 0) {
            xcur = (coord)(xcur + empty_width);
            ++text;
            continue;
        }

        zx_draw_bmp_mode(gpx, xcur, y, (bmp_t *)glyph, c, m, clip);
        xcur = (coord)(xcur + (coord)gw + advance);
        ++text;
    }
}
