#include "xbench.h"
BENCH_MAIN()

/* 200 show/hide pairs of a stock cursor, walking a diagonal. */
static uint8_t under[GPX_SPRITE_BG_SIZE];

void bench_body(gpx_t *gpx)
{
    sprite_t s;
    coord i;

    s.bitmap = gpx_get_stock_bmp(GPXSB_CURSOR_CLASSIC);
    s.background = (bmp_t *)under;
    s.clip = 0;
    for (i = 0; i < 200; ++i) {
        s.x = (coord)(i % 200 + 10);
        s.y = (coord)(i % 150 + 10);
        gpx_show_sprite(gpx, &s);
        gpx_hide_sprite(gpx, &s);
    }
}
