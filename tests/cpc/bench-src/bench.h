/*
 * bench.h -- scaffolding for Amstrad CPC micro-benchmarks.
 *
 * Each benchmark puts its measured work in bench_body(). The runner stops at
 * bench_body's entry to take a T-state reading, then runs to HALT, so setup
 * (gpx_create, clearing, seeding) is excluded and only the primitive under
 * test is counted.
 *
 * Every benchmark is built twice, once per display mode, because the two
 * pack a different number of pixels into a byte and therefore do different
 * amounts of work for the same picture.
 */
#ifndef CPCBENCH_H
#define CPCBENCH_H

#include "libgpx.h"

#ifndef DEMO_MODE
#define DEMO_MODE GPXM_DEFAULT
#endif

void bench_body(gpx_t *gpx);

/* Same xorshift the other suites use, so inputs are reproducible. */
static uint16_t rnd_state = 0xACE1;

static uint16_t rnd(void)
{
    rnd_state ^= (uint16_t)(rnd_state << 7);
    rnd_state ^= (uint16_t)(rnd_state >> 9);
    rnd_state ^= (uint16_t)(rnd_state << 8);
    return rnd_state;
}

static coord rnd_between(coord lo, coord hi)
{
    uint16_t span = (uint16_t)(hi - lo) + 1u;
    return (coord)(lo + (coord)(rnd() % span));
}

#define BENCH_MAIN()                              \
    void main(void)                               \
    {                                             \
        gpx_t *gpx = gpx_create(DEMO_MODE);       \
        bench_body(gpx);                          \
        __asm__("halt");                          \
    }

#endif /* CPCBENCH_H */
