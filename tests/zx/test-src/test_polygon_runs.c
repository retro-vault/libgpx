/*
 * Differential polygon fill coverage for long shallow edge runs, exact
 * half-step ties, reversed walks and clipped run endpoints. Record each
 * shape before later drawing can conceal a mismatch.
 */
#include "zxtest.h"

static void record_screen(void)
{
    const uint8_t *screen = zx_vram();
    uint16_t hash = 0x739B;
    uint16_t i;

    for (i = 0; i < 0x1800; ++i) {
        hash = (uint16_t)((hash << 1) | (hash >> 15));
        hash ^= screen[i];
    }
    record16(hash);
}

void main(void)
{
    static const coord rises[8] = {1, 2, 3, 4, 7, 16, 63, 127};
    static uint8_t pattern[3] = {0xFF, 0x96, 0x81};
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    rect_t clip = {13, 11, 237, 181};
    point_t pts[3];
    point_t swap;
    uint8_t shape;

    seed_screen_wash();
    for (shape = 0; shape < 8; ++shape) {
        pts[0].x = (shape & 2) ? 511 : -255;
        pts[1].x = (shape & 2) ? -255 : 511;
        pts[0].y = (shape & 4) ? -3 : 23;
        pts[1].y = pts[0].y + rises[shape & 7];
        pts[2].x = (shape & 2) ? 127 : 128;
        pts[2].y = pts[1].y + 17;
        if (shape & 4) {
            swap = pts[0];
            pts[0] = pts[1];
            pts[1] = swap;
        }
        gpx_fill_polygon(gpx, pts, 3, (color)(shape & 1),
            (bmode)((shape >> 1) & 1), pattern,
            (uint8_t)(1 + shape % 3), (shape & 1) ? &clip : 0);
        record_screen();
    }
    TEST_END();
}
