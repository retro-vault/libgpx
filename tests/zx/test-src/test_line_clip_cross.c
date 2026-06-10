#include "libgpx.h"

/* Lines crossing a clip rectangle. All crossing lines are solid: a patterned
 * hline in BM_CPY replaces its whole covered byte span (clears gaps), whereas
 * the reference only sets pattern-1 pixels, so overlapping patterned CPY lines
 * legitimately differ. Pattern phase is covered separately over empty fields.
 * Diagonals that cross the boundary use exact 45-degree slopes. */
void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    rect_t clip = {40, 40, 80, 70};

    /* horizontal/vertical through the clip (hline/vline clip is exact) */
    gpx_draw_line(gpx, 0, 55, 120, 55, CO_FORE, BM_CPY, 0xFF, &clip);
    gpx_draw_line(gpx, 60, 0, 60, 120, CO_FORE, BM_CPY, 0xFF, &clip);

    /* exact 45-degree diagonals crossing the boundary */
    gpx_draw_line(gpx, 20, 20, 110, 110, CO_FORE, BM_CPY, 0xFF, &clip);
    gpx_draw_line(gpx, 110, 20, 20, 110, CO_FORE, BM_CPY, 0xFF, &clip);

    /* fully inside (no clipping of the diagonal) */
    gpx_draw_line(gpx, 45, 45, 75, 65, CO_FORE, BM_CPY, 0xFF, &clip);
    gpx_draw_line(gpx, 75, 45, 45, 65, CO_FORE, BM_CPY, 0xFF, &clip);

    /* fully outside (rejected) */
    gpx_draw_line(gpx, 0, 0, 30, 30, CO_FORE, BM_CPY, 0xFF, &clip);
    gpx_draw_line(gpx, 100, 100, 200, 150, CO_FORE, BM_CPY, 0xFF, &clip);

    __asm
        halt
    __endasm;
}
