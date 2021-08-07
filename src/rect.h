/*
 * rect.h
 *
 * rectangle definitions
 *
 * MIT License (see: LICENSE)
 * copyright (c) 2021 tomaz stih
 *
 * 07.08.2021   tstih
 *
 */
#ifndef __RECT_H__
#define __RECT_H__

/* due to interdependency structure rect_t is defined in gpxdef.h */
#include <gpxdef.h>

/* does rectangle contains point? */
extern bool gpx_rect_contains(rect_t *r, coord x, coord y);

/* do rectangles overlap? */
extern bool gpx_rect_overlap(rect_t *a, rect_t *b);

/* intersection of rectangles */
extern rect_t* gpx_rect_intersect(rect_t *a, rect_t *b, rect_t *intersect);

#endif /* __RECT_H__ */