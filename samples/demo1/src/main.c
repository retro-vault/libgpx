#include "libgpx.h"

int main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    const font_t *font = gpx_get_system_font();

    gpx_clrscr();

    gpx_draw_text(gpx, 0, 0, "loading yos...", font, CO_FORE, BM_CPY, NULL);
    gpx_draw_text(gpx, 0, 11, "detected 3 microdrives", font, CO_FORE, BM_CPY, NULL);

    uint8_t fpatt[] = { 0xAA, 0x55 };
    rect_t screen={0,0,255,191}; 
    
    bmp_t *cursor = gpx_get_stock_bmp(GPXSB_CURSOR_CLASSIC);
    uint8_t loc=64;
    rect_t clip={loc,loc,loc+cursor->w-1,loc+cursor->h-1}; 

    for (uint8_t i=0; i<255; i++) {
        gpx_fill_rectangle(gpx,&screen,CO_FORE,BM_CPY,fpatt,2,&clip);  
        gpx_draw_bmp(gpx, loc, loc, cursor, &clip);
    }

    return 0;
}
