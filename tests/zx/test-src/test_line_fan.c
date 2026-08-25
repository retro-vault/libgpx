#include "zxtest.h"

/* A dense fan from one centre: 96 rays sweep every octant and every
 * slope class, including the four axes and the four exact diagonals.
 * Endpoints are generated so both raster majors (x-major and y-major)
 * and both step directions are exercised for each. */
void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    coord cx = 128, cy = 96;
    coord dx, dy;
    uint8_t i;

    /* 25 rays per quadrant: dy runs 0..r while dx runs r..0, so the slope
     * sweeps continuously from horizontal through 45 degrees to vertical.
     * All four quadrants get the same sweep, which covers every octant and
     * both raster majors in both step directions. */
    for (i = 0; i <= 24; ++i) {
        dx = (coord)(96 - (i * 4));
        dy = (coord)(i * 4);

        gpx_draw_line(gpx, cx, cy, (coord)(cx + dx), (coord)(cy + dy),
            CO_FORE, BM_CPY, 0xFF, (const rect_t *)0);
        gpx_draw_line(gpx, cx, cy, (coord)(cx - dx), (coord)(cy + dy),
            CO_FORE, BM_CPY, 0xFF, (const rect_t *)0);
        gpx_draw_line(gpx, cx, cy, (coord)(cx + dx), (coord)(cy - dy),
            CO_FORE, BM_CPY, 0xFF, (const rect_t *)0);
        gpx_draw_line(gpx, cx, cy, (coord)(cx - dx), (coord)(cy - dy),
            CO_FORE, BM_CPY, 0xFF, (const rect_t *)0);
    }

    /* The same rays drawn end-to-start: a solid line must be symmetric, so
     * redrawing it backwards may not light a single extra pixel. */
    for (i = 0; i <= 24; ++i) {
        dx = (coord)(96 - (i * 4));
        dy = (coord)(i * 4);
        gpx_draw_line(gpx, (coord)(cx + dx), (coord)(cy + dy), cx, cy,
            CO_FORE, BM_CPY, 0xFF, (const rect_t *)0);
        gpx_draw_line(gpx, (coord)(cx - dx), (coord)(cy - dy), cx, cy,
            CO_FORE, BM_CPY, 0xFF, (const rect_t *)0);
    }

    /* Degenerate: a line of length zero is one pixel; with an empty
     * pattern it is none. */
    gpx_draw_line(gpx, 10, 180, 10, 180, CO_FORE, BM_CPY, 0xFF,
        (const rect_t *)0);
    gpx_draw_line(gpx, 12, 180, 12, 180, CO_FORE, BM_CPY, 0x00,
        (const rect_t *)0);
    gpx_draw_line(gpx, 14, 180, 14, 180, CO_FORE, BM_CPY, 0x01,
        (const rect_t *)0);

    TEST_END();
}
