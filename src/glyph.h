/*
 * glyph.h
 *
 * Glyph definitions.
 *
 * MIT License (see: LICENSE)
 * copyright (c) 2021 tomaz stih
 *
 * 15.08.2021   tstih
 *
 */
#ifndef __GLPYH_H__
#define __GLPYH_H__

#include <std.h>

/* Known glyph classes */
#define GYCLS_RASTER    0
#define GYCLS_TINY      1
#define GYCLS_LINES     2
#define GYCLS_RLE       3

/* Generic glyph header. */
typedef struct glyph_s {
    uint8_t reserved1:5;                /* low nibble */
    uint8_t class:3;                    /* high nibble */
    uint8_t reserved2[3];
    uint8_t data[0];                    /* start of data */
} glyph_t;

/* Raster glyph header (a generic variant) */
typedef struct raster_glyph_s {
    uint8_t stride:5;                   /* stride-1 (1-16) */
    uint8_t class:3;                    /* high nibble */
    uint8_t width;                      /* width-1 (1-256) */
    uint8_t height;                     /* height-1 (1-256) */
    uint8_t reserved;                   /* not used */
    uint8_t data[0];                    /* start of data */
} raster_glyph_t;

#endif /* __GLYPH_H__ */