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
#include <unistd.h>
#include <stdio.h>
#include <fcntl.h>
#include <linux/fb.h>
#include <sys/mman.h>

#include <std.h>
#include <util.h>
#include <string.h>
#include <gpxcore.h>
#include <cap.h>
#include <pixie/pixie.h>

/* there can be only one gpx! */
gpx_t _g;
static bool _ginitialized = false;

/* capabilities */
static gpx_cap_t _cap;
static bool _capinitialized = false;

/* pages and resolutions */
static uint8_t _current_resolution;
static gpx_page_t _page0;
static gpx_resolution_t _native_resolution;



/* ----- initialization and exit ------------------------------------------- */

gpx_t* gpx_init() {

    /* open pixie channel */
    pxopen();

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

    /* resolutions for the only page is 0 */
    _current_resolution=0;
    _g.resolutions=&_current_resolution;

    /* finally, clipping rect. */
    _g.clip_area.x0=_g.clip_area.y0=0;
    _g.clip_area.x1=PIXIE_WIDTH-1;
    _g.clip_area.y1=PIXIE_HEIGHT-1;

    /* initialize capabilities internals */
    gpx_cap(&_g);

    /* return it */
    return &_g;
}

void gpx_exit(gpx_t* g) {
    UNUSED(g);
    pxclose();
}

/* get the capabilities */
gpx_cap_t* gpx_cap(gpx_t *g) 
{
    UNUSED(g);

    /* not the first time? */
    if (_capinitialized) return &_cap;
    /* signal initialized */
    _capinitialized=true;
    
    /* configure pages */
    _cap.num_pages=1;
    _cap.pages=&_page0;                  /* point to page 0 */
    _page0.num_resolutions=1;
    _page0.resolutions=&_native_resolution;
    _native_resolution.width=PIXIE_WIDTH;
    _native_resolution.height=PIXIE_HEIGHT;

    /* simulate mono */
    _cap.num_colors=2;
    _cap.fore_color=0;
    _cap.back_color=1;

    /* and return */
    return &_cap;
}

gpx_resolution_t *gpx_get_disp_page_resolution(
    gpx_t *g,
    gpx_resolution_t *res) {
    UNUSED(g);

    memcpy(
        res,
        &_native_resolution,
        sizeof(gpx_resolution_t)
    );

    return res;
}

/* ----- dummy functions that do not work on zx spectrum ------------------- */

void gpx_set_resolution(gpx_t *g, uint8_t resolution) {
    UNUSED(g);
    UNUSED(resolution);
}

void gpx_set_page(gpx_t *g, uint8_t page, uint8_t pgop) {
    if (pgop&PG_DISPLAY) {
        g->display_page=page;
        pxwrite("PAGE DISPLAY %d\n",page);
    }
    if (pgop&PG_WRITE) {
        g->write_page=page;
        pxwrite("PAGE WRITE %d\n",page);
    }
}

uint8_t gpx_get_page(gpx_t *g, uint8_t page, uint8_t pgop) {
    if (pgop==PG_DISPLAY)
        return g->display_page;
    else
        return g->write_page;
}

void gpx_set_line_style(gpx_t *g, uint8_t line_style) {
    g->line_style=line_style;
}

void gpx_set_fill_brush(gpx_t *g, uint8_t fill_brush_size, uint8_t *fill_brush) {
    
    /* copy brush */
    memcpy(&(g->fill_brush),fill_brush,fill_brush_size);

    /* and store size. */
    g->fill_brush_size=fill_brush_size;
}

void gpx_set_clip_area(gpx_t *g, rect_t *clip_area) {
    memcpy(&(g->clip_area),clip_area,sizeof(rect_t));
}

void gpx_set_blit(gpx_t *g, uint8_t blit) {
    /* store blit */
    g->blit=blit;
    /* and activate on pixie */
    pxwrite("B%d\n",blit);
}

void gpx_set_color(gpx_t *g, color c, uint8_t ct) {
    if (ct==CO_BACK)
        g->back_color=c; /* no effect... */
    else {
        g->fore_color=c;
        pxwrite("I%d\n",c == 0 ? 255 : 0);
    }
}