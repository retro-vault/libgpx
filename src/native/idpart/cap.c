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
#include <stdlib.h>
#include <stdlib.h>
#include <gpx.h>

#include "ef9367.h"

/* cached, always the same */
static gpx_cap_t cap;

/* two pages, cached */
static gpx_page_t pages[2];

/* three resolutions */
static gpx_resolution_t resolutions[3];

gpx_cap_t* gpx_cap() {

    /* colors */
    cap.num_colors=2;
    cap.fore_color=1;
    cap.back_color=0;

    /* two pages */
    cap.num_pages=2;
    cap.pages = pages;

    /* emulated resolution (does not exist on idp)  */
    resolutions[0].width=512;
    resolutions[0].height=256;
    /* native idp resolution 0 */
    resolutions[1].width=1024;
    resolutions[1].height=256;
    /* native idp resolution 1 */
    resolutions[2].width=1024;
    resolutions[2].height=512;

    /* populate pages */
    pages[0].num_resolutions=3;
    pages[0].resolutions=resolutions;
    pages[1].num_resolutions=3;
    pages[1].resolutions=resolutions;

    /* and return initialized capabilities */
    return &cap;
}