#include "zxtest.h"

/* Serialized fonts cover both offset byte orders, invalid and empty glyphs,
 * and widths whose per-character advance crosses an 8-bit boundary. */
static uint8_t font_bytes[] = {
    0, 'A', 'E', 3, 5, 2, 1, 0,
    18,0, 25,0, 34,0, 41,0, 0,0,
    0x00,3,2,2,0, 0xA0,0x60,
    0x10,5,2,4,0, 0x87,0x50,0x2F,0xA0,
    0x20,4,2,2,0, 0xFF,0xFF,
    0x00,0,2,2,0, 0xFF,0xFF
};
static uint8_t sprite_bytes[] = {
    0x11,16,3,12,0,
    0x93,0xD7,0xA5,0x69,
    0x6C,0xA8,0x5A,0x96,
    0xDB,0x72,0x3C,0xC3
};

void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    uint8_t bg[GPX_SPRITE_BG_SIZE];
    uint8_t pattern[255];
    sprite_t sprite;
    rect_t r = {-20, -32768, 100, 180};
    rect_t clip = {11, 170, 83, 182};
    uint8_t order, mode, phase, width, i;
    uint16_t hash;

    seed_screen_wash();
    for (order = 0; order < 2; ++order) {
        record16((uint16_t)gpx_measure_text("ZABCDE@ABCDE", (font_t *)font_bytes));
        for (mode = 0; mode < 4; ++mode)
            for (phase = 0; phase < 8; ++phase) {
                gpx_set_text_background(gpx, (textbg)(mode >> 1));
                gpx_draw_text(gpx, (coord)(8 + phase * 27),
                    (coord)(order * 50 + mode * 10), "ABCDE",
                    (font_t *)font_bytes, (color)(phase & 1),
                    (bmode)(mode & 1), (const rect_t *)0);
            }
        font_bytes[6] = 255;
        font_bytes[3] = 250;
        record16((uint16_t)gpx_measure_text("ABCDEABCDE", (font_t *)font_bytes));
        font_bytes[6] = 1;
        font_bytes[3] = 3;
        font_bytes[0] ^= FONT_FLAG_OFFSETS_BE;
        for (i = 8; i < 18; i += 2) {
            width = font_bytes[i];
            font_bytes[i] = font_bytes[i + 1];
            font_bytes[i + 1] = width;
        }
    }

    /* The saved bytes are observable too: zero padding and each partial
     * right-edge mask must agree, even when hide would clip those bits. */
    sprite.bitmap = (bmp_t *)sprite_bytes;
    sprite.background = (bmp_t *)bg;
    sprite.clip = (const rect_t *)0;
    for (width = 1; width <= 16; ++width) {
        sprite_bytes[1] = width;
        hash = 0;
        for (phase = 0; phase < 8; ++phase) {
            sprite.x = (coord)(247 + phase);
            sprite.y = 190;
            gpx_show_sprite(gpx, &sprite);
            for (i = 0; i < GPX_SPRITE_BG_SIZE; ++i)
                hash = (uint16_t)((hash << 1) ^ bg[i] ^ (hash >> 15));
            gpx_hide_sprite(gpx, &sprite);
        }
        record16(hash);
    }

    for (i = 0; i < 255; ++i)
        pattern[i] = (uint8_t)(i * 73 + 0x93);
    gpx_fill_rectangle(gpx, &r, CO_FORE, BM_XOR, pattern, 255, &clip);
    gpx_fill_rectangle(gpx, &r, CO_BACK, BM_CPY, pattern, 5, &clip);
    gpx_fill_rectangle(gpx, &r, CO_FORE, BM_XOR, pattern, 1, &clip);
    TEST_END();
}
