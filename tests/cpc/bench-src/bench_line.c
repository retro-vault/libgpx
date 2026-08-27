#include "bench.h"

BENCH_MAIN()

/* Lines: axis-parallel runs through the span path, then diagonals in every
 * octant through Bresenham, then clipped and patterned variants. */
void bench_body(gpx_t *gpx)
{
    dim w = gpx_width(), h = gpx_height();
    rect_t clip;
    coord i;

    clip.x0 = (coord)(w / 8); clip.y0 = 30;
    clip.x1 = (coord)(w - w / 8); clip.y1 = 170;

    for (i = 0; i < 60; ++i)
        gpx_draw_line(gpx, 0, (coord)(i * 3), (coord)(w - 1), (coord)(i * 3),
                      CO_FORE, BM_CPY, 0xFF, 0);
    for (i = 0; i < 60; ++i)
        gpx_draw_line(gpx, (coord)(i * 3), 0, (coord)(i * 3), (coord)(h - 1),
                      CO_FORE, BM_CPY, 0xFF, 0);
    for (i = 0; i < 30; ++i)
        gpx_draw_line(gpx, 0, 0, (coord)(w - 1), (coord)(i * 6),
                      CO_FORE, BM_CPY, 0xFF, 0);
    for (i = 0; i < 30; ++i)
        gpx_draw_line(gpx, (coord)(w - 1), 0, 0, (coord)(i * 6),
                      CO_FORE, BM_CPY, 0xAA, 0);
    for (i = 0; i < 30; ++i)
        gpx_draw_line(gpx, 0, (coord)(h - 1), (coord)(w - 1), (coord)(i * 6),
                      CO_FORE, BM_CPY, 0xFF, &clip);

    /* Steep diagonals. Every family above has dx > dy and so runs the
     * x-major raster; without these the y-major one is never measured. The
     * x span straddles zero so both x directions are covered. */
    for (i = 0; i < 30; ++i)
        gpx_draw_line(gpx, (coord)(w / 2), 0,
                      (coord)(w / 2 + (i - 15) * 4), (coord)(h - 1),
                      CO_FORE, BM_CPY, 0xFF, 0);
}
