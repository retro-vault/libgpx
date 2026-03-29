/*
 * pixie.c
 *
 * Pixie definitions.
 * 
 * MIT License (see: LICENSE)
 * copyright (c) 2022 tomaz stih
 *
 * 26.01.2022   tstih
 *
 */
#include <fcntl.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdarg.h>

#include <pixie/pixie.h>

/* pixie comms */

static int _fd=0;
static char _buffer[MAX_PIXIE_BUFFER];

void pxopen() {
    if ( (_fd = open(PIXIE_PIPE, O_WRONLY)) < 0)
        exit(1);
}

void pxclose() {
    close(_fd);
}

void pxwrite(const char *format, ...) {

    /* Pass to file... */
    va_list argptr;
    va_start(argptr, format);
    vsprintf(_buffer, format, argptr);
    write(_fd,_buffer,strlen(_buffer));
    va_end(argptr);
}