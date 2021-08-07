/*
 * rect.c
 *
 * rectangle arith. functions
 *
 * NOTES:
 *  this is pure "C" implementation and it might be a bit non-optimal for
 *  8-bit machines. consider writing parts of it in assembly.
 * 
 * MIT License (see: LICENSE)
 * copyright (c) 2021 tomaz stih
 *
 * 07.10.2013   tstih
 *
 */
#include <std.h>
#include <rect.h>

bool gpx_rect_contains(rect_t *r, coord x, coord y) {
	return (r->x0 <= x && r->x1 >= x && r->y0 <= y && r->y1 >=y );
}

bool gpx_rect_overlap(rect_t *a, rect_t *b) {
	return !(a->y1 < b->y0 || a->y0 > b->y1 || a->x1 < b->x0 || a->x0 > b->x1);
}

rect_t* gpx_rect_intersect(rect_t *a, rect_t *b, rect_t *intersect) {
	if (gpx_rect_overlap(a,b)) {
		intersect->x0=MAX(a->x0,b->x0);
		intersect->y0=MAX(a->y0,b->y0);
		intersect->x1=MIN(a->x1,b->x1);
		intersect->y1=MIN(a->y1,b->y1);
		return intersect;
	} else return NULL;
}