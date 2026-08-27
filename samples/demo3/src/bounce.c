/*
 * bounce.c
 *
 * libgpx manual example 2: a sprite moved across a busy background.
 *
 * Shows the show/hide contract. gpx_show_sprite draws the sprite and
 * gpx_hide_sprite puts back exactly what was underneath, so a moving
 * object leaves the scene it travels over untouched. How that is done
 * is the backend's business: the ZX saves the pixels under the sprite
 * into sprite->background, while the Partner has no readable display
 * memory and instead XOR-draws the sprite, which undoes itself when
 * drawn a second time.
 *
 * GPL2 License (see: LICENSE)
 * Copyright (C) 2026 Tomaz Stih
 */
#include "libgpx.h"

/* The Amstrad CPC has two display modes and one library, so the manual's
 * screenshots are taken twice from this one source. Everything below is
 * derived from gpx_width()/gpx_height(), so only this line changes. */
#ifndef DEMO_MODE
#define DEMO_MODE GPXM_DEFAULT
#endif

static uint8_t patt_half[2]  = {0xAA, 0x55};
static uint8_t patt_solid[1] = {0xFF};

/* Background storage for the ZX save-under. The Partner ignores it. */
static uint8_t under[GPX_SPRITE_BG_SIZE];

static void scene(gpx_t *gpx, dim w, dim h)
{
    rect_t r;
    coord i;

    gpx_clrscr();

    r.x0 = 0; r.y0 = 0; r.x1 = (coord)(w - 1); r.y1 = (coord)(h - 1);
    gpx_draw_rectangle(gpx, &r, CO_FORE, BM_CPY, 0xFF, 0);

    /* A half-tone slab and a solid slab, so the sprite crosses both
     * set and clear pixels on its way across. */
    r.x0 = (coord)(w / 16); r.y0 = (coord)(h / 3);
    r.x1 = (coord)(w / 2);  r.y1 = (coord)(h - h / 4);
    gpx_fill_rectangle(gpx, &r, CO_FORE, BM_CPY, patt_half, 2, 0);

    r.x0 = (coord)(w / 2 + w / 16); r.y0 = (coord)(h / 3);
    r.x1 = (coord)(w - w / 16);     r.y1 = (coord)(h / 2);
    gpx_fill_rectangle(gpx, &r, CO_FORE, BM_CPY, patt_solid, 1, 0);

    /* Hairlines fanning across the whole width. */
    for (i = 0; i < 6; i++)
        gpx_draw_line(gpx, 0, (coord)(i * (h / 6)),
                      (coord)(w - 1), (coord)(h - 1 - i * (h / 6)),
                      CO_FORE, BM_CPY, 0xFF, 0);
}

void main(void)
{
    gpx_t *gpx = gpx_create(DEMO_MODE);
    dim w = gpx_width();
    dim h = gpx_height();
    sprite_t sp;
    coord step = (coord)(w / 24);
    coord i;

    scene(gpx, w, h);

    sp.bitmap = gpx_get_stock_bmp(GPXSB_CURSOR_CLASSIC);
    sp.background = (bmp_t *)under;
    sp.clip = 0;

    /* Walk it across the artwork. Every fourth position is left on
     * screen and the rest are hidden again, so the picture shows both
     * halves of the contract at once: the trail proves the sprite was
     * drawn at each step, and the untouched artwork between the marks
     * proves hide put back exactly what was underneath. */
    for (i = 0; i < 20; i++) {
        sp.x = (coord)(w / 16 + i * step);
        sp.y = (coord)(h / 8 + i * (h / 32));
        gpx_show_sprite(gpx, &sp);
        if (i % 4 != 0)
            gpx_hide_sprite(gpx, &sp);
    }

    gpx_destroy(gpx);
}
