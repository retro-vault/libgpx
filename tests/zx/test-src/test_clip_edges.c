#include "libgpx.h"

/* Exhaustive clip-boundary coverage for the hline/vline 1-D segment clipper:
 * every reject path (segment fully past each edge, scalar axis just outside)
 * and every clamp path (lo end, hi end, both ends, exact boundary = no clamp).
 * Solid 0xFF / BM_CPY / CO_FORE keep it on the set==replace path so the real
 * backend and the per-pixel oracle agree (H/V lines clip identically).
 *
 * NOTE: no helper functions — with --no-std-crt0 the emulator enters at the
 * lowest code address, which must be main(); everything is inlined here. */

void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    rect_t clip = {40, 40, 120, 120};
    gpx_clrscr();

    /* ---- horizontal: segment along X, scalar = y ---- */
    gpx_draw_line(gpx, 20, 40, 140, 40, CO_FORE, BM_CPY, 0xFF, &clip);   /* top edge, clamp both */
    gpx_draw_line(gpx, 20, 120, 140, 120, CO_FORE, BM_CPY, 0xFF, &clip); /* bottom edge, clamp both */
    gpx_draw_line(gpx, 20, 39, 140, 39, CO_FORE, BM_CPY, 0xFF, &clip);   /* y above clip -> reject */
    gpx_draw_line(gpx, 20, 121, 140, 121, CO_FORE, BM_CPY, 0xFF, &clip); /* y below clip -> reject */
    gpx_draw_line(gpx, 20, 50, 80, 50, CO_FORE, BM_CPY, 0xFF, &clip);    /* straddle left only */
    gpx_draw_line(gpx, 80, 55, 140, 55, CO_FORE, BM_CPY, 0xFF, &clip);   /* straddle right only */
    gpx_draw_line(gpx, 40, 60, 120, 60, CO_FORE, BM_CPY, 0xFF, &clip);   /* exact both edges, no clamp */
    gpx_draw_line(gpx, 0, 65, 30, 65, CO_FORE, BM_CPY, 0xFF, &clip);     /* fully left -> reject */
    gpx_draw_line(gpx, 130, 70, 200, 70, CO_FORE, BM_CPY, 0xFF, &clip);  /* fully right -> reject */
    gpx_draw_line(gpx, 119, 75, 121, 75, CO_FORE, BM_CPY, 0xFF, &clip);  /* 1px inside right edge */
    gpx_draw_line(gpx, 39, 80, 41, 80, CO_FORE, BM_CPY, 0xFF, &clip);    /* 1px inside left edge */

    /* ---- vertical: segment along Y, scalar = x ---- */
    gpx_draw_line(gpx, 40, 20, 40, 140, CO_FORE, BM_CPY, 0xFF, &clip);   /* left edge, clamp both */
    gpx_draw_line(gpx, 120, 20, 120, 140, CO_FORE, BM_CPY, 0xFF, &clip); /* right edge, clamp both */
    gpx_draw_line(gpx, 39, 20, 39, 140, CO_FORE, BM_CPY, 0xFF, &clip);   /* x left of clip -> reject */
    gpx_draw_line(gpx, 121, 20, 121, 140, CO_FORE, BM_CPY, 0xFF, &clip); /* x right of clip -> reject */
    gpx_draw_line(gpx, 50, 20, 50, 80, CO_FORE, BM_CPY, 0xFF, &clip);    /* straddle top only */
    gpx_draw_line(gpx, 55, 80, 55, 140, CO_FORE, BM_CPY, 0xFF, &clip);   /* straddle bottom only */
    gpx_draw_line(gpx, 60, 40, 60, 120, CO_FORE, BM_CPY, 0xFF, &clip);   /* exact both edges, no clamp */
    gpx_draw_line(gpx, 65, 0, 65, 30, CO_FORE, BM_CPY, 0xFF, &clip);     /* fully above -> reject */
    gpx_draw_line(gpx, 70, 130, 70, 200, CO_FORE, BM_CPY, 0xFF, &clip);  /* fully below -> reject */
    gpx_draw_line(gpx, 75, 119, 75, 121, CO_FORE, BM_CPY, 0xFF, &clip);  /* 1px inside bottom edge */
    gpx_draw_line(gpx, 80, 39, 80, 41, CO_FORE, BM_CPY, 0xFF, &clip);    /* 1px inside top edge */

    __asm
        halt
    __endasm;
}
