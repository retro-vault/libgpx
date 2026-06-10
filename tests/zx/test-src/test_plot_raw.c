#include "libgpx.h"

/* Stresses the register-fed pixel core __gpx_plot_raw, reached via both the
 * public gpx_draw_pixel (wrapper) and Bresenham (direct call). Exercises:
 *  - screen-bounds reject for off-screen pixels and line endpoints
 *  - clip accept/reject exactly on each clip edge and corner
 *  - all three plot ops (set / clear via CO_BACK / xor) through the packed flag
 * Clipped diagonals are kept at 45 deg (and H/V) so real and oracle clip
 * identically (per-pixel clip is unchanged by this refactor).
 *
 * NOTE: no helper functions before main() (emulator enters at lowest address).
 */

void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    rect_t clip = {40, 40, 120, 120};
    rect_t band = {8, 150, 247, 175};
    uint8_t fp = 0xFF;
    coord i;

    gpx_clrscr();
    /* solid band for clear/xor tests (cleared screen => set==replace) */
    gpx_fill_rectangle(gpx, &band, CO_FORE, BM_CPY, &fp, 1, (const rect_t *)0);

    /* --- draw_pixel: clip edges/corners (CO_FORE) --- */
    gpx_draw_pixel(gpx, 40, 40, CO_FORE, BM_CPY, &clip);    /* TL corner, accept */
    gpx_draw_pixel(gpx, 120, 40, CO_FORE, BM_CPY, &clip);   /* TR corner, accept */
    gpx_draw_pixel(gpx, 40, 120, CO_FORE, BM_CPY, &clip);   /* BL corner, accept */
    gpx_draw_pixel(gpx, 120, 120, CO_FORE, BM_CPY, &clip);  /* BR corner, accept */
    gpx_draw_pixel(gpx, 39, 80, CO_FORE, BM_CPY, &clip);    /* just left, reject */
    gpx_draw_pixel(gpx, 121, 80, CO_FORE, BM_CPY, &clip);   /* just right, reject */
    gpx_draw_pixel(gpx, 80, 39, CO_FORE, BM_CPY, &clip);    /* just above, reject */
    gpx_draw_pixel(gpx, 80, 121, CO_FORE, BM_CPY, &clip);   /* just below, reject */

    /* --- draw_pixel: off-screen bounds reject (no clip) --- */
    gpx_draw_pixel(gpx, -1, 10, CO_FORE, BM_CPY, (const rect_t *)0);
    gpx_draw_pixel(gpx, 256, 10, CO_FORE, BM_CPY, (const rect_t *)0);
    gpx_draw_pixel(gpx, 10, -1, CO_FORE, BM_CPY, (const rect_t *)0);
    gpx_draw_pixel(gpx, 10, 192, CO_FORE, BM_CPY, (const rect_t *)0);
    gpx_draw_pixel(gpx, 0, 0, CO_FORE, BM_CPY, (const rect_t *)0);
    gpx_draw_pixel(gpx, 255, 191, CO_FORE, BM_CPY, (const rect_t *)0);

    /* --- draw_pixel over solid band: clear (CO_BACK) and xor --- */
    for (i = 0; i < 16; ++i) {
        gpx_draw_pixel(gpx, (coord)(20 + i * 3), 158, CO_BACK, BM_CPY, (const rect_t *)0);
        gpx_draw_pixel(gpx, (coord)(20 + i * 3), 168, CO_FORE, BM_XOR, (const rect_t *)0);
    }

    /* --- Bresenham 45deg diagonals crossing the clip rect (CO_FORE) --- */
    gpx_draw_line(gpx, 20, 20, 140, 140, CO_FORE, BM_CPY, 0xFF, &clip);   /* through TL..BR */
    gpx_draw_line(gpx, 140, 20, 20, 140, CO_FORE, BM_CPY, 0xFF, &clip);   /* anti-diagonal */
    gpx_draw_line(gpx, 30, 130, 130, 30, CO_FORE, BM_CPY, 0xFF, &clip);

    /* --- Bresenham off-screen endpoints, no clip (per-pixel bounds) --- */
    gpx_draw_line(gpx, -20, -20, 60, 60, CO_FORE, BM_CPY, 0xFF, (const rect_t *)0);
    gpx_draw_line(gpx, 220, 60, 300, 140, CO_FORE, BM_CPY, 0xFF, (const rect_t *)0);

    /* --- patterned + xor diagonal over the solid band --- */
    gpx_draw_line(gpx, 10, 150, 35, 175, CO_FORE, BM_XOR, 0xFF, (const rect_t *)0);
    gpx_draw_line(gpx, 60, 175, 85, 150, CO_FORE, BM_CPY, 0xAA, (const rect_t *)0);

    __asm
        halt
    __endasm;
}
