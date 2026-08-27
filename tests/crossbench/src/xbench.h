/*
 * xbench.h -- scaffolding for the cross-backend benchmarks.
 *
 * The per-backend suites under tests/{zx,cpc,partner} size their work from
 * gpx_width()/gpx_height(), which makes their numbers incomparable: the same
 * "fill the screen" benchmark paints 256x192 on a Spectrum and 1024x256 on a
 * Partner. These benchmarks instead use fixed absolute coordinates inside a
 * 256x192 box, which fits every supported display, so all three backends are
 * asked to draw exactly the same picture.
 *
 * As elsewhere, the measured work goes in bench_body(); the runner takes a
 * T-state reading at its entry and another at HALT, so gpx_create() and the
 * initial clear are excluded.
 */
#ifndef XBENCH_H
#define XBENCH_H

#include "libgpx.h"

/* The CPC has two display modes behind one library; every other backend
 * ignores this. */
#ifndef DEMO_MODE
#define DEMO_MODE GPXM_DEFAULT
#endif

#define XB_W 256
#define XB_H 192

void bench_body(gpx_t *gpx);

#define BENCH_MAIN()                              \
    void main(void)                               \
    {                                             \
        gpx_t *gpx = gpx_create(DEMO_MODE);       \
        gpx_clrscr();                             \
        bench_body(gpx);                          \
        __asm__("halt");                          \
    }

#endif /* XBENCH_H */
