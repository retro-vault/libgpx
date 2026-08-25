#include "bench.h"

BENCH_MAIN()

/* Lines on all three raster paths, solid and dashed, clipped and not. */
void bench_body(gpx_t *gpx)
{
    rect_t clip = {40, 40, 215, 151};
    coord i;

    /* Horizontal: the byte-span path, full width. */
    for (i = 0; i < 192; ++i)
        gpx_draw_line(gpx, 0, i, 255, i, CO_FORE, BM_CPY, 0xFF,
            (const rect_t *)0);

    /* Horizontal, dashed. */
    for (i = 0; i < 192; ++i)
        gpx_draw_line(gpx, 0, i, 255, i, CO_FORE, BM_CPY, 0xAA,
            (const rect_t *)0);

    /* Vertical. */
    for (i = 0; i < 256; ++i)
        gpx_draw_line(gpx, i, 0, i, 191, CO_FORE, BM_CPY, 0xFF,
            (const rect_t *)0);

    /* Shallow and steep diagonals. */
    for (i = 0; i < 64; ++i) {
        gpx_draw_line(gpx, 0, (coord)(i * 3), 255, (coord)(191 - i * 3),
            CO_FORE, BM_CPY, 0xFF, (const rect_t *)0);
        gpx_draw_line(gpx, (coord)(i * 4), 0, (coord)(255 - i * 4), 191,
            CO_FORE, BM_CPY, 0xFF, (const rect_t *)0);
    }

    /* Clipped diagonals: the Cohen-Sutherland front end plus rasterisation. */
    for (i = 0; i < 64; ++i)
        gpx_draw_line(gpx, -100, (coord)(i * 5 - 50), 400,
            (coord)(300 - i * 5), CO_FORE, BM_CPY, 0xFF, &clip);

    /* Fully rejected lines: the early-out cost. */
    for (i = 0; i < 200; ++i)
        gpx_draw_line(gpx, -500, -500, -400, -400, CO_FORE, BM_CPY, 0xFF,
            (const rect_t *)0);
}
