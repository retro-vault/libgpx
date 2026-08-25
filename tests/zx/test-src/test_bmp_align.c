#include "zxtest.h"
#include "test_bitmaps.h"

/* The same bitmap blitted at every horizontal bit phase. A blit shifts the
 * source into the destination byte grid, so phases 0..7 exercise every
 * shift amount and the carry between destination bytes. */
void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    coord phase;

    for (phase = 0; phase < 8; ++phase) {
        gpx_draw_bmp(gpx, (coord)(8 + phase), (coord)(phase * 6),
            (bmp_t *)bmp_diagonal, (const rect_t *)0);
        gpx_draw_bmp(gpx, (coord)(40 + phase), (coord)(phase * 6),
            (bmp_t *)bmp_w12, (const rect_t *)0);
        gpx_draw_bmp(gpx, (coord)(80 + phase), (coord)(phase * 6),
            (bmp_t *)bmp_w20, (const rect_t *)0);
        gpx_draw_bmp(gpx, (coord)(130 + phase), (coord)(phase * 6),
            (bmp_t *)bmp_w3, (const rect_t *)0);
        gpx_draw_bmp(gpx, (coord)(150 + phase), (coord)(phase * 6),
            (bmp_t *)bmp_w1, (const rect_t *)0);
    }

    /* The same phases again against the right-hand edge of the screen, so
     * the last destination byte is the last byte of the row. */
    for (phase = 0; phase < 8; ++phase) {
        gpx_draw_bmp(gpx, (coord)(248 - phase), (coord)(60 + phase * 6),
            (bmp_t *)bmp_diagonal, (const rect_t *)0);
        gpx_draw_bmp(gpx, (coord)(236 - phase), (coord)(110 + phase * 6),
            (bmp_t *)bmp_w20, (const rect_t *)0);
    }

    /* Against the left edge. */
    for (phase = 0; phase < 8; ++phase)
        gpx_draw_bmp(gpx, (coord)phase, (coord)(160 + phase * 4),
            (bmp_t *)bmp_checker, (const rect_t *)0);

    TEST_END();
}
