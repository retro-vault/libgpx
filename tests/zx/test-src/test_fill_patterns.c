#include "zxtest.h"

/* Fill patterns: every length 1..8, applied over seeded content so that
 * the pattern 0-bits are visibly left alone, and at several x offsets so
 * the horizontal phase of the pattern is exercised. */
void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    static uint8_t p1[1] = {0xAA};
    static uint8_t p2[2] = {0xAA, 0x55};
    static uint8_t p3[3] = {0xFF, 0x18, 0x81};
    static uint8_t p4[4] = {0x11, 0x22, 0x44, 0x88};
    static uint8_t p5[5] = {0xF0, 0xE1, 0xC3, 0x87, 0x0F};
    static uint8_t p8[8] = {0x80, 0x40, 0x20, 0x10, 0x08, 0x04, 0x02, 0x01};
    rect_t r;
    coord phase;

    seed_screen_wash();

    /* Same pattern started at eight different x offsets: the pattern is
     * anchored to the rectangle, not to the byte grid. */
    for (phase = 0; phase < 8; ++phase) {
        r.x0 = (coord)(phase * 30 + phase);
        r.y0 = 0;
        r.x1 = (coord)(r.x0 + 25);
        r.y1 = 20;
        gpx_fill_rectangle(gpx, &r, CO_FORE, BM_CPY, p3, 3,
            (const rect_t *)0);
    }

    /* Each pattern length down the screen. Row n uses fpatt[n % len], so a
     * tall rectangle proves the vertical index wraps correctly. */
    r.x0 = 4; r.x1 = 60;
    r.y0 = 30; r.y1 = 60;
    gpx_fill_rectangle(gpx, &r, CO_FORE, BM_CPY, p1, 1, (const rect_t *)0);
    r.x0 = 66; r.x1 = 122;
    gpx_fill_rectangle(gpx, &r, CO_FORE, BM_CPY, p2, 2, (const rect_t *)0);
    r.x0 = 128; r.x1 = 184;
    gpx_fill_rectangle(gpx, &r, CO_FORE, BM_CPY, p4, 4, (const rect_t *)0);
    r.x0 = 190; r.x1 = 246;
    gpx_fill_rectangle(gpx, &r, CO_FORE, BM_CPY, p5, 5, (const rect_t *)0);

    r.y0 = 70; r.y1 = 110;
    r.x0 = 4; r.x1 = 120;
    gpx_fill_rectangle(gpx, &r, CO_FORE, BM_CPY, p8, 8, (const rect_t *)0);

    /* A one-row fill uses only fpatt[0]; a two-row fill uses [0] and [1]. */
    r.x0 = 130; r.y0 = 70; r.x1 = 250; r.y1 = 70;
    gpx_fill_rectangle(gpx, &r, CO_FORE, BM_CPY, p5, 5, (const rect_t *)0);
    r.y0 = 72; r.y1 = 73;
    gpx_fill_rectangle(gpx, &r, CO_FORE, BM_CPY, p5, 5, (const rect_t *)0);

    /* An all-zero pattern must leave every pixel alone. */
    {
        static uint8_t pz[2] = {0x00, 0x00};
        r.x0 = 0; r.y0 = 120; r.x1 = 255; r.y1 = 140;
        gpx_fill_rectangle(gpx, &r, CO_FORE, BM_CPY, pz, 2,
            (const rect_t *)0);
    }

    /* fpatt_len 0 is a documented no-op. */
    r.x0 = 0; r.y0 = 145; r.x1 = 255; r.y1 = 160;
    gpx_fill_rectangle(gpx, &r, CO_FORE, BM_CPY, p1, 0, (const rect_t *)0);

    TEST_END();
}
