/*
 * bresenham.c
 *
 * Draw line using Bresenham.
 *
 * MIT License (see: LICENSE)
 * copyright (c) 2021 tomaz stih
 *
 * 19.01.2022   tstih
 *
 */
#include <native.h>

void _line(coord x0, coord y0, coord x1, coord y1) {
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