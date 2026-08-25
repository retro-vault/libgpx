#include "zxtest.h"

/* Random fills over seeded content: random geometry (often off-screen),
 * random colour and mode, random pattern of random length, half of them
 * through a random clip rect. */
void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    uint8_t patt[8];
    rect_t r;
    rect_t clip;
    uint16_t i;
    uint8_t k;

    seed_screen_wash();
    rnd_seed(0x9E37);

    for (i = 0; i < 60; ++i) {
        uint8_t len = (uint8_t)(1 + (rnd() & 7));
        for (k = 0; k < len; ++k)
            patt[k] = (uint8_t)rnd();

        r.x0 = rnd_between(-30, ZX_W + 30);
        r.y0 = rnd_between(-30, ZX_H + 30);
        r.x1 = (coord)(r.x0 + rnd_between(0, 60));
        r.y1 = (coord)(r.y0 + rnd_between(0, 40));

        if (rnd() & 1) {
            gpx_fill_rectangle(gpx, &r, (color)(rnd() & 1),
                (bmode)(rnd() & 1), patt, len, (const rect_t *)0);
        } else {
            clip.x0 = rnd_between(-20, ZX_W);
            clip.y0 = rnd_between(-20, ZX_H);
            clip.x1 = (coord)(clip.x0 + rnd_between(0, 90));
            clip.y1 = (coord)(clip.y0 + rnd_between(0, 70));
            gpx_fill_rectangle(gpx, &r, (color)(rnd() & 1),
                (bmode)(rnd() & 1), patt, len, &clip);
        }
    }

    TEST_END();
}
