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
#include <stdlib.h>

#include <pixie/pixie.h>

int open_pixie_channel() {
    int channel;
    if ( (channel = open(PIXIE_PIPE, O_WRONLY)) < 0)
        exit(1);
    return channel;
}

void close_pixie_channel(int channel) {
    close(channel);
}