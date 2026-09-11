/* Native raster algorithms, adapted from the libgpx conformance oracle.
 * GPL2 License (see: LICENSE), Copyright (C) 2026 tomaz stih. */
#include "rasta_internal.h"

static uint8_t rasta_rotate_pattern(uint8_t lpatt)
{
    return (uint8_t)((lpatt >> 1) | (lpatt << 7));
}

static uint8_t rasta_rotate_pattern_n(uint8_t lpatt, uint8_t n)
{
    while (n-- > 0)
        lpatt = rasta_rotate_pattern(lpatt);
    return lpatt;
}

static int32_t rasta_abs32(int32_t v)
{
    return (v < 0) ? -v : v;
}

#define RASTA_OC_LEFT   0x01
#define RASTA_OC_RIGHT  0x02
#define RASTA_OC_TOP    0x04
#define RASTA_OC_BOTTOM 0x08

static uint8_t rasta_outcode(int32_t x, int32_t y, const rect_t *clip)
{
    uint8_t code = 0;
    if (x < clip->x0)
        code |= RASTA_OC_LEFT;
    else if (x > clip->x1)
        code |= RASTA_OC_RIGHT;

    if (y < clip->y0)
        code |= RASTA_OC_TOP;
    else if (y > clip->y1)
        code |= RASTA_OC_BOTTOM;
    return code;
}

static int rasta_clip_line(
    coord *x0, coord *y0, coord *x1, coord *y1,
    const rect_t *clip)
{
    int64_t ax0 = *x0;
    int64_t ay0 = *y0;
    int64_t ax1 = *x1;
    int64_t ay1 = *y1;

    while (1) {
        uint8_t c0 = rasta_outcode(ax0, ay0, clip);
        uint8_t c1 = rasta_outcode(ax1, ay1, clip);
        uint8_t out;
        int64_t nx = 0;
        int64_t ny = 0;

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
        if (out & RASTA_OC_TOP) {
            if (ay1 == ay0)
                return 0;
            ny = clip->y0;
            nx = ax0 + (ax1 - ax0) * (ny - ay0) / (ay1 - ay0);
        } else if (out & RASTA_OC_BOTTOM) {
            if (ay1 == ay0)
                return 0;
            ny = clip->y1;
            nx = ax0 + (ax1 - ax0) * (ny - ay0) / (ay1 - ay0);
        } else if (out & RASTA_OC_RIGHT) {
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
static int rasta_span_bounds(
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
        else if (m == BM_CPY)
            gpx_draw_pixel(gpx, x0, y0,
                (color)((c ^ 1u) & 1u), BM_CPY, clip);
        return original_lpatt;
    }

    eff.x0 = 0;
    eff.y0 = 0;
    eff.x1 = RASTA_WIDTH - 1;
    eff.y1 = RASTA_HEIGHT - 1;
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

    if (!rasta_clip_line(&x0, &y0, &x1, &y1, &eff))
        return original_lpatt;

    odx = rasta_abs32((int32_t)ox1 - (int32_t)ox0);
    ody = rasta_abs32((int32_t)oy1 - (int32_t)oy0);
    if (odx >= ody)
        skip = rasta_abs32((int32_t)x0 - (int32_t)ox0);
    else
        skip = rasta_abs32((int32_t)y0 - (int32_t)oy0);
    lpatt = rasta_rotate_pattern_n(lpatt, (uint8_t)(skip & 7));

    dx = x1 > x0 ? x1 - x0 : x0 - x1;
    sx = x0 < x1 ? 1 : -1;
    dy = y1 > y0 ? y1 - y0 : y0 - y1;
    sy = y0 < y1 ? 1 : -1;
    err = (dx > dy ? dx : -dy) / 2;

    while (1) {
        if (lpatt & 0x01)
            rasta_pixel(gpx, x0, y0, c, m, NULL); /* pre-clipped: no per-pixel checks */
        else if (m == BM_CPY)
            rasta_pixel(gpx, x0, y0,
                (color)((c ^ 1u) & 1u), BM_CPY, NULL);
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
        lpatt = rasta_rotate_pattern(lpatt);
    }

    return lpatt;
}

void gpx_fill_rectangle(
    gpx_t *gpx, rect_t *r,
    color c, bmode m,
    uint8_t *fpatt, uint8_t fpatt_len, const rect_t *clip)
{
    if (!fpatt || fpatt_len == 0)
        return;

    if (!r)
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
        if (!rasta_span_bounds(rect.y0, rect.y1, RASTA_HEIGHT - 1,
                clip ? &clip->y0 : (const coord *)0,
                clip ? &clip->y1 : (const coord *)0, &ylo, &yhi))
            return;
        if (!rasta_span_bounds(rect.x0, rect.x1, RASTA_WIDTH - 1,
                clip ? &clip->x0 : (const coord *)0,
                clip ? &clip->x1 : (const coord *)0, &xlo, &xhi))
            return;

        for (coord y = ylo; y <= yhi; ++y) {
            uint8_t pattern =
                fpatt[((int32_t)y - rect.y0) % fpatt_len];
            for (coord x = xlo; x <= xhi; ++x) {
                uint8_t mask = (uint8_t)(0x80 >>
                    (((uint16_t)x - (uint16_t)rect.x0) & 7));
                if (m == BM_CPY)
                    gpx_draw_pixel(gpx, x, y,
                        (pattern & mask) ? c : (color)((c ^ 1u) & 1u),
                        BM_CPY, clip);
                else if (pattern & mask)
                    gpx_draw_pixel(gpx, x, y, c, m, clip);
            }
        }
    }
}
