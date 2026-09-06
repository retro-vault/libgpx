        ;; gpx_show_sprite.s
        ;;
        ;; Partner save/restore sprite: XOR draw, XOR draw again.
        ;;
        ;; The Partner has no CPU-readable framebuffer, so the ZX-style
        ;; save-under is impossible; instead the sprite's tiny-vector
        ;; bitmap is drawn with XOR strokes. Drawing it a second time at
        ;; the same position toggles every pixel back, so show and hide
        ;; are literally the same routine and sprite->background is
        ;; unused on this platform. sprite->clip (NULL = screen) rides
        ;; into the stroke renderer, where each stroke is clipped by the
        ;; exact Cohen-Sutherland; show and hide read the same rect from
        ;; the descriptor, so the XOR identity holds for clipped sprites.
        ;;
        ;; GPL2 License (see: LICENSE)
        ;; Copyright (C) 2026 Tomaz Stih
        ;;
        ;; 2026-07-13   TS

        .module gpx_show_sprite
        .optsdcc -mz80 sdcccall(1)

        .globl  _gpx_show_sprite
        .globl  _gpx_hide_sprite
        .globl  _gpx_draw_bmp_xor

        .area   _CODE

        ;; ------------------------------------------------------------
        ;; _gpx_show_sprite, _gpx_hide_sprite
        ;; Show and hide are literally the same routine here. The Partner
        ;; cannot read display memory, so there is no save-under: the
        ;; sprite is XOR-stroked in, and stroking it again at the same
        ;; place toggles every pixel back. sprite->background is unused.
        ;;
        ;; Signature:
        ;;   void gpx_show_sprite(gpx_t *gpx, sprite_t *sprite)
        ;;   void gpx_hide_sprite(gpx_t *gpx, sprite_t *sprite)
        ;;
        ;; Arguments:
        ;;   HL = gpx
        ;;   DE = sprite; x, y, bitmap and clip must be unchanged between
        ;;        the two calls or the XOR identity does not hold
        ;;
        ;; Clobbers:
        ;;   AF, BC, DE, HL, IX, IY, and the alternate set
        ;;
        ;; References:
        ;;   _gpx_draw_bmp_xor
        ;; ------------------------------------------------------------
_gpx_show_sprite::
_gpx_hide_sprite::
        ld      a,d
        or      e
        ret     z                       ; sprite == NULL

        push    ix
        push    de
        pop     ix                      ; sprite descriptor, HL remains gpx

        ld      c,8(ix)
        ld      b,9(ix)
        push    bc                      ; clip
        ld      c,4(ix)
        ld      b,5(ix)
        push    bc                      ; bitmap (renderer checks NULL)
        ld      c,2(ix)
        ld      b,3(ix)
        push    bc                      ; y
        ld      e,0(ix)
        ld      d,1(ix)                 ; x
        call    _gpx_draw_bmp_xor       ; callee cleans the three words
        pop     ix
        ret
