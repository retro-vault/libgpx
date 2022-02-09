/*
 * pixie.h
 *
 * Pixie definitions.
 * 
 * MIT License (see: LICENSE)
 * copyright (c) 2022 tomaz stih
 *
 * 26.01.2022   tstih
 *
 */
#ifndef __PIXIE_H__
#define __PIXIE_H__

#define PIXIE_WIDTH     1024
#define PIXIE_HEIGHT    512
#define PIXIE_PIPE      "/tmp/pixie.pipe"

/* Pixie file descriptor. */
extern int open_pixie_channel();
extern void close_pixie_channel(int channel);

#endif /* __PIXIE_H__ */