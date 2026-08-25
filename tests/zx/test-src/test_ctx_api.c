#include "zxtest.h"

/* Context lifecycle and every accessor that returns a value rather than
 * drawing: the results block carries them into the comparison. */
void main(void)
{
    gpx_t *gpx;
    const font_t *sys;
    const font_t *tiny;
    bmp_t *b;
    uint8_t i;

    gpx = gpx_create(GPXM_DEFAULT);

    record(gpx != (gpx_t *)0);
    record16(gpx_width());
    record16(gpx_height());
    record16(gpx->width);
    record16(gpx->height);
    record(gpx->pages);

    /* Paging is a no-op on a single-page display, but must not disturb the
     * context or the screen. */
    gpx_set_page(PG_DISPLAY, 0);
    gpx_set_page(PG_WRITE, 0);
    gpx_set_page(PG_DISPLAY | PG_WRITE, 1);
    record16(gpx_width());
    record16(gpx_height());

    sys = gpx_get_system_font();
    tiny = gpx_get_tiny_font();
    record(sys != (const font_t *)0);
    record(tiny != (const font_t *)0);
    record(sys->first_ascii);
    record(sys->last_ascii);
    record(sys->empty_width);
    record(sys->max_glyph_width);
    record(sys->glyph_height);
    record(sys->advance);
    record(sys->descent);
    record(sys->flags);

    /* Every stock id, plus one past the end. */
    for (i = 0; i <= GPXSB_CURSOR_HAND + 1; ++i) {
        b = gpx_get_stock_bmp(i);
        record(b != (bmp_t *)0);
        if (b != (bmp_t *)0) {
            record(b->signature);
            record(b->w);
            record(b->h);
            record16(b->size);
        }
    }

    gpx_destroy(gpx);
    /* Accessors keep working after destroy: the context is a singleton. */
    record16(gpx_width());
    record16(gpx_height());

    TEST_END();
}
