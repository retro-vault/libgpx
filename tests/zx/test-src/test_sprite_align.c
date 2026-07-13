#include "libgpx.h"

/* Alignment sweep for the save-under sprite path (_gpx_store_background capture
 * + _gpx_sprite_blit_raw + restore), compared byte-for-byte vs the per-pixel
 * oracle stub. A show->hide round-trip must restore the screen exactly, so any
 * error in the SHIFT-based background gather at a given x&7 corrupts the screen
 * and diverges from the oracle. Left-shown sprites exercise the blit compositor
 * at every alignment too. Textures are laid on a cleared screen (set==replace)
 * to avoid the patterned-CPY oracle divergence.
 *
 * NOTE: no helper functions — main() must be the lowest code address.
 */

static const uint8_t spr_std[] = {
    BMP_SIG_STRIDE(BMP_ENC_1BPP, 2), 12, 6, 12, 0,
    0xFF, 0xF0,
    0x80, 0x10,
    0xBF, 0xD0,
    0xA0, 0x50,
    0xBF, 0xD0,
    0x80, 0x10
};

/* masked 12x6 stride 2: per row AND0 AND1 OR0 OR1. size = 6*2*2 = 24 */
static const uint8_t spr_msk[] = {
    BMP_SIG_STRIDE(BMP_ENC_1BPP_MASK, 2), 12, 6, 24, 0,
    0x00, 0x00, 0xFF, 0xF0,
    0x0F, 0x00, 0xF0, 0x00,
    0xC3, 0x00, 0x3C, 0xF0,
    0xAA, 0x00, 0x55, 0x50,
    0x0F, 0x00, 0xF0, 0x00,
    0xFF, 0x00, 0x00, 0xF0
};

void main(void)
{
    gpx_t *gpx = gpx_create(GPXM_DEFAULT);
    uint8_t fp_solid = 0xFF;
    uint8_t fp_diag[2] = {0xCC, 0x33};
    rect_t band_top = {16, 24, 239, 48};
    rect_t band_mid = {16, 80, 239, 104};
    uint8_t bg_rt[GPX_SPRITE_BG_SIZE];
    uint8_t bg_left[6][GPX_SPRITE_BG_SIZE];
    sprite_t s;
    coord dx;

    gpx_clrscr();

    /* textured backgrounds on a cleared screen (set==replace, oracle-safe) */
    gpx_fill_rectangle(gpx, &band_top, CO_FORE, BM_CPY, &fp_solid, 1, (const rect_t *)0);
    gpx_fill_rectangle(gpx, &band_mid, CO_FORE, BM_CPY, fp_diag, 2, (const rect_t *)0);

    /* --- standard sprite: show->hide round-trip at every x&7 (incl right edge) --- */
    s.bitmap = (bmp_t *)spr_std;
    s.background = (bmp_t *)bg_rt;
    s.clip = (const rect_t *)0;
    for (dx = 0; dx < 8; ++dx) {
        s.x = (coord)(40 + dx);
        s.y = 28;
        gpx_show_sprite(gpx, &s);
        gpx_hide_sprite(gpx, &s);
    }
    /* right-edge clipped round-trip (visw < w) */
    s.x = 250; s.y = 30;
    gpx_show_sprite(gpx, &s);
    gpx_hide_sprite(gpx, &s);

    /* --- masked sprite: round-trip at every x&7 over the diagonal band --- */
    s.bitmap = (bmp_t *)spr_msk;
    s.background = (bmp_t *)bg_rt;
    for (dx = 0; dx < 8; ++dx) {
        s.x = (coord)(40 + dx);
        s.y = 84;
        gpx_show_sprite(gpx, &s);
        gpx_hide_sprite(gpx, &s);
    }

    /* --- left shown (stay visible): blit composition at several alignments --- */
    {
        sprite_t std0 = {140, 28, (bmp_t *)spr_std, (bmp_t *)bg_left[0]};
        sprite_t std1 = {150, 28, (bmp_t *)spr_std, (bmp_t *)bg_left[1]};
        sprite_t std2 = {163, 28, (bmp_t *)spr_std, (bmp_t *)bg_left[2]};
        sprite_t msk0 = {140, 84, (bmp_t *)spr_msk, (bmp_t *)bg_left[3]};
        sprite_t msk1 = {151, 84, (bmp_t *)spr_msk, (bmp_t *)bg_left[4]};
        sprite_t edge = {250, 84, (bmp_t *)spr_std, (bmp_t *)bg_left[5]};
        gpx_show_sprite(gpx, &std0);
        gpx_show_sprite(gpx, &std1);
        gpx_show_sprite(gpx, &std2);
        gpx_show_sprite(gpx, &msk0);
        gpx_show_sprite(gpx, &msk1);
        gpx_show_sprite(gpx, &edge);
    }

    __asm
        halt
    __endasm;
}
