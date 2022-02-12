/*
 * std.h
 *
 * standard library definitions to make libgpx independent
 *
 * MIT License (see: LICENSE)
 * copyright (c) 2021 tomaz stih
 *
 * 07.08.2021   tstih
 *
 */
#ifndef __STD_H__
#define __STD_H__

/* stdbool.h */
#define bool int
#define false 0
#define FALSE 0
#define true 1
#define TRUE 1

/* stdlib.h */
#ifndef NULL
#define NULL     (void *)0
#endif

extern int _abs (int i);

#ifdef __SDCC
/* stdint.h */
typedef signed char     int8_t;
typedef unsigned char   uint8_t;
typedef int             int16_t;
typedef unsigned int    uint16_t;
typedef long            int32_t;
typedef unsigned long   uint32_t;
#else
#include <stdint.h>
#endif

/* string.h */
extern void _memcpy (void* dst, void* src, unsigned int num);

/* misc macros */
#define MAX(a,b) (a>b?a:b)
#define MIN(a,b) (a<b?a:b)

#endif /* __STD_H__ */