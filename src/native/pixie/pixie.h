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

#define PIXIE_WIDTH         1024
#define PIXIE_HEIGHT        512
#define PIXIE_PIPE          "/tmp/pixie.pipe"

/* max buffer to send...*/
#define MAX_PIXIE_BUFFER    32

/* Pixie file descriptor. */
extern void pxopen();
extern void pxclose();
extern void pxwrite(const char *format, ...);

#endif /* __PIXIE_H__ */