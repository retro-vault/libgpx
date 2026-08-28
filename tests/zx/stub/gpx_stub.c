#include "libgpx.h"

#define ZX_WIDTH 256
#define ZX_HEIGHT 192
#define ZX_STRIDE (ZX_WIDTH / 8)
#define ZX_SIZE (ZX_STRIDE * ZX_HEIGHT)
#define ZX_ATTR_SIZE 0x300
#define ZX_ATTR_DEFAULT 0x38 /* black ink, white paper */

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
#define ZX_FONT_GLYPH_B_OFFSET (ZX_FONT_GLYPH_A_OFFSET + 13)
#define ZX_FONT_BLOB_SIZE (ZX_FONT_GLYPH_B_OFFSET + 13)
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

    /* 1bpp glyph 'A' (3x8), stride encoded in signature low nibble. */
    a = &zx_font_blob[ZX_FONT_GLYPH_A_OFFSET];
    a[0] = BMP_SIG_STRIDE(BMP_ENC_1BPP, 1);
    a[1] = 3;  /* width */
    a[2] = 8;  /* height */
    zx_font_put_u16le(&a[3], 8);
    a[5] = 0x40;
    a[6] = 0xA0;
    a[7] = 0xE0;
    a[8] = 0xA0;
    a[9] = 0xA0;
    a[10] = 0x00;
    a[11] = 0x00;
    a[12] = 0x00;

    /* 1bpp glyph 'B' (3x8), stride encoded in signature low nibble. */
    b = &zx_font_blob[ZX_FONT_GLYPH_B_OFFSET];
    b[0] = BMP_SIG_STRIDE(BMP_ENC_1BPP, 1);
    b[1] = 3;  /* width */
    b[2] = 8;  /* height */
    zx_font_put_u16le(&b[3], 8);
    b[5] = 0xC0;
    b[6] = 0xA0;
    b[7] = 0xC0;
    b[8] = 0xA0;
    b[9] = 0xC0;
    b[10] = 0x00;
    b[11] = 0x00;
    b[12] = 0x00;

    zx_font_blob_ready = 1;
}
#endif

static const uint8_t zx_stock_classic[] = {
    BMP_SIG_STRIDE(BMP_ENC_1BPP_MASK, 1), 8, 10, 20, 0,
    0b00111111, 0b00000000,
    0b00011111, 0b01000000,
    0b00001111, 0b01100000,
    0b00000111, 0b01110000,
    0b00000011, 0b01111000,
    0b00000001, 0b01111100,
    0b00000011, 0b01110000,
    0b00000011, 0b01011000,
    0b00100011, 0b00001000,
    0b11110111, 0b00000000,
    0x01, 0x01
};
static const uint8_t zx_stock_std[] = {
    BMP_SIG_STRIDE(BMP_ENC_1BPP_MASK, 1), 8, 10, 20, 0,
    0b11111111, 0b11000000,
    0b00011111, 0b10100000,
    0b00001111, 0b10010000,
    0b00000111, 0b10001000,
    0b00000011, 0b10000100,
    0b00000001, 0b10000010,
    0b00000011, 0b10001100,
    0b00000011, 0b10100100,
    0b10000011, 0b01100100,
    0b11100111, 0b00011000,
    0x01, 0x01
};
static const uint8_t zx_stock_hourglass[] = {
    BMP_SIG_STRIDE(BMP_ENC_1BPP_MASK, 1), 8, 10, 20, 0,
    0b00000001, 0b11111110,
    0b10000011, 0b01000100,
    0b10000011, 0b01010100,
    0b11000111, 0b00101000,
    0b11101111, 0b00010000,
    0b11000111, 0b00101000,
    0b10000011, 0b01000100,
    0b10000011, 0b01010100,
    0b00000001, 0b11111110,
    0b11111111, 0b00000000,
    0x03, 0x04
};
static const uint8_t zx_stock_caret[] = {
    BMP_SIG_STRIDE(BMP_ENC_1BPP_MASK, 1), 8, 10, 20, 0,
    0b00100111, 0b11011000,
    0b00000111, 0b10101000,
    0b00000111, 0b11011000,
    0b10001111, 0b01010000,
    0b10001111, 0b01010000,
    0b10001111, 0b01010000,
    0b10001111, 0b01010000,
    0b00000111, 0b11011000,
    0b00000111, 0b10101000,
    0b00100111, 0b11011000,
    0x01, 0x07
};
static const uint8_t zx_stock_hand[] = {
    BMP_SIG_STRIDE(BMP_ENC_1BPP_MASK, 1), 8, 10, 20, 0,
    0b11011111, 0b00100000,
    0b10001111, 0b01010000,
    0b10000011, 0b01011100,
    0b10000001, 0b01010110,
    0b00000000, 0b11010101,
    0b00000000, 0b10010101,
    0b00000000, 0b10000001,
    0b00000000, 0b10000001,
    0b10000001, 0b01000010,
    0b11000011, 0b00111100,
    0x02, 0x00
};

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
    zx_gpx.pages = 1;
    zx_gpx.text_background = GPX_TEXT_BG_OPAQUE;
    gpx_clrscr();
    return &zx_gpx;
}

void gpx_set_text_background(gpx_t *gpx, textbg background)
{
    if (gpx)
        gpx->text_background = (textbg)(background & 1);
}

void gpx_destroy(gpx_t *gpx)
{
    (void)gpx;
}

void gpx_set_page(uint8_t op, uint8_t page)
{
    (void)op;
    (void)page;
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
    uint16_t i;

    for (i = 0; i < ZX_SIZE; ++i) {
        screen[i] = 0;
#ifdef GPX_STUB_HOST
        ++zx_host_vram_writes;
#endif
    }

#ifndef GPX_STUB_HOST
    /* Match the backend contract: black ink on white paper, white border. */
    for (i = 0; i < ZX_ATTR_SIZE; ++i)
        screen[ZX_SIZE + i] = ZX_ATTR_DEFAULT;
    __asm__("ld a,#0x07\n\tout (#0xfe),a");
#endif
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


/* Narrow [lo,hi] to the range gpx_draw_pixel could possibly accept: the
 * screen, and the clip rect when there is one. This is an iteration bound
 * only -- every pattern phase below still refers to the caller's original
 * origin -- but it also keeps `coord` from wrapping when a caller passes
 * the extremes of the coordinate type. */
static int zx_span_bounds(
    coord lo, coord hi, coord limit,
    const coord *clip_lo, const coord *clip_hi,
    coord *out_lo, coord *out_hi)
{
    if (lo < 0)
        lo = 0;
    if (hi > limit)
        hi = limit;
    if (clip_lo != (const coord *)0) {
        if (*clip_lo > lo)
            lo = *clip_lo;
        if (*clip_hi < hi)
            hi = *clip_hi;
    }
    *out_lo = lo;
    *out_hi = hi;
    return lo <= hi;
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
        /* A swapped clip rect admits no coordinate at all, the same way
         * gpx_draw_pixel sees it. */
        if (clip->x0 > clip->x1 || clip->y0 > clip->y1)
            return original_lpatt;
        if (y < clip->y0 || y > clip->y1)
            return original_lpatt;
    }
    if (y < 0 || y >= ZX_HEIGHT)
        return original_lpatt;

    {
        coord xlo;
        coord xhi;
        if (!zx_span_bounds(x0, x1, ZX_WIDTH - 1,
                clip ? &clip->x0 : (const coord *)0,
                clip ? &clip->x1 : (const coord *)0, &xlo, &xhi))
            return original_lpatt;

        lpatt = zx_rotate_pattern_n(lpatt,
            (uint8_t)(((uint16_t)xlo - (uint16_t)x0) & 7));

        for (coord x = xlo; x <= xhi; ++x) {
            if (lpatt & 0x01)
                gpx_draw_pixel(gpx, x, y, c, m, clip);
            lpatt = zx_rotate_pattern(lpatt);
        }
    }

    return lpatt;
}

/* Line semantics: the segment is clipped up front (Cohen-Sutherland) against
 * the effective rect = clip ∩ screen (screen alone when clip is NULL), the
 * dash pattern is pre-rotated by the skipped major-axis distance, and the
 * clipped segment is then rasterized with NO per-pixel checks. A clip rect
 * with swapped corners draws nothing. The returned pattern is the rotation
 * state at the clipped end, so chained segments stay in phase. */
uint8_t gpx_draw_line(
    gpx_t *gpx, coord x0, coord y0, coord x1, coord y1,
    color c, bmode m, uint8_t lpatt, const rect_t *clip)
{
    coord ox0 = x0;
    coord oy0 = y0;
    coord ox1 = x1;
    coord oy1 = y1;
    uint8_t original_lpatt = lpatt;
    rect_t eff;
    int32_t odx;
    int32_t ody;
    int32_t skip;
    int dx;
    int sx;
    int dy;
    int sy;
    int err;
    int e2;

    if (x0 == x1 && y0 == y1) {
        if (lpatt & 0x01)
            gpx_draw_pixel(gpx, x0, y0, c, m, clip);
        return original_lpatt;
    }

    eff.x0 = 0;
    eff.y0 = 0;
    eff.x1 = ZX_WIDTH - 1;
    eff.y1 = ZX_HEIGHT - 1;
    if (clip) {
        if (clip->x0 > clip->x1 || clip->y0 > clip->y1)
            return original_lpatt;
        if (clip->x0 > eff.x0)
            eff.x0 = clip->x0;
        if (clip->y0 > eff.y0)
            eff.y0 = clip->y0;
        if (clip->x1 < eff.x1)
            eff.x1 = clip->x1;
        if (clip->y1 < eff.y1)
            eff.y1 = clip->y1;
        if (eff.x0 > eff.x1 || eff.y0 > eff.y1)
            return original_lpatt;
    }

    if (!zx_clip_line(&x0, &y0, &x1, &y1, &eff))
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

    while (1) {
        if (lpatt & 0x01)
            zx_set_pixel(x0, y0, c, m); /* pre-clipped: no per-pixel checks */
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
    if (rect.y1 != rect.y0)
        gpx_draw_hline(gpx, rect.x0, rect.x1, rect.y1, c, m, lpatt, clip);

    {
        coord ylo;
        coord yhi;
        if (zx_span_bounds(rect.y0, rect.y1, ZX_HEIGHT - 1,
                clip ? &clip->y0 : (const coord *)0,
                clip ? &clip->y1 : (const coord *)0, &ylo, &yhi)) {
            /* The two horizontal edges are already drawn. */
            if (ylo == rect.y0)
                ++ylo;
            if (yhi == rect.y1)
                --yhi;
            for (coord y = ylo; y <= yhi; ++y) {
                gpx_draw_pixel(gpx, rect.x0, y, c, m, clip);
                gpx_draw_pixel(gpx, rect.x1, y, c, m, clip);
            }
        }
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

    {
        coord ylo;
        coord yhi;
        coord xlo;
        coord xhi;
        if (!zx_span_bounds(rect.y0, rect.y1, ZX_HEIGHT - 1,
                clip ? &clip->y0 : (const coord *)0,
                clip ? &clip->y1 : (const coord *)0, &ylo, &yhi))
            return;
        if (!zx_span_bounds(rect.x0, rect.x1, ZX_WIDTH - 1,
                clip ? &clip->x0 : (const coord *)0,
                clip ? &clip->x1 : (const coord *)0, &xlo, &xhi))
            return;

        for (coord y = ylo; y <= yhi; ++y) {
            uint8_t pattern =
                fpatt[((uint16_t)y - (uint16_t)rect.y0) % fpatt_len];
            for (coord x = xlo; x <= xhi; ++x) {
                uint8_t mask = (uint8_t)(0x80 >>
                    (((uint16_t)x - (uint16_t)rect.x0) & 7));
                if (pattern & mask)
                    gpx_draw_pixel(gpx, x, y, c, m, clip);
            }
        }
    }
}

/* --- advanced primitives -------------------------------------------
 * The midpoint circle stepper, mirroring src/common. Both the outline and
 * the fill walk the same octant, so the fill's row spans are exactly the
 * ones the outline lands on. Every pixel and every row is emitted once,
 * which is what keeps BM_XOR meaningful.
 */

void gpx_draw_circle(
    gpx_t *gpx, coord x, coord y, coord r,
    color c, bmode m, const rect_t *clip)
{
    coord xn = 0;
    coord yn = r;
    int16_t f;
    int16_t ddx;
    int16_t ddy;

    if (r < 0)
        return;
    if (r == 0) {
        gpx_draw_pixel(gpx, x, y, c, m, clip);
        return;
    }

    gpx_draw_pixel(gpx, x, (coord)(y + r), c, m, clip);
    gpx_draw_pixel(gpx, x, (coord)(y - r), c, m, clip);
    gpx_draw_pixel(gpx, (coord)(x + r), y, c, m, clip);
    gpx_draw_pixel(gpx, (coord)(x - r), y, c, m, clip);

    f = (int16_t)(1 - r);
    ddx = 1;
    ddy = (int16_t)(-2 * r);

    while (xn < yn) {
        ++xn;
        ddx += 2;
        f += ddx;
        if (f >= 0) {
            --yn;
            ddy += 2;
            f += ddy;
        }
        if (xn <= yn) {
            gpx_draw_pixel(gpx, (coord)(x + xn), (coord)(y + yn), c, m, clip);
            gpx_draw_pixel(gpx, (coord)(x - xn), (coord)(y + yn), c, m, clip);
            gpx_draw_pixel(gpx, (coord)(x + xn), (coord)(y - yn), c, m, clip);
            gpx_draw_pixel(gpx, (coord)(x - xn), (coord)(y - yn), c, m, clip);
        }
        /* On the diagonal the swapped four are the same four pixels. */
        if (xn < yn) {
            gpx_draw_pixel(gpx, (coord)(x + yn), (coord)(y + xn), c, m, clip);
            gpx_draw_pixel(gpx, (coord)(x - yn), (coord)(y + xn), c, m, clip);
            gpx_draw_pixel(gpx, (coord)(x + yn), (coord)(y - xn), c, m, clip);
            gpx_draw_pixel(gpx, (coord)(x - yn), (coord)(y - xn), c, m, clip);
        }
    }
}

/* One row of the disc, as the one-row rectangle the backend fills. The
 * pattern byte is picked by the row's distance from the top of the
 * bounding box and rotated so its MSB still lands on the box's left edge,
 * which is what makes a filled circle line up with a filled rectangle. */
static void zx_circle_row(
    gpx_t *gpx, coord x, coord y, coord r, coord dy, coord w,
    color c, bmode m, uint8_t *fpatt, uint8_t fpatt_len, const rect_t *clip)
{
    rect_t row;
    uint8_t byte = fpatt[(uint16_t)(dy + r) % fpatt_len];
    uint8_t rot = (uint8_t)((uint16_t)(r - w) & 7);
    uint8_t rotated = rot
        ? (uint8_t)((uint8_t)(byte << rot) | (uint8_t)(byte >> (8 - rot)))
        : byte;

    row.x0 = (coord)(x - w);
    row.x1 = (coord)(x + w);
    row.y0 = (coord)(y + dy);
    row.y1 = row.y0;
    gpx_fill_rectangle(gpx, &row, c, m, &rotated, 1, clip);
}

static void zx_circle_row_pair(
    gpx_t *gpx, coord x, coord y, coord r, coord dy, coord w,
    color c, bmode m, uint8_t *fpatt, uint8_t fpatt_len, const rect_t *clip)
{
    zx_circle_row(gpx, x, y, r, dy, w, c, m, fpatt, fpatt_len, clip);
    zx_circle_row(gpx, x, y, r, (coord)(-dy), w, c, m, fpatt, fpatt_len, clip);
}

void gpx_fill_circle(
    gpx_t *gpx, coord x, coord y, coord r,
    color c, bmode m,
    uint8_t *fpatt, uint8_t fpatt_len, const rect_t *clip)
{
    coord xn = 0;
    coord yn = r;
    int16_t f;
    int16_t ddx;
    int16_t ddy;

    if (r < 0 || fpatt_len == 0)
        return;

    zx_circle_row(gpx, x, y, r, 0, r, c, m, fpatt, fpatt_len, clip);
    if (r == 0)
        return;

    f = (int16_t)(1 - r);
    ddx = 1;
    ddy = (int16_t)(-2 * r);

    while (xn < yn) {
        ++xn;
        ddx += 2;
        f += ddx;
        if (f >= 0) {
            /* yn is as wide as it will get: the xn from before this step */
            zx_circle_row_pair(gpx, x, y, r, yn, (coord)(xn - 1),
                c, m, fpatt, fpatt_len, clip);
            --yn;
            ddy += 2;
            f += ddy;
        }
        if (xn <= yn)
            zx_circle_row_pair(gpx, x, y, r, xn, yn,
                c, m, fpatt, fpatt_len, clip);
    }
}

/* Polygons. The edge walker steps the same Bresenham gpx_draw_line uses,
 * so a span ends where the outline is drawn; an edge the polygon traverses
 * upwards is walked downwards here and takes the opposite rounding bias,
 * which reproduces the reversed walk exactly. */

typedef struct zx_edge_s
{
    coord y1;
    coord dx;
    coord dy;
    coord err;
    coord cx;
    coord cy;
    coord lo;
    coord hi;
    int8_t sx;
} zx_edge_t;

void gpx_draw_polygon(
    gpx_t *gpx, point_t *pts, uint8_t n,
    color c, bmode m, uint8_t lpatt, const rect_t *clip)
{
    uint8_t i;
    uint8_t j;

    if (pts == (point_t *)0 || n < 2)
        return;

    for (i = 0, j = 1; i < n; ++i, j = (uint8_t)((j + 1) % n))
        lpatt = gpx_draw_line(gpx, pts[i].x, pts[i].y, pts[j].x, pts[j].y,
            c, m, lpatt, clip);
}

/* One edge, normalized top to bottom. Horizontal edges get no walker: they
 * contribute no crossing, and the edges meeting them carry the row. */
static int zx_edge_init(zx_edge_t *e, const point_t *a, const point_t *b)
{
    int flipped = 0;
    coord v;
    coord pix;
    coord piy;
    coord pjx;
    coord pjy;

    /* Taken through locals rather than by-value point_t parameters: the
     * Z80 compiler and the host compiler do not agree on struct passing,
     * and this oracle has to mean the same thing in both. */
    pix = a->x;
    piy = a->y;
    pjx = b->x;
    pjy = b->y;

    if (piy > pjy) {
        coord t = pix; pix = pjx; pjx = t;
        t = piy; piy = pjy; pjy = t;
        flipped = 1;
    }
    if (piy == pjy)
        return 0;

    e->y1 = pjy;
    e->dy = (coord)(pjy - piy);
    e->dx = (coord)(pjx >= pix ? pjx - pix : pix - pjx);
    e->sx = (int8_t)(pjx > pix ? 1 : (pjx < pix ? -1 : 0));
    v = (coord)(e->dx > e->dy ? e->dx : e->dy);
    if (flipped)
        --v;
    v = (coord)(v >> 1);
    e->err = (coord)(e->dx > e->dy ? v : -v);
    e->cx = pix;
    e->cy = piy;
    return 1;
}

static void zx_edge_step(zx_edge_t *e)
{
    coord e2 = e->err;

    if (e2 > (coord)(-e->dx)) {
        e->err = (coord)(e2 - e->dy);
        e->cx = (coord)(e->cx + e->sx);
    }
    if (e2 < e->dy) {
        e->err = (coord)(e->err + e->dx);
        ++e->cy;
    }
}

/* The run this edge paints on scanline y, or 0 if it does not reach it.
 * Half-open y0 <= y < y1 keeps a shared vertex from counting twice; on the
 * polygon's own bottom row the rule closes so the bottom edge is filled. */
/* The run is left in e->lo / e->hi rather than written through pointer
 * parameters: the Z80 compiler does not pass a five-argument call the way
 * the host one does, and this oracle has to mean the same thing in both. */
static int zx_edge_run(zx_edge_t *e, coord y, int lastrow)
{
    coord oldy;

    if (y < e->cy)
        return 0;
    if (lastrow ? (y > e->y1) : (y >= e->y1))
        return 0;

    while (e->cy < y)
        zx_edge_step(e);

    e->lo = e->cx;
    e->hi = e->cx;
    for (;;) {
        oldy = e->cy;
        zx_edge_step(e);
        if (e->cy != oldy)
            break;
        if (e->cx < e->lo)
            e->lo = e->cx;
        if (e->cx > e->hi)
            e->hi = e->cx;
    }
    return 1;
}

/* File scope, not locals: the tables are a few hundred bytes and the Z80
 * compiler addresses a frame that large through one-byte IX offsets, which
 * silently wraps. The library's own assembler version walks them with
 * cursors instead, so only the oracle needs this. */
static zx_edge_t zx_poly_edges[GPX_MAX_POLY_PTS];
static coord zx_poly_lo[GPX_MAX_POLY_PTS];
static coord zx_poly_hi[GPX_MAX_POLY_PTS];

void gpx_fill_polygon(
    gpx_t *gpx, point_t *pts, uint8_t n,
    color c, bmode m,
    uint8_t *fpatt, uint8_t fpatt_len, const rect_t *clip)
{
    zx_edge_t *edges = zx_poly_edges;
    coord *lo = zx_poly_lo;
    coord *hi = zx_poly_hi;
    uint8_t nedges = 0;
    uint8_t patt_idx = 0;
    coord ymin;
    coord ymax;
    coord xmin;
    coord y;
    uint8_t i;
    uint8_t j;

    if (pts == (point_t *)0 || n < 3 || n > GPX_MAX_POLY_PTS
            || fpatt_len == 0 || fpatt == (uint8_t *)0)
        return;

    ymin = ymax = pts[0].y;
    xmin = pts[0].x;
    for (i = 0, j = 1; i < n; ++i, j = (uint8_t)((j + 1) % n)) {
        if (pts[i].x < xmin)
            xmin = pts[i].x;
        if (pts[i].y < ymin)
            ymin = pts[i].y;
        if (pts[i].y > ymax)
            ymax = pts[i].y;
        if (zx_edge_init(&edges[nedges], &pts[i], &pts[j]))
            ++nedges;
    }
    if (nedges == 0)
        return;

    for (y = ymin; y <= ymax; ++y) {
        uint8_t k = 0;
        coord prev_end = -32768;

        for (i = 0; i < nedges; ++i) {
            if (zx_edge_run(&edges[i], y, y == ymax)) {
                lo[k] = edges[i].lo;
                hi[k] = edges[i].hi;
                ++k;
            }
        }

        /* selection sort by the low x */
        for (i = 0; i + 1 < k; ++i) {
            uint8_t mn = i;
            for (j = (uint8_t)(i + 1); j < k; ++j)
                if (lo[j] < lo[mn])
                    mn = j;
            if (mn != i) {
                coord t = lo[i]; lo[i] = lo[mn]; lo[mn] = t;
                t = hi[i]; hi[i] = hi[mn]; hi[mn] = t;
            }
        }

        for (i = 0; (uint8_t)(i + 1) < k; i = (uint8_t)(i + 2)) {
            coord x0 = lo[i];
            coord x1 = hi[i + 1];
            uint8_t byte;
            uint8_t rev;
            uint8_t rot;
            uint8_t b;

            /* two spans can meet on a shared vertex pixel: leave it to the
             * first, so BM_XOR does not cancel it */
            if (x0 <= prev_end)
                x0 = (coord)(prev_end + 1);
            if (x0 > x1)
                continue;
            prev_end = x1;

            byte = fpatt[patt_idx];
            rev = 0;
            for (b = 0; b < 8; ++b) {
                rev = (uint8_t)((rev << 1) | (byte & 1));
                byte = (uint8_t)(byte >> 1);
            }
            rot = (uint8_t)((uint16_t)(x0 - xmin) & 7);
            if (rot)
                rev = (uint8_t)((rev >> rot) | (rev << (8 - rot)));
            gpx_draw_line(gpx, x0, y, x1, y, c, m, rev, clip);
        }

        if (++patt_idx >= fpatt_len)
            patt_idx = 0;
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
        view->w = raw[1];
        view->h = raw[2];
        view->stride = BMP_STRIDE(raw[0]);
        view->size = (uint16_t)(raw[3] | ((uint16_t)raw[4] << 8));
        view->bitmap = &raw[5];
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
            uint8_t byte;
            uint8_t mask = (uint8_t)(0x80 >> (col & 7));
            if (view.signature == BMP_SIG(BMP_ENC_1BPP_MASK)) {
                uint16_t masked_row = (uint16_t)(row * view.stride * 2);
                uint8_t and_byte = view.bitmap[masked_row + (uint16_t)(col >> 3)];
                uint8_t or_byte =
                    view.bitmap[masked_row + view.stride + (uint16_t)(col >> 3)];
                if (!(and_byte & mask)) {
                    gpx_draw_pixel(gpx, (coord)(x + (coord)col), (coord)(y + (coord)row),
                        (or_byte & mask) ? CO_FORE : CO_BACK, BM_CPY, cl);
                } else if (or_byte & mask) {
                    gpx_draw_pixel(gpx, (coord)(x + (coord)col), (coord)(y + (coord)row),
                        CO_FORE, BM_CPY, cl);
                }
                continue;
            }

            byte = view.bitmap[row_offset + (uint16_t)(col >> 3)];
            if (byte & mask) {
                gpx_draw_pixel(gpx, (coord)(x + (coord)col), (coord)(y + (coord)row),
                    CO_FORE, BM_CPY, cl);
            }
        }
    }
}

static void zx_draw_bmp_mode(
    gpx_t *gpx, coord x, coord y, bmp_t *b,
    color c, bmode m, int transparent, const rect_t *clip)
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
            int bit = (byte & mask) != 0;
            coord px = (coord)(x + (coord)col);
            coord py = (coord)(y + (coord)row);
            if (m & 1) {
                /* BM_XOR: flip only the source set bits (DRAWMODE 3). */
                if (bit)
                    gpx_draw_pixel(gpx, px, py, c, m, cl);
            } else if (transparent) {
                /* Transparent copy: source set bits take the text color;
                 * source zeroes preserve the destination. */
                if (bit)
                    gpx_draw_pixel(gpx, px, py, c, BM_CPY, cl);
            } else {
                /* BM_CPY mode-aware (DRAWMODE 1/2): OPAQUE copy of the source
                 * bits over the glyph width -- zero bits are written too, not
                 * left transparent. CO_FORE => pixel = bit; CO_BACK => !bit. */
                int setpix = (c & 1) ? bit : !bit;
                gpx_draw_pixel(gpx, px, py,
                    (color)(setpix ? CO_FORE : CO_BACK), BM_CPY, cl);
            }
        }
    }
}

static void zx_capture_sprite_background(sprite_t *sprite, uint8_t w, uint8_t h)
{
    uint8_t x = (uint8_t)sprite->x;
    uint8_t y = (uint8_t)sprite->y;
    uint8_t *bg = (uint8_t *)sprite->background;
    uint8_t *screen = zx_screen();
    uint16_t row;

    for (row = 0; row < h; ++row) {
        uint16_t col;
        uint16_t bg_row = (uint16_t)row << 1;
        for (col = 0; col < w; ++col) {
            uint16_t off = zx_screen_offset((coord)(x + (uint8_t)col), (coord)(y + (uint8_t)row));
            uint8_t src_mask = (uint8_t)(0x80 >> ((x + (uint8_t)col) & 7));
            uint8_t dst_mask = (uint8_t)(0x80 >> (col & 7));
            if (screen[off] & src_mask)
                bg[5 + bg_row + (uint16_t)(col >> 3)] |= dst_mask;
        }
    }
}

static void zx_restore_sprite_background(sprite_t *sprite)
{
    const uint8_t *bg = (const uint8_t *)sprite->background;
    uint16_t row;
    uint8_t w;
    uint8_t h;

    if (!sprite || !sprite->background)
        return;

    w = bg[1];
    h = bg[2];

    for (row = 0; row < h; ++row) {
        uint16_t col;
        uint16_t bg_row = (uint16_t)row << 1;
        coord py = (coord)(sprite->y + (coord)row);
        if (py >= ZX_HEIGHT)
            break;
        for (col = 0; col < w; ++col) {
            coord px = (coord)(sprite->x + (coord)col);
            uint8_t byte;
            uint8_t mask = (uint8_t)(0x80 >> (col & 7));
            if (px >= ZX_WIDTH)
                break;
            byte = bg[5 + bg_row + (uint16_t)(col >> 3)];
            zx_set_pixel(
                px,
                py,
                (byte & mask) ? CO_FORE : CO_BACK,
                BM_CPY);
        }
    }
}

void gpx_show_sprite(gpx_t *gpx, sprite_t *sprite)
{
    zx_bmp_view_t view;
    uint16_t i;
    uint8_t visw;
    uint8_t vish;

    if (!sprite || !sprite->bitmap || !sprite->background)
        return;
    if (!zx_parse_bmp(sprite->bitmap, &view))
        return;
    if (view.w == 0 || view.h == 0 || view.w > 16 || view.h > 16 || view.stride > 2)
        return;
    if (sprite->x < 0 || sprite->y < 0 || sprite->x >= ZX_WIDTH || sprite->y >= ZX_HEIGHT)
        return;

    visw = (uint8_t)view.w;
    if ((int)sprite->x + (int)view.w > ZX_WIDTH)
        visw = (uint8_t)(ZX_WIDTH - (int)sprite->x);

    vish = (uint8_t)view.h;
    if ((int)sprite->y + (int)view.h > ZX_HEIGHT)
        vish = (uint8_t)(ZX_HEIGHT - (int)sprite->y);

    sprite->background->signature = BMP_SIG_STRIDE(BMP_ENC_1BPP, 2);
    sprite->background->w = (uint8_t)view.w;
    sprite->background->h = (uint8_t)view.h;
    sprite->background->size = (uint16_t)(view.h << 1);
    for (i = GPX_SPRITE_BG_HEADER_SIZE; i < GPX_SPRITE_BG_SIZE; ++i)
        ((uint8_t *)sprite->background)[i] = 0;

    zx_capture_sprite_background(sprite, visw, vish);
    gpx_draw_bmp(gpx, sprite->x, sprite->y, sprite->bitmap, sprite->clip);
}

void gpx_hide_sprite(gpx_t *gpx, sprite_t *sprite)
{
    (void)gpx;
    zx_restore_sprite_background(sprite);
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
        return (bmp_t *)zx_stock_classic;
    case GPXSB_CURSOR_STD:
        return (bmp_t *)zx_stock_std;
    case GPXSB_CURSOR_HOURGLASS:
        return (bmp_t *)zx_stock_hourglass;
    case GPXSB_CURSOR_CARET:
        return (bmp_t *)zx_stock_caret;
    case GPXSB_CURSOR_HAND:
        return (bmp_t *)zx_stock_hand;
    default:
        return (bmp_t *)0;
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

/* Fill an inter-character / missing-glyph gap with the inverse text color. */
static void zx_text_gap(
    gpx_t *gpx, coord x, coord y, uint8_t w, uint8_t h,
    color c, const rect_t *clip)
{
    rect_t r;
    uint8_t solid = 0xFF;
    color inv = (color)((c ^ 1) & 1);

    if (w == 0 || h == 0)
        return;
    r.x0 = x;
    r.y0 = y;
    r.x1 = (coord)(x + (coord)w - 1);
    r.y1 = (coord)(y + (coord)h - 1);
    gpx_fill_rectangle(gpx, &r, inv, BM_CPY, &solid, 1, clip);
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
    uint8_t glyph_height;
    int transparent;

    if (text == (const char *)0 || font == (const font_t *)0)
        return;

    empty_width = fraw[3];
    glyph_height = fraw[5];
    advance = fraw[6];
    transparent = gpx &&
        gpx->text_background == GPX_TEXT_BG_TRANSPARENT;

    while (*text) {
        uint8_t ch = (uint8_t)*text;
        const uint8_t *glyph = zx_font_glyph_ptr(font, ch);
        uint16_t gw = zx_glyph_width(glyph);

        if (gw == 0) {
            /* BM_XOR never fills the spacing: the gap fill is an opaque
             * write, so filling it would stop a second identical draw from
             * restoring the display. Partner leaves the gap alone too. */
            if (!transparent && m != BM_XOR)
                zx_text_gap(gpx, xcur, y, empty_width, glyph_height, c, clip);
            xcur = (coord)(xcur + empty_width);
            ++text;
            continue;
        }

        zx_draw_bmp_mode(gpx, xcur, y, (bmp_t *)glyph, c, m,
            transparent, clip);
        xcur = (coord)(xcur + (coord)gw);
        if (!transparent && m != BM_XOR)
            zx_text_gap(gpx, xcur, y, advance, glyph_height, c, clip);
        xcur = (coord)(xcur + advance);
        ++text;
    }
}
