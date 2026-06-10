#include "libgpx.h"

/* Lines in all 8 octants from a common center, solid. */
void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    rect_t full = {0, 0, 255, 191};
    coord cx = 80, cy = 80;

    gpx_draw_line(gpx, cx, cy, cx + 40, cy + 10, CO_FORE, BM_CPY, 0xFF, &full);
    gpx_draw_line(gpx, cx, cy, cx + 10, cy + 40, CO_FORE, BM_CPY, 0xFF, &full);
    gpx_draw_line(gpx, cx, cy, cx - 10, cy + 40, CO_FORE, BM_CPY, 0xFF, &full);
    gpx_draw_line(gpx, cx, cy, cx - 40, cy + 10, CO_FORE, BM_CPY, 0xFF, &full);
    gpx_draw_line(gpx, cx, cy, cx - 40, cy - 10, CO_FORE, BM_CPY, 0xFF, &full);
    gpx_draw_line(gpx, cx, cy, cx - 10, cy - 40, CO_FORE, BM_CPY, 0xFF, &full);
    gpx_draw_line(gpx, cx, cy, cx + 10, cy - 40, CO_FORE, BM_CPY, 0xFF, &full);
    gpx_draw_line(gpx, cx, cy, cx + 40, cy - 10, CO_FORE, BM_CPY, 0xFF, &full);

    /* exact diagonals */
    gpx_draw_line(gpx, 10, 120, 50, 160, CO_FORE, BM_CPY, 0xFF, &full);
    gpx_draw_line(gpx, 50, 120, 10, 160, CO_FORE, BM_CPY, 0xFF, &full);

    /* degenerate */
    gpx_draw_line(gpx, 200, 100, 200, 100, CO_FORE, BM_CPY, 0xFF, &full);
    gpx_draw_line(gpx, 201, 100, 201, 100, CO_FORE, BM_CPY, 0x00, &full);

    __asm
        halt
    __endasm;
}
