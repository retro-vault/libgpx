        ;; gpx_draw_text.s
        ;;
        ;; Partner text renderer over serialized font_t data.
        ;; Glyph payloads are delegated to gpx_draw_bmp.

        .module gpx_draw_text
        .optsdcc -mz80 sdcccall(1)

        .globl  _gpx_draw_text
        .globl  _gpx_draw_bmp

        .equ    FONT_FLAG_OFFSETS_BE,  0x02
        .equ    BMP_ENC_MASK,          0xF0
        .equ    BMP_SIG_1BPP,          0x00
        .equ    BMP_SIG_1BPP_MASK,     0x10
        .equ    BMP_SIG_TINY,          0x20
        .equ    BMP_SIG_TINY_MASK,     0x30

        .area   _CODE

        ;; ------------------------------------------------------------
        ;; void gpx_draw_text(
        ;;   gpx_t *gpx, coord x, coord y,
        ;;   const char *text, const font_t *font,
        ;;   color c, bmode m, const rect_t *clip)
        ;;
        ;; Input:
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
        inc     hl                      ;; skip max_glyph_width
        inc     hl                      ;; skip glyph_height
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

        ;; Accept supported signatures and read glyph width.
        ld      a,(hl)
        and     #BMP_ENC_MASK
        cp      #BMP_SIG_1BPP
        jr      z,.dt_w8
        cp      #BMP_SIG_1BPP_MASK
        jr      z,.dt_w8
        cp      #BMP_SIG_TINY
        jr      z,.dt_w8
        cp      #BMP_SIG_TINY_MASK
        jr      z,.dt_w8
        jp      .dt_add_empty

.dt_w8:
        inc     hl
        ld      e,(hl)
        ld      d,#0x00

        ld      a,d
        or      e
        jp      z,.dt_add_empty

        ;; Preserve width across draw call.
        push    de

        ;; gpx_draw_bmp(gpx, xcur, y, glyph, clip)
        ld      l,12(ix)
        ld      h,13(ix)
        push    hl                      ;; clip

        ld      l,c
        ld      h,b
        push    hl                      ;; glyph

        ld      l,4(ix)
        ld      h,5(ix)
        push    hl                      ;; y

        ld      l,-7(ix)
        ld      h,-8(ix)
        ld      e,-1(ix)
        ld      d,-2(ix)
        call    _gpx_draw_bmp

        ;; Restore glyph width.
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
