/*
 * bench.h — scaffolding for ZX Spectrum micro-benchmarks.
 *
 * Each benchmark puts its measured work in bench_body(). The runner stops at
 * bench_body's entry to take a T-state reading, then runs to HALT, so setup
 * (gpx_create, clearing, seeding) is excluded and only the primitive under
 * test is counted.
 */
#ifndef ZXBENCH_H
#define ZXBENCH_H

#include "libgpx.h"

#define ZX_W 256
#define ZX_H 192

void bench_body(gpx_t *gpx);

/* Shared with the test suite: same xorshift, so benchmark inputs are
 * reproducible across runs and across toolchain versions. */
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
        gpx_t *gpx = gpx_create(GPXM_DEFAULT);    \
        bench_body(gpx);                          \
        __asm__("halt");                          \
    }

#endif /* ZXBENCH_H */
