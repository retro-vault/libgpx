/* Lines in every octant, plus the four hardware vector styles and one
 * software pattern, so both the EF9367 vector path and the Bresenham
 * fallback in _gpx_bresenham_line.s are exercised. */
#include "gdptest.h"

static const coord cx = 300;
static const coord cy = 120;

void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    static const signed char dir[8][2] = {
        {1, 0}, {1, 1}, {0, 1}, {-1, 1},
        {-1, 0}, {-1, -1}, {0, -1}, {1, -1}
    };
    uint8_t i;

    gpx_clrscr();

    /* Eight radial spokes: every octant through the delta-command encoder. */
    for (i = 0; i < 8; i++)
        gpx_draw_line(gpx, cx, cy,
                      (coord)(cx + dir[i][0] * 200),
                      (coord)(cy + dir[i][1] * 100),
                      CO_FORE, BM_CPY, 0xFF, 0);

    /* Shallow and steep slopes either side of the diagonal. */
    gpx_draw_line(gpx, 600, 10, 1000, 60, CO_FORE, BM_CPY, 0xFF, 0);
    gpx_draw_line(gpx, 600, 60, 1000, 10, CO_FORE, BM_CPY, 0xFF, 0);
    gpx_draw_line(gpx, 620, 200, 660, 250, CO_FORE, BM_CPY, 0xFF, 0);
    gpx_draw_line(gpx, 700, 250, 740, 200, CO_FORE, BM_CPY, 0xFF, 0);
    gdp_phase();

    gpx_clrscr();
    /* Hardware CR2 styles: solid, dotted, dashed, dot-dash. */
    gpx_draw_line(gpx, 20, 20, 900, 20, CO_FORE, BM_CPY, 0xFF, 0);
    gpx_draw_line(gpx, 20, 50, 900, 50, CO_FORE, BM_CPY, 0xAA, 0);
    gpx_draw_line(gpx, 20, 80, 900, 80, CO_FORE, BM_CPY, 0xF0, 0);
    gpx_draw_line(gpx, 20, 110, 900, 110, CO_FORE, BM_CPY, 0xE4, 0);
    /* Unrecognised pattern: falls through to the software Bresenham path. */
    gpx_draw_line(gpx, 20, 140, 900, 140, CO_FORE, BM_CPY, 0x9B, 0);
    gpx_draw_line(gpx, 20, 170, 500, 250, CO_FORE, BM_CPY, 0x9B, 0);
    gdp_phase();

    gpx_clrscr();
    /* A long vector needing the >255 delta split, and a degenerate point. */
    gpx_draw_line(gpx, 0, 0, 1000, 250, CO_FORE, BM_CPY, 0xFF, 0);
    gpx_draw_line(gpx, 0, 250, 1000, 0, CO_FORE, BM_CPY, 0xFF, 0);
    gpx_draw_line(gpx, 500, 125, 500, 125, CO_FORE, BM_CPY, 0xFF, 0);
    gdp_done();
}
