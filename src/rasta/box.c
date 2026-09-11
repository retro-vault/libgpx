/* Selected-edge, XOR-safe box outlines for the native Rasta backend. */
#include "libgpx.h"

static uint8_t rotate_pattern(uint8_t pattern, uint8_t count)
{
    count &= 7;
    while (count-- != 0)
        pattern = (uint8_t)((pattern >> 1) | (pattern << 7));
    return pattern;
}

static uint8_t axis_length_mod8(coord x0, coord y0, coord x1, coord y1)
{
    uint16_t distance;

    if (x0 != x1)
        distance = x0 < x1 ?
            (uint16_t)((uint16_t)x1 - (uint16_t)x0) :
            (uint16_t)((uint16_t)x0 - (uint16_t)x1);
    else
        distance = y0 < y1 ?
            (uint16_t)((uint16_t)y1 - (uint16_t)y0) :
            (uint16_t)((uint16_t)y0 - (uint16_t)y1);
    return (uint8_t)((distance + 1u) & 7u);
}

static uint8_t draw_edge(
    gpx_t *gpx, coord x0, coord y0, coord x1, coord y1,
    color c, bmode m, uint8_t pattern, const rect_t *clip)
{
    (void)gpx_draw_line(gpx, x0, y0, x1, y1, c, m, pattern, clip);
    return rotate_pattern(pattern, axis_length_mod8(x0, y0, x1, y1));
}

uint8_t gpx_draw_box(
    gpx_t *gpx, const rect_t *r, uint8_t edges,
    color c, bmode m, uint8_t lpatt, const rect_t *clip)
{
    rect_t box;
    coord t;

    edges &= GPX_EDGE_ALL;
    if (!r || !edges)
        return lpatt;
    box = *r;
    if (box.x0 > box.x1) {
        t = box.x0;
        box.x0 = box.x1;
        box.x1 = t;
    }
    if (box.y0 > box.y1) {
        t = box.y0;
        box.y0 = box.y1;
        box.y1 = t;
    }

    if (box.x0 == box.x1 && box.y0 == box.y1)
        return draw_edge(gpx, box.x0, box.y0, box.x0, box.y0,
            c, m, lpatt, clip);

    if (box.y0 == box.y1) {
        if (edges & (GPX_EDGE_TOP | GPX_EDGE_BOTTOM))
            return draw_edge(gpx, box.x0, box.y0, box.x1, box.y0,
                c, m, lpatt, clip);
        if (edges & GPX_EDGE_LEFT)
            lpatt = draw_edge(gpx, box.x0, box.y0, box.x0, box.y0,
                c, m, lpatt, clip);
        if (edges & GPX_EDGE_RIGHT)
            lpatt = draw_edge(gpx, box.x1, box.y0, box.x1, box.y0,
                c, m, lpatt, clip);
        return lpatt;
    }

    if (box.x0 == box.x1) {
        if (edges & (GPX_EDGE_LEFT | GPX_EDGE_RIGHT))
            return draw_edge(gpx, box.x0, box.y0, box.x0, box.y1,
                c, m, lpatt, clip);
        if (edges & GPX_EDGE_TOP)
            lpatt = draw_edge(gpx, box.x0, box.y0, box.x0, box.y0,
                c, m, lpatt, clip);
        if (edges & GPX_EDGE_BOTTOM)
            lpatt = draw_edge(gpx, box.x0, box.y1, box.x0, box.y1,
                c, m, lpatt, clip);
        return lpatt;
    }

    if (edges & GPX_EDGE_TOP)
        lpatt = draw_edge(gpx, box.x0, box.y0, box.x1, box.y0,
            c, m, lpatt, clip);
    if (edges & GPX_EDGE_RIGHT)
        lpatt = draw_edge(
            gpx, box.x1,
            (coord)(box.y0 + ((edges & GPX_EDGE_TOP) != 0)),
            box.x1, box.y1, c, m, lpatt, clip);
    if (edges & GPX_EDGE_BOTTOM)
        lpatt = draw_edge(
            gpx, (coord)(box.x1 - ((edges & GPX_EDGE_RIGHT) != 0)),
            box.y1, box.x0, box.y1, c, m, lpatt, clip);
    if (edges & GPX_EDGE_LEFT) {
        coord start = (coord)(box.y1 - ((edges & GPX_EDGE_BOTTOM) != 0));
        coord end = (coord)(box.y0 + ((edges & GPX_EDGE_TOP) != 0));
        if (start >= end)
            lpatt = draw_edge(gpx, box.x0, start, box.x0, end,
                c, m, lpatt, clip);
    }
    return lpatt;
}

void gpx_draw_rectangle(
    gpx_t *gpx, rect_t *r,
    color c, bmode m, uint8_t lpatt, const rect_t *clip)
{
    (void)gpx_draw_box(gpx, r, GPX_EDGE_ALL, c, m, lpatt, clip);
}
