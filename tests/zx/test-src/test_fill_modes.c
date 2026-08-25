#include "zxtest.h"

/* CO_BACK and BM_XOR fills over content. A pattern 0-bit is untouched in
 * every mode, so the wash underneath must show through the gaps. */
void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    static uint8_t solid[1] = {0xFF};
    static uint8_t dash[2] = {0xAA, 0x55};
    rect_t r;
    coord i;

    seed_screen_wash();

    /* Solid erase, dashed erase. */
    r.x0 = 4; r.y0 = 4; r.x1 = 120; r.y1 = 30;
    gpx_fill_rectangle(gpx, &r, CO_BACK, BM_CPY, solid, 1,
        (const rect_t *)0);
    r.x0 = 130; r.x1 = 250;
    gpx_fill_rectangle(gpx, &r, CO_BACK, BM_CPY, dash, 2,
        (const rect_t *)0);

    /* XOR with both colours: the colour must not matter. */
    r.x0 = 4; r.y0 = 40; r.x1 = 120; r.y1 = 66;
    gpx_fill_rectangle(gpx, &r, CO_FORE, BM_XOR, dash, 2,
        (const rect_t *)0);
    r.x0 = 130; r.x1 = 246;
    gpx_fill_rectangle(gpx, &r, CO_BACK, BM_XOR, dash, 2,
        (const rect_t *)0);

    /* XOR twice restores the content exactly. */
    r.x0 = 10; r.y0 = 80; r.x1 = 240; r.y1 = 110;
    for (i = 0; i < 2; ++i)
        gpx_fill_rectangle(gpx, &r, CO_FORE, BM_XOR, solid, 1,
            (const rect_t *)0);

    /* Solid set over solid erase leaves a clean block regardless of what
     * was underneath. */
    r.x0 = 10; r.y0 = 120; r.x1 = 240; r.y1 = 150;
    gpx_fill_rectangle(gpx, &r, CO_BACK, BM_CPY, solid, 1,
        (const rect_t *)0);
    gpx_fill_rectangle(gpx, &r, CO_FORE, BM_CPY, dash, 2,
        (const rect_t *)0);

    TEST_END();
}
