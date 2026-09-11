/* Cross-backend conformance for UI-oriented core primitives. */
#include "libgpx.h"

#ifndef DEMO_MODE
#define DEMO_MODE GPXM_DEFAULT
#endif

uint8_t gdp_finished;
#define phase() __asm__("halt")
#define done()  do { gdp_finished = 0xA5; __asm__("halt"); } while (0)

static uint8_t solid[] = {0xff};
static uint8_t checker[] = {0x55, 0xaa};

static void cursor_hotspot(const bmp_t *bitmap, uint8_t *x, uint8_t *y)
{
    const uint8_t *trailer = &bitmap->bitmap[bitmap->size];

    if (BMP_ENC(bitmap->signature) == BMP_ENC_TINY ||
        BMP_ENC(bitmap->signature) == BMP_ENC_TINY_MASK) {
        *x = trailer[0];
        *y = trailer[1];
    } else {
        *x = (uint8_t)(trailer[0] & 0x0f);
        *y = (uint8_t)(trailer[0] >> 4);
    }
}

void main(void)
{
    gpx_t *gpx = gpx_create(DEMO_MODE);
    rect_t r;
    uint8_t mask;

    /* All sixteen masks, packed into a regular grid. */
    gpx_clrscr();
    for (mask = 0; mask < 16; ++mask) {
        r.x0 = (coord)(4 + (mask & 3) * 60);
        r.y0 = (coord)(4 + (mask >> 2) * 38);
        r.x1 = (coord)(r.x0 + 42);
        r.y1 = (coord)(r.y0 + 24);
        (void)gpx_draw_box(gpx, &r, mask,
            CO_FORE, BM_CPY, GPX_LP_SOLID, 0);
    }
    phase();

    /* Dotted focus-style boxes, clipping, and degenerate rectangles. */
    gpx_clrscr();
    {
        static rect_t clip = {30, 20, 220, 165};
        static rect_t boxes[] = {
            {4, 4, 100, 50}, {110, 4, 250, 70},
            {20, 90, 20, 170}, {40, 100, 180, 100},
            {200, 120, 200, 120}
        };
        uint8_t i;
        for (i = 0; i < 5; ++i)
            (void)gpx_draw_box(gpx, &boxes[i], GPX_EDGE_ALL,
                CO_FORE, BM_CPY, GPX_LP_DOTTED, &clip);
    }
    phase();

    /* Opaque fill replaces both zero and one pattern bits. */
    gpx_clrscr();
    {
        static rect_t background = {0, 0, 255, 191};
        static rect_t fill = {13, 11, 242, 178};
        static rect_t tiles[] = {
            {13, 11, 127, 94}, {128, 11, 242, 94},
            {13, 95, 127, 178}, {128, 95, 242, 178}
        };
        uint8_t i;
        gpx_fill_rectangle(gpx, &background,
            CO_FORE, BM_CPY, solid, 1, 0);
        for (i = 0; i < 4; ++i)
            gpx_fill_rectangle(gpx, &fill,
                CO_FORE, BM_CPY, checker, 2, &tiles[i]);
    }
    phase();

    /* Hotspot metadata is stored directly after each stock bitmap. */
    gpx_clrscr();
    for (mask = 0; mask <= GPXSB_CURSOR_RESIZE; ++mask) {
        bmp_t *bitmap = gpx_get_stock_bmp(mask);
        if (bitmap) {
            uint8_t hotspot_x;
            uint8_t hotspot_y;
            coord x = (coord)(8 + mask * 40);
            cursor_hotspot(bitmap, &hotspot_x, &hotspot_y);
            gpx_draw_line(gpx, x, 10,
                (coord)(x + hotspot_x), 10,
                CO_FORE, BM_CPY, GPX_LP_SOLID, 0);
            gpx_draw_line(gpx, x, 20,
                (coord)(x + hotspot_y), 20,
                CO_FORE, BM_CPY, GPX_LP_SOLID, 0);
        }
    }
    phase();

    /* BM_OR paints one bits only, while BM_CPY also replaces the gaps. */
    gpx_clrscr();
    {
        static rect_t background = {0, 0, 255, 191};
        static rect_t fill = {12, 12, 118, 70};
        gpx_fill_rectangle(gpx, &background,
            CO_FORE, BM_CPY, solid, 1, 0);
        gpx_fill_rectangle(gpx, &fill,
            CO_BACK, BM_OR, checker, 2, 0);
        (void)gpx_draw_line(gpx, 132, 20, 240, 68,
            CO_BACK, BM_OR, GPX_LP_DASHED_SHORT, 0);
        (void)gpx_draw_line(gpx, 132, 90, 240, 138,
            CO_BACK, BM_CPY, GPX_LP_DASHED_SHORT, 0);
    }
    done();
}
