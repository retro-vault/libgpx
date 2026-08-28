#include "zxtest.h"

/* Filled discs: the small radii, the pattern paths (a power-of-two length
 * is masked, anything else goes through the divide), and the XOR round
 * trip. Patterns are anchored to the disc's bounding box, so neighbouring
 * rows have to line up vertically. */
void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    uint8_t solid[1];
    uint8_t two[2];
    uint8_t three[3];
    uint8_t five[5];
    coord r;

    solid[0] = 0xFF;
    two[0] = 0xCC;
    two[1] = 0x33;
    three[0] = 0xF0;
    three[1] = 0x0F;
    three[2] = 0xAA;
    five[0] = 0x80;
    five[1] = 0x40;
    five[2] = 0x20;
    five[3] = 0x10;
    five[4] = 0x08;

    seed_screen_wash();

    for (r = 0; r < 9; ++r)
        gpx_fill_circle(gpx, (coord)(12 + r * 22), 16, r,
            CO_FORE, BM_CPY, solid, 1, (const rect_t *)0);

    for (r = 0; r < 9; ++r)
        gpx_fill_circle(gpx, (coord)(12 + r * 22), 42, r,
            CO_BACK, BM_CPY, solid, 1, (const rect_t *)0);

    /* Power-of-two lengths take the masked path, 3 and 5 the divide. */
    gpx_fill_circle(gpx, 40, 100, 30, CO_FORE, BM_CPY, two, 2,
        (const rect_t *)0);
    gpx_fill_circle(gpx, 110, 100, 30, CO_FORE, BM_CPY, three, 3,
        (const rect_t *)0);
    gpx_fill_circle(gpx, 180, 100, 30, CO_FORE, BM_CPY, five, 5,
        (const rect_t *)0);
    gpx_fill_circle(gpx, 235, 100, 18, CO_FORE, BM_CPY, patt_bytes, 8,
        (const rect_t *)0);

    /* An empty pattern draws nothing. */
    gpx_fill_circle(gpx, 128, 96, 20, CO_FORE, BM_CPY, solid, 0,
        (const rect_t *)0);

    /* Filling the same disc twice in XOR restores what was underneath. */
    gpx_fill_circle(gpx, 60, 165, 22, CO_FORE, BM_XOR, two, 2,
        (const rect_t *)0);
    gpx_fill_circle(gpx, 60, 165, 22, CO_FORE, BM_XOR, two, 2,
        (const rect_t *)0);

    /* A fill with the outline of the same radius on top of it: the outline
     * must land on the disc's own edge, not outside it. */
    gpx_fill_circle(gpx, 190, 160, 25, CO_FORE, BM_CPY, solid, 1,
        (const rect_t *)0);
    gpx_draw_circle(gpx, 190, 160, 25, CO_BACK, BM_CPY, (const rect_t *)0);

    TEST_END();
}
