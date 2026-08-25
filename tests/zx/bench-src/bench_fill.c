#include "bench.h"

BENCH_MAIN()

/* Rectangle fills: the solid whole-screen case that dominates UI repaint,
 * patterned fills, clipped fills and XOR fills. */
void bench_body(gpx_t *gpx)
{
    static uint8_t solid[1] = {0xFF};
    static uint8_t dash[2] = {0xAA, 0x55};
    static uint8_t p5[5] = {0xF0, 0xE1, 0xC3, 0x87, 0x0F};
    rect_t clip = {40, 40, 215, 151};
    rect_t r;
    uint8_t i;

    r.x0 = 0; r.y0 = 0; r.x1 = 255; r.y1 = 191;
    for (i = 0; i < 4; ++i)
        gpx_fill_rectangle(gpx, &r, CO_FORE, BM_CPY, solid, 1,
            (const rect_t *)0);
    for (i = 0; i < 4; ++i)
        gpx_fill_rectangle(gpx, &r, CO_BACK, BM_CPY, solid, 1,
            (const rect_t *)0);
    for (i = 0; i < 4; ++i)
        gpx_fill_rectangle(gpx, &r, CO_FORE, BM_CPY, dash, 2,
            (const rect_t *)0);
    for (i = 0; i < 4; ++i)
        gpx_fill_rectangle(gpx, &r, CO_FORE, BM_XOR, p5, 5,
            (const rect_t *)0);
    for (i = 0; i < 4; ++i)
        gpx_fill_rectangle(gpx, &r, CO_FORE, BM_CPY, p5, 5, &clip);

    /* Many small fills: per-call overhead rather than per-byte throughput. */
    for (i = 0; i < 60; ++i) {
        r.x0 = (coord)(i * 3);
        r.y0 = (coord)(i * 2);
        r.x1 = (coord)(r.x0 + 11);
        r.y1 = (coord)(r.y0 + 7);
        gpx_fill_rectangle(gpx, &r, CO_FORE, BM_CPY, solid, 1,
            (const rect_t *)0);
    }
}
