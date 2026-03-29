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
#define INSIDE  0 /* 0000 */
#define LEFT    1 /* 0001 */
#define RIGHT   2 /* 0010 */
#define BOTTOM  4 /* 0100 */
#define TOP     8 /* 1000 */

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

static coord _bisect(coord a0, coord b0, coord a1, coord b1, coord b) {
    
    /* temps */
    coord ta, tb;
    
    /* make sure b0 < b1 */
    if (b0>b1) {
        /* swap */
        ta=a0; tb=b0;
        a0=a1; b0=b1;
        a1=ta; b1=tb;
    }

    /* as long as we don't hit the b ...*/
    while (b!=b0 && b!=b1) {
        /* get mid point of line */
        ta = (a0+a1)/2;
        tb = (b0+b1)/2;
        /* if mid point is above b */
        if (tb < b) {
            b0 = tb;
            a0 = ta;
        } else {
            b1 = tb;
            a1 = ta;
        }
    }
    if (b==b0)
        return a0;
    else
        return a1;
}

bool _cohen_sutherland(
    rect_t *clip_area, 
    coord *x0, coord *y0, 
    coord *x1, coord *y1) {

    /* get cs codes */
    unsigned char 
        c1=_csc(clip_area,*x0,*y0)
        ,c2=_csc(clip_area,*x1,*y1);


    /* initialize line as outside the rectangular window */
    bool accept = false;
  
    while (true) {
        if ((c1 == 0) && (c2 == 0)) {
            /* if both endpoints lie within rectangle */
            accept = true;
            break;
        }
        else if (c1 & c2) {
            /* if both endpoints are outside rectangle, in same region */
            break;
        }
        else {
            /* some segment of line lies within the rectangle */
            unsigned char code_out;
            coord x = 0, y = 0;
  
            /* at least one endpoint is outside the rectangle, pick it. */
            if (c1 != 0)
                code_out = c1;
            else
                code_out = c2;
  
            /* find intersection point */
            if (code_out & TOP) {
                /* point is above the clip rectangle */
                y = clip_area->y1;
                x = _bisect(*x0,*y0,*x1,*y1,y);
            }
            else if (code_out & BOTTOM) {
                /* point is below the rectangle */
                y = clip_area->y0;
                x = _bisect(*x0,*y0,*x1,*y1,y);
            }
            else if (code_out & RIGHT) {
                /* point is to the right of rectangle */
                x = clip_area->x1;
                y = _bisect(*y0,*x0,*y1,*x1,x);
            }
            else if (code_out & LEFT) {
                /* point is to the left of rectangle */
                x = clip_area->x0;
                y = _bisect(*y0,*x0,*y1,*x1,x);
            }
  
            /* intersection point x, y is found
               we replace point outside rectangle
               by intersection point */
            #ifdef SDCC
            #pragma save
            #pragma disable_warning 84
            #endif
            if (code_out == c1) {
                *x0 = x;
                *y0 = y;
                c1=_csc(clip_area,*x0,*y0);
            }
            else {
                *x1 = x;
                *y1 = y;
                c2=_csc(clip_area,*x1,*y1);
            }
            #ifdef SDCC
            #pragma restore
            #endif
        }
    }

    /* return accept */
    return accept;
}