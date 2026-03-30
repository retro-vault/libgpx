        ;; gpx_measure_text.s
        ;;
        ;; Measure text width from serialized font_t data.

        .module gpx_measure_text
        .optsdcc -mz80 sdcccall(1)

        .globl  _gpx_measure_text

        .equ    FONT_FLAG_OFFSETS_BE,  0x02
        .equ    BMP_ENC_MASK,          0xF0
        .equ    BMP_SIG_1BPP,          0x00
        .equ    BMP_SIG_1BPP_MASK,     0x10
        .equ    BMP_SIG_TINY,          0x20
        .equ    BMP_SIG_TINY_MASK,     0x30

        .area   _CODE

        ;; ------------------------------------------------------------
        ;; coord gpx_measure_text(const char *text, const font_t *font)
        ;; Input:
        ;;   HL = text
        ;;   DE = font
        ;;
        ;; Output:
        ;;   DE = measured width
        ;;
        ;; Clobbers:
        ;;   AF, BC, DE, HL, IX, IY
_gpx_measure_text::
        ld      a,h                     ;; text != NULL ?
        or      l
        jp      z,.mt_zero

        ld      a,d                     ;; font != NULL ?
        or      e
        jp      z,.mt_zero

        push    ix
        push    iy
        push    de
        pop     ix                      ;; IX = font
        push    hl
        pop     iy                      ;; IY = text

        ld      bc,#0x0000              ;; BC = accumulated width

.mt_loop:
        ld      a,0(iy)                 ;; ch = *text
        or      a
        jr      z,.mt_done
        inc     iy

        cp      1(ix)                   ;; ch < first_ascii ?
        jr      c,.mt_add_empty

        ld      d,a                     ;; D = ch
        ld      a,2(ix)                 ;; last_ascii
        cp      d                       ;; last_ascii < ch ?
        jr      c,.mt_add_empty

        ;; idx = (ch - first_ascii) * 2
        ld      a,d
        sub     1(ix)
        ld      l,a
        ld      h,#0x00
        add     hl,hl

        ;; HL = &offset[idx] at font + 8
        ld      de,#0x0008
        add     hl,de
        push    ix
        pop     de
        add     hl,de

        ;; Read glyph offset in configured endian.
        ld      a,0(ix)
        and     #FONT_FLAG_OFFSETS_BE
        jr      nz,.mt_read_be

        ld      e,(hl)                  ;; little-endian
        inc     hl
        ld      d,(hl)
        jr      .mt_have_off

.mt_read_be:
        ld      d,(hl)                  ;; big-endian
        inc     hl
        ld      e,(hl)

.mt_have_off:
        ld      a,d
        or      e
        jr      z,.mt_add_empty         ;; missing glyph

        ;; HL = glyph bmp_t*
        push    ix
        pop     hl
        add     hl,de

        ;; Accept compact 1bpp and tiny encodings.
        ld      a,(hl)
        and     #BMP_ENC_MASK
        cp      #BMP_SIG_1BPP
        jr      z,.mt_w8
        cp      #BMP_SIG_1BPP_MASK
        jr      z,.mt_w8
        cp      #BMP_SIG_TINY
        jr      z,.mt_w8
        cp      #BMP_SIG_TINY_MASK
        jr      z,.mt_w8
        jr      .mt_add_empty

.mt_w8:
        inc     hl                      ;; +1 => width
        ld      e,(hl)
        ld      d,#0x00

        ld      a,d
        or      e
        jr      z,.mt_add_empty

        ;; sum += glyph_width
        ld      a,c
        add     a,e
        ld      c,a
        ld      a,b
        adc     a,d
        ld      b,a

        ;; sum += advance
        ld      a,c
        add     a,6(ix)
        ld      c,a
        jr      nc,.mt_loop
        inc     b
        jr      .mt_loop

.mt_add_empty:
        ld      a,c
        add     a,3(ix)                 ;; empty_width
        ld      c,a
        jr      nc,.mt_loop
        inc     b
        jr      .mt_loop

.mt_done:
        ld      d,b
        ld      e,c
        pop     iy
        pop     ix
        ret

.mt_zero:
        ld      de,#0x0000
        ret
