/* Differential coverage of large clipped circles and 16-bit pattern
 * indices, including empty rows and non-power-of-two pattern lengths. */
#include "zxtest.h"

void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    uint8_t pattern[5];
    rect_t clip;
    uint8_t shape;

    rnd_seed(0xBA91);
    seed_screen_wash();
    clip.x0 = 9; clip.y0 = 7; clip.x1 = 243; clip.y1 = 182;
    pattern[0] = 0; pattern[1] = 0xFF; pattern[2] = 0x81;
    pattern[3] = 0x96; pattern[4] = 0x42;

    for (shape = 0; shape < 8; ++shape) {
        coord x = rnd_between(-24, 280);
        coord y = rnd_between(-24, 216);
        coord r = (coord)(shape * 24);
        uint16_t hash = 0xA731;
        uint16_t i;
        const uint8_t *screen = zx_vram();

        gpx_fill_circle(gpx, x, y, r, (color)(shape & 1),
            (bmode)((shape >> 1) & 1), pattern, (uint8_t)(1 + shape % 5),
            &clip);
        gpx_draw_circle(gpx, x, y, r, CO_FORE, BM_XOR, &clip);
        for (i = 0; i < 0x1800; ++i) {
            hash = (uint16_t)((hash << 1) | (hash >> 15));
            hash ^= screen[i];
        }
        record16(hash);
    }
    TEST_END();
}
