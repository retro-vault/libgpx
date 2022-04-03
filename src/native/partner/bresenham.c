/*
 * brensenham.c
 *
 * Iskra Delta Partner bresenham algorithm for
 * custom line patterns.
 * 
 * MIT License (see: LICENSE)
 * copyright (c) 2022 tomaz stih
 *
 * 19.03.2022   tstih
 *
 */
#include <std.h>
#include <gpxcore.h>
#include <native.h>

void _bresenham(int x0, int y0, int x1, int y1, uint8_t pattern) {

    uint8_t bit=0x80; /* Start with top bit... */
    
    int dx =  _abs (x1 - x0), sx = x0 < x1 ? 1 : -1;
    int dy = -_abs (y1 - y0), sy = y0 < y1 ? 1 : -1; 
    int err = dx + dy, e2; /* error value e_xy */

    for (;;){  /* Loop */

        /* dot or not? */
        if (pattern & bit)
            _plotxy(x0,y0);

        /* Shift pattern. */
        bit>>=1;
        if (bit==0) bit=0x80;

        if (x0 == x1 && y0 == y1) break;
        e2 = 2 * err;
        if (e2 >= dy) { err += dy; x0 += sx; } /* e_xy+e_x > 0 */
        if (e2 <= dx) { err += dx; y0 += sy; } /* e_xy+e_y < 0 */
    }
}