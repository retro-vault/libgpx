/*
 * gpxcore.h
 *
 * libgpx core definitions 
 * 
 * MIT License (see: LICENSE)
 * copyright (c) 2021 tomaz stih
 *
 * 07.08.2021   tstih
 *
 */
#ifndef __GPXDEF_H__
#define __GPXDEF_H__

#include <std.h>



/* ----- core gpx new type(s) ---------------------------------------------- */
typedef int16_t coord;
typedef int16_t color;                  /* if more then 16 colors, then it's a pointer */



/* ----- basic graphics structures (rect_t, graphics_t, etc.) -------------- */

/* basic rectangle */
typedef struct rect_s {                 /* the rectangle */
	coord x0;
	coord y0;
	coord x1;
	coord y1;
} rect_t;

typedef struct point_s {
    coord x;
    coord y;
} point_t;

/* drawing mode */
#define BLT_NONE            0           /* no drawing, pen up */
#define BLT_COPY            1           /* standard operation */
#define BLT_XOR             2           /* XOR operations */

/* official list styles (will work fast!) */
#define LS_SOLID            0xff
#define LS_DOTTED           0xaa
#define LS_DASHED           0xcc


typedef struct gpx_s {
    uint8_t blit;                       /* one of BM_ mmodes */
    uint8_t line_style;                 /* one of LS_ styles */
    uint8_t fill_brush_size;            /* bytes in brush */
    uint8_t fill_brush[8];              /* array of byes (max 8) */
    rect_t clip_area;                   /* absolute clipping rectangle */
    uint8_t display_page;               /* currently displaying ... */
    uint8_t write_page;                 /* all drawing goes to page... */
    uint8_t *resolutions;               /* current resolution for each page */
    color fore_color;                   /* current fore color */
    color back_color;                   /* current back color */
} gpx_t;


/* set color consts. */
#define CO_NONE             0
#define CO_FORE             1
#define CO_BACK             2

/* page ops */
#define PG_DISPLAY          1
#define PG_WRITE            2

#endif /* __GPXDEF_H__ */