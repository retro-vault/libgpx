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

        push    hl
        exx
        pop     hl                      ; HL' = gpx
        exx

        ex      de,hl                   ; HL = sprite
        ld      e,(hl)
        inc     hl
        ld      d,(hl)                  ; DE = x
        inc     hl
        ld      c,(hl)
        inc     hl
        ld      b,(hl)                  ; BC = y
        inc     hl
        ld      a,(hl)                  ; bitmap lo
        inc     hl
        push    hl                      ; park walk ptr (sprite+5)
        ld      h,(hl)
        ld      l,a                     ; HL = bitmap
        or      h
        jr      nz,.ss_bmp_ok
        pop     hl                      ; balance the park
        ret                             ; bitmap == NULL
.ss_bmp_ok:
        push    de
        exx
        pop     de                      ; DE' = x (alt now holds gpx + x)
        exx
        ex      (sp),hl                 ; HL = walk ptr, TOS = bitmap
        inc     hl
        inc     hl
        inc     hl                      ; -> sprite->clip
        ld      e,(hl)
        inc     hl
        ld      d,(hl)                  ; DE = clip (NULL allowed)
        pop     hl                      ; HL = bitmap

        push    de                      ; clip
        push    hl                      ; bitmap
        push    bc                      ; y

        exx
        push    hl                      ; gpx
        push    de                      ; x
        exx
        pop     de                      ; DE = x
        pop     hl                      ; HL = gpx
        call    _gpx_draw_bmp_xor       ; XOR strokes; callee cleans args
        ret
