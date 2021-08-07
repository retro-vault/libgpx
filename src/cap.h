/*
 * cap.h
 *
 * gpx capabilities definitions
 *
 * MIT License (see: LICENSE)
 * copyright (c) 2021 tomaz stih
 *
 * 07.08.2021   tstih
 *
 */
#ifndef __CAP_H__
#define __CAP_H__

#include <std.h>
#include <gpxdef.h>

/* page resolution */
typedef struct gpx_resolution_s {
    coord width;                        /* width in pixels */
    coord height;                       /* height in pixels */
} gpx_resolution_t;

/* the page  */
typedef struct gpx_page_s {
    int num_resolutions;                /* number of resolutions */
    gpx_resolution_t *resolutions;      /* array of resolutions */
} gpx_page_t;

/* gpx capabilities struct. */
typedef struct gpx_cap_s {
    /* pages info */
    int num_pages;                      /* number of pages */
    gpx_page_t *pages;                  /* array of pages */
    /* colors info */
    int num_colors;
    color fore_color;                   /* system fore color */
    color back_color;                   /* system back color */
} gpx_cap_t;

/* get gpx capabilities */
extern gpx_cap_t* gpx_cap(gpx_t *g);

#endif /* __CAP_H__ */