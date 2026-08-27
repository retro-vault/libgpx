/* Cross-backend conformance: the same drawing on both backends must produce
 * the same pixels. Everything stays inside 256x192 so the ZX display file and
 * the Partner raster can be compared directly. */
#include "libgpx.h"

/* The CPC has two display modes behind one library and is compared in both;
 * every other backend accepts this and ignores it. */
#ifndef DEMO_MODE
#define DEMO_MODE GPXM_DEFAULT
#endif

uint8_t gdp_finished;
#define phase() __asm__("halt")
#define done()  do { gdp_finished = 0xA5; __asm__("halt"); } while (0)

void main(void)
{
    gpx_t *gpx = gpx_create(DEMO_MODE);
    coord i;

    /* --- solid lines, several slopes and both directions --- */
    gpx_clrscr();
    gpx_draw_line(gpx, 0, 0, 200, 100, CO_FORE, BM_CPY, 0xFF, 0);
    gpx_draw_line(gpx, 0, 100, 200, 0, CO_FORE, BM_CPY, 0xFF, 0);
    gpx_draw_line(gpx, 10, 120, 240, 150, CO_FORE, BM_CPY, 0xFF, 0);
    gpx_draw_line(gpx, 10, 190, 60, 110, CO_FORE, BM_CPY, 0xFF, 0);
    gpx_draw_line(gpx, 0, 60, 255, 60, CO_FORE, BM_CPY, 0xFF, 0);
    gpx_draw_line(gpx, 128, 0, 128, 191, CO_FORE, BM_CPY, 0xFF, 0);
    phase();

    /* --- patterned lines: every pattern Partner diverts to a CR2 style --- */
    gpx_clrscr();
    gpx_draw_line(gpx, 0, 10, 250, 10, CO_FORE, BM_CPY, 0xAA, 0);
    gpx_draw_line(gpx, 0, 30, 250, 30, CO_FORE, BM_CPY, 0xF0, 0);
    gpx_draw_line(gpx, 0, 50, 250, 50, CO_FORE, BM_CPY, 0xE4, 0);
    gpx_draw_line(gpx, 0, 70, 250, 70, CO_FORE, BM_CPY, 0xCC, 0);
    gpx_draw_line(gpx, 0, 90, 250, 90, CO_FORE, BM_CPY, 0x9B, 0);
    gpx_draw_line(gpx, 0, 110, 250, 160, CO_FORE, BM_CPY, 0xAA, 0);
    phase();

    /* --- the returned pattern must chain across segments identically --- */
    gpx_clrscr();
    {
        uint8_t p = 0xAA;
        coord x = 0;
        for (i = 0; i < 8; i++) {
            p = gpx_draw_line(gpx, x, 20, (coord)(x + 30), 20,
                              CO_FORE, BM_CPY, p, 0);
            x = (coord)(x + 30);
        }
        /* Record the final rotation as a bar of that many pixels. */
        for (i = 0; i < 8; i++)
            if (p & (1 << i))
                gpx_draw_line(gpx, 0, (coord)(40 + i * 4), 40,
                              (coord)(40 + i * 4), CO_FORE, BM_CPY, 0xFF, 0);
    }
    phase();

    /* --- XOR must ignore the colour argument on both backends --- */
    gpx_clrscr();
    {
        static rect_t band = {0, 0, 250, 80};
        static uint8_t solid[1] = {0xFF};
        gpx_fill_rectangle(gpx, &band, CO_FORE, BM_CPY, solid, 1, 0);
        gpx_draw_line(gpx, 10, 20, 240, 20, CO_FORE, BM_XOR, 0xFF, 0);
        gpx_draw_line(gpx, 10, 40, 240, 40, CO_BACK, BM_XOR, 0xFF, 0);
        gpx_draw_line(gpx, 10, 100, 240, 100, CO_FORE, BM_XOR, 0xFF, 0);
        gpx_draw_line(gpx, 10, 120, 240, 120, CO_BACK, BM_XOR, 0xFF, 0);
    }
    phase();

    /* --- rectangles and pattern fills --- */
    gpx_clrscr();
    {
        static rect_t a = {5, 5, 120, 60};
        static rect_t b = {130, 5, 250, 60};
        static rect_t c = {5, 70, 120, 130};
        static uint8_t check[2] = {0xAA, 0x55};
        static uint8_t brick[4] = {0xFF, 0x88, 0x88, 0x88};
        static uint8_t solid[1] = {0xFF};
        gpx_fill_rectangle(gpx, &a, CO_FORE, BM_CPY, check, 2, 0);
        gpx_fill_rectangle(gpx, &b, CO_FORE, BM_CPY, brick, 4, 0);
        gpx_fill_rectangle(gpx, &c, CO_FORE, BM_CPY, solid, 1, 0);
        gpx_draw_rectangle(gpx, &b, CO_FORE, BM_CPY, 0xAA, 0);
    }
    phase();

    /* --- clipping --- */
    gpx_clrscr();
    {
        static rect_t win = {40, 40, 200, 150};
        gpx_draw_rectangle(gpx, &win, CO_FORE, BM_CPY, 0xFF, 0);
        for (i = 0; i <= 190; i += 19)
            gpx_draw_line(gpx, 0, 0, 255, (coord)i, CO_FORE, BM_CPY, 0xFF, &win);
        for (i = 0; i <= 250; i += 25)
            gpx_draw_line(gpx, (coord)i, 191, 255, 0, CO_FORE, BM_CPY, 0xAA, &win);
        gpx_draw_pixel(gpx, 39, 39, CO_FORE, BM_CPY, &win);
        gpx_draw_pixel(gpx, 40, 40, CO_FORE, BM_CPY, &win);
        gpx_draw_pixel(gpx, 200, 150, CO_FORE, BM_CPY, &win);
        gpx_draw_pixel(gpx, 201, 151, CO_FORE, BM_CPY, &win);
    }
    phase();

    /* --- is each backend internally consistent about pattern phase? ---
     * A fill row and a line with the same pattern over the same x range must
     * light the same pixels. x0 is byte-aligned so the ZX byte grid cannot
     * confuse the answer; this isolates MSB-first from LSB-first. */
    gpx_clrscr();
    {
        static rect_t r = {8, 10, 71, 13};
        static uint8_t patt[1] = {0xAA};
        gpx_fill_rectangle(gpx, &r, CO_FORE, BM_CPY, patt, 1, 0);
        gpx_draw_line(gpx, 8, 20, 71, 20, CO_FORE, BM_CPY, 0xAA, 0);
        /* and again at an unaligned x0, to expose byte-grid anchoring */
        {
            static rect_t r2 = {13, 40, 76, 43};
            gpx_fill_rectangle(gpx, &r2, CO_FORE, BM_CPY, patt, 1, 0);
            gpx_draw_line(gpx, 13, 50, 76, 50, CO_FORE, BM_CPY, 0xAA, 0);
        }
    }
    phase();

    /* --- clipped diagonals: intersection math vs pattern phase ---
     * The solid pair isolates where Cohen-Sutherland puts the clipped
     * endpoints. The patterned pair adds the question of whether the pattern
     * keeps the phase it would have had unclipped. */
    gpx_clrscr();
    {
        static rect_t w = {60, 60, 190, 130};
        gpx_draw_line(gpx, 0, 20, 255, 170, CO_FORE, BM_CPY, 0xFF, &w);
        gpx_draw_line(gpx, 0, 170, 255, 20, CO_FORE, BM_CPY, 0xFF, &w);
        gpx_draw_line(gpx, 0, 40, 255, 150, CO_FORE, BM_CPY, 0xAA, &w);
        gpx_draw_line(gpx, 0, 150, 255, 40, CO_FORE, BM_CPY, 0xAA, &w);
        /* steep: major axis is Y, which is where the phase correction after
         * clipping has to count Y steps rather than X steps */
        gpx_draw_line(gpx, 80, 0, 120, 191, CO_FORE, BM_CPY, 0xAA, &w);
        gpx_draw_line(gpx, 150, 191, 175, 0, CO_FORE, BM_CPY, 0xAA, &w);
        gpx_draw_line(gpx, 100, 0, 110, 191, CO_FORE, BM_CPY, 0xE4, &w);
        gpx_draw_line(gpx, 130, 191, 140, 0, CO_FORE, BM_CPY, 0x9B, &w);
    }
    phase();

    /* --- XOR must knock text out of solid ink on both backends --- */
    gpx_clrscr();
    {
        static rect_t band = {0, 0, 250, 40};
        static uint8_t solid[1] = {0xFF};
        gpx_fill_rectangle(gpx, &band, CO_FORE, BM_CPY, solid, 1, 0);
        gpx_draw_text(gpx, 4, 4, "XOR", gpx_get_system_font(),
                      CO_FORE, BM_XOR, 0);
    }
    phase();

    /* --- text --- */
    gpx_clrscr();
    gpx_draw_text(gpx, 4, 10, "Iskra Delta 0123", gpx_get_system_font(),
                  CO_FORE, BM_CPY, 0);
    gpx_draw_text(gpx, 4, 60, "Partner !@#$%", gpx_get_tiny_font(),
                  CO_FORE, BM_CPY, 0);
    done();
}
