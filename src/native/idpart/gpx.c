/*
 * gpx.c
 *
 * Graphics init and exit functions for Iskra Delta Partner.
 * 
 * MIT License (see: LICENSE)
 * copyright (c) 2021 tomaz stih
 *
 * 03.08.2021   tstih
 *
 */
#include <stdlib.h>
#include <stdlib.h>
#include <gpx.h>

#include "ef9367.h"

/* there can be only one gpx! */
static gpx_t* g = NULL;

/* default brush is solid, 1 byte, 0xff */
static signed char solid_brush = 0xff;

/* partner page resolutions */
static uint8_t current_resolutions[2];

gpx_t* gpx_init() {

    /* not the first time? */
    if (g!=NULL) return g;
    
    /* allocate memory */
    g=malloc(sizeof(gpx_t));

    /* default colors are black on white*/
    g->back_color = 1;                  /* pen */
    g->fore_color = 0;                  /* eraser */

    /* blit mode */
    g->blit_mode = BM_COPY;
    g->line_style = LS_SOLID;
    g->fill_brush_size = 1;             /* 1 byte */
    g->fill_brush=&solid_brush;

    /* display and write page is 0 */
    g->display_page = 0;
    g->write_page = 0;

    /* resolutions for both pages to 1024x512 */
    current_resolutions[0]=0;
    current_resolutions[1]=0;
    g->resolutions=current_resolutions;

    /* finally, clipping rect. */
    g->clip_area.x0=g->clip_area.y0=0;
    g->clip_area.x1=EF9367_HIRES_WIDTH-1;
    g->clip_area.y1=EF9367_HIRES_HEIGHT-1;

    /* now that we prepared everything ... configure the hardware 
       to match our settings */
}


void gpx_exit(gpx_t* g) {
    /* deallocate memory */
    free(g);
}


void gpx_cls(gpx_t *g) {
    _ef9367_cls();
}


void gpx_set_blit(gpx_t *g, uint8_t blit) {
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


void gpx_draw_pixel(gpx_t *g, coord x, coord y) {
    __asm
        push    ix                      ; store index reg.
        ld      ix, #0                  ; index to 0
        add     ix, sp                  ; ix = sp
        ;; hl=x
        ld      l, 4(ix)                
        ld      h, 5(ix)
        ;; de=y
        ld      e, 6(ix)                
        ld      d, 7(ix)
        ;; goto x,y
        call    ef9367_xy
        ;; and draw pixel
        call    _ef9367_put_pixel
        ;; restore ix
        pop     ix
    __endasm;
}