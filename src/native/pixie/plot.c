/*
 * plot.c
 *
 * Basic drawing functions.
 * 
 * MIT License (see: LICENSE)
 * copyright (c) 2022 tomaz stih
 *
 * 26.01.2022   tstih
 *
 */
#include <stdio.h>
#include <unistd.h>
#include <string.h>

#include <util.h>
#include <native.h>
#include <gpxcore.h>

#include <pixie/pixie.h>

/* pick modes from current graphics 
   disclaimer: there is only one, always! */
extern gpx_t _g;

void _plotxy(coord x, coord y) {
    /* be compatible and don't draw if BLT_NONE. */
    if (_g.blit==BLT_NONE) return;
    /* and write */
    pxwrite("P%d,%d\n",x,y);
}

void _line(coord x0, coord y0, coord x1, coord y1) {   
    /* be compatible and don't draw if BLT_NONE. */
    if (_g.blit==BLT_NONE) return;
    /* and write */
    pxwrite("L%d,%d,%d,%d,%d\n",x0,y0,x1,y1,_g.line_style);
}

void _hline(coord x0, coord x1, coord y) {
    _line(x0,y,x1,y);
}

void _vline(coord x, coord y0, coord y1) {
    _line(x,y0,x,y1);
}

void _stridexy(
        coord x, 
        coord y, 
        void *data, 
        uint8_t start, 
        uint8_t end) {

    /* get byte array */
    uint8_t * bdata=(uint8_t *)data;
    /* calculate start byte...*/
    uint8_t start_byte=start/8, start_bit=start%8;
    uint8_t mask=0x80>>start_bit;
    /* now loop */
    uint8_t array[0xff], count=0, b=0, bval, bind=0;
    while (start < end) {
        bval=bdata[start_byte]; /* get byte value */
        if (bval & mask) /* bit is 1 */
            b=(b<<1)|0x01;
        else 
            b=b<<1;
        mask=mask>>1; start++; bind++;
        if (!mask) { /* next byte? */
            mask=0x80; /* reinit mask */
            start_byte++;
        }
        if (bind==8) { /* next raster byte? */
            array[count++]=b;
            bind=0;
            b=0;
        }
    }
    /* TODO: if we are here there may be a byte pending... */
    if (bind!=0)
        array[count++]=b<<(8-bind);

    /* finally, send to pixie... */
    pxwrite("WRITE RASTER %d,%d VALUES ",x,y);
    for (int i=0;i<count;i++)
        if (!i) pxwrite("%d",array[i]);
        else pxwrite(",%d",array[i]);
    /* conclude line */
    pxwrite("\n");
}

extern void gpx_set_color(gpx_t *g, color c, uint8_t ct);
extern void gpx_set_line_style(gpx_t *g, uint8_t line_style);
extern void gpx_draw_line(gpx_t *g, coord x0, coord y0, coord x1, coord y1);

void _tinyxy(
    coord x, 
    coord y, 
    uint8_t *moves,
    uint8_t num,
    void *clip){

    /* store fore color and line style */
    color fore=_g.fore_color, back=_g.back_color;
    uint8_t line_style=_g.line_style;
    gpx_set_line_style(&_g,0xff);

    /* first two bytes are offset of first line */
    x+=*moves; y+=*(moves+1);
    coord x0=x,y0=y,x1,y1;

    /* do we need to clip it? */
    for(int imove=2;imove<num;imove++) {
        /* get the move */
        uint8_t move=moves[imove];
        /* break it down */
        int8_t signx=0, signy=0, dx=0, dy=0, color=0;
        /* extract color */
        if (move&0x01) color=2;
        if (move&0x80) color+=1;
        /* extract signs */
        signx=move&0x02?-1:1;
        signy=move&0x04?-1:1;
        /* and finally, deltas... */
        dy = (move>>3) & 0x03;
        if (!dy) signy=0;
        dx = (move>>5) & 0x03;
        if (!dx) signx=0;
        /* and draw it... */
        x1=x0+signx*dx; y1=y0+signy*dy;
        if (color==CO_FORE) {
            gpx_set_color(&_g,fore,CO_FORE);
            gpx_draw_line(&_g,x0,y0,x1,y1);
        }
        else if (color==CO_BACK) {
            gpx_set_color(&_g,back,CO_FORE);
            gpx_draw_line(&_g,x0,y0,x1,y1);
        }
        /* next line */
        x0=x1; y0=y1;
    }

    /* restore color */
    gpx_set_color(&_g,fore,CO_FORE);
    gpx_set_line_style(&_g,line_style);
}

void gpx_cls(gpx_t *g) {
    UNUSED(g);
    pxwrite("C\n");
}