#include "zxtest.h"

/* Cohen-Sutherland region coverage: a fixed clip window, with line
 * endpoints placed in each of the nine regions around it, in every pairing.
 * That covers both-inside, one-inside, trivially-rejected, and the awkward
 * both-outside-but-crossing cases on all four edges and corners. */
void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    rect_t clip = {64, 48, 191, 143};
    /* One representative point per region, in reading order. */
    static const coord px[9] = {30, 128, 225, 30, 128, 225, 30, 128, 225};
    static const coord py[9] = {20, 20, 20, 96, 96, 96, 172, 172, 172};
    uint8_t a, b;

    for (a = 0; a < 9; ++a)
        for (b = 0; b < 9; ++b)
            gpx_draw_line(gpx, px[a], py[a], px[b], py[b],
                CO_FORE, BM_CPY, 0xFF, &clip);

    /* Lines that graze exactly along each clip edge, and just outside it. */
    gpx_draw_line(gpx, 0, 48, 255, 48, CO_FORE, BM_CPY, 0xFF, &clip);
    gpx_draw_line(gpx, 0, 47, 255, 47, CO_FORE, BM_CPY, 0xFF, &clip);
    gpx_draw_line(gpx, 0, 143, 255, 143, CO_FORE, BM_CPY, 0xFF, &clip);
    gpx_draw_line(gpx, 0, 144, 255, 144, CO_FORE, BM_CPY, 0xFF, &clip);
    gpx_draw_line(gpx, 64, 0, 64, 191, CO_FORE, BM_CPY, 0xFF, &clip);
    gpx_draw_line(gpx, 63, 0, 63, 191, CO_FORE, BM_CPY, 0xFF, &clip);
    gpx_draw_line(gpx, 191, 0, 191, 191, CO_FORE, BM_CPY, 0xFF, &clip);
    gpx_draw_line(gpx, 192, 0, 192, 191, CO_FORE, BM_CPY, 0xFF, &clip);

    /* Exactly the clip corners. */
    gpx_draw_line(gpx, 64, 48, 64, 48, CO_FORE, BM_CPY, 0xFF, &clip);
    gpx_draw_line(gpx, 191, 143, 191, 143, CO_FORE, BM_CPY, 0xFF, &clip);
    gpx_draw_line(gpx, 63, 47, 63, 47, CO_FORE, BM_CPY, 0xFF, &clip);
    gpx_draw_line(gpx, 192, 144, 192, 144, CO_FORE, BM_CPY, 0xFF, &clip);

    TEST_END();
}
