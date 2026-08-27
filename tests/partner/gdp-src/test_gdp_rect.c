/* Rectangle outlines and pattern fills, clipped and unclipped. */
#include "gdptest.h"

static uint8_t solid[1]  = {0xFF};
static uint8_t check[2]  = {0xAA, 0x55};
static uint8_t brick[4]  = {0xFF, 0x88, 0x88, 0x88};

void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    static rect_t a = {20, 20, 300, 120};
    static rect_t b = {340, 20, 620, 120};
    static rect_t c = {660, 20, 940, 120};
    static rect_t d = {20, 150, 300, 240};

    gpx_clrscr();
    gpx_fill_rectangle(gpx, &a, CO_FORE, BM_CPY, solid, 1, 0);
    gpx_fill_rectangle(gpx, &b, CO_FORE, BM_CPY, check, 2, 0);
    gpx_fill_rectangle(gpx, &c, CO_FORE, BM_CPY, brick, 4, 0);
    gpx_draw_rectangle(gpx, &d, CO_FORE, BM_CPY, 0xFF, 0);
    gdp_phase();

    gpx_clrscr();
    /* Fill, then punch a background hole out of it, then XOR a band. */
    {
        static rect_t big  = {50, 30, 700, 220};
        static rect_t hole = {150, 70, 400, 150};
        static rect_t band = {300, 30, 500, 220};
        gpx_fill_rectangle(gpx, &big, CO_FORE, BM_CPY, solid, 1, 0);
        gpx_fill_rectangle(gpx, &hole, CO_BACK, BM_CPY, solid, 1, 0);
        gpx_fill_rectangle(gpx, &band, CO_FORE, BM_XOR, solid, 1, 0);
    }
    gdp_phase();

    gpx_clrscr();
    /* Clipped fills: partly outside the window on each side. */
    {
        static rect_t win = {200, 60, 700, 200};
        static rect_t r1  = {100, 20, 350, 120};
        static rect_t r2  = {600, 100, 900, 240};
        static rect_t r3  = {0, 0, 1023, 255};
        gpx_draw_rectangle(gpx, &win, CO_FORE, BM_CPY, 0xAA, 0);
        gpx_fill_rectangle(gpx, &r1, CO_FORE, BM_CPY, check, 2, &win);
        gpx_fill_rectangle(gpx, &r2, CO_FORE, BM_CPY, brick, 4, &win);
        gpx_draw_rectangle(gpx, &r3, CO_FORE, BM_CPY, 0xFF, &win);
    }
    gdp_done();
}
