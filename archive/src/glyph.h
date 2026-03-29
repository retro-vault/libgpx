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

/* Tiny glyph header. */
typedef struct tiny_glyph_s {
    uint8_t reserved:5;                 /* stride-1 (1-16) */
    uint8_t class:3;                    /* high nibble */
    uint8_t width;                      /* width-1 (1-256) */
    uint8_t height;                     /* height-1 (1-256) */
    uint8_t moves;                      /* number of moves */
    uint8_t data[0];                    /* start of data */
} tiny_glyph_t;

/* Line glyph header. */
typedef struct line_glyph_s {
    uint8_t len_msb:5;                  /* data len MSB */
    uint8_t class:3;                    /* high nibble */
    uint8_t width;                      /* width-1 (1-256) */
    uint8_t height;                     /* height-1 (1-256) */
    uint8_t len_lsb;                    /* number of moves */
    uint8_t data[0];                    /* start of data */
} line_glyph_t;

/* RLE glyph header. */
typedef struct rle_glyph_s {
    uint8_t height_msb:2;               /* height MSB */
    uint8_t width_msb:2;                /* width MSB */
    uint8_t byte_aligned:1;             /* reserved */
    uint8_t class:3;                    /* high nibble */
    uint8_t width_lsb;                  /* width-1 (1-256) */
    uint8_t height_lsb;                 /* height-1 (1-256) */
    uint8_t reserved2;                  /* number of moves */
    uint8_t data[0];                    /* start of data */
} rle_glyph_t;


#endif /* __GLYPH_H__ */