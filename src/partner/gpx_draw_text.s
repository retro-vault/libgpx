        ;; gpx_draw_text.s
        ;;
        ;; Partner text renderer over serialized font_t data.
        ;; Glyph payloads are delegated to gpx_draw_bmp.
        ;;
        ;; GPL2 License (see: LICENSE)
        ;; Copyright (C) 2026 Tomaz Stih
        ;;
        ;; 2026-03-30   TS

        .module gpx_draw_text
        .optsdcc -mz80 sdcccall(1)

        .globl  _gpx_draw_text
        .globl  __gpx_draw_bmp_mode
        .globl  __gpx_bmp_invert
        .globl  _gpx_fill_rectangle

        .equ    FONT_FLAG_OFFSETS_BE,  0x02
        .equ    BMP_ENC_MASK,          0xF0
        .equ    BMP_SIG_1BPP,          0x00
        .equ    BMP_SIG_1BPP_MASK,     0x10
        .equ    BMP_SIG_TINY,          0x20
        .equ    BMP_SIG_TINY_MASK,     0x30
        .equ    BM_CPY,                0x00

        .area   _CODE

        ;; ------------------------------------------------------------
        ;; void gpx_draw_text(
        ;;   gpx_t *gpx, coord x, coord y,
        ;;   const char *text, const font_t *font,
        ;;   color c, bmode m, const rect_t *clip)
        ;;
        ;; Arguments:
        ;;   HL = gpx
        ;;   DE = x
        ;;   stack: y, text, font, c, m, clip
        ;;
        ;; Clobbers:
        ;;   AF, BC, DE, HL, IX
_gpx_draw_text::
        push    ix
        ld      ix,#0
        add     ix,sp

        ;; text == NULL ?
        ld      a,6(ix)
        or      7(ix)
        jp      z,.dt_epilogue

        ;; font == NULL ?
        ld      a,8(ix)
        or      9(ix)
        jp      z,.dt_epilogue

        ;; locals (23 bytes):
        ;; -1..-2   xcur
        ;; -3..-4   text pointer
        ;; -5..-6   font base
        ;; -7..-8   gpx pointer
        ;; -9       flags
        ;; -10      first_ascii
        ;; -11      last_ascii
        ;; -12      empty_width
        ;; -13      advance
        ;; -14      glyph_height
        ;; -15      text background policy
        ;; -23..-16 background fill rect
        ld      b,h                     ; preserve gpx across allocation
        ld      c,l
        ld      hl,#-23
        add     hl,sp
        ld      sp,hl

        ;; xcur
        ld      -1(ix),e
        ld      -2(ix),d

        ;; text pointer
        ld      a,6(ix)
        ld      -3(ix),a
        ld      a,7(ix)
        ld      -4(ix),a

        ;; font base
        ld      a,8(ix)
        ld      -5(ix),a
        ld      a,9(ix)
        ld      -6(ix),a

        ;; gpx pointer
        ld      -7(ix),c
        ld      -8(ix),b

        ;; Cache the context's text background setting. A NULL context is
        ;; rejected by the fill and glyph helpers, but defaults to opaque here.
        xor     a
        ld      -15(ix),a
        ld      a,b
        or      c
        jr      z,.dt_background_cached
        ld      l,c
        ld      h,b
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        inc     hl                      ; -> gpx->text_background
        ld      a,(hl)
        and     #0x01
        ld      -15(ix),a
.dt_background_cached:

        ;; cache relevant font header bytes
        ld      l,-5(ix)
        ld      h,-6(ix)
        ld      a,(hl)
        ld      -9(ix),a
        inc     hl
        ld      a,(hl)
        ld      -10(ix),a
        inc     hl
        ld      a,(hl)
        ld      -11(ix),a
        inc     hl
        ld      a,(hl)
        ld      -12(ix),a
        inc     hl
        inc     hl                      ; skip max_glyph_width
        ld      a,(hl)
        ld      -14(ix),a               ; glyph_height
        inc     hl
        ld      a,(hl)
        ld      -13(ix),a

.dt_loop:
        ;; ch = *text++
        ld      l,-3(ix)
        ld      h,-4(ix)
        ld      a,(hl)
        or      a
        jp      z,.dt_done
        inc     hl
        ld      -3(ix),l
        ld      -4(ix),h

        ;; if (ch < first || ch > last) add empty width
        ld      e,a
        cp      -10(ix)
        jp      c,.dt_add_empty

        ld      a,-11(ix)
        cp      e
        jp      c,.dt_add_empty

        ;; idx = (ch - first_ascii) * 2
        ld      a,e
        sub     -10(ix)
        ld      l,a
        ld      h,#0x00
        add     hl,hl

        ;; HL = &offset[idx] at font + 8
        ld      de,#0x0008
        add     hl,de
        ld      e,-5(ix)
        ld      d,-6(ix)
        add     hl,de

        ;; read glyph offset (LE/BE)
        ld      a,-9(ix)
        and     #FONT_FLAG_OFFSETS_BE
        jr      nz,.dt_off_be

        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        jr      .dt_have_off

.dt_off_be:
        ld      d,(hl)
        inc     hl
        ld      e,(hl)

.dt_have_off:
        ld      a,d
        or      e
        jp      z,.dt_add_empty

        ;; HL = glyph pointer = font + offset
        ld      l,-5(ix)
        ld      h,-6(ix)
        add     hl,de

        ;; BC = glyph pointer (for draw call)
        ld      c,l
        ld      b,h

        ;; Encodings 0/1 share the raster width; 2/3 share Tiny width-1.
        ld      a,(hl)
        and     #0xE0
        jr      z,.dt_w8
        cp      #BMP_SIG_TINY
        jr      z,.dt_tiny_w8
        jp      .dt_add_empty

.dt_tiny_w8:
        ;; Legacy Tiny font glyph headers store width-1.
        inc     hl
        ld      e,(hl)
        inc     e
        ld      d,#0x00
        jr      .dt_have_width

.dt_w8:
        inc     hl
        ld      e,(hl)
        ld      d,#0x00

.dt_have_width:
        ld      a,d
        or      e
        jp      z,.dt_add_empty

        ;; In opaque copy mode, clear the glyph box before drawing the vector
        ;; strokes. Spectrum's raster compositor performs the same replacement
        ;; as part of its copy operation.
        push    bc                      ; glyph pointer
        push    de                      ; glyph width
        ld      a,e
        call    .dt_fill_glyph_span
        pop     de
        pop     bc

        ;; Preserve width across draw call.
        push    de

        ;; gpx_draw_bmp(gpx, xcur, y, glyph, clip)
        ld      l,12(ix)
        ld      h,13(ix)
        push    hl                      ; clip

        ld      l,c
        ld      h,b
        push    hl                      ; glyph

        ld      l,4(ix)
        ld      h,5(ix)
        push    hl                      ; y

        ;; Hand the caller's colour and blit mode down to the glyph. The
        ;; public gpx_draw_bmp entry has no room for either, so text uses
        ;; the internal one; without this a CO_BACK or BM_XOR request was
        ;; silently dropped and the ZX backend drew something else.
        ld      a,10(ix)                ; colour
        and     #0x01
        xor     #0x01                   ; CO_BACK swaps ink and paper
        ld      (__gpx_bmp_invert),a

        ld      l,-7(ix)
        ld      h,-8(ix)
        ld      e,-1(ix)
        ld      d,-2(ix)
        ld      a,11(ix)                ; blit mode
        call    __gpx_draw_bmp_mode

        ;; Restore glyph width.
        pop     de

        ;; xcur += glyph_width
        ld      a,-1(ix)
        add     a,e
        ld      -1(ix),a
        ld      a,-2(ix)
        adc     a,d
        ld      -2(ix),a

        ;; Opaque text also paints the inter-character advance.
        ld      a,-13(ix)
        call    .dt_fill_inv_span

        ;; xcur += advance
        ld      a,-1(ix)
        add     a,-13(ix)
        ld      -1(ix),a
        jp      nc,.dt_loop
        inc     -2(ix)
        jp      .dt_loop

.dt_add_empty:
        ;; A missing glyph still owns its empty-width cell in opaque mode.
        ld      a,-12(ix)
        call    .dt_fill_inv_span

        ld      a,-1(ix)
        add     a,-12(ix)
        ld      -1(ix),a
        jp      nc,.dt_loop
        inc     -2(ix)
        jp      .dt_loop

.dt_fill_glyph_span:
        ;; Opaque BM_CPY replaces the whole glyph box. BM_XOR retains the
        ;; historical ink-only glyph operation; spacing still follows the
        ;; selected background policy below.
        ld      c,a
        ld      a,11(ix)
        and     #0x01
        ret     nz
        ld      a,c

.dt_fill_inv_span:
        ;; A = width. Fill the current character span with the inverse text
        ;; color, clipped through the same public rectangle path as callers.
        ld      c,a
        ld      a,-15(ix)
        or      a
        ret     nz                      ; transparent: preserve background
        ld      a,c
        or      a
        ret     z
        ld      a,-14(ix)
        or      a
        ret     z

        ;; rect.x0 = xcur, rect.y0 = y
        ld      a,-1(ix)
        ld      -23(ix),a
        ld      a,-2(ix)
        ld      -22(ix),a
        ld      a,4(ix)
        ld      -21(ix),a
        ld      a,5(ix)
        ld      -20(ix),a

        ;; rect.x1 = xcur + width - 1
        ld      a,c
        dec     a
        add     a,-1(ix)
        ld      -19(ix),a
        ld      a,-2(ix)
        adc     a,#0x00
        ld      -18(ix),a

        ;; rect.y1 = y + glyph_height - 1
        ld      a,-14(ix)
        dec     a
        add     a,4(ix)
        ld      -17(ix),a
        ld      a,5(ix)
        adc     a,#0x00
        ld      -16(ix),a

        ;; gpx_fill_rectangle(gpx, &rect, inverse, BM_CPY,
        ;;                    &solid, 1, clip)
        ld      l,12(ix)
        ld      h,13(ix)
        push    hl                      ; clip

        ld      a,#1
        push    af                      ; fpatt_len
        inc     sp

        ld      hl,#.dt_solid
        push    hl                      ; fpatt

        ld      a,10(ix)
        xor     #0x01
        and     #0x01
        ld      l,a                     ; inverse color
        ld      h,#BM_CPY
        push    hl                      ; c, m

        push    ix
        pop     de
        ld      hl,#-23
        add     hl,de
        ex      de,hl                   ; DE = &rect
        ld      l,-7(ix)
        ld      h,-8(ix)                ; HL = gpx
        call    _gpx_fill_rectangle
        ret

.dt_done:
        ld      sp,ix

.dt_epilogue:
        pop     ix

        ;; callee cleanup:
        ;; y(2), text(2), font(2), c(1), m(1), clip(2) = 10
        pop     de
        ld      hl,#10
        add     hl,sp
        ld      sp,hl
        push    de
        ret

        .area   _DATA

.dt_solid:
        .db     0xff
