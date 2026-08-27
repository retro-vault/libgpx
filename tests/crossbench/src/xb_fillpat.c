#include "xbench.h"
BENCH_MAIN()

/* 8 patterned fills of the same 248x184 area, half of them XOR. A pattern
 * cannot be handed to the EF9367's area fill, so the Partner draws these in
 * software and this is where it pays for having no raster hardware. */
void bench_body(gpx_t *gpx)
{
    static uint8_t dash[2] = {0xAA, 0x55};
    rect_t r;
    uint8_t i;

    r.x0 = 4; r.y0 = 4; r.x1 = 251; r.y1 = 187;
    for (i = 0; i < 4; ++i)
        gpx_fill_rectangle(gpx, &r, CO_FORE, BM_CPY, dash, 2, 0);
    for (i = 0; i < 4; ++i)
        gpx_fill_rectangle(gpx, &r, CO_FORE, BM_XOR, dash, 2, 0);
}
