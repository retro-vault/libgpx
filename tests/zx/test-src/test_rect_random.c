#include "zxtest.h"

/* Random outlines over seeded content: window-sized rectangles, often
 * partly off-screen, half of them through a narrow strip clip of the kind
 * a window decoration produces. A strip is only a few pixels wide on one
 * axis, so every call keeps a sliver of one or two edges and rejects the
 * rest -- the combination a plain sweep never reaches. */
void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    rect_t r;
    rect_t clip;
    uint16_t i;
    uint8_t patt = 0xFF;

    seed_screen_wash();
    rnd_seed(0x51C7);

    for (i = 0; i < 48; ++i) {
        color c = (color)(rnd() & 1);
        bmode m = (bmode)(rnd() & 1);
        uint8_t p = (uint8_t)rnd();

        r.x0 = rnd_between(-40, ZX_W + 40);
        r.y0 = rnd_between(-40, ZX_H + 40);
        r.x1 = (coord)(r.x0 + rnd_between(0, 130));
        r.y1 = (coord)(r.y0 + rnd_between(0, 100));

        if (rnd() & 1) {
            gpx_draw_rectangle(gpx, &r, c, m, p, (const rect_t *)0);
        } else {
            clip.x0 = rnd_between(-20, ZX_W);
            clip.y0 = rnd_between(-20, ZX_H);
            if (rnd() & 1) {
                clip.x1 = (coord)(clip.x0 + rnd_between(0, 6));
                clip.y1 = (coord)(clip.y0 + rnd_between(0, 100));
            } else {
                clip.x1 = (coord)(clip.x0 + rnd_between(0, 130));
                clip.y1 = (coord)(clip.y0 + rnd_between(0, 6));
            }
            gpx_draw_rectangle(gpx, &r, c, m, p, &clip);
        }
        patt = (uint8_t)(patt + 1u);
        if (i < TEST_RESULTS_BYTES)
            record(patt);
    }

    TEST_END();
}
