/*
 * gpxcore.c
 *
 * Graphics init and exit functions for ZX Spectrum 48K.
 * 
 * MIT License (see: LICENSE)
 * copyright (c) 2021 tomaz stih
 *
 * 03.08.2021   tstih
 *
 */
#include <std.h>
#include <gpxcore.h>

#include <zxspec48/video.h>

/* there can be only one gpx! */
static gpx_t _g;
static bool _ginitialized = false;

/* default brush is solid, 1 byte, 0xff */
static unsigned char _solid_brush = 0xff;

/* zx spectrum page resolution */
static uint8_t _current_resolution;


/* ----- initialization and exit ------------------------------------------- */

gpx_t* gpx_init() {

    /* not the first time? */
    if (_ginitialized) return &_g;
    
    /* initialize it */
    _ginitialized=true;

    _g.blit_mode = BM_COPY;
    _g.line_style = LS_SOLID;
    _g.fill_brush_size = 1;             /* 1 byte */
    _g.fill_brush=&_solid_brush;

    /* display and write page is 0 */
    _g.display_page = 0;
    _g.write_page = 0;

    /* set ink and paper */
    _g.fore_color = 0;    
    _g.back_color = 7;

    /* resolutions for the only page is 0 (256x192) */
    _current_resolution=0;
    _g.resolutions=&_current_resolution;

    /* finally, clipping rect. */
    _g.clip_area.x0=_g.clip_area.y0=0;
    _g.clip_area.x1=MAX_X;
    _g.clip_area.y1=MAX_Y;

    /* return it */
    return &_g;
}

void gpx_exit(gpx_t* g) {
    g;
    /* nothing, for now */
}


/* ----- dummy functions that do not work on zx spectrum ------------------- */

void gpx_set_resolution(gpx_t *g, uint8_t resolution) {
    g; resolution;
}

void gpx_set_page(gpx_t *g, uint8_t page, uint8_t pgop) {
    g; page; pgop;
}

uint8_t gpx_get_page(gpx_t *g, uint8_t page, uint8_t pgop) {
    g; page; pgop;
    /* always the same page on speccy */
    return 0;
}

void gpx_line_style(gpx_t *g, uint8_t line_style) {
    g->line_style=line_style;
}

/* TODO: brush lifetime? */
void gpx_fill_brush(gpx_t *g, uint8_t fill_brush_size, uint8_t *fill_brush) {
    g->fill_brush_size=fill_brush_size;
    g->fill_brush=fill_brush;
}