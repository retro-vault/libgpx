/*
 * draw.c
 *
 * high level (clipped) drawing functions
 *
 * MIT License (see: LICENSE)
 * copyright (c) 2021 tomaz stih
 *
 * 09.08.2021   tstih
 *
 */
#include <gpxcore.h>
#include <rect.h>
#include <native.h>
#include <clip.h>

void gpx_draw_pixel(gpx_t *g, coord x, coord y) {
    /* are we inside clip area? */
    if (gpx_rect_contains(&(g->clip_area),x,y))
        _plotxy(x, y);
}

void gpx_draw_circle(gpx_t *g, coord x0, coord y0, coord radius)
{
    g;
    int f = 1 - radius;
    int ddF_x = 1;
    int ddF_y = -2 * radius;
    int x = 0;
    int y = radius;

    gpx_draw_pixel(g, x0, y0 + radius);
    gpx_draw_pixel(g, x0, y0 - radius);
    gpx_draw_pixel(g, x0 + radius, y0);
    gpx_draw_pixel(g, x0 - radius, y0);
    while (x < y)
    {
        if (f >= 0)
        {
            y--;
            ddF_y += 2;
            f += ddF_y;
        }
        x++;
        ddF_x += 2;
        f += ddF_x;
        gpx_draw_pixel(g, x0 + x, y0 + y);
        gpx_draw_pixel(g, x0 - x, y0 + y);
        gpx_draw_pixel(g, x0 + x, y0 - y);
        gpx_draw_pixel(g, x0 - x, y0 - y);
        gpx_draw_pixel(g, x0 + y, y0 + x);
        gpx_draw_pixel(g, x0 - y, y0 + x);
        gpx_draw_pixel(g, x0 + y, y0 - x);
        gpx_draw_pixel(g, x0 - y, y0 - x);
    }
}

void gpx_draw_line(gpx_t *g, coord x0, coord y0, coord x1, coord y1) {
    /* first check for point, horizontal line or vertical lines */
    if (x0==x1 && y0==y1) { /* point */
    } else if (x0==x1) {    /* vertical line */
    } else if (y0==y1) {    /* horizontal line */
    } else {
        if (!_cohen_sutherland(&(g->clip_area),&x0,&y0,&x1,&y1))
            return;         /* rejected */
        else {              /* bresenham */
            int dx = _abs(x1-x0), sx = x0<x1 ? 1 : -1;
            int dy = _abs(y1-y0), sy = y0<y1 ? 1 : -1; 
            int err = (dx>dy ? dx : -dy)/2, e2;
            
            for(;;){
                _plotxy(x0,y0);
                if (x0==x1 && y0==y1) break;
                e2 = err;
                if (e2 >-dx) { err -= dy; x0 += sx; }
                if (e2 < dy) { err += dx; y0 += sy; }
            }
        }
    }
}

void gpx_draw_rect(gpx_t *g, rect_t *rect) {
    /* top */
    gpx_draw_line(g,rect->x0, rect->y0, rect->x1, rect->y0);
    /* bottom */
    gpx_draw_line(g,rect->x0, rect->y1, rect->x1, rect->y1);
    /* left */
    gpx_draw_line(g,rect->x0, rect->y0, rect->x0, rect->y1);
    /* right */
    gpx_draw_line(g,rect->x1, rect->y0, rect->x1, rect->y1);
}