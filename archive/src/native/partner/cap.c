/*
 * cap.c
 *
 * Iskra Delta Partner gpx_cap implementation.
 * 
 * MIT License (see: LICENSE)
 * copyright (c) 2021 tomaz stih
 *
 * 03.08.2021   tstih
 *
 */
#include <cap.h>

#include <partner/ef9367.h>

/* there can be only one gpx! */
static gpx_cap_t _cap;
static bool _capinitialized = false;

/* two pages, cached */
static gpx_page_t _pages[2];

/* three resolutions */
static gpx_resolution_t _resolutions[3];

/* get the capabilities */
gpx_cap_t* gpx_cap(gpx_t *g) {
    g;

    /* not the first time? */
    if (_capinitialized) return &_cap;
    /* signal initialized */
    _capinitialized=true;
    
    /* always start with highest resolution */
    _resolutions[0].width=1024;
    _resolutions[0].height=512;
    /* native idp resolution 1 */
    _resolutions[1].width=1024;
    _resolutions[1].height=256;
    
    /* populate pages */
    _cap.num_pages=2;
    _cap.pages=_pages;
    _pages[0].num_resolutions=2;
    _pages[0].resolutions=_resolutions;
    _pages[1].num_resolutions=2;
    _pages[1].resolutions=_resolutions;

    /* configure colors */
    _cap.num_colors=2;
    _cap.fore_color=1;
    _cap.back_color=0;

    /* and return */
    return &_cap;
}

gpx_resolution_t *gpx_get_disp_page_resolution(
    gpx_t *g,
    gpx_resolution_t *res) {

    _memcpy(
        res,
        &(_resolutions[(g->resolutions)[g->display_page]]),
        sizeof(gpx_resolution_t)
    );

    return res;
}