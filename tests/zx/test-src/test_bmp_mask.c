#include "zxtest.h"
#include "test_bitmaps.h"

/* Masked bitmaps: the AND plane punches holes and the OR plane sets ink, so
 * a masked blit both clears and sets. Drawn over content at every phase,
 * because with a blank screen the AND plane has nothing to remove. */
void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    rect_t clip;
    coord phase, k;

    seed_screen(0xFF);

    /* Every bit phase, stride 1 and stride 2. */
    for (phase = 0; phase < 8; ++phase) {
        gpx_draw_bmp(gpx, (coord)(8 + phase), (coord)(phase * 8),
            (bmp_t *)bmp_mask8, (const rect_t *)0);
        gpx_draw_bmp(gpx, (coord)(60 + phase), (coord)(phase * 8),
            (bmp_t *)bmp_mask12, (const rect_t *)0);
    }

    /* Against both screen edges. */
    for (phase = 0; phase < 8; ++phase) {
        gpx_draw_bmp(gpx, (coord)phase, (coord)(70 + phase * 7),
            (bmp_t *)bmp_mask12, (const rect_t *)0);
        gpx_draw_bmp(gpx, (coord)(244 + phase), (coord)(70 + phase * 7),
            (bmp_t *)bmp_mask12, (const rect_t *)0);
    }

    /* Negative x at every sub-byte offset: the source must be advanced by a
     * partial byte, carrying bits across source bytes on both planes. */
    for (k = 1; k <= 12; ++k)
        gpx_draw_bmp(gpx, (coord)-k, (coord)(130 + k * 5),
            (bmp_t *)bmp_mask12, (const rect_t *)0);

    /* The same offsets expressed as a left clip instead of a negative x. */
    for (k = 1; k <= 12; ++k) {
        clip.x0 = (coord)(150 + k);
        clip.y0 = (coord)(130 + k * 5);
        clip.x1 = 200;
        clip.y1 = (coord)(clip.y0 + 4);
        gpx_draw_bmp(gpx, 150, clip.y0, (bmp_t *)bmp_mask12, &clip);
    }

    TEST_END();
}
