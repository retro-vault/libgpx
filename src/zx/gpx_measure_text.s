        ;; gpx_measure_text.s
        ;;
        ;; Measure text width from serialized font_t data.
        ;; No decoded meta structure is used; the routine reads
        ;; font header fields directly from font_t.

        .module gpx_measure_text
        .optsdcc -mz80 sdcccall(1)

        .globl  _gpx_measure_text

        .equ    FONT_FLAG_OFFSETS_BE, 0x02
        .equ    BMP_ENC_MASK,         0xF0
        .equ    BMP_SIG_1BPP,         0x00
        .equ    BMP_SIG_1BPP_MASK,    0x10
        .equ    BMP_SIG_1BPP_COMPACT, 0x20
        .equ    BMP_SIG_1BPP_MASK_COMPACT, 0x30

        .area   _CODE

        ;; coord gpx_measure_text(const char *text, const font_t *font)
        ;;   HL = text
        ;;   DE = font
        ;; Returns:
        ;;   DE = width
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

        ld      a,d                     ;; idx = ch - first_ascii
        sub     1(ix)
        ld      l,a
        ld      h,#0x00
        add     hl,hl                   ;; idx * 2
        ld      de,#0x0008
        add     hl,de                   ;; + offset table start
        push    ix
        pop     de
        add     hl,de                   ;; HL = &offset[idx]

        ld      a,0(ix)                 ;; flags
        and     #FONT_FLAG_OFFSETS_BE
        jr      nz,.mt_read_be

        ld      e,(hl)                  ;; little-endian offset
        inc     hl
        ld      d,(hl)
        jr      .mt_have_off

.mt_read_be:
        ld      d,(hl)                  ;; big-endian offset
        inc     hl
        ld      e,(hl)

.mt_have_off:
        ld      a,d
        or      e
        jr      z,.mt_add_empty         ;; missing glyph

        push    ix
        pop     hl
        add     hl,de                   ;; HL = glyph bmp_t*
        ld      a,(hl)
        and     #BMP_ENC_MASK
        cp      #BMP_SIG_1BPP
        jr      z,.mt_w16
        cp      #BMP_SIG_1BPP_MASK
        jr      z,.mt_w16
        cp      #BMP_SIG_1BPP_COMPACT
        jr      z,.mt_w8
        cp      #BMP_SIG_1BPP_MASK_COMPACT
        jr      z,.mt_w8
        jr      .mt_add_empty

.mt_w16:
        inc     hl                      ;; +1 => width lo
        ld      e,(hl)
        inc     hl
        ld      d,(hl)                  ;; DE = glyph width
        jr      .mt_have_w

.mt_w8:
        inc     hl                      ;; +1 => width
        ld      e,(hl)
        ld      d,#0x00

.mt_have_w:

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
        add     a,6(ix)                 ;; advance
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
