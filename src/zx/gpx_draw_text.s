        ;; gpx_draw_text.s
        ;;
        ;; Compact text drawing for ZX Spectrum GPX.
        ;; Walks serialized font_t and renders each glyph via gpx_draw_bmp.
        ;; Supports 1bpp and 1bpp-mask glyph payloads through the bitmap
        ;; renderer (no per-pixel drawing path here).

        .module gpx_draw_text
        .optsdcc -mz80 sdcccall(1)

        .globl  _gpx_draw_text
        .globl  _gpx_draw_bmp_clip
        .globl  _gpx_fill_rectangle
        .globl  __gpx_glyph_lookup

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

        ;; keep gpx in alternate HL for draw calls
        push    hl
        exx
        pop     hl
        exx

        ;; text == NULL ?
        ld      a,6(ix)
        or      7(ix)
        jp      z,.dt_epilogue

        ;; font == NULL ?
        ld      a,8(ix)
        or      9(ix)
        jp      z,.dt_epilogue

        ;; locals (18 bytes):
        ;; -1..-2   xcur
        ;; -3..-4   text pointer
        ;; -8       empty_width
        ;; -9       advance
        ;; -10      glyph_height
        ;; -11..-18 spacing rect (x0,y0,x1,y1)
        ;; (-5..-7 no longer used: __gpx_glyph_lookup reads flags/first/last
        ;;  straight from the font.)
        ld      hl,#-18
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

        ;; cache only the header fields the drawer itself needs (gap fill):
        ;; empty_width (font[3]), glyph_height (font[5]), advance (font[6]).
        ld      l,8(ix)
        ld      h,9(ix)               ;; HL = font
        inc     hl
        inc     hl
        inc     hl                    ;; -> font[3]
        ld      a,(hl)
        ld      -8(ix),a              ;; empty_width
        inc     hl
        inc     hl                    ;; -> font[5]
        ld      a,(hl)
        ld      -10(ix),a             ;; glyph_height
        inc     hl
        ld      a,(hl)
        ld      -9(ix),a              ;; advance

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

        ;; width = __gpx_glyph_lookup(ch, font).  A = ch already; font in DE.
        ;; The helper does the range / offset-table / encoding work itself
        ;; (shared with gpx_measure_text), preserves IX (our frame), and
        ;; returns A = width (0 => missing/empty) and HL = glyph bmp_t*.
        ld      e,8(ix)
        ld      d,9(ix)               ;; DE = font
        call    __gpx_glyph_lookup
        or      a
        jp      z,.dt_add_empty
        ld      c,l
        ld      b,h                   ;; BC = glyph bmp_t*

        ;; preserve width across draw_bmp call (width in A)
        push    af

        ;; Call the shared bitmap core directly.
        ld      l,12(ix)
        ld      h,13(ix)
        push    hl                    ;; clip

        push    bc                    ;; glyph bmp_t*

        ld      l,4(ix)
        ld      h,5(ix)
        push    hl                    ;; y

        exx
        push    hl
        exx
        pop     hl                    ;; gpx
        ld      e,-1(ix)
        ld      d,-2(ix)              ;; xcur
        ld      b,11(ix)              ;; bmode
        ld      c,10(ix)              ;; color
        call    _gpx_draw_bmp_clip

        ;; xcur += glyph_width
        pop     af                    ;; A = width
        add     a,-1(ix)
        ld      -1(ix),a
        jr      nc,.dt_advance_xcur
        inc     -2(ix)

.dt_advance_xcur:
        ;; Fill inter-character advance gap with inverse color.
        ld      a,-9(ix)              ;; advance
.dt_fill_and_advance:
        ;; A = span width; fill the gap, then xcur += width.
        ;; .dt_fill_inv_span calls fill_rectangle (trashes regs), so the width
        ;; is carried across the call on the stack rather than in a register.
        push    af
        call    .dt_fill_inv_span
        pop     af
        ld      b,a
        ld      a,-1(ix)
        add     a,b
        ld      -1(ix),a
        jp      nc,.dt_loop
        inc     -2(ix)
        jp      .dt_loop

.dt_add_empty:
        ;; Fill missing/empty glyph span with inverse color.
        ld      a,-8(ix)              ;; empty_width
        jr      .dt_fill_and_advance

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

.dt_fill_inv_span:
        ;; A = span width in pixels
        or      a
        ret     z
        ld      b,a
        ld      a,-10(ix)             ;; glyph_height
        or      a
        ret     z

        ;; rect.x0 = xcur  (packed at -18..-17)
        ld      a,-1(ix)
        ld      -18(ix),a
        ld      a,-2(ix)
        ld      -17(ix),a

        ;; rect.y0 = y argument  (packed at -16..-15)
        ld      a,4(ix)
        ld      -16(ix),a
        ld      a,5(ix)
        ld      -15(ix),a

        ;; rect.x1 = xcur + (width - 1)  (packed at -14..-13)
        ld      a,b
        dec     a
        ld      b,a
        ld      a,-1(ix)
        add     a,b
        ld      -14(ix),a
        ld      a,-2(ix)
        adc     a,#0x00
        ld      -13(ix),a

        ;; rect.y1 = y + (glyph_height - 1)  (packed at -12..-11)
        ld      a,-10(ix)
        dec     a
        ld      b,a
        ld      a,4(ix)
        add     a,b
        ld      -12(ix),a
        ld      a,5(ix)
        adc     a,#0x00
        ld      -11(ix),a

        ;; gpx_fill_rectangle(gpx, &rect, inv_color, BM_CPY, {0xFF}, 1, clip)
        ld      l,12(ix)
        ld      h,13(ix)
        push    hl                    ;; clip

        ld      a,#0x01
        push    af
        inc     sp                    ;; fpatt_len

        ld      hl,#.dt_solid_fpatt
        push    hl                    ;; fpatt*

        ld      a,10(ix)              ;; inverse color of text color
        xor     #0x01
        and     #0x01
        ld      l,a
        ld      h,#BM_CPY
        push    hl                    ;; c,m

        exx
        push    hl
        exx
        pop     hl                    ;; gpx

        push    ix
        pop     de
        ld      hl,#-18
        add     hl,de
        ex      de,hl                 ;; DE = &rect
        exx
        push    hl
        exx
        pop     hl                    ;; HL = gpx
        call    _gpx_fill_rectangle
        ret

.dt_solid_fpatt:
        .db     0xff
