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
static signed char _solid_brush = 0xff;

/* zx spectrum page resolution */
static uint8_t _current_resolution;

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