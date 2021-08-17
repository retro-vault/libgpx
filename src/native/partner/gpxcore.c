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
        ld      ix, #0                  ; index to 0
        add     ix, sp                  ; ix = sp
        ld      l, 2(ix)                ; g to hl
        ld      h, 3(ix)
        ld      b, 4(ix)                ; blit mode into b
        ld      (hl), b                 ; update gpx_t
        call    __ef9367_set_blit_mode  ; set blit mode!
        pop     ix                      ; restore ix
    __endasm;
}

void gpx_set_clip_area(gpx_t *g, rect_t *clip_area) {
    _memcpy(&(g->clip_area),clip_area,sizeof(rect_t));
}