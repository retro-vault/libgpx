/*
 * gpx.zxspec48.c
 *
 * Graphics init and exit functions for ZX Spectrum 48K.
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

#include "video.h"

/* there can be only one gpx! */
static gpx_t* g = NULL;

/* default brush is solid, 1 byte, 0xff */
static signed char solid_brush = 0xff;

/* partner page resolutions */
static uint8_t current_resolution;

gpx_t* gpx_init() {

    /* not the first time? */
    if (g!=NULL) return g;
    
    /* allocate memory */
    g=malloc(sizeof(gpx_t));

    /* default colors are black on white*/
    g->back_color = 7;                  /* white */
    g->fore_color = 0;                  /* black */

    /* blit mode */
    g->blit_mode = BM_COPY;
    g->line_style = LS_SOLID;
    g->fill_brush_size = 1;             /* 1 byte */
    g->fill_brush=&solid_brush;

    /* display and write page is 0 */
    g->display_page = 0;
    g->write_page = 0;

    /* set pen and eraser */
    g->fore_color = 0;                  /* ink: black */
    g->back_color = 7;                  /* paper: white */

    /* resolutions for the only page is 0 (256x192) */
    current_resolution=0;
    g->resolutions=&current_resolution;

    /* finally, clipping rect. */
    g->clip_area = { 0, 0, MAX_X, MAX_Y };
}


void gpx_exit(gpx_t* g) {

}