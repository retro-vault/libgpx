/* Per-primitive Z80 cost on the Partner GDP.
 *
 * Each phase runs one primitive in a tight loop and HALTs, so the runner can
 * difference the T-state counter across the phase and divide by the
 * iteration count. EF9367 commands execute asynchronously; the measured
 * CPU cost includes any waits for the emulated GDP to finish drawing. */
#include "gdptest.h"

static uint8_t solid[1] = {0xFF};
static uint8_t brick[4] = {0xFF, 0x88, 0x88, 0x88};

/* Actual 16x8 Tiny outline. Partner does not support raster 1bpp assets;
 * benchmarking one would only time its unsupported-encoding return. */
static const uint8_t glyph[] = {
    BMP_SIG_STRIDE(BMP_ENC_TINY, 0), 16, 8, 16, 0,
    0xE0, 0xE0, 0xE0, 0xE0, 0xE0, /* right 15 */
    0x98, 0x98, 0x88,             /* down 7 */
    0xE2, 0xE2, 0xE2, 0xE2, 0xE2, /* left 15 */
    0x9C, 0x9C, 0x8C              /* up 7 */
};

static const char sample[] = "Iskra Delta Partner 0123456789";

void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    static sprite_t sp;
    static rect_t win = {100, 40, 900, 220};
    coord i;

    gpx_clrscr();
    gdp_phase();                                    /* 0: settle */

    for (i = 0; i < 200; i++)                       /* 1: hw vector line */
        gpx_draw_line(gpx, 20, 20, 900, (coord)(30 + (i & 63)),
                      CO_FORE, BM_CPY, 0xFF, 0);
    gdp_phase();

    for (i = 0; i < 200; i++)                       /* 2: same, clipped */
        gpx_draw_line(gpx, 20, 20, 900, (coord)(30 + (i & 63)),
                      CO_FORE, BM_CPY, 0xFF, &win);
    gdp_phase();

    for (i = 0; i < 20; i++)                        /* 3: sw bresenham line */
        gpx_draw_line(gpx, 20, 20, 900, (coord)(30 + (i & 63)),
                      CO_FORE, BM_CPY, 0x9B, 0);
    gdp_phase();

    for (i = 0; i < 2000; i++)                      /* 4: pixels */
        gpx_draw_pixel(gpx, (coord)(i & 1023), (coord)(i & 255),
                       CO_FORE, BM_CPY, 0);
    gdp_phase();

    {
        static rect_t r = {100, 40, 700, 200};      /* 5: solid fill */
        for (i = 0; i < 5; i++)
            gpx_fill_rectangle(gpx, &r, CO_FORE, BM_CPY, solid, 1, 0);
    }
    gdp_phase();

    {
        static rect_t r = {100, 40, 400, 100};      /* 6: patterned fill */
        for (i = 0; i < 2; i++)                     /*    (sw path) */
            gpx_fill_rectangle(gpx, &r, CO_FORE, BM_CPY, brick, 4, 0);
    }
    gdp_phase();

    for (i = 0; i < 200; i++)                       /* 7: bitmap blit */
        gpx_draw_bmp(gpx, (coord)(i & 511), (coord)(i & 127),
                     (bmp_t *)glyph, 0);
    gdp_phase();

    for (i = 0; i < 20; i++)                        /* 8: text */
        gpx_draw_text(gpx, 20, (coord)(20 + (i & 127)), sample,
                      gpx_get_system_font(), CO_FORE, BM_CPY, 0);
    gdp_phase();

    for (i = 0; i < 4; i++)                         /* 10: clrscr alone */
        gpx_clrscr();
    gdp_phase();

    for (i = 0; i < 4; i++) {                       /* 11: the work alone */
        coord w;
        uint8_t k;
        for (k = 0; k < 40; k++)
            w = gpx_measure_text(sample, gpx_get_system_font());
        (void)w;
    }
    gdp_phase();

    /* 12: the same clears, each followed by CPU work that does not touch the
     * GDP. A screen clear is one or two whole frames of chip time, so with
     * the fence on the way in rather than the way out this measuring work
     * runs while the clear is still scanning, and costs close to nothing. */
    for (i = 0; i < 4; i++) {
        coord w;
        uint8_t k;
        gpx_clrscr();
        for (k = 0; k < 40; k++)
            w = gpx_measure_text(sample, gpx_get_system_font());
        (void)w;
    }
    gdp_phase();

    sp.bitmap = gpx_get_stock_bmp(GPXSB_CURSOR_CLASSIC);
    sp.background = 0;
    sp.clip = 0;
    sp.y = 120;
    for (i = 0; i < 100; i++) {                     /* 9: sprite show+hide */
        sp.x = (coord)(100 + (i & 255));
        gpx_show_sprite(gpx, &sp);
        gpx_hide_sprite(gpx, &sp);
    }
    gdp_done();
}
