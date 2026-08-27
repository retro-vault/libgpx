/* Sprite show/hide on the Partner is an XOR identity: the framebuffer is not
 * CPU-readable, so there is no save-under. gpx_show_sprite XOR-strokes the
 * tiny bitmap in, and gpx_hide_sprite strokes exactly the same path again,
 * toggling every pixel back.
 *
 * The runner captures the raster at each phase and asserts that the raster
 * after hide is byte-identical to the raster before show. That property is
 * the whole contract, and it must hold over plain background, over dense
 * artwork, and with the sprite clipped by a window. */
#include "gdptest.h"

static uint8_t solid[1] = {0xFF};
static uint8_t check[2] = {0xAA, 0x55};

static void scene(gpx_t *gpx)
{
    static rect_t base = {0, 0, 1023, 255};
    static rect_t panel = {60, 40, 500, 200};
    coord i;

    gpx_clrscr();
    /* Deliberately busy: solid ink, half-tone, and hairlines, so a sprite
     * dropped anywhere lands on a mix of set and clear pixels. */
    gpx_fill_rectangle(gpx, &panel, CO_FORE, BM_CPY, check, 2, 0);
    for (i = 0; i < 10; i++)
        gpx_draw_line(gpx, 0, (coord)(i * 25), 1023, (coord)(255 - i * 25),
                      CO_FORE, BM_CPY, 0xFF, 0);
    {
        static rect_t blk = {600, 60, 900, 180};
        gpx_fill_rectangle(gpx, &blk, CO_FORE, BM_CPY, solid, 1, 0);
    }
    gpx_draw_rectangle(gpx, &base, CO_FORE, BM_CPY, 0xFF, 0);
}

void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    static sprite_t sp;
    static rect_t win = {200, 90, 400, 170};
    uint8_t which;

    /* --- 1: every stock cursor, XOR'd in over busy artwork ------------- */
    scene(gpx);
    gdp_phase();                       /* clean plate */

    sp.background = 0;                 /* unused on Partner: XOR is the undo */
    sp.clip = 0;
    for (which = 0; which <= GPXSB_CURSOR_HAND; which++) {
        sp.bitmap = gpx_get_stock_bmp(which);
        sp.x = (coord)(120 + which * 150);
        sp.y = 100;
        gpx_show_sprite(gpx, &sp);
    }
    gdp_phase();                       /* all five visible */

    for (which = 0; which <= GPXSB_CURSOR_HAND; which++) {
        sp.bitmap = gpx_get_stock_bmp(which);
        sp.x = (coord)(120 + which * 150);
        sp.y = 100;
        gpx_hide_sprite(gpx, &sp);
    }
    gdp_phase();                       /* must equal the clean plate */

    /* --- 2: a sprite walked across the scene, one step at a time ------- */
    scene(gpx);
    gdp_phase();                       /* clean plate */

    sp.bitmap = gpx_get_stock_bmp(GPXSB_CURSOR_CLASSIC);
    sp.clip = 0;
    sp.y = 120;
    for (sp.x = 40; sp.x < 900; sp.x = (coord)(sp.x + 37)) {
        gpx_show_sprite(gpx, &sp);
        gpx_hide_sprite(gpx, &sp);
    }
    gdp_phase();                       /* must equal the clean plate */

    /* --- 3: clipped sprite; show and hide read the same rect ----------- */
    scene(gpx);
    gpx_draw_rectangle(gpx, &win, CO_FORE, BM_CPY, 0xAA, 0);
    gdp_phase();                       /* clean plate */

    sp.clip = &win;
    sp.y = 86;
    for (sp.x = 180; sp.x < 430; sp.x = (coord)(sp.x + 30)) {
        gpx_show_sprite(gpx, &sp);
        sp.y = (coord)(sp.y + 12);
    }
    gdp_phase();                       /* partly-clipped sprites visible */

    sp.y = 86;
    for (sp.x = 180; sp.x < 430; sp.x = (coord)(sp.x + 30)) {
        gpx_hide_sprite(gpx, &sp);
        sp.y = (coord)(sp.y + 12);
    }
    gdp_done();                        /* must equal the clean plate */
}
