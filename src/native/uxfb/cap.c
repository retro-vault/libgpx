/*
 * gpxcore.c
 *
 * Unix frambuffer capabilities implementation.
 * 
 * MIT License (see: LICENSE)
 * copyright (c) 2022 tomaz stih
 *
 * 26.01.2022   tstih
 *
 */
#include <cap.h>

#include <zxspec48/video.h>

/* there can be only one gpx! */
static gpx_cap_t _cap;
static bool _capinitialized = false;

static gpx_page_t _page0;
static gpx_resolution_t _native_resolution;

/* get the capabilities */
gpx_cap_t* gpx_cap(gpx_t *g) {
    /* not the first time? */
    if (_capinitialized) return &_cap;
    /* signal initialized */
    _capinitialized=true;
    
    /* configure pages */
    _cap.num_pages=1;
    _cap.pages=&_page0;                  /* point to page 0 */
    _page0.num_resolutions=1;
    _page0.resolutions=&_native_resolution;
    _native_resolution.width=800;
    _native_resolution.height=600;

    /* configure colors */
    _cap.num_colors=15;
    _cap.fore_color=4;                  /* green on... */
    _cap.back_color=0;                  /* ...black */

    /* and return */
    return &_cap;
}

gpx_resolution_t *gpx_get_disp_page_resolution(
    gpx_t *g,
    gpx_resolution_t *res) {


    return NULL;
}