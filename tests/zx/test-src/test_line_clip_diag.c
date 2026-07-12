#include "libgpx.h"

/* Non-45-degree diagonals crossing clip edges, far off-screen endpoints,
 * beyond-screen and swapped clip rects, NULL-clip screen clipping, XOR over
 * a clipped crossing, and dash-pattern chaining across a clipped segment.
 * All of these resolve through the Cohen-Sutherland pre-clip + intersection
 * division path, which the older tests never reached (they only used
 * trivial-accept or exact H/V/45 cases). Real backend and oracle stub run
 * the same algorithm, so every case here must match byte-for-byte. */
void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    rect_t clip = {60, 40, 140, 100};
    rect_t tall = {30, 20, 50, 170};
    rect_t offscr = {-40, -30, 300, 250};   /* eff = whole screen */
    rect_t swapped = {120, 80, 40, 30};     /* draws nothing */
    rect_t empty = {300, 200, 320, 220};    /* off-screen: nothing */
    uint8_t p;

    /* shallow diagonals crossing left/right edges (x-major, both dirs) */
    gpx_draw_line(gpx, 20, 50, 200, 90, CO_FORE, BM_CPY, 0xFF, &clip);
    gpx_draw_line(gpx, 200, 45, 20, 95, CO_FORE, BM_CPY, 0xFF, &clip);

    /* steep diagonals crossing top/bottom edges (y-major, both dirs) */
    gpx_draw_line(gpx, 90, 10, 120, 130, CO_FORE, BM_CPY, 0xFF, &clip);
    gpx_draw_line(gpx, 130, 130, 100, 10, CO_FORE, BM_CPY, 0xFF, &clip);

    /* corner-crossing diagonal (clips on two edges) */
    gpx_draw_line(gpx, 30, 20, 190, 120, CO_FORE, BM_CPY, 0xFF, &clip);

    /* far off-screen endpoints, tall window (intersection division) */
    gpx_draw_line(gpx, -3000, -2000, 250, 180, CO_FORE, BM_CPY, 0xFF, &tall);
    gpx_draw_line(gpx, 40, -500, 40, 500, CO_FORE, BM_CPY, 0xFF, &tall);

    /* clip larger than the screen: effective rect is the screen */
    gpx_draw_line(gpx, -20, 150, 300, 170, CO_FORE, BM_CPY, 0xFF, &offscr);

    /* NULL clip with off-screen endpoints: clipped to the screen */
    gpx_draw_line(gpx, -50, 185, 310, 155, CO_FORE, BM_CPY, 0xFF, (rect_t *)0);

    /* swapped / fully off-screen clips draw nothing */
    gpx_draw_line(gpx, 0, 0, 255, 191, CO_FORE, BM_CPY, 0xFF, &swapped);
    gpx_draw_line(gpx, 0, 0, 255, 191, CO_FORE, BM_CPY, 0xFF, &empty);

    /* XOR line crossing the clip twice over an already-set diagonal */
    gpx_draw_line(gpx, 20, 50, 200, 90, CO_FORE, BM_XOR, 0xFF, &clip);

    /* patterned clipped diagonal: phase must match an unclipped draw */
    gpx_draw_line(gpx, 50, 108, 210, 148, CO_FORE, BM_CPY, 0xAA, &clip);
    gpx_draw_line(gpx, 50, 110, 210, 150, CO_FORE, BM_CPY, 0x81, &clip);

    /* chain the returned pattern across a clipped segment */
    p = gpx_draw_line(gpx, -30, 160, 100, 165, CO_FORE, BM_CPY, 0xF0,
                      (rect_t *)0);
    gpx_draw_line(gpx, 100, 165, 240, 170, CO_FORE, BM_CPY, p, (rect_t *)0);

    __asm
        halt
    __endasm;
}
