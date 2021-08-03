/*
 * gpx.h
 *
 * include this and -llibgpx to use libgpx.. 
 *
 * MIT License (see: LICENSE)
 * copyright (c) 2021 tomaz stih
 *
 * 03.08.2021   tstih
 *
 */
#ifndef __GPX_H__
#define __GPX_H__

#include <stdbool.h>
#include <stdint.h>


/* extra gpx type(s) */
typedef int16_t coord;
typedef int16_t color;                  /* if more then 16 colors, then it's a pointer */


/* ----- basic graphics structures (rect_t, graphics_t, etc.) -------------- */
typedef struct rect_s {                 /* the rectangle */
	coord x0;
	coord y0;
	coord x1;
	coord y1;
} rect_t;

/* drawing mode */
#define BM_COPY             0
#define BM_XOR              2

/* official list styles (will work fast!) */
#define LS_SOLID            0xff
#define LS_DOTTED           0xaa
#define LS_DASHED           0xee
#define LS_DOT_DASH         0xe4

typedef struct gpx_s {
    uint8_t blit_mode;                  /* one of BM_ mmodes */
    uint8_t line_style;                 /* one of LS_ styles */
    uint8_t fill_brush_size;            /* bytes in brush */
    uint8_t *fill_brush;                /* array of byes (max 8) */
    rect_t clip_area;                   /* absolute clipping rectangle */
    uint8_t display_page;               /* currently displaying ... */
    uint8_t write_page;                 /* all drawing goes to page... */
    uint8_t *resolutions;               /* current resolution for each page */
    color fore_color;                   /* current fore color */
    color back_color;                   /* current back color */
} gpx_t;


/* ----- initialization ---------------------------------------------------- */

/* initialize the graphics system */
extern gpx_t* gpx_init();

/* exit graphics mode */
extern void gpx_exit(gpx_t* g);


/* ----- query lib capabilities -------------------------------------------- */

/* page resolution */
typedef gpx_resolution_s {
    coord width;                        /* width in pixels */
    coord height;                       /* height in pixels */
} gpx_resolution_t;

/* the page  */
typedef gpx_page_s {
    int num_resolutions;                /* number of resolutions */
    gpx_resolution_t *resolutions;      /* array of resolutions */
} gpx_page_t;

/* gpx capabilities struct. */
typedef gpx_cap_s {
    /* pages info */
    int num_pages;                      /* number of pages */
    gpx_page_t *pages;                  /* array of pages */
    /* colors info */
    int num_colors;
    color fore_color;                   /* system fore color */
    color back_color;                   /* system back color */
} gpx_cap_t;



/* ----- drawing modes, styles, patterns, colors --------------------------- */

/* set curent page */
extern void gpx_set_page(gpx_t *g, uint8_t page, uint8_t pgop);

/* get curent page */
extern uint8_t gpx_get_page(gpx_t *g, uint8_t page, uint8_t pgop);

/* set resolution (of current write page) */
extern void gpx_set_resolution(gpx_t *g, uint8_t resolution);

/* set current color */
extern void gpx_set_color(gpx_t *g, color c, uint8_t ct);

/* set clippig rectangle, if NULL then default page resolution is used */
extern void gpx_set_clip(gpx_t *, rect_t *clip);

/* set blit mode */
extern void gpx_set_blit(gpx_t *, uint8_t blit);

/* set line style  */
extern void gpx_line_style(gpx_t *, uint8_t line_style);

/* set fill brush */
extern void gpx_fill_brush(gpx_t *, uint8_t fill_brush_size, uint8_t *fill_brush);



/* ----- draw and fill functions ------------------------------------------- */

/* clear screen */
extern void gpx_cls(gpx_t *g);

/* draw pixel */
extern void gpx_draw_pixel(gpx_t *g, coord x, coord y);

/* draw line */
extern void gpx_draw_line(gpx_t *g, coord x0, coord y0, coord x1, coord y1);

/* draw rectangle */
extern void gpx_draw_rect(gpx_t *g, rect_t *rect);

/* fill rectangle */
extern void gpx_fill_rect(gpx_t *g, rect_t *rect);

/* draw glyph */
extern void gpx_draw_rect(gpx_t *g, rect_t *rect);



/* ----- glyphs ------------------------------------------------------------ */

typedef struct glyph_s {

} glyph_t;

/* draw glyph */
extern void gpx_draw_glyph(gpx_t *g, coord x, coord y, glyph_t *glyph);

/* get glyph from screen */
extern glyph_t* gpx_snatch_glyph(gpx_t *g, coord x, coord y, coord width, coord height);



/* ----- fonts and text related -------------------------------------------- */

typedef struct font_s {

} font_t;

/* draw string at x,y */
extern void gpx_draw_string(gpx_t *g, font_t *f, coord x, coord y, char* text);

/* measure string (but don't draw it)! */
extern rect_t* gpx_measure_string(gpx_t *g, font_t *f, char* text);


/* ----- rectangle functions  ---------------------------------------------- */

/* Does rectangle contains point? */
extern bool rect_contains(rect_t *r, coord x, coord y);

/* Do rectangles overlap? */
extern bool rect_overlap(rect_t *a, rect_t *b);

/* Inflate coordinates by dx and dy */
extern rect_t* rect_inflate(rect_t* rect, coord dx, coord dy);

/* Get intersect rectangle. */
extern rect_t* rect_intersect(rect_t *a, rect_t *b, rect_t *intersect);

/* Convert relative to absolute coordinates for parent and child rectangle. */
extern rect_t* rect_rel2abs(rect_t* abs, rect_t* rel, rect_t* out);

/* Subtract rectangles and return what's left. */
extern void rect_subtract(rect_t *outer, rect_t *inner, rect_t *result,	uint8_t *num);

/* Offset rectangle. */
extern void rect_delta_offset(rect_t *rect, 
    coord oldx, coord newx, coord oldy, coord newy, coord size_only);

#endif /* __GPX_H__ */