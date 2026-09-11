/* Full HD showcase of the native libgpx raster API.
 * GPL2 License (see: LICENSE), Copyright (C) 2026 tomaz stih. */
#include "libgpx.h"
#include <stdio.h>

int main(void)
{
    gpx_t *gpx = gpx_create(GPXM_RASTA_1920X1080);
    uint8_t solid[] = {0xff};
    uint8_t hatch[] = {0xaa, 0x55};
    uint8_t brick[] = {0xff, 0x88, 0x88, 0x88};
    uint8_t background[GPX_SPRITE_BG_SIZE];
    rect_t screen = {12, 12, 1907, 1067};
    rect_t title = {24, 24, 1895, 54};
    rect_t panel = {50, 100, 900, 470};
    const font_t *font = gpx_get_system_font();
    coord i;

    if (!gpx) {
        perror("gpx_create");
        return 1;
    }
    gpx_draw_rectangle(gpx, &screen, CO_FORE, BM_CPY, 0xff, NULL);
    gpx_fill_rectangle(gpx, &title, CO_FORE, BM_CPY, solid, 1, NULL);
    gpx_draw_text(gpx, 40, 35,
        "libgpx / Rasta / 1920 x 1080 / 1bpp", font,
        CO_BACK, BM_CPY, NULL);
    gpx_draw_text(gpx, 50, 80, "Lines, dash patterns and clipping", font,
        CO_FORE, BM_CPY, NULL);
    gpx_draw_rectangle(gpx, &panel, CO_FORE, BM_CPY, 0xff, NULL);
    for (i = 0; i < 36; ++i)
        gpx_draw_line(gpx, 475, 285, (coord)(50 + i * 25), 95,
            CO_FORE, BM_CPY, (uint8_t)(i & 1 ? 0x33 : 0xff), &panel);
    for (i = 0; i < 36; ++i)
        gpx_draw_line(gpx, 475, 285, (coord)(50 + i * 25), 490,
            CO_FORE, BM_CPY, (uint8_t)(i & 1 ? 0x55 : 0xff), &panel);
    gpx_draw_text(gpx, 980, 80, "Pattern fills and XOR", font,
        CO_FORE, BM_CPY, NULL);
    panel = (rect_t){980, 100, 1410, 470};
    gpx_fill_rectangle(gpx, &panel, CO_FORE, BM_CPY, hatch, 2, NULL);
    panel = (rect_t){1210, 170, 1870, 400};
    gpx_fill_rectangle(gpx, &panel, CO_FORE, BM_XOR, brick, 4, NULL);

#if GPX_ADVANCED
    gpx_draw_text(gpx, 50, 520, "Circles, polygons and anchored patterns",
        font, CO_FORE, BM_CPY, NULL);
    for (i = 20; i <= 200; i += 20)
        gpx_draw_circle(gpx, 270, 780, i, CO_FORE, BM_CPY, NULL);
    gpx_fill_circle(gpx, 720, 780, 200, CO_FORE, BM_CPY, brick, 4, NULL);
    gpx_draw_circle(gpx, 720, 780, 200, CO_FORE, BM_CPY, NULL);
    {
        point_t star[] = {{1150, 565}, {1210, 710}, {1380, 710},
            {1250, 810}, {1300, 980}, {1150, 880}, {1000, 980},
            {1050, 810}, {920, 710}, {1090, 710}};
        gpx_fill_polygon(gpx, star, 10, CO_FORE, BM_CPY, hatch, 2, NULL);
        gpx_draw_polygon(gpx, star, 10, CO_FORE, BM_CPY, 0xff, NULL);
    }
#endif
    gpx_draw_text(gpx, 1480, 580, "Stock cursor bitmaps and save-under sprites",
        font, CO_FORE, BM_CPY, NULL);
    for (i = 0; i < 6; ++i) {
        sprite_t sprite = {(coord)(1500 + i * 60), 620,
            gpx_get_stock_bmp((uint8_t)i), (bmp_t *)background, NULL};
        gpx_show_sprite(gpx, &sprite);
        gpx_hide_sprite(gpx, &sprite);
        gpx_draw_bmp(gpx, sprite.x, sprite.y, sprite.bitmap, NULL);
    }
    panel = (rect_t){1480, 700, 1840, 900};
    gpx_fill_rectangle(gpx, &panel, CO_FORE, BM_CPY, brick, 4, NULL);
    gpx_draw_text(gpx, 1500, 740, "Opaque proportional text", font,
        CO_FORE, BM_CPY, NULL);
    gpx_set_text_background(gpx, GPX_TEXT_BG_TRANSPARENT);
    gpx_draw_text(gpx, 1500, 780, "Transparent proportional text", font,
        CO_FORE, BM_CPY, NULL);
    gpx_destroy(gpx);
    return 0;
}
