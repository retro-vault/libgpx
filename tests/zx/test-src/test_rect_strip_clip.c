#include "zxtest.h"

/* An application window's outer outline, drawn once per strip of a
 * borrowed non-client clip region -- the shape Alto's window decoration
 * produces. The outline is the whole inclusive window rectangle and each
 * clip is one of the four frame strips, so every call keeps at most part
 * of two edges and rejects the rest. */

static uint8_t canary[16];

static void frame_window(gpx_t *gpx, coord ox, coord oy)
{
    rect_t outline;
    rect_t strip;

    outline.x0 = ox;
    outline.y0 = oy;
    outline.x1 = (coord)(ox + 127);
    outline.y1 = (coord)(oy + 95);

    /* top */
    strip.x0 = ox;
    strip.y0 = oy;
    strip.x1 = (coord)(ox + 127);
    strip.y1 = (coord)(oy + 11);
    gpx_draw_rectangle(gpx, &outline, CO_FORE, BM_CPY, 0xFF, &strip);

    /* bottom */
    strip.x0 = ox;
    strip.y0 = (coord)(oy + 92);
    strip.x1 = (coord)(ox + 127);
    strip.y1 = (coord)(oy + 95);
    gpx_draw_rectangle(gpx, &outline, CO_FORE, BM_CPY, 0xFF, &strip);

    /* left */
    strip.x0 = ox;
    strip.y0 = (coord)(oy + 12);
    strip.x1 = (coord)(ox + 3);
    strip.y1 = (coord)(oy + 91);
    gpx_draw_rectangle(gpx, &outline, CO_FORE, BM_CPY, 0xFF, &strip);

    /* right */
    strip.x0 = (coord)(ox + 124);
    strip.y0 = (coord)(oy + 12);
    strip.x1 = (coord)(ox + 127);
    strip.y1 = (coord)(oy + 91);
    gpx_draw_rectangle(gpx, &outline, CO_FORE, BM_CPY, 0xFF, &strip);
}

/* A banded region can split either vertical frame strip into a one-row
 * rectangle. The clipped side is then a single pixel even though the source
 * rectangle is not degenerate. */
static void frame_point_clips(gpx_t *gpx)
{
    rect_t outline = {20, 20, 80, 80};
    rect_t strip = {20, 35, 23, 35};

    gpx_draw_rectangle(gpx, &outline, CO_FORE, BM_CPY, 0xFF, &strip);
    strip.x0 = 77;
    strip.x1 = 80;
    strip.y0 = 36;
    strip.y1 = 36;
    gpx_draw_rectangle(gpx, &outline, CO_FORE, BM_CPY, 0xFF, &strip);
}

void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    uint8_t i;
    uint8_t bad = 0;

    for (i = 0; i < 16; ++i)
        canary[i] = (uint8_t)(0xA5 ^ i);

    seed_screen_wash();

    frame_window(gpx, 0, 0);
    frame_window(gpx, 1, 1);
    frame_window(gpx, 5, 3);
    frame_window(gpx, 64, 48);
    frame_window(gpx, 128, 96);
    frame_point_clips(gpx);

    for (i = 0; i < 16; ++i)
        if (canary[i] != (uint8_t)(0xA5 ^ i))
            ++bad;

    record(bad);
    record(0x5A);
    TEST_END();
}
