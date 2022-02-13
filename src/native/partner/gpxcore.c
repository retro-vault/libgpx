/*
 * gpxcore.c
 *
 * Graphics init and exit functions for Iskra Delta Partner.
 * 
 * MIT License (see: LICENSE)
 * copyright (c) 2021 tomaz stih
 *
 * 03.08.2021   tstih
 *
 */
#include <std.h>
#include <gpxcore.h>
#include <cap.h>

#include <rect.h>
#include "partner/ef9367.h"

/* there can be only one gpx! */
static gpx_t _g;
static bool _ginitialized = false;

/* partner page resolutions */
static uint8_t _current_resolutions[2];

gpx_t* gpx_init() {

    /* not the first time? */
    if (_ginitialized) return &_g;
    
    /* initialize it */
    _ginitialized=true;

    /* default colors are black on white*/
    _g.back_color = 1;                 /* pen */
    _g.fore_color = 0;                 /* eraser */

    /* blit mode */
    _g.blit = BLT_COPY;
    _g.line_style = LS_SOLID;
    _g.fill_brush_size = 1;             /* 1 byte */
     _g.fill_brush[0]=0xff;              /* solid brush */

    /* display and write page is 0 */
    _g.display_page = 0;
    _g.write_page = 0;

    /* resolutions for both pages to 1024x512 */
    _current_resolutions[0]=0;
    _current_resolutions[1]=0;
    _g.resolutions=_current_resolutions;

    /* finally, clipping rect. */
    _g.clip_area.x0=_g.clip_area.y0=0;
    _g.clip_area.x1=EF9367_HIRES_WIDTH-1;
    _g.clip_area.y1=EF9367_HIRES_HEIGHT-1;

    /* call gpx_cap to initialize the structure...*/
    gpx_cap(&_g);

    /* now that we prepared everything ... configure the hardware 
       to match our settings */
    _ef9367_init();

    /* Initial cls. */
    _ef9367_cls();

    /* and return it */
    return &_g;
}


void gpx_exit(gpx_t* g) {
    g;
    /* nothing, for now */
}


void gpx_cls(gpx_t *g) {
    g;
    _ef9367_cls();
}


void gpx_set_blit(gpx_t *g, uint8_t blit) {
    g; blit;
    __asm
        push    ix                      ; store index 
        ld      ix, #4                  ; index to 0
        add     ix, sp                  ; ix = sp
        ld      l, (ix)                ; g to hl
        ld      h, 1(ix)
        ld      b, 2(ix)                ; blit mode into b
        ld      (hl), b                 ; update gpx_t
        call    __ef9367_set_blit_mode  ; set blit mode!
        pop     ix                      ; restore ix
    __endasm;
}

void gpx_set_clip_area(gpx_t *g, rect_t *clip_area) {

    /* If null, use current resolution. */
    if (clip_area==NULL) {
        gpx_resolution_t res;
        gpx_get_disp_page_resolution(g,&res);
        g->clip_area.x0=0;
        g->clip_area.y0=0;
        g->clip_area.x1=res.width - 1;
        g->clip_area.y1=res.height - 1;
    } else 
        /* Copy rectangle.*/
        _memcpy(&(g->clip_area),clip_area,sizeof(rect_t));
    
    /* Normalize rect. coordinates (left,top,right,bottom) */
    gpx_rect_norm(&(g->clip_area));
}

void gpx_set_page(gpx_t *g, uint8_t page, uint8_t pgop) {
    g; page; pgop;
    /* uint8_t grcc=0;  
    if (
        ((g->display_page)!=page) 
        && ((pgop & PG_DISPLAY)!=0))
    {} 
    if ((pgop & PG_WRITE) && (g->write_page!=page))
    {} 
    */
   
    /* write grcc back */
}

uint8_t gpx_get_page(gpx_t *g, uint8_t pgop) {
    g; pgop;
    /* always the same page on speccy */
    return 0;
}

void gpx_set_line_style(gpx_t *g, uint8_t line_style) {
    g->line_style=line_style;
}

void gpx_set_fill_brush(gpx_t *g, uint8_t fill_brush_size, uint8_t *fill_brush) {
    
    /* copy brush */
    for (register uint8_t i=0;i<fill_brush_size;i++)
        g->fill_brush[i]=fill_brush[i];

    /* and store size. */
    g->fill_brush_size=fill_brush_size;
}