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
#include <glyph.h>
#include <font.h>

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

void gpx_draw_glyph(
    gpx_t *g, 
    coord x, 
    coord y, 
    glyph_t *glyph) {

    /* If no intersect between glyph and clip area,
       just return. */
    rect_t grect={ x, y, 0, 0 };
    rect_t intersect;

    /* Use different logic for each glyph class. */
    if (glyph->class == GYCLS_RASTER) {
        /* Convert to raster glyph. */
        raster_glyph_t* raster=(raster_glyph_t *)glyph;
        grect.x1=x+raster->width;
        grect.y1=y+raster->height;
        /* If no intersection with the clip then do nothing */
        if (gpx_rect_intersect(&grect,&(g->clip_area),&intersect)==NULL)
            return;
        /* Get the pointer to start of data. */
        uint8_t *dptr=raster->data;   
        /* Skip over clipped lines. */
        uint16_t skip=( (intersect.y0 - y) * (raster->stride + 1) );
        dptr += skip;
        /* How many lines of glyph to draw? */
        uint8_t nlines=intersect.y1 - intersect.y0 + 1;
        y=intersect.y0;
        while (nlines--) {
            _stridexy(
                intersect.x0, 
                y++, 
                dptr,
                intersect.x0-x, 
                intersect.x1 - x + 1);
            dptr = dptr + raster->stride + 1; /* Next row. */
        }
    }
}

void gpx_draw_string(
    gpx_t *g, 
    font_t *f, 
    coord x, 
    coord y, 
    char* text) {

    uint8_t *start=(uint8_t *)f;

    /* first get spacing hint */
    while (*text) {
        uint8_t chi=*text-f->first_ascii;
        uint16_t *offsets=f->glyph_offsets;
        uint16_t offs=f->glyph_offsets[*text-f->first_ascii];
        raster_glyph_t *glyph=(raster_glyph_t *)(start+offs);
        gpx_draw_glyph(g,x,y,(glyph_t*)glyph);
        x=x+glyph->width + f->hor_spacing_hint;
        text++;
    }
}