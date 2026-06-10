#include "libgpx.h"

/* Fills whose rectangles extend past the screen edges (negative / >255 / >191).
 * Exercises the screen-clamp path and pattern-phase alignment relative to the
 * unclipped origin. All regions are DISJOINT: a patterned CPY fill replaces its
 * covered byte-span, so overlapping patterned fills would diverge from the
 * set-only reference (see project notes on patterned-CPY span replacement). */
void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    uint8_t p2[2] = {0xAA, 0x55};
    uint8_t p3[3] = {0xFF, 0x18, 0x81};
    uint8_t pf = 0xFF;

    /* spans left edge (x0 negative) -> tests x-phase vs negative origin */
    rect_t l = {-10, 10, 30, 16};
    gpx_fill_rectangle(gpx, &l, CO_FORE, BM_CPY, p3, 3, (const rect_t *)0);

    /* spans right edge (x1 > 255) */
    rect_t r = {240, 20, 270, 26};
    gpx_fill_rectangle(gpx, &r, CO_FORE, BM_CPY, p3, 3, (const rect_t *)0);

    /* spans top edge (y0 negative) -> tests pattern index vs negative origin */
    rect_t t = {40, -5, 55, 8};
    gpx_fill_rectangle(gpx, &t, CO_FORE, BM_CPY, p2, 2, (const rect_t *)0);

    /* spans bottom edge (y1 > 191) */
    rect_t b = {40, 180, 55, 200};
    gpx_fill_rectangle(gpx, &b, CO_FORE, BM_CPY, p2, 2, (const rect_t *)0);

    /* fully off-screen -> nothing */
    rect_t off = {-50, -50, -10, -10};
    gpx_fill_rectangle(gpx, &off, CO_FORE, BM_CPY, &pf, 1, (const rect_t *)0);

    /* off-screen rect with a clip, solid (isolated rows) */
    rect_t big = {-20, 100, 280, 110};
    rect_t clip = {30, 103, 220, 107};
    gpx_fill_rectangle(gpx, &big, CO_FORE, BM_CPY, &pf, 1, &clip);

    __asm
        halt
    __endasm;
}
