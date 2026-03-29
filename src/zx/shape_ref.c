#include "libgpx.h"

static void rect_normalize_local(rect_t *r)
{
    coord t;
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

void gpx_draw_rectangle_ref(
    gpx_t *gpx, rect_t *r,
    color c, bmode m, uint8_t lpatt, const rect_t *clip)
{
    rect_t rect;
    coord y;

    if (r == (rect_t *)0)
        return;

    rect = *r;
    rect_normalize_local(&rect);

    gpx_draw_line(gpx, rect.x0, rect.y0, rect.x1, rect.y0, c, m, lpatt, clip);
    gpx_draw_line(gpx, rect.x0, rect.y1, rect.x1, rect.y1, c, m, lpatt, clip);

    for (y = (coord)(rect.y0 + 1); y < rect.y1; ++y) {
        gpx_draw_pixel(gpx, rect.x0, y, c, m, clip);
        gpx_draw_pixel(gpx, rect.x1, y, c, m, clip);
    }
}

void gpx_fill_rectangle_ref(
    gpx_t *gpx, rect_t *r,
    color c, bmode m,
    uint8_t *fpatt, uint8_t fpatt_len, const rect_t *clip)
{
    rect_t rect;
    coord y;

    if (r == (rect_t *)0 || fpatt_len == 0)
        return;

    rect = *r;
    rect_normalize_local(&rect);

    for (y = rect.y0; y <= rect.y1; ++y) {
        uint8_t pattern = fpatt[(uint8_t)((y - rect.y0) % fpatt_len)];
        coord x;
        for (x = rect.x0; x <= rect.x1; ++x) {
            uint8_t mask = (uint8_t)(0x80 >> ((x - rect.x0) & 7));
            if (pattern & mask)
                gpx_draw_pixel(gpx, x, y, c, m, clip);
        }
    }
}
