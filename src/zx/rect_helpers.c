#include "libgpx.h"

uint8_t _rect_cmp16s_lt(coord a, coord b)
{
    return (a < b) ? 1u : 0u;
}

uint8_t rect_contains(const rect_t *r, const point_t *p)
{
    if (!r || !p)
        return 0u;

    if (p->x < r->x0 || p->x > r->x1)
        return 0u;
    if (p->y < r->y0 || p->y > r->y1)
        return 0u;

    return 1u;
}

void rect_normalize(rect_t *r)
{
    coord t;

    if (!r)
        return;

    if (r->x0 > r->x1) {
        t = r->x0;
        r->x0 = r->x1;
        r->x1 = t;
    }

    if (r->y0 > r->y1) {
        t = r->y0;
        r->y0 = r->y1;
        r->y1 = t;
    }
}

rect_t *rect_intersect(const rect_t *a, const rect_t *b, rect_t *out)
{
    if (!a || !b || !out)
        return (rect_t *)0;

    out->x0 = (a->x0 > b->x0) ? a->x0 : b->x0;
    out->y0 = (a->y0 > b->y0) ? a->y0 : b->y0;
    out->x1 = (a->x1 < b->x1) ? a->x1 : b->x1;
    out->y1 = (a->y1 < b->y1) ? a->y1 : b->y1;

    if (out->x0 > out->x1 || out->y0 > out->y1)
        return (rect_t *)0;

    return out;
}
