        ;; gpx_draw_text.s
        ;;
        ;; Compact text drawing for ZX Spectrum GPX.
        ;; Walks serialized font_t and renders each glyph via gpx_draw_bmp.
        ;; Supports 1bpp and 1bpp-mask glyph payloads through the bitmap
        ;; renderer (no per-pixel drawing path here).

        .module gpx_draw_text
        .optsdcc -mz80 sdcccall(1)

        .globl  _gpx_draw_text
        .globl  _gpx_draw_bmp
        .globl  _gpx_draw_bmp_mode_internal

        .equ    FONT_FLAG_OFFSETS_BE, 0x02
        .equ    BMP_ENC_MASK,         0xF0
        .equ    BMP_SIG_1BPP,         0x00
        .equ    BMP_SIG_1BPP_MASK,    0x10
        .equ    CO_FORE,              0x01
        .equ    BM_CPY,               0x00

        .area   _CODE

        ;; void gpx_draw_text(
        ;;     gpx_t *gpx, coord x, coord y,
        ;;     const char *text, const font_t *font,
        ;;     color c, bmode m, const rect_t *clip)
        ;;
        ;; HL = gpx
        ;; DE = x
        ;; stack: y, text, font, c, m, clip
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

        ;; locals (13 bytes):
        ;; -1..-2   xcur
        ;; -3..-4   text pointer
        ;; -5..-6   font base
        ;; -7..-8   gpx pointer
        ;; -9       flags
        ;; -10      first_ascii
        ;; -11      last_ascii
        ;; -12      empty_width
        ;; -13      advance
        ld      hl,#-13
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
        ld      -7(ix),l
        ld      -8(ix),h

        ;; cached font header bytes
        ld      l,-5(ix)
        ld      h,-6(ix)              ;; HL = font
        ld      a,(hl)
        ld      -9(ix),a              ;; flags
        inc     hl
        ld      a,(hl)
        ld      -10(ix),a             ;; first_ascii
        inc     hl
        ld      a,(hl)
        ld      -11(ix),a             ;; last_ascii
        inc     hl
        ld      a,(hl)
        ld      -12(ix),a             ;; empty_width
        inc     hl
        inc     hl                    ;; skip max_glyph_width
        inc     hl                    ;; skip glyph_height
        ld      a,(hl)
        ld      -13(ix),a             ;; advance

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
        ld      e,a                   ;; E = ch
        cp      -10(ix)
        jp      c,.dt_add_empty

        ld      a,-11(ix)             ;; A = last
        cp      e                     ;; last < ch ?
        jp      c,.dt_add_empty

        ;; idx = ch - first
        ld      a,e
        sub     -10(ix)
        ld      l,a
        ld      h,#0x00
        add     hl,hl                 ;; idx * 2

        ;; HL = font + 8 + idx*2
        ld      de,#0x0008
        add     hl,de
        ld      e,-5(ix)
        ld      d,-6(ix)
        add     hl,de

        ;; read glyph offset (LE/BE from flag)
        ld      a,-9(ix)
        and     #FONT_FLAG_OFFSETS_BE
        jr      nz,.dt_off_be

        ld      e,(hl)                ;; LE
        inc     hl
        ld      d,(hl)
        jr      .dt_have_off

.dt_off_be:
        ld      d,(hl)                ;; BE
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

        ;; BC = glyph pointer (kept for draw call)
        ld      c,l
        ld      b,h

        ;; DE = glyph width
        ld      a,(hl)
        and     #BMP_ENC_MASK
        cp      #BMP_SIG_1BPP
        jr      z,.dt_w8
        cp      #BMP_SIG_1BPP_MASK
        jr      z,.dt_w8
        jp      .dt_add_empty

.dt_w8:
        inc     hl
        ld      e,(hl)
        ld      d,#0x00

.dt_w_ok:

        ld      a,d
        or      e
        jp      z,.dt_add_empty

        ;; preserve width across draw_bmp call
        push    de

        ;; Use the fast bitmap blit only for normal foreground copy text.
        ;; Other modes (for example BM_XOR) need the generic per-pixel path.
        ld      a,10(ix)               ;; color
        cp      #CO_FORE
        jr      nz,.dt_draw_mode
        ld      a,11(ix)               ;; bmode
        cp      #BM_CPY
        jr      nz,.dt_draw_mode

        ;; gpx_draw_bmp(gpx, xcur, y, glyph, clip)
        ;; stack args (callee-cleaned by gpx_draw_bmp): y, glyph, clip
        ld      l,12(ix)
        ld      h,13(ix)
        push    hl                    ;; clip

        ld      l,c
        ld      h,b
        push    hl                    ;; glyph bmp_t*

        ld      l,4(ix)
        ld      h,5(ix)
        push    hl                    ;; y

        ld      l,-7(ix)
        ld      h,-8(ix)              ;; gpx
        ld      e,-1(ix)
        ld      d,-2(ix)              ;; xcur
        call    _gpx_draw_bmp
        jr      .dt_draw_done

.dt_draw_mode:
        ;; gpx_draw_bmp_mode_internal(gpx, xcur, y, glyph, c, m, clip)
        ;; stack args (callee-cleaned): y, glyph, c, m, clip
        ld      l,12(ix)
        ld      h,13(ix)
        push    hl                    ;; clip

        ld      a,11(ix)
        push    af                    ;; m
        inc     sp

        ld      a,10(ix)
        push    af                    ;; c
        inc     sp

        ld      l,c
        ld      h,b
        push    hl                    ;; glyph bmp_t*

        ld      l,4(ix)
        ld      h,5(ix)
        push    hl                    ;; y

        ld      l,-7(ix)
        ld      h,-8(ix)              ;; gpx
        ld      e,-1(ix)
        ld      d,-2(ix)              ;; xcur
        call    _gpx_draw_bmp_mode_internal

.dt_draw_done:

        ;; restore width
        pop     de

        ;; xcur += glyph_width
        ld      a,-1(ix)
        add     a,e
        ld      -1(ix),a
        ld      a,-2(ix)
        adc     a,d
        ld      -2(ix),a

        ;; xcur += advance
        ld      a,-1(ix)
        add     a,-13(ix)
        ld      -1(ix),a
        jp      nc,.dt_loop
        inc     -2(ix)
        jp      .dt_loop

.dt_add_empty:
        ld      a,-1(ix)
        add     a,-12(ix)
        ld      -1(ix),a
        jp      nc,.dt_loop
        inc     -2(ix)
        jp      .dt_loop

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
