#include "zxtest.h"
#include "test_bitmaps.h"

/* Save-under sprites at every horizontal bit phase. Show captures the
 * background through a shifted gather, hide replays it, so a round trip
 * must restore the screen exactly whatever the alignment. */
void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    uint8_t bg_store[GPX_SPRITE_BG_SIZE];
    sprite_t s;
    coord phase;

    seed_screen_wash();

    s.background = (bmp_t *)bg_store;
    s.clip = (const rect_t *)0;

    /* Plain sprite: show at each phase and leave it there. */
    s.bitmap = (bmp_t *)bmp_w12;
    for (phase = 0; phase < 8; ++phase) {
        s.x = (coord)(8 + phase);
        s.y = (coord)(phase * 8);
        gpx_show_sprite(gpx, &s);
    }

    /* Masked sprite at each phase. */
    s.bitmap = (bmp_t *)bmp_mask12;
    for (phase = 0; phase < 8; ++phase) {
        s.x = (coord)(70 + phase);
        s.y = (coord)(phase * 8);
        gpx_show_sprite(gpx, &s);
    }

    /* Show then hide at every phase: the wash underneath must come back
     * byte for byte, so this whole band ends unchanged. */
    s.bitmap = (bmp_t *)bmp_w12;
    for (phase = 0; phase < 8; ++phase) {
        s.x = (coord)(140 + phase * 13);
        s.y = 80;
        gpx_show_sprite(gpx, &s);
        gpx_hide_sprite(gpx, &s);
    }
    s.bitmap = (bmp_t *)bmp_mask12;
    for (phase = 0; phase < 8; ++phase) {
        s.x = (coord)(140 + phase * 13);
        s.y = 100;
        gpx_show_sprite(gpx, &s);
        gpx_hide_sprite(gpx, &s);
    }

    /* Walk a sprite one pixel at a time, hiding before each move: the
     * trail must be clean and only the final position visible. */
    s.bitmap = (bmp_t *)bmp_w12;
    s.x = 10;
    s.y = 130;
    gpx_show_sprite(gpx, &s);
    for (phase = 1; phase <= 24; ++phase) {
        gpx_hide_sprite(gpx, &s);
        s.x = (coord)(10 + phase);
        gpx_show_sprite(gpx, &s);
    }

    TEST_END();
}
