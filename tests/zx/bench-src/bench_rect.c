#include "bench.h"

BENCH_MAIN()

/* Rectangle outlines, solid and dashed, clipped and not. */
void bench_body(gpx_t *gpx)
{
    rect_t clip = {40, 40, 215, 151};
    rect_t r;
    uint8_t i;

    for (i = 0; i < 80; ++i) {
        r.x0 = (coord)i;
        r.y0 = (coord)i;
        r.x1 = (coord)(255 - i);
        r.y1 = (coord)(191 - i);
        gpx_draw_rectangle(gpx, &r, CO_FORE, BM_CPY, 0xFF,
            (const rect_t *)0);
    }
    for (i = 0; i < 80; ++i) {
        r.x0 = (coord)i;
        r.y0 = (coord)i;
        r.x1 = (coord)(255 - i);
        r.y1 = (coord)(191 - i);
        gpx_draw_rectangle(gpx, &r, CO_FORE, BM_CPY, 0xAA, &clip);
    }
    for (i = 0; i < 100; ++i) {
        r.x0 = (coord)(i + 4);
        r.y0 = (coord)(i);
        r.x1 = (coord)(r.x0 + 9);
        r.y1 = (coord)(r.y0 + 5);
        gpx_draw_rectangle(gpx, &r, CO_FORE, BM_XOR, 0xFF,
            (const rect_t *)0);
    }
}
