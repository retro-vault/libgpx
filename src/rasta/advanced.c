/* Native raster algorithms, adapted from the libgpx conformance oracle.
 * GPL2 License (see: LICENSE), Copyright (C) 2026 tomaz stih. */
#include "rasta_internal.h"

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
    int32_t xn = 0;
    int32_t yn = r;
    int32_t f;
    int32_t ddx;
    int32_t ddy;

    if (r < 0)
        return;
    if (r == 0) {
        rasta_pixel(gpx, x, y, c, m, clip);
        return;
    }

    rasta_pixel(gpx, x, (int32_t)(y + r), c, m, clip);
    rasta_pixel(gpx, x, (int32_t)(y - r), c, m, clip);
    rasta_pixel(gpx, (int32_t)(x + r), y, c, m, clip);
    rasta_pixel(gpx, (int32_t)(x - r), y, c, m, clip);

    f = (int32_t)(1 - r);
    ddx = 1;
    ddy = (int32_t)(-2 * r);

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
            rasta_pixel(gpx, (int32_t)(x + xn), (int32_t)(y + yn), c, m, clip);
            rasta_pixel(gpx, (int32_t)(x - xn), (int32_t)(y + yn), c, m, clip);
            rasta_pixel(gpx, (int32_t)(x + xn), (int32_t)(y - yn), c, m, clip);
            rasta_pixel(gpx, (int32_t)(x - xn), (int32_t)(y - yn), c, m, clip);
        }
        /* On the diagonal the swapped four are the same four pixels. */
        if (xn < yn) {
            rasta_pixel(gpx, (int32_t)(x + yn), (int32_t)(y + xn), c, m, clip);
            rasta_pixel(gpx, (int32_t)(x - yn), (int32_t)(y + xn), c, m, clip);
            rasta_pixel(gpx, (int32_t)(x + yn), (int32_t)(y - xn), c, m, clip);
            rasta_pixel(gpx, (int32_t)(x - yn), (int32_t)(y - xn), c, m, clip);
        }
    }
}

/* One row of the disc, as the one-row rectangle the backend fills. The
 * pattern byte is picked by the row's distance from the top of the
 * bounding box and rotated so its MSB still lands on the box's left edge,
 * which is what makes a filled circle line up with a filled rectangle. */
static void rasta_circle_row(
    gpx_t *gpx, int32_t x, int32_t y, int32_t r, int32_t dy, int32_t w,
    color c, bmode m, uint8_t *fpatt, uint8_t fpatt_len, const rect_t *clip)
{
    uint8_t byte = fpatt[(dy + r) % fpatt_len];
    rasta_pattern_span(gpx, x - w, x + w, y + dy,
        x - r, byte, c, m, clip);
}

static void rasta_circle_row_pair(
    gpx_t *gpx, int32_t x, int32_t y, int32_t r, int32_t dy, int32_t w,
    color c, bmode m, uint8_t *fpatt, uint8_t fpatt_len, const rect_t *clip)
{
    rasta_circle_row(gpx, x, y, r, dy, w, c, m, fpatt, fpatt_len, clip);
    rasta_circle_row(gpx, x, y, r, (int32_t)(-dy), w, c, m, fpatt, fpatt_len, clip);
}

void gpx_fill_circle(
    gpx_t *gpx, coord x, coord y, coord r,
    color c, bmode m,
    uint8_t *fpatt, uint8_t fpatt_len, const rect_t *clip)
{
    int32_t xn = 0;
    int32_t yn = r;
    int32_t f;
    int32_t ddx;
    int32_t ddy;

    if (r < 0 || !fpatt || fpatt_len == 0)
        return;

    rasta_circle_row(gpx, x, y, r, 0, r, c, m, fpatt, fpatt_len, clip);
    if (r == 0)
        return;

    f = (int32_t)(1 - r);
    ddx = 1;
    ddy = (int32_t)(-2 * r);

    while (xn < yn) {
        ++xn;
        ddx += 2;
        f += ddx;
        if (f >= 0) {
            /* yn is as wide as it will get: the xn from before this step */
            rasta_circle_row_pair(gpx, x, y, r, yn, (int32_t)(xn - 1),
                c, m, fpatt, fpatt_len, clip);
            --yn;
            ddy += 2;
            f += ddy;
        }
        if (xn <= yn)
            rasta_circle_row_pair(gpx, x, y, r, xn, yn,
                c, m, fpatt, fpatt_len, clip);
    }
}

/* Polygons. The edge walker steps the same Bresenham gpx_draw_line uses,
 * so a span ends where the outline is drawn; an edge the polygon traverses
 * upwards is walked downwards here and takes the opposite rounding bias,
 * which reproduces the reversed walk exactly. */

typedef struct rasta_edge_s
{
    int32_t y1;
    int32_t dx;
    int32_t dy;
    int32_t err;
    int32_t cx;
    int32_t cy;
    int32_t lo;
    int32_t hi;
    int8_t sx;
} rasta_edge_t;

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
static int rasta_edge_init(rasta_edge_t *e, const point_t *a, const point_t *b)
{
    int flipped = 0;
    int32_t v;
    int32_t pix;
    int32_t piy;
    int32_t pjx;
    int32_t pjy;

    /* Normalize in widened locals so full-range endpoints cannot wrap. */
    pix = a->x;
    piy = a->y;
    pjx = b->x;
    pjy = b->y;

    if (piy > pjy) {
        int32_t t = pix; pix = pjx; pjx = t;
        t = piy; piy = pjy; pjy = t;
        flipped = 1;
    }
    if (piy == pjy)
        return 0;

    e->y1 = pjy;
    e->dy = (int32_t)(pjy - piy);
    e->dx = (int32_t)(pjx >= pix ? pjx - pix : pix - pjx);
    e->sx = (int8_t)(pjx > pix ? 1 : (pjx < pix ? -1 : 0));
    v = (int32_t)(e->dx > e->dy ? e->dx : e->dy);
    if (flipped)
        --v;
    v = (int32_t)(v >> 1);
    e->err = (int32_t)(e->dx > e->dy ? v : -v);
    e->cx = pix;
    e->cy = piy;
    return 1;
}

static void rasta_edge_step(rasta_edge_t *e)
{
    int32_t e2 = e->err;

    if (e2 > (int32_t)(-e->dx)) {
        e->err = (int32_t)(e2 - e->dy);
        e->cx = (int32_t)(e->cx + e->sx);
    }
    if (e2 < e->dy) {
        e->err = (int32_t)(e->err + e->dx);
        ++e->cy;
    }
}

/* The run this edge paints on scanline y, or 0 if it does not reach it.
 * Half-open y0 <= y < y1 keeps a shared vertex from counting twice; on the
 * polygon's own bottom row the rule closes so the bottom edge is filled. */
/* Leave the inclusive crossing run in e->lo / e->hi. */
static int rasta_edge_run(rasta_edge_t *e, int32_t y, int lastrow)
{
    int32_t oldy;

    if (y < e->cy)
        return 0;
    if (lastrow ? (y > e->y1) : (y >= e->y1))
        return 0;

    while (e->cy < y)
        rasta_edge_step(e);

    e->lo = e->cx;
    e->hi = e->cx;
    for (;;) {
        oldy = e->cy;
        rasta_edge_step(e);
        if (e->cy != oldy)
            break;
        if (e->cx < e->lo)
            e->lo = e->cx;
        if (e->cx > e->hi)
            e->hi = e->cx;
    }
    return 1;
}

void gpx_fill_polygon(
    gpx_t *gpx, point_t *pts, uint8_t n,
    color c, bmode m,
    uint8_t *fpatt, uint8_t fpatt_len, const rect_t *clip)
{
    rasta_edge_t edges[GPX_MAX_POLY_PTS];
    int32_t lo[GPX_MAX_POLY_PTS];
    int32_t hi[GPX_MAX_POLY_PTS];
    uint8_t nedges = 0;
    uint8_t patt_idx = 0;
    int32_t ymin;
    int32_t ymax;
    int32_t xmin;
    int32_t y;
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
        if (rasta_edge_init(&edges[nedges], &pts[i], &pts[j]))
            ++nedges;
    }
    if (nedges == 0)
        return;

    y = ymin < 0 ? 0 : ymin;
    if (clip && y < clip->y0) y = clip->y0;
    patt_idx = (uint8_t)((y - ymin) % fpatt_len);
    for (; y <= ymax && y < RASTA_HEIGHT; ++y) {
        if (clip && y > clip->y1) break;
        uint8_t k = 0;
        int32_t prev_end = INT32_MIN;

        for (i = 0; i < nedges; ++i) {
            if (rasta_edge_run(&edges[i], y, y == ymax)) {
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
                int32_t t = lo[i]; lo[i] = lo[mn]; lo[mn] = t;
                t = hi[i]; hi[i] = hi[mn]; hi[mn] = t;
            }
        }

        for (i = 0; (uint8_t)(i + 1) < k; i = (uint8_t)(i + 2)) {
            int32_t x0 = lo[i];
            int32_t x1 = hi[i + 1];
            /* Disjoint spans make shared vertices safe under XOR. */
            if (x0 <= prev_end)
                x0 = prev_end + 1;
            if (x0 > x1)
                continue;
            prev_end = x1;
            rasta_pattern_span(gpx, x0, x1, y, xmin,
                fpatt[patt_idx], c, m, clip);
        }

        if (++patt_idx >= fpatt_len)
            patt_idx = 0;
    }
}
