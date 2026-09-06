/* Native styles and finite XOR compositions, plus unrelated fallback bytes.
 * Each phase is 40 long horizontal calls, alternating direction. */
#include "gdptest.h"

extern void _ef9367_wait_ready(void);

static const uint8_t patterns[] = {0xAA,0x55,0xCC,0x33,0xF0,0x0F,
                                 0x11,0x88,0x77,0xEE,0x1F,0x3F,0x7F,0xA5,0x5A,0x9B};
void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    uint8_t i, p, mode;
    gpx_clrscr();
    _ef9367_wait_ready();
    gdp_phase();
    for (mode = 0; mode != 2; ++mode) {
        for (p = 0; p != sizeof(patterns); ++p) {
            for (i = 0; i != 40; ++i)
                gpx_draw_line(gpx, (i & 1) ? 1023 : 0, 50+i,
                    (i & 1) ? 0 : 1023, 50+i,
                    CO_FORE, mode, patterns[p], 0);
            _ef9367_wait_ready();
            if (mode == 1 && p == sizeof(patterns)-1) gdp_done();
            else gdp_phase();
        }
    }
}
