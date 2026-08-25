#include "zxtest.h"
#include "test_bitmaps.h"

/* Sprite clipping. The origin is required to be on-screen; only the right
 * and bottom edges clip, and an optional window rect narrows what is drawn
 * while the saved background still covers the whole box. */
void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    uint8_t bg_store[GPX_SPRITE_BG_SIZE];
    rect_t window = {60, 40, 100, 70};
    sprite_t s;
    coord k;

    seed_screen_wash();

    s.background = (bmp_t *)bg_store;
    s.bitmap = (bmp_t *)bmp_w12;

    /* Right-edge clipping at every overlap. */
    s.clip = (const rect_t *)0;
    for (k = 0; k < 12; ++k) {
        s.x = (coord)(255 - k);
        s.y = (coord)(k * 7);
        gpx_show_sprite(gpx, &s);
    }

    /* Bottom-edge clipping at every overlap. */
    for (k = 0; k < 6; ++k) {
        s.x = (coord)(10 + k * 14);
        s.y = (coord)(191 - k);
        gpx_show_sprite(gpx, &s);
    }

    /* Both edges at once. */
    s.x = 250;
    s.y = 188;
    gpx_show_sprite(gpx, &s);

    /* A window rect that cuts the sprite on each side. Hide restores the
     * whole box regardless of what the window suppressed, so each of these
     * show/hide pairs must leave the wash intact. */
    s.clip = &window;
    for (k = 0; k < 10; ++k) {
        s.x = (coord)(56 + k * 4);
        s.y = (coord)(36 + k * 3);
        gpx_show_sprite(gpx, &s);
        gpx_hide_sprite(gpx, &s);
    }
    /* One left visible inside the window. */
    s.x = 70;
    s.y = 50;
    gpx_show_sprite(gpx, &s);

    /* A window that excludes the sprite entirely: nothing drawn, and hide
     * still heals the box. */
    {
        rect_t elsewhere = {200, 10, 210, 20};
        s.clip = &elsewhere;
        s.x = 20;
        s.y = 90;
        gpx_show_sprite(gpx, &s);
        gpx_hide_sprite(gpx, &s);
    }

    TEST_END();
}
