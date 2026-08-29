#include "zxtest.h"

/* Hunts for writes that leave the framebuffer. Rectangle outlines are the
 * one primitive that mixes the byte-span horizontal path with the Bresenham
 * vertical path, and a clip strip narrow on one axis exercises both of
 * their reject/clamp corners at once. RAM just past the attribute area is
 * seeded and verified afterwards, so a span whose byte count underflowed or
 * a raster that stepped past the last row is caught even when the visible
 * screen still looks plausible. */

#define GUARD_BASE ((uint8_t *)0x5B00)
#define GUARD_LEN  0x0500

static uint8_t guard_byte(uint16_t i)
{
    return (uint8_t)(0x5A ^ (i & 0xFF) ^ (uint8_t)(i >> 8));
}

static void sweep(gpx_t *gpx, uint16_t seed)
{
    rect_t r;
    rect_t clip;
    uint16_t i;

    rnd_seed(seed);
    for (i = 0; i < 40; ++i) {
        color c = (color)(rnd() & 1);
        bmode m = (bmode)(rnd() & 1);
        uint8_t p = (uint8_t)rnd();

        r.x0 = rnd_between(-140, ZX_W + 140);
        r.y0 = rnd_between(-140, ZX_H + 140);
        r.x1 = (coord)(r.x0 + rnd_between(0, 300));
        r.y1 = (coord)(r.y0 + rnd_between(0, 240));

        clip.x0 = rnd_between(-60, ZX_W + 60);
        clip.y0 = rnd_between(-60, ZX_H + 60);
        switch (rnd() & 3) {
        case 0: /* tall sliver, like a window's left or right frame edge */
            clip.x1 = (coord)(clip.x0 + rnd_between(0, 4));
            clip.y1 = (coord)(clip.y0 + rnd_between(0, 200));
            break;
        case 1: /* wide sliver, like a title bar or bottom frame */
            clip.x1 = (coord)(clip.x0 + rnd_between(0, 260));
            clip.y1 = (coord)(clip.y0 + rnd_between(0, 4));
            break;
        case 2: /* degenerate or inverted */
            clip.x1 = (coord)(clip.x0 + rnd_between(-8, 8));
            clip.y1 = (coord)(clip.y0 + rnd_between(-8, 8));
            break;
        default:
            clip.x1 = (coord)(clip.x0 + rnd_between(0, 260));
            clip.y1 = (coord)(clip.y0 + rnd_between(0, 200));
            break;
        }
        gpx_draw_rectangle(gpx, &r, c, m, p, &clip);
    }
}

void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    uint16_t i;
    uint16_t bad = 0;

    for (i = 0; i < GUARD_LEN; ++i)
        GUARD_BASE[i] = guard_byte(i);

    seed_screen_wash();

    sweep(gpx, 0x1357);
    sweep(gpx, 0x8BAD);
    sweep(gpx, 0xF00D);

    for (i = 0; i < GUARD_LEN; ++i)
        if (GUARD_BASE[i] != guard_byte(i))
            ++bad;

    record16(bad);
    record(0x5A);
    TEST_END();
}
