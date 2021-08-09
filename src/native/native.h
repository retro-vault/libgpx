/*
 * native.h
 *
 * native interfaces, that high level functions
 * expect
 * 
 * MIT License (see: LICENSE)
 * copyright (c) 2021 tomaz stih
 *
 * 09.08.2021   tstih
 *
 */
#ifndef __NATIVE_H__
#define __NATIVE_H__

#include <gpxcore.h>

/* pixel at x,y */
void _plotxy(coord x, coord y);

/* vertical line */
void _vline(coord x, coord y0, coord y1);

/* horizontal line */
void _hline(coord x0, coord x1, coord y);

#endif /* __NATIVE_H__ */