#include "libgpx.h"

/* Window-clipped sprites (sprite->clip): the draw is restricted to the
 * window rect while the background capture stays full-box, so hide
 * restores everything including pixels the clip suppressed. All cases
 * are oracle-compared; fills stay solid (oracle-safe). */
static uint8_t bg_a[GPX_SPRITE_BG_SIZE];
static uint8_t bg_b[GPX_SPRITE_BG_SIZE];
static uint8_t bg_c[GPX_SPRITE_BG_SIZE];
static uint8_t bg_d[GPX_SPRITE_BG_SIZE];

void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    rect_t band = {30, 20, 130, 70};
    rect_t win = {50, 25, 80, 45};
    rect_t far_win = {0, 0, 10, 10};
    uint8_t solid = 0xFF;
    sprite_t a;
    sprite_t b;
    sprite_t c;
    sprite_t d;

    /* field assignment, not aggregates: local aggregate initializers with
     * non-constant members (&win) are not reliable under SDCC/C89 */
    a.x = 55;
    a.y = 28;
    a.bitmap = gpx_get_stock_bmp(GPXSB_CURSOR_CLASSIC);
    a.background = (bmp_t *)bg_a;
    a.clip = &win;
    b.x = 75;
    b.y = 40;
    b.bitmap = gpx_get_stock_bmp(GPXSB_CURSOR_HAND);
    b.background = (bmp_t *)bg_b;
    b.clip = &win;
    c.x = 100;
    c.y = 50;
    c.bitmap = gpx_get_stock_bmp(GPXSB_CURSOR_STD);
    c.background = (bmp_t *)bg_c;
    c.clip = &far_win;
    d.x = 36;
    d.y = 60;
    d.bitmap = gpx_get_stock_bmp(GPXSB_CURSOR_HOURGLASS);
    d.background = (bmp_t *)bg_d;
    d.clip = (const rect_t *)0;

    gpx_fill_rectangle(gpx, &band, CO_FORE, BM_CPY, &solid, 1,
                       (const rect_t *)0);

    gpx_show_sprite(gpx, &a);          /* lasting, straddles the window */

    gpx_show_sprite(gpx, &b);          /* clipped round-trip: identity */
    gpx_hide_sprite(gpx, &b);

    gpx_show_sprite(gpx, &c);          /* window excludes it entirely */

    gpx_show_sprite(gpx, &d);          /* NULL clip: fast path in-scene */

    __asm
        halt
    __endasm;
}
