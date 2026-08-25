#include "zxtest.h"
#include "test_bitmaps.h"

/* Two sprites over the same area, and sprites over drawn content. Hiding in
 * the reverse order of showing must restore the original screen; hiding in
 * the same order must not (the second capture already contains the first
 * sprite), and both behaviours have to match the oracle exactly. */
void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    uint8_t bg_a[GPX_SPRITE_BG_SIZE];
    uint8_t bg_b[GPX_SPRITE_BG_SIZE];
    static uint8_t dash[2] = {0xCC, 0x33};
    sprite_t a;
    sprite_t b;
    rect_t band;

    seed_screen_wash();

    /* Lay some drawn content under the sprites as well as the wash. */
    band.x0 = 0; band.y0 = 20; band.x1 = 255; band.y1 = 60;
    gpx_fill_rectangle(gpx, &band, CO_FORE, BM_CPY, dash, 2,
        (const rect_t *)0);

    a.background = (bmp_t *)bg_a;
    a.bitmap = (bmp_t *)bmp_w12;
    a.clip = (const rect_t *)0;
    b.background = (bmp_t *)bg_b;
    b.bitmap = (bmp_t *)bmp_mask12;
    b.clip = (const rect_t *)0;

    /* Overlapping, hidden in reverse order: the screen must come back. */
    a.x = 20; a.y = 30;
    b.x = 26; b.y = 32;
    gpx_show_sprite(gpx, &a);
    gpx_show_sprite(gpx, &b);
    gpx_hide_sprite(gpx, &b);
    gpx_hide_sprite(gpx, &a);

    /* Overlapping, hidden in the same order: a documented artefact, pinned
     * here so a change in capture order is noticed. */
    a.x = 100; a.y = 30;
    b.x = 106; b.y = 32;
    gpx_show_sprite(gpx, &a);
    gpx_show_sprite(gpx, &b);
    gpx_hide_sprite(gpx, &a);
    gpx_hide_sprite(gpx, &b);

    /* Hide without a preceding show replays whatever the buffer holds. */
    a.x = 200; a.y = 30;
    gpx_hide_sprite(gpx, &a);

    /* Show twice at the same place, then hide once: the second capture
     * contains the sprite, so the sprite stays. */
    a.x = 40; a.y = 120;
    gpx_show_sprite(gpx, &a);
    gpx_show_sprite(gpx, &a);
    gpx_hide_sprite(gpx, &a);

    /* Sprite at the exact screen corners. */
    a.x = 0; a.y = 0;
    gpx_show_sprite(gpx, &a);
    a.x = 0; a.y = 180;
    gpx_show_sprite(gpx, &a);

    TEST_END();
}
