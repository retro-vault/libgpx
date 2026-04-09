#include "libgpx.h"

static uint8_t std_sprite[] = {
    BMP_SIG_STRIDE(BMP_ENC_1BPP, 2), 12, 6, 12, 0,
    0xFF, 0xF0,
    0x80, 0x10,
    0xBF, 0xD0,
    0xA0, 0x50,
    0xBF, 0xD0,
    0x80, 0x10
};

void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    uint8_t fpatt[2] = {0xAA, 0x55};
    rect_t center_bg = {36, 18, 63, 39};
    rect_t right_bg = {244, 12, 255, 31};
    rect_t edge_bg = {248, 184, 255, 191};
    uint8_t classic_bg[GPX_SPRITE_BG_SIZE];
    uint8_t std_bg[GPX_SPRITE_BG_SIZE];
    uint8_t hourglass_bg[GPX_SPRITE_BG_SIZE];
    uint8_t hand_bg[GPX_SPRITE_BG_SIZE];
    sprite_t classic = {40, 20, gpx_get_stock_bmp(GPXSB_CURSOR_CLASSIC), (bmp_t *)classic_bg};
    sprite_t standard = {250, 14, (bmp_t *)std_sprite, (bmp_t *)std_bg};
    sprite_t hourglass = {252, 186, gpx_get_stock_bmp(GPXSB_CURSOR_HOURGLASS), (bmp_t *)hourglass_bg};
    sprite_t hand = {46, 22, gpx_get_stock_bmp(GPXSB_CURSOR_HAND), (bmp_t *)hand_bg};

    gpx_clrscr();
    gpx_fill_rectangle(gpx, &center_bg, CO_FORE, BM_CPY, fpatt, 2, (const rect_t *)0);
    gpx_fill_rectangle(gpx, &right_bg, CO_FORE, BM_CPY, fpatt, 2, (const rect_t *)0);
    gpx_fill_rectangle(gpx, &edge_bg, CO_FORE, BM_CPY, fpatt, 2, (const rect_t *)0);

    gpx_show_sprite(gpx, &classic);
    gpx_hide_sprite(gpx, &classic);

    gpx_show_sprite(gpx, &standard);
    gpx_hide_sprite(gpx, &standard);

    gpx_show_sprite(gpx, &hourglass);
    gpx_hide_sprite(gpx, &hourglass);

    gpx_show_sprite(gpx, &hand);

    __asm
        halt
    __endasm;
}
