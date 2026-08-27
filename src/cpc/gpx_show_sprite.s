        ;; gpx_show_sprite.s
        ;;
        ;; Amstrad CPC save-under sprite show and hide.
        ;;
        ;; The CPC framebuffer is readable, so this is the ZX-style
        ;; save-under rather than the Partner's XOR trick: capture the box
        ;; the sprite is about to cover, then blit the sprite over it. Both
        ;; the capture and the redraw go through the shared bitmap paths, so
        ;; the mode 1 nibble packing is handled in exactly one place.
        ;;
        ;; Policy:
        ;;   - accepts standard 1bpp and masked 1bpp bmp_t payloads
        ;;   - limited to 16x16 sprites
        ;;   - x/y must already be on-screen (no top/left clipping)
        ;;   - only right/bottom clipping is applied to the capture
        ;;   - saved background is a standard 1bpp bmp_t with stride 2
        ;;
        ;; GPL2 License (see: LICENSE)
        ;; Copyright (C) 2026 Tomaz Stih
        ;;
        ;; 2026-08-26   TS

        .module gpx_show_sprite
        .optsdcc -mz80 sdcccall(1)

        .include "_cpc-defs.inc"

        .globl  _gpx_show_sprite
        .globl  _gpx_hide_sprite
        .globl  __gpx_store_background
        .globl  _gpx_draw_bmp_clip
        .globl  __cpc_width

        .equ    BMP_SIG_ENC_MASK,        0xF0
        .equ    BMP_SIG_1BPP,            0x00
        .equ    BMP_SIG_1BPP_MASK,       0x10
        .equ    BMP_SIG_1BPP_STRIDE2,    0x01
        .equ    CO_FORE,                 0x01
        .equ    BM_CPY,                  0x00
        .equ    BMP_TRANSPARENT,         0x80

        .equ    SPR_X,                   0
        .equ    SPR_Y,                   2
        .equ    SPR_BMP,                 4
        .equ    SPR_BG,                  6
        .equ    SPR_CLIP,                8

        .area   _CODE

        ;; ------------------------------------------------------------
        ;; _gpx_show_sprite
        ;; Save the pixels under the sprite into sprite->background, then
        ;; draw the sprite over them, so gpx_hide_sprite can put the
        ;; artwork back exactly.
        ;;
        ;; Signature:
        ;;   void gpx_show_sprite(gpx_t *gpx, sprite_t *sprite)
        ;;
        ;; Arguments:
        ;;   HL = gpx (unused), DE = sprite
        ;;
        ;; Clobbers:
        ;;   AF, BC, DE, HL, IX, IY
        ;;
        ;; References:
        ;;   __gpx_store_background
        ;;   _gpx_draw_bmp_clip
_gpx_show_sprite::
        ld      a,d
        or      e
        ret     z                       ; sprite == NULL

        push    ix
        push    de
        pop     ix                      ; IX = sprite

        ;; on-screen origin only. x reaches 639 on this machine, so this is
        ;; a 16-bit range test, not the byte test a 256-pixel-wide display
        ;; can get away with; a negative x has 0xFF in the high byte and
        ;; fails it too.
        ld      l,SPR_X(ix)
        ld      h,SPR_X+1(ix)
        ld      de,(__cpc_width)
        or      a
        sbc     hl,de                   ; carry when x < width
        jp      nc,.gs_done
.gs_x_ok:
        ld      a,SPR_Y+1(ix)
        or      a
        jp      nz,.gs_done
        ld      a,SPR_Y(ix)
        cp      #CPC_HEIGHT
        jp      nc,.gs_done

        ld      l,SPR_BMP(ix)
        ld      h,SPR_BMP+1(ix)
        ld      a,h
        or      l
        jp      z,.gs_done
        ld      c,SPR_BG(ix)
        ld      b,SPR_BG+1(ix)
        ld      a,b
        or      c
        jp      z,.gs_done

        ;; signature must be a 1bpp form this backend understands
        ld      a,(hl)
        and     #BMP_SIG_ENC_MASK
        cp      #BMP_SIG_1BPP
        jr      z,.gs_sig_ok
        cp      #BMP_SIG_1BPP_MASK
        jp      nz,.gs_done
.gs_sig_ok:
        inc     hl
        ld      d,(hl)                  ; D = width
        inc     hl
        ld      e,(hl)                  ; E = height
        ld      a,d
        or      a
        jp      z,.gs_done
        cp      #17
        jp      nc,.gs_done
        ld      a,e
        or      a
        jp      z,.gs_done
        cp      #17
        jp      nc,.gs_done

        ;; visible height = min(h, CPC_HEIGHT - y); the width is left to the
        ;; capture, which clamps against the row on its own
        ld      a,e
        dec     a
        add     a,SPR_Y(ix)
        cp      #CPC_HEIGHT
        jr      c,.gs_vish_ok
        ld      a,#CPC_HEIGHT
        sub     SPR_Y(ix)
        ld      e,a
.gs_vish_ok:

        ;; background header: a standard stride-2 1bpp bitmap
        ld      l,SPR_BG(ix)
        ld      h,SPR_BG+1(ix)
        ld      (hl),#BMP_SIG_1BPP_STRIDE2
        inc     hl
        ld      (hl),d                  ; w
        inc     hl
        ld      (hl),e                  ; h
        inc     hl
        ld      a,e
        add     a,a
        ld      (hl),a                  ; size = h * 2
        inc     hl
        ld      (hl),#0x00

        ;; capture the box
        ld      l,SPR_BG(ix)
        ld      h,SPR_BG+1(ix)
        ld      c,d                     ; C = width
        ld      a,e                     ; A = height
        ld      e,SPR_X(ix)
        ld      d,SPR_X+1(ix)           ; DE = x
        ld      b,SPR_Y(ix)             ; B = y
        call    __gpx_store_background

        ;; draw the sprite through the shared blitter, public semantics
        ld      l,SPR_CLIP(ix)
        ld      h,SPR_CLIP+1(ix)
        push    hl                      ; clip
        ld      l,SPR_BMP(ix)
        ld      h,SPR_BMP+1(ix)
        push    hl                      ; bitmap
        ld      l,SPR_Y(ix)
        ld      h,#0x00
        push    hl                      ; y
        ld      e,SPR_X(ix)
        ld      d,SPR_X+1(ix)           ; DE = x
        ld      b,#BMP_TRANSPARENT      ; public gpx_draw_bmp semantics
        ld      c,#CO_FORE
        call    _gpx_draw_bmp_clip

.gs_done:
        pop     ix
        ret

        ;; ------------------------------------------------------------
        ;; _gpx_hide_sprite
        ;; Put the saved background back with an opaque copy, which is the
        ;; one draw mode that writes source zeroes as well as source ones.
        ;; The capture was a full box, so this heals pixels a clip
        ;; suppressed when the sprite was shown.
        ;;
        ;; Signature:
        ;;   void gpx_hide_sprite(gpx_t *gpx, sprite_t *sprite)
        ;;
        ;; Arguments:
        ;;   HL = gpx (unused), DE = sprite
        ;;
        ;; Clobbers:
        ;;   AF, BC, DE, HL, IX, IY
        ;;
        ;; References:
        ;;   _gpx_draw_bmp_clip
_gpx_hide_sprite::
        ld      a,d
        or      e
        ret     z                       ; sprite == NULL

        push    ix
        push    de
        pop     ix                      ; IX = sprite

        ld      a,SPR_BG(ix)
        or      SPR_BG+1(ix)
        jr      z,.gh_done

        ld      hl,#0x0000
        push    hl                      ; no clip: the box is healed whole
        ld      l,SPR_BG(ix)
        ld      h,SPR_BG+1(ix)
        push    hl                      ; saved background
        ld      l,SPR_Y(ix)
        ld      h,#0x00
        push    hl                      ; y
        ld      e,SPR_X(ix)
        ld      d,SPR_X+1(ix)           ; DE = x
        ld      b,#BM_CPY               ; opaque copy: zeroes are written too
        ld      c,#CO_FORE
        call    _gpx_draw_bmp_clip

.gh_done:
        pop     ix
        ret
