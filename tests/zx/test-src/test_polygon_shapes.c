#include "zxtest.h"

/* Outlines and fills of the shapes that stress the scanline rule: convex,
 * concave, self-intersecting, horizontal edges, a shape one pixel tall, and
 * both winding directions. A fill must end exactly on its own outline. */
void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    uint8_t solid[1];
    point_t tri[3];
    point_t tri2[3];
    point_t quad[4];
    point_t conc[5];
    point_t star[10];
    point_t bow[4];
    point_t flat[4];
    point_t horz[5];

    solid[0] = 0xFF;
    seed_screen_wash();

    tri[0].x = 4;   tri[0].y = 4;
    tri[1].x = 44;  tri[1].y = 14;
    tri[2].x = 14;  tri[2].y = 44;
    gpx_fill_polygon(gpx, tri, 3, CO_FORE, BM_CPY, solid, 1,
        (const rect_t *)0);
    gpx_draw_polygon(gpx, tri, 3, CO_BACK, BM_CPY, 0xFF, (const rect_t *)0);

    /* The same triangle wound the other way must fill identically. */
    tri2[0].x = 74;  tri2[0].y = 44;
    tri2[1].x = 104; tri2[1].y = 14;
    tri2[2].x = 64;  tri2[2].y = 4;
    gpx_fill_polygon(gpx, tri2, 3, CO_FORE, BM_CPY, solid, 1,
        (const rect_t *)0);

    /* A rectangle as a polygon: this has to match gpx_fill_rectangle. */
    quad[0].x = 130; quad[0].y = 4;
    quad[1].x = 180; quad[1].y = 4;
    quad[2].x = 180; quad[2].y = 40;
    quad[3].x = 130; quad[3].y = 40;
    gpx_fill_polygon(gpx, quad, 4, CO_FORE, BM_CPY, solid, 1,
        (const rect_t *)0);
    {
        rect_t r;
        r.x0 = 195; r.y0 = 4; r.x1 = 245; r.y1 = 40;
        gpx_fill_rectangle(gpx, &r, CO_FORE, BM_CPY, solid, 1,
            (const rect_t *)0);
    }

    /* Concave: the notch must stay empty. */
    conc[0].x = 4;   conc[0].y = 60;
    conc[1].x = 54;  conc[1].y = 60;
    conc[2].x = 54;  conc[2].y = 110;
    conc[3].x = 29;  conc[3].y = 78;
    conc[4].x = 4;   conc[4].y = 110;
    gpx_fill_polygon(gpx, conc, 5, CO_FORE, BM_CPY, solid, 1,
        (const rect_t *)0);
    gpx_draw_polygon(gpx, conc, 5, CO_BACK, BM_CPY, 0xFF, (const rect_t *)0);

    /* Ten-point star: even-odd leaves the middle filled, spans on a row
     * come in pairs that must not overlap. */
    star[0].x = 100; star[0].y = 58;
    star[1].x = 108; star[1].y = 78;
    star[2].x = 128; star[2].y = 78;
    star[3].x = 112; star[3].y = 91;
    star[4].x = 118; star[4].y = 111;
    star[5].x = 100; star[5].y = 98;
    star[6].x = 82;  star[6].y = 111;
    star[7].x = 88;  star[7].y = 91;
    star[8].x = 72;  star[8].y = 78;
    star[9].x = 92;  star[9].y = 78;
    gpx_fill_polygon(gpx, star, 10, CO_FORE, BM_CPY, solid, 1,
        (const rect_t *)0);

    /* Self-intersecting bowtie: even-odd empties the crossing. */
    bow[0].x = 150; bow[0].y = 58;
    bow[1].x = 200; bow[1].y = 108;
    bow[2].x = 200; bow[2].y = 58;
    bow[3].x = 150; bow[3].y = 108;
    gpx_fill_polygon(gpx, bow, 4, CO_FORE, BM_CPY, solid, 1,
        (const rect_t *)0);

    /* Two pixels tall, and a shape whose top and bottom are horizontal. */
    flat[0].x = 210; flat[0].y = 60;
    flat[1].x = 250; flat[1].y = 60;
    flat[2].x = 250; flat[2].y = 61;
    flat[3].x = 210; flat[3].y = 61;
    gpx_fill_polygon(gpx, flat, 4, CO_FORE, BM_CPY, solid, 1,
        (const rect_t *)0);

    horz[0].x = 210; horz[0].y = 70;
    horz[1].x = 240; horz[1].y = 70;
    horz[2].x = 252; horz[2].y = 90;
    horz[3].x = 240; horz[3].y = 110;
    horz[4].x = 210; horz[4].y = 110;
    gpx_fill_polygon(gpx, horz, 5, CO_FORE, BM_CPY, solid, 1,
        (const rect_t *)0);
    gpx_draw_polygon(gpx, horz, 5, CO_BACK, BM_CPY, 0xFF, (const rect_t *)0);

    /* Degenerate input draws nothing at all. */
    gpx_fill_polygon(gpx, tri, 2, CO_FORE, BM_CPY, solid, 1,
        (const rect_t *)0);
    gpx_fill_polygon(gpx, tri, 3, CO_FORE, BM_CPY, solid, 0,
        (const rect_t *)0);
    gpx_draw_polygon(gpx, tri, 1, CO_FORE, BM_CPY, 0xFF, (const rect_t *)0);

    TEST_END();
}
