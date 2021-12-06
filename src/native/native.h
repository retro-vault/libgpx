/*
 * native.h
 *
 * native interfaces, that high level functions
 * expect
 * 
 * MIT License (see: LICENSE)
 * copyright (c) 2021 tomaz stih
 *
 * 09.08.2021   tstih
 *
 */
#ifndef __NATIVE_H__
#define __NATIVE_H__

#include <gpxcore.h>

/* pixel at x,y */
extern void _plotxy(coord x, coord y);

/* vertical line */
extern void _vline(coord x, coord y0, coord y1);

/* horizontal line */
extern void _hline(coord x0, coord x1, coord y);

/* draw fast line */ 
extern void _ef9367_draw_line(
    coord x0, 
    coord y0, 
    coord x1,
    coord y1);  

/* stride */
extern void _stridexy(
    coord x, 
    coord y, 
    void *data, 
    uint8_t start, 
    uint8_t end);

/* Structure for clipping tiny glyph. */
typedef struct tiny_clip_s {
    uint8_t posx;
    uint8_t poxy;
    uint8_t left;
    uint8_t top;
    uint8_t right;
    uint8_t bottom;
} tiny_clip_t;

/* tiny */
extern int _tinyxy(
    coord x, 
    coord y, 
    uint8_t *moves,
    uint8_t num,
    void *clip);

#endif /* __NATIVE_H__ */