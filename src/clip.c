/*
 * clip.c
 *
 * clipping functions
 *
 * MIT License (see: LICENSE)
 * copyright (c) 2021 tomaz stih
 *
 * 09.08.2021   tstih
 *
 */
#include <clip.h>

/* defining cohen sutherland region codes */
#define INSIDE  0; /* 0000 */
#define LEFT    1; /* 0001 */
#define RIGHT   2; /* 0010 */
#define BOTTOM  4; /* 0100 */
#define TOP     8; /* 1000 */

/* cohen sutherland code */
static unsigned char _csc(rect_t *clip_area, coord x, coord y)
{
    /* asume we are inside */
    unsigned char code = INSIDE;
  
    /* detect areas */
    if (x < clip_area->x0) code |= LEFT;
    if (x > clip_area->x1) code |= RIGHT;
    if (y < clip_area->y0) code |= BOTTOM;
    if (y > clip_area->y1) code |= TOP;
  
    return code;
}

bool _cohen_sutherland(
    rect_t *clip_area, 
    coord *x0, coord *y0, 
    coord *x1, coord *y1) {

    /* get cs codes */
    unsigned char 
        c1=_csc(clip_area,*x0,*y0)
        ,c2=_csc(clip_area,*x1,*y1);

    /* return accept */
    return true;
}