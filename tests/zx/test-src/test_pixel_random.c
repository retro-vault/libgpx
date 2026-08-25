#include "zxtest.h"

/* A wide random walk over the whole parameter space: position (including
 * off-screen), colour, mode, and a clip rect that is sometimes absent,
 * sometimes degenerate. */
void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    rect_t full_screen = FULL_SCREEN_RECT;
    rect_t clip;
    uint16_t i;
    coord x, y;
    color c;
    bmode m;

    seed_screen_wash();
    rnd_seed(0x1234);

    for (i = 0; i < 500; ++i) {
        x = rnd_between(-20, ZX_W + 20);
        y = rnd_between(-20, ZX_H + 20);
        c = (color)(rnd() & 1);
        m = (bmode)(rnd() & 1);

        switch (rnd() & 3) {
        case 0:
            gpx_draw_pixel(gpx, x, y, c, m, (const rect_t *)0);
            break;
        case 1:
            gpx_draw_pixel(gpx, x, y, c, m, &full_screen);
            break;
        default:
            clip.x0 = rnd_between(-10, ZX_W);
            clip.y0 = rnd_between(-10, ZX_H);
            clip.x1 = rnd_between(-10, ZX_W);
            clip.y1 = rnd_between(-10, ZX_H);
            gpx_draw_pixel(gpx, x, y, c, m, &clip);
            break;
        }
    }

    TEST_END();
}
