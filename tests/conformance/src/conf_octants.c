/* Cross-backend conformance: line direction coverage.
 *
 * conf_lines draws every line left-to-right, which leaves half of a
 * Bresenham implementation untested. This scenario walks a fan through all
 * eight octants so both x directions and both y directions are drawn, in
 * both the x-major and y-major rasters, solid and patterned, clipped and
 * unclipped.
 *
 * That matters most on the CPC, whose raster is specialised on exactly
 * those axes: the x-major loop is chosen per x direction and display mode,
 * the y-major loop per y direction and display mode, giving eight loop
 * bodies that only a fan like this one reaches.
 *
 * Everything stays inside 256x192 so the rasters can be compared directly.
 */
#include "libgpx.h"

/* The CPC has two display modes behind one library and is compared in both;
 * every other backend accepts this and ignores it. */
#ifndef DEMO_MODE
#define DEMO_MODE GPXM_DEFAULT
#endif

uint8_t gdp_finished;
#define phase() __asm__("halt")
#define done()  do { gdp_finished = 0xA5; __asm__("halt"); } while (0)

/* A full turn from one centre. Each ray leaves the centre outwards, so the
 * eight octants are drawn as eight distinct directions rather than as four
 * lines drawn twice. */
static void fan(gpx_t *gpx, coord cx, coord cy, coord rx, coord ry,
                uint8_t patt, rect_t *clip)
{
    coord i;

    for (i = 0; i <= 8; i++) {
        coord dx = (coord)(rx - i * (2 * rx / 8));
        coord dy = (coord)(ry - i * (2 * ry / 8));

        /* right/left pairs cover both x directions at this slope, and the
         * two y offsets cover both y directions. */
        gpx_draw_line(gpx, cx, cy, (coord)(cx + rx), (coord)(cy + dy),
                      CO_FORE, BM_CPY, patt, clip);
        gpx_draw_line(gpx, cx, cy, (coord)(cx - rx), (coord)(cy + dy),
                      CO_FORE, BM_CPY, patt, clip);
        gpx_draw_line(gpx, cx, cy, (coord)(cx + dx), (coord)(cy + ry),
                      CO_FORE, BM_CPY, patt, clip);
        gpx_draw_line(gpx, cx, cy, (coord)(cx + dx), (coord)(cy - ry),
                      CO_FORE, BM_CPY, patt, clip);
    }
}

void main(void)
{
    gpx_t *gpx = gpx_create(DEMO_MODE);

    /* --- solid fan: every octant, x-major and y-major, both rasters --- */
    gpx_clrscr();
    fan(gpx, 120, 92, 110, 85, 0xFF, 0);
    phase();

    /* --- the same fan patterned: the pattern must stay in phase across a
     *     byte boundary in every direction --- */
    gpx_clrscr();
    fan(gpx, 120, 92, 110, 85, 0xAA, 0);
    phase();

    /* --- steep rays only, so the y-major raster carries the whole phase in
     *     both y directions --- */
    gpx_clrscr();
    {
        coord i;
        for (i = 0; i <= 10; i++) {
            coord x = (coord)(120 + (i - 5) * 5);
            gpx_draw_line(gpx, 120, 96, x, 4, CO_FORE, BM_CPY, 0xFF, 0);
            gpx_draw_line(gpx, 120, 96, x, 188, CO_FORE, BM_CPY, 0xE4, 0);
        }
    }
    phase();

    /* --- clipped fan: the pre-rotation of a clipped pattern has to agree
     *     in every direction too --- */
    gpx_clrscr();
    {
        static rect_t win = {40, 40, 200, 150};
        gpx_draw_rectangle(gpx, &win, CO_FORE, BM_CPY, 0xFF, 0);
        fan(gpx, 120, 92, 110, 85, 0xAA, &win);
    }
    done();
}
