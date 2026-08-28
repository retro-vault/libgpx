        ;; gpx_draw_circle.s
        ;;
        ;; Midpoint (Bresenham) circle outline.
        ;;
        ;; Portable: the only thing this module touches is gpx_draw_pixel,
        ;; so clipping, blit modes and the framebuffer layout all stay the
        ;; backend's business and one copy of the code serves every
        ;; machine. The eight octant points of a step are emitted from a
        ;; single sign/swap selector. A step that lands on the 45-degree
        ;; diagonal emits only the first four: the other four are the same
        ;; pixels, and plotting them twice would cancel under BM_XOR.
        ;;
        ;; GPL2 License (see: LICENSE)
        ;; Copyright (C) 2026 Tomaz Stih
        ;;
        ;; 2026-08-28   TS

        .module gpx_draw_circle
        .optsdcc -mz80 sdcccall(1)

        .globl  _gpx_draw_circle
        .globl  _gpx_draw_pixel

        .area   _CODE

        ;; ------------------------------------------------------------
        ;; _gpx_draw_circle
        ;; Plot the circle centred on (x,y) with radius r. Every pixel is
        ;; plotted exactly once, so the outline is safe to draw in BM_XOR
        ;; and to erase by drawing it again. r == 0 is a single pixel and
        ;; a negative r draws nothing.
        ;;
        ;; Signature:
        ;;   void gpx_draw_circle(gpx_t *gpx, coord x, coord y, coord r,
        ;;                        color c, bmode m, const rect_t *clip)
        ;;
        ;; Arguments:
        ;;   HL = gpx, DE = x
        ;;   stack: y(2), r(2), c(1), m(1), clip(2)
        ;;
        ;; Clobbers:
        ;;   AF, BC, DE, HL, IX, IY, and the alternate set
        ;;
        ;; References:
        ;;   _gpx_draw_pixel
_gpx_draw_circle::
        push    ix
        ld      ix,#0
        add     ix,sp

        ;; locals (16 bytes)
        ;; -1..-2   gpx
        ;; -3..-4   x (centre)
        ;; -5..-6   xn
        ;; -7..-8   yn
        ;; -9..-10  f     (decision variable)
        ;; -11..-12 ddx
        ;; -13..-14 ddy
        ;; -15      octant selector: bit0 negates dx, bit1 dy, bit2 swaps
        ;; -16      how many selector values this step emits (4 or 8)
        ld      b,h
        ld      c,l                     ; gpx, out of the way of the frame
        ld      hl,#-16
        add     hl,sp
        ld      sp,hl
        ld      -1(ix),c
        ld      -2(ix),b
        ld      -3(ix),e
        ld      -4(ix),d

        ;; a negative radius draws nothing
        ld      a,7(ix)
        or      a
        jp      m,.dc_done

        ;; r == 0 is one pixel at the centre
        or      6(ix)
        jr      nz,.dc_nsew
        ld      de,#0
        ld      h,d
        ld      l,e
        call    .plot_dxdy
        jp      .dc_done

.dc_nsew:
        ;; the four axis points, which the octant loop never reaches
        ld      de,#0
        ld      l,6(ix)
        ld      h,7(ix)
        call    .plot_dxdy              ; (x, y+r)
        ld      de,#0
        ld      l,6(ix)
        ld      h,7(ix)
        call    .neg_hl
        call    .plot_dxdy              ; (x, y-r)
        ld      hl,#0
        ld      e,6(ix)
        ld      d,7(ix)
        call    .plot_dxdy              ; (x+r, y)
        ld      hl,#0
        ld      e,6(ix)
        ld      d,7(ix)
        ex      de,hl
        call    .neg_hl
        ex      de,hl
        call    .plot_dxdy              ; (x-r, y)

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

.dc_loop:
        ;; while (xn < yn)
        call    .cmp_xn_yn
        jp      p,.dc_done

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

        ;; if (f >= 0) { yn--; ddy += 2; f += ddy; }
        bit     7,h
        jr      nz,.dc_stepped
        ld      l,-7(ix)
        ld      h,-8(ix)
        dec     hl
        ld      -7(ix),l
        ld      -8(ix),h
        ld      l,-13(ix)
        ld      h,-14(ix)
        inc     hl
        inc     hl
        ld      -13(ix),l
        ld      -14(ix),h
        ex      de,hl
        ld      l,-9(ix)
        ld      h,-10(ix)
        add     hl,de
        ld      -9(ix),l
        ld      -10(ix),h

.dc_stepped:
        ;; xn < yn emits all eight octant points, xn == yn only the four
        ;; distinct ones, xn > yn none at all
        call    .cmp_xn_yn
        jp      m,.dc_eight
        ld      a,h
        or      l
        jp      nz,.dc_loop
        ld      a,#4
        jr      .dc_emit
.dc_eight:
        ld      a,#8
.dc_emit:
        ld      -16(ix),a
        xor     a
        ld      -15(ix),a
.dc_emit_loop:
        call    .plot_sel
        ld      a,-15(ix)
        inc     a
        ld      -15(ix),a
        cp      -16(ix)
        jr      c,.dc_emit_loop
        jp      .dc_loop

.dc_done:
        ld      sp,ix
        pop     ix

        ;; callee cleanup: y(2), r(2), c(1), m(1), clip(2) = 8
        pop     de
        ld      hl,#8
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

        ;; .plot_sel
        ;; plot one octant point for the selector in -15(ix)
        ;; clobbers: AF, BC, DE, HL
.plot_sel:
        ld      l,-5(ix)
        ld      h,-6(ix)                ; HL = dx magnitude (xn)
        ld      e,-7(ix)
        ld      d,-8(ix)                ; DE = dy magnitude (yn)
        ld      a,-15(ix)
        and     #0x04
        jr      z,.ps_noswap
        ex      de,hl                   ; mirrored octant
.ps_noswap:
        ld      a,-15(ix)
        and     #0x01
        jr      z,.ps_posx
        call    .neg_hl
.ps_posx:
        ld      a,-15(ix)
        and     #0x02
        jr      z,.ps_posy
        ex      de,hl
        call    .neg_hl
        ex      de,hl
.ps_posy:
        ex      de,hl                   ; DE = dx, HL = dy
        ;; falls into .plot_dxdy

        ;; .plot_dxdy
        ;; plot (x + dx, y + dy) with the caller's color, mode and clip
        ;; param: DE = dx, HL = dy
        ;; clobbers: AF, BC, DE, HL
.plot_dxdy:
        ld      c,4(ix)
        ld      b,5(ix)
        add     hl,bc                   ; y + dy
        push    hl
        ld      l,-3(ix)
        ld      h,-4(ix)
        add     hl,de                   ; x + dx
        ex      de,hl
        pop     bc
        ;; The callee does not keep IX and cleans its own arguments, so IX
        ;; is saved underneath them.
        push    ix
        ld      l,10(ix)
        ld      h,11(ix)
        push    hl                      ; clip
        ld      a,9(ix)
        push    af
        inc     sp                      ; m
        ld      a,8(ix)
        push    af
        inc     sp                      ; c
        push    bc                      ; y
        ld      l,-1(ix)
        ld      h,-2(ix)                ; gpx
        call    _gpx_draw_pixel
        pop     ix                      ; saved below the argument block
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
