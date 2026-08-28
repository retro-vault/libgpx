/* Cross-backend conformance for the ADVANCED polygon primitives. The edge
 * walker and the pattern anchoring live in one portable module, so any
 * difference here is the backend underneath it: gpx_draw_line for both the
 * outline and the spans. Everything stays inside 256x192. */
#include "libgpx.h"

#ifndef DEMO_MODE
#define DEMO_MODE GPXM_DEFAULT
#endif

uint8_t gdp_finished;
#define phase() __asm__("halt")
#define done()  do { gdp_finished = 0xA5; __asm__("halt"); } while (0)

static uint8_t solid[1] = {0xFF};
static uint8_t check[2] = {0xAA, 0x55};
static uint8_t three[3] = {0xF0, 0x0F, 0xAA};
static uint8_t brick[8] = {0xFF, 0x88, 0x88, 0x88, 0xFF, 0x08, 0x08, 0x08};

void main(void)
{
    gpx_t *gpx = gpx_create(DEMO_MODE);
    point_t p[10];

    /* --- convex fills, both winding directions, plus a rectangle as a
     * polygon beside the same rectangle filled as a rectangle --- */
    gpx_clrscr();
    p[0].x = 4;   p[0].y = 4;
    p[1].x = 60;  p[1].y = 16;
    p[2].x = 20;  p[2].y = 60;
    gpx_fill_polygon(gpx, p, 3, CO_FORE, BM_CPY, solid, 1, 0);
    p[0].x = 100; p[0].y = 60;
    p[1].x = 140; p[1].y = 16;
    p[2].x = 84;  p[2].y = 4;
    gpx_fill_polygon(gpx, p, 3, CO_FORE, BM_CPY, solid, 1, 0);
    p[0].x = 160; p[0].y = 4;
    p[1].x = 210; p[1].y = 4;
    p[2].x = 210; p[2].y = 40;
    p[3].x = 160; p[3].y = 40;
    gpx_fill_polygon(gpx, p, 4, CO_FORE, BM_CPY, solid, 1, 0);
    {
        static rect_t r = {215, 4, 250, 40};
        gpx_fill_rectangle(gpx, &r, CO_FORE, BM_CPY, solid, 1, 0);
    }
    phase();

    /* --- concave, self-intersecting, and a ten-point star --- */
    gpx_clrscr();
    p[0].x = 4;   p[0].y = 4;
    p[1].x = 74;  p[1].y = 4;
    p[2].x = 74;  p[2].y = 74;
    p[3].x = 39;  p[3].y = 30;
    p[4].x = 4;   p[4].y = 74;
    gpx_fill_polygon(gpx, p, 5, CO_FORE, BM_CPY, solid, 1, 0);
    p[0].x = 90;  p[0].y = 4;
    p[1].x = 160; p[1].y = 74;
    p[2].x = 160; p[2].y = 4;
    p[3].x = 90;  p[3].y = 74;
    gpx_fill_polygon(gpx, p, 4, CO_FORE, BM_CPY, solid, 1, 0);
    p[0].x = 210; p[0].y = 100;
    p[1].x = 222; p[1].y = 132;
    p[2].x = 254; p[2].y = 132;
    p[3].x = 228; p[3].y = 152;
    p[4].x = 238; p[4].y = 184;
    p[5].x = 210; p[5].y = 164;
    p[6].x = 182; p[6].y = 184;
    p[7].x = 192; p[7].y = 152;
    p[8].x = 166; p[8].y = 132;
    p[9].x = 198; p[9].y = 132;
    gpx_fill_polygon(gpx, p, 10, CO_FORE, BM_CPY, solid, 1, 0);
    phase();

    /* --- the fill ends on its own outline: a dithered fill closed with a
     * solid rim, and a solid fill with the rim knocked out --- */
    gpx_clrscr();
    p[0].x = 10;  p[0].y = 10;
    p[1].x = 90;  p[1].y = 30;
    p[2].x = 60;  p[2].y = 100;
    p[3].x = 14;  p[3].y = 70;
    gpx_fill_polygon(gpx, p, 4, CO_FORE, BM_CPY, check, 2, 0);
    gpx_draw_polygon(gpx, p, 4, CO_FORE, BM_CPY, 0xFF, 0);
    p[0].x = 150; p[0].y = 10;
    p[1].x = 230; p[1].y = 30;
    p[2].x = 200; p[2].y = 100;
    p[3].x = 154; p[3].y = 70;
    gpx_fill_polygon(gpx, p, 4, CO_FORE, BM_CPY, solid, 1, 0);
    gpx_draw_polygon(gpx, p, 4, CO_BACK, BM_CPY, 0xFF, 0);
    phase();

    /* --- patterns are anchored to the bounding box, so the stripes run
     * straight through the shape and line up with a rectangle fill --- */
    gpx_clrscr();
    {
        static rect_t band = {10, 10, 109, 60};
        gpx_fill_rectangle(gpx, &band, CO_FORE, BM_CPY, brick, 8, 0);
    }
    p[0].x = 130; p[0].y = 10;
    p[1].x = 250; p[1].y = 10;
    p[2].x = 210; p[2].y = 90;
    p[3].x = 150; p[3].y = 90;
    gpx_fill_polygon(gpx, p, 4, CO_FORE, BM_CPY, brick, 8, 0);
    p[0].x = 20;  p[0].y = 110;
    p[1].x = 120; p[1].y = 130;
    p[2].x = 70;  p[2].y = 185;
    gpx_fill_polygon(gpx, p, 3, CO_FORE, BM_CPY, three, 3, 0);
    phase();

    /* --- clipping, and a dashed outline chaining round the corners --- */
    gpx_clrscr();
    {
        static rect_t win = {60, 50, 190, 150};
        gpx_draw_rectangle(gpx, &win, CO_FORE, BM_CPY, 0xFF, 0);
        p[0].x = 20;  p[0].y = 20;
        p[1].x = 240; p[1].y = 70;
        p[2].x = 200; p[2].y = 180;
        p[3].x = 40;  p[3].y = 160;
        gpx_fill_polygon(gpx, p, 4, CO_FORE, BM_CPY, check, 2, &win);
        gpx_draw_polygon(gpx, p, 4, CO_FORE, BM_CPY, 0xFF, &win);
        p[0].x = 10;  p[0].y = 165;
        p[1].x = 50;  p[1].y = 165;
        p[2].x = 30;  p[2].y = 188;
        gpx_draw_polygon(gpx, p, 3, CO_FORE, BM_CPY, 0xE4, 0);
    }
    phase();

    /* --- XOR: filling the same polygon twice restores what was under it,
     * and the colour argument is ignored --- */
    gpx_clrscr();
    {
        static rect_t band = {0, 0, 250, 90};
        gpx_fill_rectangle(gpx, &band, CO_FORE, BM_CPY, solid, 1, 0);
        p[0].x = 10;  p[0].y = 10;
        p[1].x = 90;  p[1].y = 20;
        p[2].x = 60;  p[2].y = 80;
        gpx_fill_polygon(gpx, p, 3, CO_FORE, BM_XOR, solid, 1, 0);
        p[0].x = 110; p[0].y = 10;
        p[1].x = 190; p[1].y = 20;
        p[2].x = 160; p[2].y = 80;
        gpx_fill_polygon(gpx, p, 3, CO_BACK, BM_XOR, solid, 1, 0);

        p[0].x = 20;  p[0].y = 110;
        p[1].x = 120; p[1].y = 130;
        p[2].x = 70;  p[2].y = 185;
        gpx_fill_polygon(gpx, p, 3, CO_FORE, BM_XOR, check, 2, 0);
        gpx_fill_polygon(gpx, p, 3, CO_FORE, BM_XOR, check, 2, 0);
    }
    done();
}
