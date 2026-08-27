#include "bench.h"

BENCH_MAIN()

/* Sprites: the show/hide pair is what an animation loop actually costs. */
void bench_body(gpx_t *gpx)
{
    static uint8_t under[GPX_SPRITE_BG_SIZE];
    sprite_t s;
    coord i;

    s.background = (bmp_t *)under;
    s.clip = 0;
    for (i = 0; i < 100; ++i) {
        s.bitmap = gpx_get_stock_bmp((uint8_t)(i % 5));
        s.x = (coord)(rnd_between(0, (coord)(gpx_width() - 17)));
        s.y = (coord)(rnd_between(0, 183));
        gpx_show_sprite(gpx, &s);
        gpx_hide_sprite(gpx, &s);
    }
}
