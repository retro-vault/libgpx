        ;; gpx_show_sprite.s
        ;;
        ;; ZX Spectrum save-under sprite show path.
        ;;
        ;; Policy:
        ;;   - accepts standard 1bpp and masked 1bpp bmp_t payloads
        ;;   - limited to 16x16 sprites
        ;;   - x/y must already be on-screen (no top/left clipping)
        ;;   - only right/bottom clipping is applied
        ;;   - saved background is stored as a valid standard 1bpp bmp_t
        ;;     with fixed stride=2 and zero-filled clipped bytes

        .module gpx_show_sprite
        .optsdcc -mz80 sdcccall(1)

        .globl  _gpx_show_sprite
        .globl  __gpx_store_background
        .globl  __gpx_sprite_blit_raw
        .globl  __vid_rowaddr

        .equ    BMP_SIG_ENC_MASK,        0xF0
        .equ    BMP_SIG_1BPP,            0x00
        .equ    BMP_SIG_1BPP_MASK,       0x10
        .equ    BMP_SIG_1BPP_STRIDE2,    0x01
        .equ    SCRHEIGHT,               192
        .equ    BG_HEADER_SIZE,          5
        .equ    BG_PAYLOAD_SIZE,         32

        .equ    SPR_X_LO,                0
        .equ    SPR_X_HI,                1
        .equ    SPR_Y_LO,                2
        .equ    SPR_Y_HI,                3
        .equ    SPR_BMP_LO,              4
        .equ    SPR_BMP_HI,              5
        .equ    SPR_BG_LO,               6
        .equ    SPR_BG_HI,               7

        ;; gpx_show_sprite locals (10 bytes)
        .equ    S_BMP_LO,                -2
        .equ    S_BMP_HI,                -1
        .equ    S_BG_LO,                 -4
        .equ    S_BG_HI,                 -3
        .equ    S_X_LO,                  -5
        .equ    S_Y_LO,                  -6
        .equ    S_W,                     -7
        .equ    S_H,                     -8
        .equ    S_VISW,                  -9
        .equ    S_VISH,                  -10

        .macro  LD16HL off
        ld      l,off(ix)
        ld      h,off+1(ix)
        .endm

        .macro  ST16HL off
        ld      off(ix),l
        ld      off+1(ix),h
        .endm

        .macro  LD16DE off
        ld      e,off(ix)
        ld      d,off+1(ix)
        .endm

        .macro  ST16DE off
        ld      off(ix),e
        ld      off+1(ix),d
        .endm

        .area   _CODE

        ;; ------------------------------------------------------------
        ;; void gpx_show_sprite(gpx_t *gpx, sprite_t *sprite)
        ;;
        ;; Input:
        ;;   HL = gpx
        ;;   DE = sprite
_gpx_show_sprite::
        push    ix
        ld      ix,#0
        add     ix,sp

        ld      hl,#-10
        add     hl,sp
        ld      sp,hl

        ld      a,d
        or      e
        jp      z,.gs_done

        ex      de,hl
        ld      a,(hl)
        ld      S_X_LO(ix),a
        inc     hl
        ld      a,(hl)
        or      a
        jp      nz,.gs_done
        inc     hl
        ld      a,(hl)
        ld      S_Y_LO(ix),a
        inc     hl
        ld      a,(hl)
        or      a
        jp      nz,.gs_done

        ld      a,S_Y_LO(ix)
        cp      #SCRHEIGHT
        jp      nc,.gs_done

        inc     hl
        ld      a,(hl)
        ld      S_BMP_LO(ix),a
        inc     hl
        ld      a,(hl)
        ld      S_BMP_HI(ix),a
        inc     hl
        ld      a,(hl)
        ld      S_BG_LO(ix),a
        inc     hl
        ld      a,(hl)
        ld      S_BG_HI(ix),a

        ;; sprite pointers must exist
        ld      a,S_BMP_LO(ix)
        or      S_BMP_HI(ix)
        jp      z,.gs_done
        ld      a,S_BG_LO(ix)
        or      S_BG_HI(ix)
        jp      z,.gs_done

        ld      l,S_BMP_LO(ix)
        ld      h,S_BMP_HI(ix)

        ld      a,(hl)
        and     #BMP_SIG_ENC_MASK
        cp      #BMP_SIG_1BPP
        jr      z,.gs_sig_ok
        cp      #BMP_SIG_1BPP_MASK
        jp      nz,.gs_done

.gs_sig_ok:
        ld      a,(hl)
        and     #0x0F
        inc     a
        cp      #3
        jp      nc,.gs_done

        inc     hl
        ld      a,(hl)
        ld      S_W(ix),a
        or      a
        jp      z,.gs_done
        cp      #17
        jp      nc,.gs_done

        inc     hl
        ld      a,(hl)
        ld      S_H(ix),a
        or      a
        jp      z,.gs_done
        cp      #17
        jp      nc,.gs_done

        ;; visible width = min(w, 256 - x)
        ld      a,S_W(ix)
        dec     a
        ld      b,S_X_LO(ix)
        add     a,b
        jr      nc,.gs_no_right_clip
        ld      a,S_X_LO(ix)
        cpl
        inc     a
        jr      .gs_store_visw
.gs_no_right_clip:
        ld      a,S_W(ix)
.gs_store_visw:
        ld      S_VISW(ix),a

        ;; visible height = min(h, 192 - y)
        ld      a,S_H(ix)
        dec     a
        ld      b,a
        ld      a,S_Y_LO(ix)
        add     a,b
        cp      #SCRHEIGHT
        jr      c,.gs_no_bottom_clip
        ld      b,S_Y_LO(ix)
        ld      a,#SCRHEIGHT
        sub     b
        jr      .gs_store_vish
.gs_no_bottom_clip:
        ld      a,S_H(ix)
.gs_store_vish:
        ld      S_VISH(ix),a

        ;; background sprite header
        ld      l,S_BG_LO(ix)
        ld      h,S_BG_HI(ix)
        ld      (hl),#BMP_SIG_1BPP_STRIDE2
        inc     hl
        ld      a,S_W(ix)
        ld      (hl),a
        inc     hl
        ld      a,S_H(ix)
        ld      (hl),a
        inc     hl
        ld      a,S_H(ix)
        add     a,a
        ld      (hl),a
        inc     hl
        xor     a
        ld      (hl),a

        ld      l,S_BG_LO(ix)
        ld      h,S_BG_HI(ix)
        ld      b,S_Y_LO(ix)
        ld      c,S_X_LO(ix)
        ld      d,S_VISW(ix)
        ld      e,S_VISH(ix)
        call    __gpx_store_background

        ld      l,S_BMP_LO(ix)
        ld      h,S_BMP_HI(ix)
        ld      b,S_Y_LO(ix)
        ld      c,S_X_LO(ix)
        xor     a                    ;; standard bitmaps keep zero bits transparent
        call    __gpx_sprite_blit_raw

.gs_done:
        ld      sp,ix
        pop     ix
        ret
