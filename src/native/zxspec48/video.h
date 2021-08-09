/*
 * video.h
 * 
 * basic video ram functions and definitions for ZX Spectrum 48L
 *
 * MIT License (see: LICENSE)
 * copyright (c) 2021 tomaz stih
 *
 * 03.08.2021   tstih
 * 
 */
#ifndef __VIDEO_H__
#define __VIDEO_H__

#include <std.h>

#define SCREEN_WIDTH    256
#define SCREEN_HEIGHT   192

#define MAX_X           SCREEN_WIDTH-1
#define MAX_Y           SCREEN_HEIGHT-1

extern void vid_plotxy(uint8_t x, uint8_t y);

#endif /* __VIDEO_H__ */