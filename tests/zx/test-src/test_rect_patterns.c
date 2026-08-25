#include "zxtest.h"

/* Dashed rectangle outlines over content, in all three modes. The pattern
 * phase runs continuously round the outline, so the corners are where a
 * phase bug shows up. */
void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    rect_t r;
    uint8_t p;

    seed_screen_wash();

    for (p = 0; p < 8; ++p) {
        r.x0 = (coord)(4 + p * 30);
        r.y0 = 4;
        r.x1 = (coord)(r.x0 + 25);
        r.y1 = 40;
        gpx_draw_rectangle(gpx, &r, CO_FORE, BM_CPY, patt_bytes[p],
            (const rect_t *)0);

        r.y0 = 50; r.y1 = 86;
        gpx_draw_rectangle(gpx, &r, CO_BACK, BM_CPY, patt_bytes[p],
            (const rect_t *)0);

        r.y0 = 96; r.y1 = 132;
        gpx_draw_rectangle(gpx, &r, CO_FORE, BM_XOR, patt_bytes[p],
            (const rect_t *)0);

        /* BM_XOR ignores the colour: this row must match the one above. */
        r.y0 = 142; r.y1 = 178;
        gpx_draw_rectangle(gpx, &r, CO_BACK, BM_XOR, patt_bytes[p],
            (const rect_t *)0);
    }

    /* Drawing the same dashed outline twice in XOR restores the content. */
    r.x0 = 200; r.y0 = 150; r.x1 = 250; r.y1 = 185;
    gpx_draw_rectangle(gpx, &r, CO_FORE, BM_XOR, 0x6D, (const rect_t *)0);
    gpx_draw_rectangle(gpx, &r, CO_FORE, BM_XOR, 0x6D, (const rect_t *)0);

    TEST_END();
}
