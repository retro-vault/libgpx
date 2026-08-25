/*
 * zxtest.h — shared scaffolding for ZX Spectrum scenario tests.
 *
 * Every scenario is compiled twice: once against the assembler backend in
 * src/zx and once against the independent C oracle in tests/zx/stub. Both
 * images run on the emulator behind zx-spectrum-mcp and must agree on the
 * whole 6912-byte screen, the border colour, and the results block below.
 *
 * Helpers here never call into libgpx, so a broken primitive cannot hide a
 * failure by corrupting the scaffolding.
 */
#ifndef ZXTEST_H
#define ZXTEST_H

#include "libgpx.h"

#define TEST_END() __asm__("halt")

#define ZX_W 256
#define ZX_H 192

/* Results block. The runner locates `_test_results` in the linker map and
 * compares it byte-for-byte, which is how scenarios assert on return values
 * (gpx_measure_text, the rotated pattern from gpx_draw_line) rather than on
 * pixels alone. */
#define TEST_RESULTS_BYTES 96
uint8_t test_results[TEST_RESULTS_BYTES];
static uint8_t test_result_slot;

static void record(uint8_t value)
{
    if (test_result_slot < TEST_RESULTS_BYTES)
        test_results[test_result_slot++] = value;
}

static void record16(uint16_t value)
{
    record((uint8_t)(value & 0xFF));
    record((uint8_t)(value >> 8));
}

/* Deterministic xorshift, so the real and oracle images walk the exact same
 * sequence of cases. Seeded per scenario. */
static uint16_t rnd_state = 0xACE1;

static void rnd_seed(uint16_t seed)
{
    rnd_state = seed ? seed : 1;
}

static uint16_t rnd(void)
{
    rnd_state ^= (uint16_t)(rnd_state << 7);
    rnd_state ^= (uint16_t)(rnd_state >> 9);
    rnd_state ^= (uint16_t)(rnd_state << 8);
    return rnd_state;
}

/* Inclusive range. lo <= hi is the caller's job. */
static coord rnd_between(coord lo, coord hi)
{
    uint16_t span = (uint16_t)(hi - lo) + 1u;
    return (coord)(lo + (coord)(rnd() % span));
}

/* Paint the screen straight through VRAM so a scenario can start from
 * non-blank content. Only then does a CO_BACK or BM_XOR draw prove anything. */
static uint8_t *zx_vram(void)
{
    return (uint8_t *)0x4000;
}

static void seed_screen(uint8_t value)
{
    uint8_t *p = zx_vram();
    uint16_t i;
    for (i = 0; i < 0x1800; ++i)
        p[i] = value;
}

/* Diagonal wash: every byte differs from its neighbours, so an off-by-one
 * in a span or a mask shows up as a mismatch instead of blending in. */
static void seed_screen_wash(void)
{
    uint8_t *p = zx_vram();
    uint16_t i;
    for (i = 0; i < 0x1800; ++i)
        p[i] = (uint8_t)(0x93 * (i & 0x1F) + (i >> 5));
}

/* Common fixtures. */
static const uint8_t patt_bytes[8] = {
    0xFF, 0x00, 0xAA, 0x55, 0xF0, 0x0F, 0x80, 0x01
};

/* A whole-screen clip must behave exactly like passing NULL. Declared as a
 * local by each scenario: xcc warns (wrongly) on const struct initializers,
 * and a clean build is worth more than the const. */
#define FULL_SCREEN_RECT {0, 0, 255, 191}

#endif /* ZXTEST_H */
