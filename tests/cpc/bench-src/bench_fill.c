#include "bench.h"

BENCH_MAIN()

/* Rectangle fills: the whole-screen solid case that dominates UI repaint,
 * patterned fills, clipped fills and XOR fills, then many small fills to
 * expose per-call overhead rather than per-byte throughput. */
void bench_body(gpx_t *gpx)
{
    static uint8_t solid[1] = {0xFF};
    static uint8_t dash[2] = {0xAA, 0x55};
    static uint8_t p5[5] = {0xF0, 0xE1, 0xC3, 0x87, 0x0F};
    dim w = gpx_width(), h = gpx_height();
    rect_t clip, r;
    uint8_t i;

    clip.x0 = (coord)(w / 8); clip.y0 = 40;
    clip.x1 = (coord)(w - w / 8); clip.y1 = 151;

    r.x0 = 0; r.y0 = 0; r.x1 = (coord)(w - 1); r.y1 = (coord)(h - 1);
    for (i = 0; i < 4; ++i)
        gpx_fill_rectangle(gpx, &r, CO_FORE, BM_CPY, solid, 1, 0);
    for (i = 0; i < 4; ++i)
        gpx_fill_rectangle(gpx, &r, CO_BACK, BM_CPY, solid, 1, 0);
    for (i = 0; i < 4; ++i)
        gpx_fill_rectangle(gpx, &r, CO_FORE, BM_CPY, dash, 2, 0);
    for (i = 0; i < 4; ++i)
        gpx_fill_rectangle(gpx, &r, CO_FORE, BM_XOR, p5, 5, 0);
    for (i = 0; i < 4; ++i)
        gpx_fill_rectangle(gpx, &r, CO_FORE, BM_CPY, p5, 5, &clip);

    for (i = 0; i < 60; ++i) {
        r.x0 = (coord)(i * 3);
        r.y0 = (coord)(i * 2);
        r.x1 = (coord)(r.x0 + 11);
        r.y1 = (coord)(r.y0 + 7);
        gpx_fill_rectangle(gpx, &r, CO_FORE, BM_CPY, solid, 1, 0);
    }
}
