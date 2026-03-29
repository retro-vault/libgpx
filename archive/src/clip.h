/*
 * clip.c
 *
 * clipping functions header
 *
 * MIT License (see: LICENSE)
 * copyright (c) 2021 tomaz stih
 *
 * 09.08.2021   tstih
 *
 */
#ifndef __CLIP_H__
#define __CLIP_H__

#include <std.h>
#include <gpxcore.h>
#include <rect.h>

bool _cohen_sutherland(
    rect_t *clip_area, 
    coord *x0, coord *y0, 
    coord *x1, coord *y1);

#endif /* __CLIP_H__ */