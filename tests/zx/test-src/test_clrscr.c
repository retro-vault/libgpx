#include "zxtest.h"

/* Clearing must zero the whole display file, reset every attribute cell and
 * set the border, from any starting state. */
void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    static uint8_t solid[1] = {0xFF};
    rect_t r;

    /* Dirty the screen thoroughly first: pixels, and attribute bytes poked
     * directly so a clear that skips them is caught. */
    seed_screen(0xFF);
    {
        uint8_t *attrs = zx_vram() + 0x1800;
        uint16_t i;
        for (i = 0; i < 0x300; ++i)
            attrs[i] = (uint8_t)(i | 0x47);
    }
    r.x0 = 0; r.y0 = 0; r.x1 = 255; r.y1 = 191;
    gpx_fill_rectangle(gpx, &r, CO_FORE, BM_CPY, solid, 1,
        (const rect_t *)0);

    gpx_clrscr();

    /* Read the result back independently of the screen comparison: a
     * checksum over the display file, the attribute area, and the first
     * attribute byte. */
    {
        uint8_t *p = zx_vram();
        uint16_t sum = 0;
        uint16_t i;
        for (i = 0; i < 0x1800; ++i)
            sum = (uint16_t)(sum + p[i]);
        record16(sum);
        sum = 0;
        for (i = 0x1800; i < 0x1B00; ++i)
            sum = (uint16_t)(sum + p[i]);
        record16(sum);
        record(p[0x1800]);
        record(p[0x1AFF]);
    }

    /* Clearing an already-clear screen is idempotent. */
    gpx_clrscr();

    /* Draw one pixel in each corner so the test would fail if clrscr also
     * ran after this point. */
    gpx_draw_pixel(gpx, 0, 0, CO_FORE, BM_CPY, (const rect_t *)0);
    gpx_draw_pixel(gpx, 255, 0, CO_FORE, BM_CPY, (const rect_t *)0);
    gpx_draw_pixel(gpx, 0, 191, CO_FORE, BM_CPY, (const rect_t *)0);
    gpx_draw_pixel(gpx, 255, 191, CO_FORE, BM_CPY, (const rect_t *)0);

    TEST_END();
}
