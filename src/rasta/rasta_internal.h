/* Internal helpers for the native packed Rasta framebuffer backend.
 * GPL2 License (see: LICENSE), Copyright (C) 2026 tomaz stih. */
#ifndef GPX_RASTA_INTERNAL_H
#define GPX_RASTA_INTERNAL_H

#include "libgpx.h"

#define RASTA_WIDTH 1920
#define RASTA_HEIGHT 1080
#define RASTA_STRIDE (RASTA_WIDTH / 8)
#define RASTA_SIZE ((size_t)RASTA_STRIDE * RASTA_HEIGHT)

/* Widened coordinates avoid wrapping offscreen geometry back onscreen. */
void rasta_pixel(gpx_t *gpx, int32_t x, int32_t y,
    color c, bmode m, const rect_t *clip);
int rasta_get_pixel(int32_t x, int32_t y);
void rasta_pattern_span(gpx_t *gpx, int32_t x0, int32_t x1, int32_t y,
    int32_t origin_x, uint8_t pattern, color c, bmode m,
    const rect_t *clip);

#endif
