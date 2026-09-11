/* Platform fonts and cursors share the canonical Spectrum raster artwork.
 * GPL2 License (see: LICENSE), Copyright (C) 2026 tomaz stih. */
#include "libgpx.h"
#include "assets.inc"

const font_t *gpx_get_system_font(void)
{
    return (const font_t *)gpx_font_envy;
}

const font_t *gpx_get_tiny_font(void)
{
    return gpx_get_system_font();
}

bmp_t *gpx_get_stock_bmp(uint8_t which)
{
    static const uint8_t *const cursors[] = {
        gpx_cur_classic, gpx_cur_std, gpx_cur_hourglass,
        gpx_cur_caret, gpx_cur_hand, gpx_cur_resize
    };
    return which < sizeof(cursors) / sizeof(cursors[0])
        ? (bmp_t *)cursors[which] : NULL;
}
