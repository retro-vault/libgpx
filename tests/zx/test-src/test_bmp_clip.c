#include "zxtest.h"
#include "test_bitmaps.h"

/* Bitmaps clipped on every side and corner. A left clip that does not fall
 * on a byte boundary makes the blit advance the source by a partial byte,
 * which is the case that historically broke the cross-byte carry. */
void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    rect_t clip;
    coord k;

    seed_screen_wash();

    /* A left clip at every offset 0..19 into a 20-wide bitmap. */
    for (k = 0; k < 20; ++k) {
        clip.x0 = (coord)(10 + k);
        clip.y0 = (coord)(k * 5);
        clip.x1 = 40;
        clip.y1 = (coord)(k * 5 + 4);
        gpx_draw_bmp(gpx, 10, (coord)(k * 5), (bmp_t *)bmp_w20, &clip);
    }

    /* A right clip at every offset. */
    for (k = 0; k < 20; ++k) {
        clip.x0 = 60;
        clip.y0 = (coord)(k * 5);
        clip.x1 = (coord)(60 + k);
        clip.y1 = (coord)(k * 5 + 4);
        gpx_draw_bmp(gpx, 60, (coord)(k * 5), (bmp_t *)bmp_w20, &clip);
    }

    /* Both edges clipped at once, leaving a narrow window that moves. */
    for (k = 0; k < 16; ++k) {
        clip.x0 = (coord)(110 + k);
        clip.y0 = (coord)(100 + k * 5);
        clip.x1 = (coord)(clip.x0 + 3);
        clip.y1 = (coord)(clip.y0 + 4);
        gpx_draw_bmp(gpx, 108, (coord)(100 + k * 5), (bmp_t *)bmp_w20,
            &clip);
    }

    /* Top and bottom clips at every row offset. */
    for (k = 0; k < 6; ++k) {
        clip.x0 = 160; clip.x1 = 180;
        clip.y0 = (coord)(k * 8 + k);
        clip.y1 = (coord)(k * 8 + 5);
        gpx_draw_bmp(gpx, 160, (coord)(k * 8), (bmp_t *)bmp_w12, &clip);
    }

    /* Clip entirely outside the bitmap, and a swapped clip. */
    clip.x0 = 0; clip.y0 = 0; clip.x1 = 5; clip.y1 = 5;
    gpx_draw_bmp(gpx, 200, 150, (bmp_t *)bmp_w12, &clip);
    clip.x0 = 220; clip.y0 = 170; clip.x1 = 200; clip.y1 = 150;
    gpx_draw_bmp(gpx, 200, 150, (bmp_t *)bmp_w12, &clip);

    /* Clip straddling the screen edge combined with a negative position. */
    clip.x0 = -10; clip.y0 = 180; clip.x1 = 20; clip.y1 = 260;
    gpx_draw_bmp(gpx, -5, 180, (bmp_t *)bmp_w20, &clip);

    TEST_END();
}
