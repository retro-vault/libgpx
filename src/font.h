/*
 * font.h
 *
 * Font structure.
 *
 * MIT License (see: LICENSE)
 * copyright (c) 2021 tomaz stih
 *
 * 17.08.2021   tstih
 *
 */
#ifndef __FONT_H__
#define __FONT_H__

#include <std.h>

typedef struct font_s {
    uint8_t hor_spacing_hint:4;         /* 0-3: hor. spacing for proport.fnt */
    uint8_t reserved:3;                 /* 4-6: unused for now */
    uint8_t proportional:1;             /* 7: proportional flag */
    uint8_t width;                      /* max width for proportional font */
    uint8_t height;                     /* font height */
    uint8_t first_ascii;                /* first ascii of font */
    uint8_t last_ascii;                 /* last ascii of font */
    uint16_t glyph_offsets[0];          /* table of offsets */
} font_t;

#endif /* __FONT_H__ */