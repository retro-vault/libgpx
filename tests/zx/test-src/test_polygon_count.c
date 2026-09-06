/*
 * Polygon outline point-count boundaries, closure and pattern continuity.
 * Keep the large point array out of the Z80 compiler's small IX frame.
 */
#include "zxtest.h"

static point_t pts[255];

static void record_screen(void)
{
    const uint8_t *screen = zx_vram();
    uint16_t hash = 0x392D;
    uint16_t i;

    for (i = 0; i < 0x1800; ++i) {
        hash = (uint16_t)((hash << 1) | (hash >> 15));
        hash ^= screen[i];
    }
    record16(hash);
}

void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    rect_t clip = {25, 17, 230, 173};
    uint8_t i;

    for (i = 0; i < 255; ++i) {
        pts[i].x = (coord)(9 + (i & 31) * 8);
        pts[i].y = (coord)(5 + (i >> 5) * 24);
    }
    seed_screen_wash();
    gpx_draw_polygon(gpx, pts, 0, CO_FORE, BM_CPY, 0x96, 0);
    record_screen();
    gpx_draw_polygon(gpx, pts, 1, CO_BACK, BM_XOR, 0x81, &clip);
    record_screen();
    gpx_draw_polygon(gpx, pts, 2, CO_FORE, BM_CPY, 0x96, 0);
    record_screen();
    gpx_draw_polygon(gpx, pts, 254, CO_BACK, BM_CPY, 0xD2, &clip);
    record_screen();
    gpx_draw_polygon(gpx, pts, 255, CO_FORE, BM_XOR, 0x69, 0);
    record_screen();
    TEST_END();
}
