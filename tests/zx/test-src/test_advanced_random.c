/*
 * Deterministic differential coverage for the shared shape walkers.
 * Crossed edges, repeated vertices, both winding directions, clipping,
 * empty pattern rows and every blit mode run over existing screen data.
 */
#include "zxtest.h"

/* Keep later overlapping shapes from hiding an earlier rendering error. */
static void record_screen(void)
{
    uint16_t hash = 0xA731;
    uint16_t i;
    const uint8_t *screen = zx_vram();

    for (i = 0; i < 0x1800; ++i) {
        hash = (uint16_t)((hash << 1) | (hash >> 15));
        hash ^= screen[i];
    }
    record16(hash);
}

void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    point_t pts[GPX_MAX_POLY_PTS];
    uint8_t pattern[5];
    rect_t clip;
    uint8_t shape;
    uint8_t i;
    uint8_t n;

    rnd_seed(0x6A91);
    seed_screen_wash();
    clip.x0 = 9; clip.y0 = 7; clip.x1 = 243; clip.y1 = 182;
    pattern[0] = 0; pattern[1] = 0xFF; pattern[2] = 0x81;
    pattern[3] = 0x96; pattern[4] = 0x42;

    for (shape = 0; shape < 16; ++shape) {
        n = (uint8_t)(3 + shape % 10);
        for (i = 0; i < n; ++i) {
            pts[i].x = rnd_between(-16, 271);
            pts[i].y = rnd_between(-12, 203);
        }
        if ((shape & 3) == 0) {
            pts[1] = pts[0];
            pts[2].y = pts[0].y;
        }
        gpx_fill_polygon(gpx, pts, n, (color)(shape & 1),
            (bmode)((shape >> 1) & 1), pattern, (uint8_t)(1 + shape % 5),
            (shape & 1) ? &clip : (const rect_t *)0);
        record_screen();
    }

    TEST_END();
}
