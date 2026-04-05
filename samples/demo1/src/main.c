#include "libgpx.h"

static char *append_dim(char *dst, dim value)
{
    char digits[5];
    uint8_t count = 0;

    do {
        digits[count++] = (char)('0' + (value % 10));
        value /= 10;
    } while (value != 0);

    while (count > 0)
        *dst++ = digits[--count];

    *dst = '\0';
    return dst;
}

static void build_dimension_line(char *dst, const char *label, dim value)
{
    while (*label != '\0')
        *dst++ = *label++;

    *dst++ = ':';
    *dst++ = ' ';
    (void)append_dim(dst, value);
}

int main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    const font_t *font = gpx_get_system_font();
    char width_line[16];
    char height_line[16];

    gpx_clrscr();

    uint8_t fpatt[] = { 0xAA, 0x55 };
    rect_t screen={0,0,255,191}; 

    gpx_fill_rectangle(gpx,&screen,CO_FORE,BM_CPY,fpatt,2,NULL);

    gpx_draw_text(gpx, 0, 0, "loading yos...", font, CO_FORE, BM_CPY, NULL);
    build_dimension_line(width_line, "width", gpx_width());
    build_dimension_line(height_line, "height", gpx_height());

    gpx_draw_text(gpx, 0, 11, width_line, font, CO_BACK, BM_CPY, NULL);
    gpx_draw_text(gpx, 0, 22, height_line, font, CO_BACK, BM_CPY, NULL);
    
    bmp_t *cursor = gpx_get_stock_bmp(GPXSB_CURSOR_CLASSIC);
    uint8_t loc=64;
    rect_t clip={loc,loc,loc+cursor->w-1,loc+cursor->h-1}; 

    for (uint8_t i=0; i<255; i++) {
        gpx_fill_rectangle(gpx,&screen,CO_FORE,BM_CPY,fpatt,2,&clip);  
        gpx_draw_bmp(gpx, loc, loc, cursor, &clip);
        for(int j=0; j<5000; j++) {}
    }

    return 0;
}
