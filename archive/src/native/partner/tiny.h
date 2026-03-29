/*
 * tiny.h
 * 
 * Internal tiny glyph definitions. 
 *
 * MIT License (see: LICENSE)
 * copyright (c) 2021 tomaz stih
 *
 * 28.08.2021   tstih
 * 
 */
#ifndef __TINY_H__
#define __TINY_H__

#include <std.h>
#include <gpxcore.h>

/* Each move is 1 byte.
   NOTE:
    SDCC lays out bits in the opposite order
    i.e. dy:3 is MSB bits 0-1. */
typedef struct tiny_move_s {
    uint8_t co1:1;                      /* high color bit */
    uint8_t dxs:1;                      /* bit 1: dx sign */
    uint8_t dys:1;                      /* bit 2: dy sign */
    uint8_t dy:2;                       /* bits 0-1: dy */
    uint8_t dx:2;                       /* bits 3-4: dx */
    /* values for co: 
        CO_NONE - don't paint, just move 
        CO_BACK - "eraser" 
        CO_FORE - standard pixel */
    uint8_t co0:1;                      /* low color bit */
} tiny_move_t;

/* Memory structure, used (internally) to 
   clip tiny glyph. */
typedef struct tiny_clip_s {
    uint8_t x0;             
    uint8_t y0;                     
    uint8_t x1;
    uint8_t y1;
    uint8_t offset;                     /* longest axis absolute len */
    uint8_t dx;
    uint8_t dy;
    uint8_t signx;                      /* -1, 0 or 1 */
    uint8_t signy;                      /* -1, 0 or 1 */
    /* bit 0 is pt0, bit 1 is pt1, 
       when 1 ... inside clipping area
       when 0 ... outside clipping area */
    uint8_t clipstat;                
    uint8_t left;
    uint8_t top;
    uint8_t right;
    uint8_t bottom;
} tiny_clip_t;

#endif /* __TINY_H__ */