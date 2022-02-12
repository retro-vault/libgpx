/*
 * rotate.c
 *
 * Fast rotate operations.
 * 
 * MIT License (see: LICENSE)
 * copyright (c) 2022 tomaz stih
 *
 * 10.02.2022   tstih
 *
 */
#include <gpxcore.h>

/* fast rotate byte left */
uint8_t _roleft(uint8_t b, uint8_t shifts) {
    /* nothing to do? */
    if (b==0xff || !shifts) return b;
    /* rotate... */
    uint8_t ext;
    shifts%=8; /* reduce shifts to byte */
    ext = b>>(8-shifts);
    b <<= shifts; /* shift b */
    return b|ext;
} 
       
/* fast rotate byte left */
uint8_t _roright(uint8_t b, uint8_t shifts) {
    /* nothing to do? */
    if (b==0xff || !shifts) return b;
    /* rotate... */
    uint8_t ext;
    shifts%=8; /* reduce shifts to byte */
    ext = b<<(8-shifts);
    b >>= shifts; /* shift b */
    return b|ext;
}