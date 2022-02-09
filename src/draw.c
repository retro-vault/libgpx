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
#include <std.h>

extern void gpx_set_line_style(gpx_t *g, uint8_t line_style);

void gpx_draw_pixel(gpx_t *g, coord x, coord y) {
    /* are we inside clip area? */
    if (gpx_rect_contains(&(g->clip_area),x,y))
        _plotxy(x, y);
}

void gpx_draw_circle(gpx_t *g, coord x0, coord y0, coord radius)
{
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

    /* is line rectangle completely out of clip rect? */
    rect_t line_rect={x0,y0,x1,y1};
    gpx_rect_norm(&line_rect);
    if (!gpx_rect_overlap(&line_rect,&(g->clip_area)))
        return;

    /* first check for point, horizontal line or vertical lines */
    if (x0==x1 && y0==y1) { /* point */
        /* inside clip area ? */
        if (gpx_rect_contains(&(g->clip_area),x0,y0))
            _plotxy(x0,y0);
    } else if (x0==x1) {    /* vertical line */
        /* smaller first */
        y0=line_rect.y0; y1=line_rect.y1;
        /* limit line to the inside of clip area */
        if ( y0 < g->clip_area.y0 ) y0=g->clip_area.y0;
        if ( y1 > g->clip_area.y1 ) y1=g->clip_area.y1;
        /* Finally, quick draw. */
        _vline(x0, y0, y1);
    } else if (y0==y1) {    /* horizontal line */
        /* smaller first */
        x0=line_rect.x0; x1=line_rect.x1;
        /* limit line to the inside of clip area */
        if ( x0 < g->clip_area.x0 ) x0=g->clip_area.x0;
        if ( x1 > g->clip_area.x1 ) x1=g->clip_area.x1;
        /* Finally, quick draw. */
        _hline(x0, x1, y0);
    } else {
        if (!_cohen_sutherland(&(g->clip_area),&x0,&y0,&x1,&y1))
            return;         /* rejected */
        else {              /* draw line */
            /* do we recognize line pattern? */
            _line(x0,y0,x1,y1);
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

void gpx_fill_rect(gpx_t *g, rect_t *rect) {
    /* first save current line style */
    uint8_t current_line_style=g->line_style;
    /* draw horz. lines */
    uint8_t index=0;
    for(int y=rect->y0; y<rect->y1; y++) {
        gpx_set_line_style(g,(g->fill_brush)[index++]);
        gpx_draw_line(g,rect->x0,y,rect->x1,y);
        if (index==g->fill_brush_size) index=0;
    }   
    /* restore line style */
    g->line_style=current_line_style;
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
    uint8_t *dptr;

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
        dptr=raster->data;   
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
    } else if (glyph->class == GYCLS_TINY) {
        /* Convert to tiny glyph. */
        tiny_glyph_t* tiny=(tiny_glyph_t *)glyph;
        grect.x1=x+tiny->width;
        grect.y1=y+tiny->height;
        /* Check initial cliping. */
        if (gpx_rect_intersect(&grect,&(g->clip_area),&intersect)==NULL)
            return;
        /* Zero moves? */
        if (tiny->moves==0) return;
        /* Get pointer to data. */
        dptr=tiny->data;
        /* If we're here, we have intersection. To clip or not to clip? */
        if (intersect.x1-intersect.x0==tiny->width && intersect.y1-intersect.y0==tiny->height)
            _tinyxy(x,y,dptr,tiny->moves, NULL);
        else {
            unsigned char tclip[14];
            /* Initial offset. */
            tclip[0]=dptr[0];
            tclip[1]=dptr[1];
            /* Clip rect. */
            tclip[10]=intersect.x0-grect.x0;
            tclip[11]=intersect.y0-grect.y0;
            tclip[12]=intersect.x1-grect.x0;
            tclip[13]=intersect.y1-grect.y0;
            _tinyxy(x,y,dptr,tiny->moves, &tclip);
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
        uint16_t offs=f->glyph_offsets[*text-f->first_ascii];
        raster_glyph_t *glyph=(raster_glyph_t *)(start+offs);
        gpx_draw_glyph(g,x,y,(glyph_t*)glyph);
        x=x+glyph->width + f->hor_spacing_hint;
        text++;
    }
}