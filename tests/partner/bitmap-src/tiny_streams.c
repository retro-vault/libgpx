/* Exhaust every Tiny move byte without changing the bitmap/font format. */
#include "gdptest.h"

/* Assembly bridges preserve the draw_bmp ABI and select the internal mode. */
extern void draw_plain_xor(gpx_t *, coord, coord, bmp_t *, const rect_t *);
extern void draw_invert(gpx_t *, coord, coord, bmp_t *, const rect_t *);
extern void draw_invert_xor(gpx_t *, coord, coord, bmp_t *, const rect_t *);

void main(void)
{
    gpx_t *gpx;
    uint16_t code;
    uint8_t phase;
    uint8_t bmp[14];
    static const uint8_t background[] = {0xA5};
    rect_t screen = {0, 0, 1023, 255};
    for (phase = 0; phase < 32; ++phase) {
        gpx = gpx_create((phase & 16) ? 1 : GPXM_DEFAULT);
        screen.y1 = (phase & 16) ? 511 : 255;
        gpx_clrscr();
        gpx_fill_rectangle(gpx, &screen, CO_FORE, BM_XOR, background, 1, 0);
        for (code = 0; code < 256; ++code) {
            coord x = (coord)(3 + (code & 31) * 32);
            coord y = (coord)(3 + (code >> 5) * ((phase & 16) ? 60 : 30));
            uint8_t *data = bmp + ((phase & 2) ? 4 : 5);
            rect_t clip = {x, y, (coord)(x + 6), (coord)(y + 6)};
            const rect_t *cp = (phase & 8) ? &clip : 0;
            bmp[0] = (code & 1) ? 0x3F : 0x20; /* Tiny + Tiny-mask */
            bmp[1] = bmp[2] = (phase & 2) ? 6 : 7;
            bmp[3] = 9;
            bmp[4] = 0;
            data[0] = 0x78;             /* pen-up, +3,+3 */
            data[1] = (uint8_t)code;
            data[2] = 0x80;             /* zero-length foreground */
            data[3] = (uint8_t)(code ^ 6);
            data[4] = 0x80;
            data[5] = (uint8_t)code;
            data[6] = 0;                /* zero-length pen-up */
            data[7] = (uint8_t)(code ^ 6);
            data[8] = 0;                /* leave native cursor pen-up */
            if (phase & 8) {
                if ((code & 3) == 1) {
                    clip.x0 += 2; clip.y0 += 2;
                    clip.x1 -= 1; clip.y1 -= 1;
                } else if ((code & 3) == 2) {
                    clip.x0 += 8; clip.x1 += 8;
                } else if ((code & 3) == 3) {
                    bmp[1] = (phase & 2) ? 255 : 0;
                }
            }
            if (phase & 4) {
                if (phase & 1)
                    draw_invert_xor(gpx, x, y, (bmp_t *)bmp, cp);
                else
                    draw_invert(gpx, x, y, (bmp_t *)bmp, cp);
            } else if (phase & 1) {
                draw_plain_xor(gpx, x, y, (bmp_t *)bmp, cp);
            } else {
                gpx_draw_bmp(gpx, x, y, (bmp_t *)bmp, cp);
            }
            /* A final pen-up move must not suppress the next primitive. */
            gpx_draw_pixel(gpx, (coord)(x + 10), (coord)(y + 10),
                           CO_FORE, BM_CPY, 0);
        }
        if (phase == 31) gdp_done();
        else gdp_phase();
    }
}
