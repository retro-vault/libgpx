        ;; gpx_fill_circle.s
        ;;
        ;; Filled circle, walked by the same midpoint stepper that draws
        ;; the outline.
        ;;
        ;; Portable: each scanline of the disc is a horizontal
        ;; gpx_draw_line, so the backend's own run renderer does the work
        ;; -- a byte-span writer on the ZX and the CPC, the EF9367's vector
        ;; generator on the Partner -- and one copy of the code serves
        ;; every machine. Every row is emitted exactly once, which keeps
        ;; BM_XOR meaningful, and the row spans are the ones
        ;; gpx_draw_circle's outline lands on, so a filled circle and an
        ;; outline of the same radius agree pixel for pixel.
        ;;
        ;; The fill pattern is anchored to the circle's bounding box, not
        ;; to each row: row n takes fpatt[n % fpatt_len] counting from the
        ;; top of the box, and the byte is turned so its MSB still falls on
        ;; the box's left edge. Filling a circle and filling its bounding
        ;; box therefore lay down the same bits. A fill pattern runs
        ;; MSB-first from the left edge while a line consumes its pattern
        ;; LSB-first from its own start, so each row's byte is reversed and
        ;; then rotated -- the same conversion the Partner's rectangle fill
        ;; does before it hands a row to the same renderer.
        ;;
        ;; GPL2 License (see: LICENSE)
        ;; Copyright (C) 2026 Tomaz Stih
        ;;
        ;; 2026-08-28   TS

        .module gpx_fill_circle
        .optsdcc -mz80 sdcccall(1)

        .globl  _gpx_fill_circle
        .globl  _gpx_draw_line

        .area   _CODE

        ;; ------------------------------------------------------------
        ;; _gpx_fill_circle
        ;; Fill the disc centred on (x,y) with radius r. r == 0 is a
        ;; single pixel, a negative r or an empty pattern draws nothing.
        ;;
        ;; Signature:
        ;;   void gpx_fill_circle(gpx_t *gpx, coord x, coord y, coord r,
        ;;                        color c, bmode m,
        ;;                        uint8_t *fpatt, uint8_t fpatt_len,
        ;;                        const rect_t *clip)
        ;;
        ;; Arguments:
        ;;   HL = gpx, DE = x
        ;;   stack: y(2), r(2), c(1), m(1), fpatt(2), fpatt_len(1), clip(2)
        ;;
        ;; Clobbers:
        ;;   AF, BC, DE, HL, IX, IY, and the alternate set
        ;;
        ;; References:
        ;;   _gpx_draw_line
_gpx_fill_circle::
        push    ix
        ld      ix,#0
        add     ix,sp

        ;; locals (19 bytes)
        ;; -1..-2   gpx
        ;; -3..-4   x (centre)
        ;; -5..-6   xn
        ;; -7..-8   yn
        ;; -9..-10  f     (decision variable)
        ;; -11..-12 ddx
        ;; -13..-14 ddy
        ;; -15..-16 dy of the row being drawn
        ;; -17..-18 half width of that row
        ;; -19      that row's pattern byte, as the line wants it
        ld      b,h
        ld      c,l                     ; gpx, out of the way of the frame
        ld      hl,#-19
        add     hl,sp
        ld      sp,hl
        ld      -1(ix),c
        ld      -2(ix),b
        ld      -3(ix),e
        ld      -4(ix),d

        ;; a negative radius or an empty pattern draws nothing
        ld      a,7(ix)
        or      a
        jp      m,.fc_done
        ld      a,12(ix)
        or      a
        jp      z,.fc_done

        ;; the centre row spans the full diameter
        ld      hl,#0
        ld      e,6(ix)
        ld      d,7(ix)
        call    .row

        ;; r == 0 was that single row
        ld      a,6(ix)
        or      7(ix)
        jp      z,.fc_done

        ;; xn = 0, yn = r
        xor     a
        ld      -5(ix),a
        ld      -6(ix),a
        ld      a,6(ix)
        ld      -7(ix),a
        ld      a,7(ix)
        ld      -8(ix),a

        ;; f = 1 - r
        ld      hl,#1
        ld      e,6(ix)
        ld      d,7(ix)
        or      a
        sbc     hl,de
        ld      -9(ix),l
        ld      -10(ix),h

        ;; ddx = 1
        ld      hl,#1
        ld      -11(ix),l
        ld      -12(ix),h

        ;; ddy = -2r
        ld      l,6(ix)
        ld      h,7(ix)
        add     hl,hl
        call    .neg_hl
        ld      -13(ix),l
        ld      -14(ix),h

.fc_loop:
        ;; while (xn < yn)
        call    .cmp_xn_yn
        jp      p,.fc_done

        ;; xn++, ddx += 2, f += ddx
        ld      l,-5(ix)
        ld      h,-6(ix)
        inc     hl
        ld      -5(ix),l
        ld      -6(ix),h
        ld      l,-11(ix)
        ld      h,-12(ix)
        inc     hl
        inc     hl
        ld      -11(ix),l
        ld      -12(ix),h
        ex      de,hl
        ld      l,-9(ix)
        ld      h,-10(ix)
        add     hl,de
        ld      -9(ix),l
        ld      -10(ix),h

        ;; f >= 0 finishes the pair of rows at +/-yn: they are as wide as
        ;; they will get, which is the xn from before this step
        bit     7,h
        jr      nz,.fc_stepped
        ld      l,-7(ix)
        ld      h,-8(ix)                ; dy = yn
        ld      e,-5(ix)
        ld      d,-6(ix)
        dec     de                      ; w = xn - 1
        call    .row_pair
        ld      l,-7(ix)
        ld      h,-8(ix)
        dec     hl
        ld      -7(ix),l
        ld      -8(ix),h                ; yn--
        ld      l,-13(ix)
        ld      h,-14(ix)
        inc     hl
        inc     hl
        ld      -13(ix),l
        ld      -14(ix),h               ; ddy += 2
        ex      de,hl
        ld      l,-9(ix)
        ld      h,-10(ix)
        add     hl,de
        ld      -9(ix),l
        ld      -10(ix),h               ; f += ddy

.fc_stepped:
        ;; the pair of rows at +/-xn is final as soon as xn is, as long as
        ;; the walk has not passed the diagonal
        call    .cmp_xn_yn
        jp      p,.fc_check_diag
.fc_row_xn:
        ld      l,-5(ix)
        ld      h,-6(ix)                ; dy = xn
        ld      e,-7(ix)
        ld      d,-8(ix)                ; w = yn
        call    .row_pair
        jp      .fc_loop
.fc_check_diag:
        ld      a,h
        or      l
        jr      z,.fc_row_xn            ; xn == yn: still one row pair
        jp      .fc_loop

.fc_done:
        ld      sp,ix
        pop     ix

        ;; callee cleanup: y(2), r(2), c(1), m(1), fpatt(2), fpatt_len(1),
        ;; clip(2) = 11
        pop     de
        ld      hl,#11
        add     hl,sp
        ld      sp,hl
        push    de
        ret

        ;; .cmp_xn_yn
        ;; return: HL = xn - yn, sign flag set when xn < yn
        ;; clobbers: AF, DE, HL
.cmp_xn_yn:
        ld      l,-5(ix)
        ld      h,-6(ix)
        ld      e,-7(ix)
        ld      d,-8(ix)
        or      a
        sbc     hl,de
        ret

        ;; .row_pair
        ;; draw the two rows dy above and below the centre
        ;; param: HL = dy (> 0), DE = half width
        ;; clobbers: AF, BC, DE, HL
.row_pair:
        call    .row
        ld      l,-15(ix)
        ld      h,-16(ix)
        call    .neg_hl
        ld      e,-17(ix)
        ld      d,-18(ix)
        jp      .row

        ;; .row
        ;; draw one row of the disc as a horizontal line
        ;; param: HL = dy from the centre, DE = half width
        ;; clobbers: AF, BC, DE, HL
.row:
        ld      -15(ix),l
        ld      -16(ix),h
        ld      -17(ix),e
        ld      -18(ix),d

        ;; the row's byte, counted from the top of the bounding box:
        ;; fpatt[(dy + r) % fpatt_len]
        ld      e,6(ix)
        ld      d,7(ix)
        add     hl,de                   ; dy + r, never negative
        ld      a,12(ix)
        ld      c,a
        dec     a
        and     c
        jr      nz,.row_divide          ; not a power of two: divide
        ld      a,c
        dec     a
        and     l
        jr      .row_have_idx
.row_divide:
        call    .mod16_8
.row_have_idx:
        ld      e,a
        ld      d,#0
        ld      l,10(ix)
        ld      h,11(ix)
        add     hl,de
        ld      a,(hl)

        ;; MSB-first from the box's left edge becomes LSB-first from the
        ;; line's start: reverse the byte, then rotate it right by how far
        ;; this row starts inside the box
        ld      b,#8
.row_reverse:
        rlca
        rr      c
        djnz    .row_reverse
        ld      a,c
        ld      -19(ix),a
        ld      l,6(ix)
        ld      h,7(ix)
        ld      e,-17(ix)
        ld      d,-18(ix)
        or      a
        sbc     hl,de                   ; r - w, never negative
        ld      a,l
        and     #0x07
        jr      z,.row_draw
        ld      b,a
        ld      a,-19(ix)
.row_rotate:
        rrca
        djnz    .row_rotate
        ld      -19(ix),a

.row_draw:
        ;; gpx_draw_line(gpx, x-w, row, x+w, row, c, m, patt, clip). The
        ;; callee does not keep IX and cleans its own arguments, so IX is
        ;; saved underneath them.
        push    ix
        ld      l,13(ix)
        ld      h,14(ix)
        push    hl                      ; clip
        ld      a,-19(ix)
        push    af
        inc     sp                      ; lpatt
        ld      l,8(ix)
        ld      h,9(ix)
        push    hl                      ; c, m
        ld      l,-3(ix)
        ld      h,-4(ix)
        ld      e,-17(ix)
        ld      d,-18(ix)
        add     hl,de
        ex      de,hl                   ; DE = x + w
        ld      l,-15(ix)
        ld      h,-16(ix)
        ld      c,4(ix)
        ld      b,5(ix)
        add     hl,bc                   ; HL = y + dy
        push    hl                      ; y1
        push    de                      ; x1
        push    hl                      ; y0
        ld      l,-3(ix)
        ld      h,-4(ix)
        ld      e,-17(ix)
        ld      d,-18(ix)
        or      a
        sbc     hl,de
        ex      de,hl                   ; DE = x - w
        ld      l,-1(ix)
        ld      h,-2(ix)                ; gpx
        call    _gpx_draw_line
        pop     ix                      ; saved below the argument block
        ret

        ;; .mod16_8
        ;; param: HL = dividend (>= 0), C = divisor (>= 1)
        ;; return: A = HL % C
        ;; clobbers: AF, B, HL
.mod16_8:
        xor     a
        ld      b,#16
.md_loop:
        add     hl,hl
        rla
        jr      c,.md_subtract
        cp      c
        jr      c,.md_next
.md_subtract:
        sub     c
.md_next:
        djnz    .md_loop
        ret

        ;; .neg_hl
        ;; return: HL = -HL
        ;; clobbers: AF, HL
.neg_hl:
        xor     a
        sub     l
        ld      l,a
        sbc     a,a
        sub     h
        ld      h,a
        ret
