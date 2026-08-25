#include "libgpx.h"

static char *append_dim(char *dst, dim value)
{
    char digits[5];
    uint8_t count = 0;

    do {
        digits[count++] = (char)('0' + (value % 10));
        value /= 10;
    } while (value != 0);

    while (count > 0)
        *dst++ = digits[--count];

    *dst = '\0';
    return dst;
}

static void build_dimension_line(char *dst, const char *label, dim value)
{
    while (*label != '\0')
        *dst++ = *label++;

    *dst++ = ':';
    *dst++ = ' ';
    (void)append_dim(dst, value);
}

static uint8_t classic_bg[GPX_SPRITE_BG_SIZE];
static uint8_t std_bg[GPX_SPRITE_BG_SIZE];
static uint8_t hourglass_bg[GPX_SPRITE_BG_SIZE];
static uint8_t caret_bg[GPX_SPRITE_BG_SIZE];
static uint8_t hand_bg[GPX_SPRITE_BG_SIZE];
static uint8_t classic_bg2[GPX_SPRITE_BG_SIZE];
static uint8_t std_bg2[GPX_SPRITE_BG_SIZE];
static uint8_t hourglass_bg2[GPX_SPRITE_BG_SIZE];
static uint8_t caret_bg2[GPX_SPRITE_BG_SIZE];
static uint8_t hand_bg2[GPX_SPRITE_BG_SIZE];
static sprite_t classic_sprite = {72, 72, 0, (bmp_t *)classic_bg};
static sprite_t std_sprite = {104, 72, 0, (bmp_t *)std_bg};
static sprite_t hourglass_sprite = {136, 72, 0, (bmp_t *)hourglass_bg};
static sprite_t caret_sprite = {168, 72, 0, (bmp_t *)caret_bg};
static sprite_t hand_sprite = {200, 72, 0, (bmp_t *)hand_bg};
static sprite_t classic_sprite2 = {72, 96, 0, (bmp_t *)classic_bg2};
static sprite_t std_sprite2 = {104, 96, 0, (bmp_t *)std_bg2};
static sprite_t hourglass_sprite2 = {136, 96, 0, (bmp_t *)hourglass_bg2};
static sprite_t caret_sprite2 = {168, 96, 0, (bmp_t *)caret_bg2};
static sprite_t hand_sprite2 = {200, 96, 0, (bmp_t *)hand_bg2};

int main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    const font_t *font = gpx_get_system_font();
    char width_line[16];
    char height_line[16];
    uint8_t fpatt[2] = {0xAA, 0x55};
    rect_t screen = {0, 0, 255, 191};

    gpx_clrscr();
    gpx_fill_rectangle(gpx, &screen, CO_FORE, BM_CPY, fpatt, 2, NULL);

    gpx_draw_text(gpx, 0, 0, "loading yos...", font, CO_FORE, BM_CPY, NULL);
    build_dimension_line(width_line, "width", gpx_width());
    build_dimension_line(height_line, "height", gpx_height());
    gpx_draw_text(gpx, 0, 11, width_line, font, CO_BACK, BM_CPY, NULL);
    gpx_draw_text(gpx, 0, 22, height_line, font, CO_BACK, BM_CPY, NULL);

    classic_sprite.bitmap = gpx_get_stock_bmp(GPXSB_CURSOR_CLASSIC);
    std_sprite.bitmap = gpx_get_stock_bmp(GPXSB_CURSOR_STD);
    hourglass_sprite.bitmap = gpx_get_stock_bmp(GPXSB_CURSOR_HOURGLASS);
    caret_sprite.bitmap = gpx_get_stock_bmp(GPXSB_CURSOR_CARET);
    hand_sprite.bitmap = gpx_get_stock_bmp(GPXSB_CURSOR_HAND);
    classic_sprite2.bitmap = classic_sprite.bitmap;
    std_sprite2.bitmap = std_sprite.bitmap;
    hourglass_sprite2.bitmap = hourglass_sprite.bitmap;
    caret_sprite2.bitmap = caret_sprite.bitmap;
    hand_sprite2.bitmap = hand_sprite.bitmap;

    if (classic_sprite.bitmap != NULL)
        gpx_show_sprite(gpx, &classic_sprite);
    if (std_sprite.bitmap != NULL)
        gpx_show_sprite(gpx, &std_sprite);
    if (hourglass_sprite.bitmap != NULL)
        gpx_show_sprite(gpx, &hourglass_sprite);
    if (caret_sprite.bitmap != NULL)
        gpx_show_sprite(gpx, &caret_sprite);
    if (hand_sprite.bitmap != NULL)
        gpx_show_sprite(gpx, &hand_sprite);

    if (classic_sprite2.bitmap != NULL)
        gpx_show_sprite(gpx, &classic_sprite2);
    if (std_sprite2.bitmap != NULL)
        gpx_show_sprite(gpx, &std_sprite2);
    if (hourglass_sprite2.bitmap != NULL)
        gpx_show_sprite(gpx, &hourglass_sprite2);
    if (caret_sprite2.bitmap != NULL)
        gpx_show_sprite(gpx, &caret_sprite2);
    if (hand_sprite2.bitmap != NULL)
        gpx_show_sprite(gpx, &hand_sprite2);

    if (classic_sprite2.bitmap != NULL)
        gpx_hide_sprite(gpx, &classic_sprite2);
    if (std_sprite2.bitmap != NULL)
        gpx_hide_sprite(gpx, &std_sprite2);
    if (hourglass_sprite2.bitmap != NULL)
        gpx_hide_sprite(gpx, &hourglass_sprite2);
    if (caret_sprite2.bitmap != NULL)
        gpx_hide_sprite(gpx, &caret_sprite2);
    if (hand_sprite2.bitmap != NULL)
        gpx_hide_sprite(gpx, &hand_sprite2);

    __asm__("halt");

    return 0;
}
