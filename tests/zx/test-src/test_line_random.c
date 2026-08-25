#include "zxtest.h"

/* A broad random sweep: 150 lines with random endpoints (frequently
 * off-screen), random colour, mode and dash, drawn over seeded content,
 * half of them through a random clip rect. The returned pattern of every
 * line is recorded, so phase arithmetic is compared as well as pixels. */
void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    rect_t clip;
    uint16_t i;
    uint8_t patt = 0xB7;

    seed_screen_wash();
    rnd_seed(0x2468);

    for (i = 0; i < 150; ++i) {
        coord x0 = rnd_between(-60, ZX_W + 60);
        coord y0 = rnd_between(-60, ZX_H + 60);
        coord x1 = rnd_between(-60, ZX_W + 60);
        coord y1 = rnd_between(-60, ZX_H + 60);
        color c = (color)(rnd() & 1);
        bmode m = (bmode)(rnd() & 1);
        uint8_t p = (uint8_t)rnd();

        if (rnd() & 1) {
            patt = gpx_draw_line(gpx, x0, y0, x1, y1, c, m, p,
                (const rect_t *)0);
        } else {
            clip.x0 = rnd_between(0, ZX_W - 1);
            clip.y0 = rnd_between(0, ZX_H - 1);
            clip.x1 = (coord)(clip.x0 + rnd_between(0, 80));
            clip.y1 = (coord)(clip.y0 + rnd_between(0, 60));
            patt = gpx_draw_line(gpx, x0, y0, x1, y1, c, m, p, &clip);
        }
        if (i < TEST_RESULTS_BYTES)
            record(patt);
    }

    TEST_END();
}
