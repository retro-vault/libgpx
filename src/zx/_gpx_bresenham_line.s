        ;; _gpx_bresenham_line.s
        ;;
        ;; Compact generic Bresenham renderer.
        ;; Clipping is delegated to gpx_draw_pixel via clip argument.

        .module _gpx_bresenham_line
        .optsdcc -mz80 sdcccall(1)

        .globl  __gpx_bresenham_line
        .globl  __gpx_draw_line_raw_local
        .globl  _gpx_draw_pixel
        .globl  __rect_cmp16s_lt

        .area   _CODE

        ;; Signature matches gpx_draw_line():
        ;;   HL = gpx
        ;;   DE = x0
        ;;   stack: y0, x1, y1, c, m, lpatt, clip
__gpx_bresenham_line::
__gpx_draw_line_raw_local::
        push    ix
        ld      ix,#0
        add     ix,sp

        ;; locals (25 bytes)
        ;; -1..-2   gpx
        ;; -3..-4   x0
        ;; -5..-6   y0
        ;; -7..-8   x1
        ;; -9..-10  y1
        ;; -11      lpatt
        ;; -12..-13 clip ptr
        ;; -14      sx (1/-1)
        ;; -15      sy (1/-1)
        ;; -16..-17 dx
        ;; -18..-19 dy
        ;; -20..-21 err
        ;; -22..-23 e2
        ;; -24..-25 neg_dy
        ld      hl,#-25
        add     hl,sp
        ld      sp,hl

        ;; save args
        ld      -1(ix),l               ;; gpx lo
        ld      -2(ix),h               ;; gpx hi

        ld      -3(ix),e               ;; x0
        ld      -4(ix),d

        ld      a,4(ix)                ;; y0
        ld      -5(ix),a
        ld      a,5(ix)
        ld      -6(ix),a

        ld      a,6(ix)                ;; x1
        ld      -7(ix),a
        ld      a,7(ix)
        ld      -8(ix),a

        ld      a,8(ix)                ;; y1
        ld      -9(ix),a
        ld      a,9(ix)
        ld      -10(ix),a

        ld      a,12(ix)               ;; lpatt
        ld      -11(ix),a

        ld      a,13(ix)               ;; clip ptr
        ld      -12(ix),a
        ld      a,14(ix)
        ld      -13(ix),a

        ;; dx + sx
        ;; if (x1 < x0) { sx=-1; dx=x0-x1; } else { sx=1; dx=x1-x0; }
        ld      l,-7(ix)
        ld      h,-8(ix)               ;; HL=x1
        ld      e,-3(ix)
        ld      d,-4(ix)               ;; DE=x0
        call    __rect_cmp16s_lt
        or      a
        jr      z,.gbl_dx_pos

        ld      a,#0xff
        ld      -14(ix),a              ;; sx=-1
        ld      l,-3(ix)
        ld      h,-4(ix)               ;; HL=x0
        ld      e,-7(ix)
        ld      d,-8(ix)               ;; DE=x1
        or      a
        sbc     hl,de
        jr      .gbl_dx_done

.gbl_dx_pos:
        ld      a,#0x01
        ld      -14(ix),a              ;; sx=+1
        ld      l,-7(ix)
        ld      h,-8(ix)               ;; HL=x1
        ld      e,-3(ix)
        ld      d,-4(ix)               ;; DE=x0
        or      a
        sbc     hl,de

.gbl_dx_done:
        ld      -16(ix),l              ;; dx
        ld      -17(ix),h

        ;; dy + sy
        ;; if (y1 < y0) { sy=-1; dy=y0-y1; } else { sy=1; dy=y1-y0; }
        ld      l,-9(ix)
        ld      h,-10(ix)              ;; HL=y1
        ld      e,-5(ix)
        ld      d,-6(ix)               ;; DE=y0
        call    __rect_cmp16s_lt
        or      a
        jr      z,.gbl_dy_pos

        ld      a,#0xff
        ld      -15(ix),a              ;; sy=-1
        ld      l,-5(ix)
        ld      h,-6(ix)               ;; HL=y0
        ld      e,-9(ix)
        ld      d,-10(ix)              ;; DE=y1
        or      a
        sbc     hl,de
        jr      .gbl_dy_done

.gbl_dy_pos:
        ld      a,#0x01
        ld      -15(ix),a              ;; sy=+1
        ld      l,-9(ix)
        ld      h,-10(ix)              ;; HL=y1
        ld      e,-5(ix)
        ld      d,-6(ix)               ;; DE=y0
        or      a
        sbc     hl,de

.gbl_dy_done:
        ld      -18(ix),l              ;; dy
        ld      -19(ix),h

        ;; err = dx - dy
        ld      l,-16(ix)
        ld      h,-17(ix)
        ld      e,-18(ix)
        ld      d,-19(ix)
        or      a
        sbc     hl,de
        ld      -20(ix),l
        ld      -21(ix),h

.gbl_loop:
        ;; if (lpatt & 1) draw pixel
        ld      a,-11(ix)
        and     #0x01
        jr      z,.gbl_after_plot

        ld      l,-12(ix)
        ld      h,-13(ix)
        push    hl                     ;; clip

        ld      l,10(ix)               ;; c
        ld      h,11(ix)               ;; m
        push    hl

        ld      l,-5(ix)
        ld      h,-6(ix)
        push    hl                     ;; y

        ld      l,-1(ix)
        ld      h,-2(ix)
        ld      e,-3(ix)
        ld      d,-4(ix)
        call    _gpx_draw_pixel

.gbl_after_plot:
        ;; if (x0==x1 && y0==y1) done
        ld      a,-3(ix)
        cp      -7(ix)
        jr      nz,.gbl_step
        ld      a,-4(ix)
        cp      -8(ix)
        jr      nz,.gbl_step
        ld      a,-5(ix)
        cp      -9(ix)
        jr      nz,.gbl_step
        ld      a,-6(ix)
        cp      -10(ix)
        jp      z,.gbl_done

.gbl_step:
        ;; e2 = err * 2
        ld      l,-20(ix)
        ld      h,-21(ix)
        add     hl,hl
        ld      -22(ix),l
        ld      -23(ix),h

        ;; neg_dy = -dy
        ld      l,-18(ix)
        ld      h,-19(ix)
        ld      a,l
        cpl
        ld      l,a
        ld      a,h
        cpl
        ld      h,a
        inc     hl
        ld      -24(ix),l
        ld      -25(ix),h

        ;; if (e2 > -dy) => if (-dy < e2)
        ld      l,-24(ix)
        ld      h,-25(ix)              ;; HL=-dy
        ld      e,-22(ix)
        ld      d,-23(ix)              ;; DE=e2
        call    __rect_cmp16s_lt
        or      a
        jr      z,.gbl_skip_x

        ;; err -= dy
        ld      l,-20(ix)
        ld      h,-21(ix)
        ld      e,-18(ix)
        ld      d,-19(ix)
        or      a
        sbc     hl,de
        ld      -20(ix),l
        ld      -21(ix),h

        ;; x0 += sx
        ld      a,-14(ix)
        cp      #0xff
        jr      z,.gbl_x_dec
        ld      l,-3(ix)
        ld      h,-4(ix)
        inc     hl
        ld      -3(ix),l
        ld      -4(ix),h
        jr      .gbl_skip_x

.gbl_x_dec:
        ld      l,-3(ix)
        ld      h,-4(ix)
        dec     hl
        ld      -3(ix),l
        ld      -4(ix),h

.gbl_skip_x:
        ;; if (e2 < dx)
        ld      l,-22(ix)
        ld      h,-23(ix)              ;; HL=e2
        ld      e,-16(ix)
        ld      d,-17(ix)              ;; DE=dx
        call    __rect_cmp16s_lt
        or      a
        jr      z,.gbl_rot

        ;; err += dx
        ld      l,-20(ix)
        ld      h,-21(ix)
        ld      e,-16(ix)
        ld      d,-17(ix)
        add     hl,de
        ld      -20(ix),l
        ld      -21(ix),h

        ;; y0 += sy
        ld      a,-15(ix)
        cp      #0xff
        jr      z,.gbl_y_dec
        ld      l,-5(ix)
        ld      h,-6(ix)
        inc     hl
        ld      -5(ix),l
        ld      -6(ix),h
        jr      .gbl_rot

.gbl_y_dec:
        ld      l,-5(ix)
        ld      h,-6(ix)
        dec     hl
        ld      -5(ix),l
        ld      -6(ix),h

.gbl_rot:
        ld      a,-11(ix)
        rrca
        ld      -11(ix),a
        jp      .gbl_loop

.gbl_done:
        ld      a,-11(ix)

        ld      sp,ix
        pop     ix

        ;; callee cleanup: y0(2), x1(2), y1(2), c(1), m(1), lpatt(1), clip(2) = 11
        pop     de
        ld      hl,#11
        add     hl,sp
        ld      sp,hl
        push    de
        ret
