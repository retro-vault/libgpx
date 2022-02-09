    /*
 * gpxcore.c
 *
 * Graphics init and exit functions for Unix frambuffer.
 * 
 * MIT License (see: LICENSE)
 * copyright (c) 2022 tomaz stih
 *
 * 26.01.2022   tstih
 *
 */
#include <stdio.h>
#include <unistd.h>
#include <string.h>

#include <util.h>
#include <native.h>
#include <gpxcore.h>

#include <pixie/pixie.h>

#define MAX_BUFFER_LEN 0xff

/* pick modes from current graphics 
   disclaimer: there is only one, always! */
extern gpx_t _g;

void _plotxy(coord x, coord y) {

    /* be compatible and don't draw if BLT_NONE. */
    if (_g.blit==BLT_NONE) return;

    static char buffer[MAX_BUFFER_LEN];
    sprintf(buffer,"P%d,%d\n",x,y);
    int channel=open_pixie_channel();
    write(channel,buffer,strlen(buffer));
    close_pixie_channel(channel);
}

void _line(coord x0, coord y0, coord x1, coord y1) {
    
    /* be compatible and don't draw if BLT_NONE. */
    if (_g.blit==BLT_NONE) return;
    
    static char buffer[MAX_BUFFER_LEN];
    sprintf(buffer,"L%d,%d,%d,%d,%d\n",x0,y0,x1,y1,_g.line_style);
    int channel=open_pixie_channel();
    write(channel,buffer,strlen(buffer));
    close_pixie_channel(channel);
}

void _hline(coord x0, coord x1, coord y) {
    _line(x0,y,x1,y);
}

void _vline(coord x, coord y0, coord y1) {
    _line(x,y0,x,y1);
}

void _stridexy(
        coord x, 
        coord y, 
        void *data, 
        uint8_t start, 
        uint8_t end) {

    UNUSED(x);UNUSED(y);
    UNUSED(data);
    UNUSED(start);UNUSED(end);
}

void _tinyxy(
    coord x, 
    coord y, 
    uint8_t *moves,
    uint8_t num,
    void *clip){

    UNUSED(x);UNUSED(y);
    UNUSED(moves);UNUSED(num);
    UNUSED(clip);
}