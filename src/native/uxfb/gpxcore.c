/*
 * gpxcore.c
 *
 * Graphics init and exit functions for Unix frambuffer.
 * 
 * MIT License (see: LICENSE)
 * copyright (c) 2022 tomaz stih
 *
 * 26.01.2022   tstih
 *
 */
#include <std.h>
#include <string.h>
#include <gpxcore.h>

/* there can be only one gpx! */
static gpx_t _g;
static bool _ginitialized = false;

/* zx spectrum page resolution */
static uint8_t _current_resolution;


/* ----- initialization and exit ------------------------------------------- */

gpx_t* gpx_init() {

    /* not the first time? */
    if (_ginitialized) return &_g;
    
    /* initialize it */
    _ginitialized=true;

    _g.blit = BLT_COPY;
    _g.line_style = LS_SOLID;
    _g.fill_brush_size = 1;             /* 1 byte */
    _g.fill_brush[0]=0xff;              /* solid brush */

    /* display and write page is 0 */
    _g.display_page = 0;
    _g.write_page = 0;

    /* set ink and paper */
    _g.fore_color = 0;    
    _g.back_color = 1;

    /* resolutions for the only page is 0 (256x192) */
    _current_resolution=0;
    _g.resolutions=&_current_resolution;

    /* finally, clipping rect. */
    _g.clip_area.x0=_g.clip_area.y0=0;
    _g.clip_area.x1=800;
    _g.clip_area.y1=600;

    /* return it */
    return &_g;
}

void gpx_exit(gpx_t* g) {
    g;
    /* nothing, for now */
}


/* ----- dummy functions that do not work on zx spectrum ------------------- */

void gpx_set_resolution(gpx_t *g, uint8_t resolution) {
}

void gpx_set_page(gpx_t *g, uint8_t page, uint8_t pgop) {
}

uint8_t gpx_get_page(gpx_t *g, uint8_t page, uint8_t pgop) {
    /* always the same page on speccy */
    return 0;
}

void gpx_line_style(gpx_t *g, uint8_t line_style) {
    g->line_style=line_style;
}

void gpx_fill_brush(gpx_t *g, uint8_t fill_brush_size, uint8_t *fill_brush) {
    
    /* copy brush */
    memcpy(&(g->fill_brush),fill_brush,fill_brush_size);

    /* and store size. */
    g->fill_brush_size=fill_brush_size;
}

void gpx_set_clip_area(gpx_t *g, rect_t *clip_area) {
    memcpy(&(g->clip_area),clip_area,sizeof(rect_t));
}

void gpx_set_blit(gpx_t *g, uint8_t blit) {
    g->blit=blit;
}

void gpx_set_color(gpx_t *g, color c, uint8_t ct) {
    if (ct==CO_BACK)
        g->back_color=c;
    else
        g->fore_color=c;
}