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
        ;; -5       flags
        ;; -6       first_ascii
        ;; -7       last_ascii
        ;; -8       empty_width
        ;; -9       advance
        ;; -10      glyph_height
        ;; -11..-18 spacing rect (x0,y0,x1,y1)
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

        ;; cached font header bytes
        ld      l,8(ix)
        ld      h,9(ix)               ;; HL = font
        ld      a,(hl)
        ld      -5(ix),a              ;; flags
        inc     hl
        ld      a,(hl)
        ld      -6(ix),a              ;; first_ascii
        inc     hl
        ld      a,(hl)
        ld      -7(ix),a              ;; last_ascii
        inc     hl
        ld      a,(hl)
        ld      -8(ix),a              ;; empty_width
        inc     hl
        inc     hl                    ;; skip max_glyph_width
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

        ;; if (ch < first || ch > last) add empty width
        ld      e,a                   ;; E = ch
        cp      -6(ix)
        jp      c,.dt_add_empty

        ld      a,-7(ix)              ;; A = last
        cp      e                     ;; last < ch ?
        jp      c,.dt_add_empty

        ;; idx = ch - first
        ld      a,e
        sub     -6(ix)
        ld      l,a
        ld      h,#0x00
        add     hl,hl                 ;; idx * 2

        ;; HL = font + 8 + idx*2
        ld      de,#0x0008
        add     hl,de
        ld      e,8(ix)
        ld      d,9(ix)
        add     hl,de

        ;; read glyph offset (LE/BE from flag)
        ld      a,-5(ix)
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
        ld      l,8(ix)
        ld      h,9(ix)
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

.dt_advance_xcur:
        ;; Fill inter-character advance gap with inverse color.
        ld      a,-9(ix)              ;; advance
        call    .dt_fill_inv_span

        ;; xcur += advance
        ld      a,-1(ix)
        add     a,-9(ix)
        ld      -1(ix),a
        jp      nc,.dt_loop
        inc     -2(ix)
        jp      .dt_loop

.dt_add_empty:
        ;; Fill missing/empty glyph span with inverse color.
        ld      a,-8(ix)              ;; empty_width
        call    .dt_fill_inv_span

        ld      a,-1(ix)
        add     a,-8(ix)
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
