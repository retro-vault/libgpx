#include "zxtest.h"

/* Every stock bitmap, drawn over content at several phases. These are
 * masked cursors, so they carry a hotspot trailer that must not be blitted. */
void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    bmp_t *b;
    uint8_t id;
    coord phase;

    seed_screen_wash();

    for (id = 0; id <= GPXSB_CURSOR_RESIZE; ++id) {
        uint8_t packed;
        b = gpx_get_stock_bmp(id);
        if (b == (bmp_t *)0)
            continue;
        packed = b->bitmap[b->size];
        record((packed & 0x0F) >= b->w || (packed >> 4) >= b->h);
        for (phase = 0; phase < 8; ++phase)
            gpx_draw_bmp(gpx, (coord)(8 + phase + id * 40),
                (coord)(phase * 14), b, (const rect_t *)0);
        /* Clipped and against the screen edge. */
        {
            rect_t clip = {(coord)(id * 40 + 4), 130,
                           (coord)(id * 40 + 12), 140};
            gpx_draw_bmp(gpx, (coord)(id * 40), 128, b, &clip);
        }
        gpx_draw_bmp(gpx, (coord)(250 - id), (coord)(150 + id * 6), b,
            (const rect_t *)0);
        gpx_draw_bmp(gpx, (coord)-(id + 1), (coord)(150 + id * 6), b,
            (const rect_t *)0);
    }

    /* Unknown ids return NULL and must not draw. */
    record(gpx_get_stock_bmp(GPXSB_CURSOR_RESIZE + 1) != (bmp_t *)0);
    record(gpx_get_stock_bmp(200) != (bmp_t *)0);

    TEST_END();
}
