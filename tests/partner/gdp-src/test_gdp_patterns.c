/* Exhaustive horizontal pattern regression, including phase and chunk edges.
 * Every byte is drawn over a mixed existing raster in each mode/direction. */
#include "gdptest.h"

uint8_t pattern_returns[256];
uint8_t pattern_phase;

void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    static rect_t clip = {0, 0, 1023, 255};
    coord p, x0, x1, span;
    uint8_t setting, range;
    pattern_phase = 0;
    for (range = 0; range != 4; ++range) {
        for (setting = 0; setting != 8; ++setting) {
            gpx_clrscr();
            for (p = 0; p != 256; ++p) {
                gpx_draw_line(gpx, 0, p, 1023, p,
                              CO_FORE, BM_CPY, 0xA5, 0);
                if (range == 0) span = p & 63;
                else if (range == 1) span = 248 + (p & 15);
                else span = 768 + p;
                x0 = (p & 1) ? 0 : 1023 - span;
                x1 = x0 + span;
                if (range == 3) { x0 = -p; x1 = 1031 + p; }
                pattern_returns[p] = gpx_draw_line(gpx,
                    (setting & 4) ? x1 : x0, p,
                    (setting & 4) ? x0 : x1, p,
                    setting & 1, (setting >> 1) & 1, (uint8_t)p,
                    range == 3 ? &clip : 0);
            }
            if (range == 3 && setting == 7) gdp_done();
            else gdp_phase();
            ++pattern_phase;
        }
    }
}
