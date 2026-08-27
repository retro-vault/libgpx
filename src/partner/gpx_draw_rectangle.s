        ;; gpx_draw_rectangle.s
        ;;
        ;; Partner rectangle outline renderer:
        ;;  - normalizes rectangle coordinates
        ;;  - top/bottom use requested pattern
        ;;  - left/right are solid and exclude corners
        ;;
        ;; GPL2 License (see: LICENSE)
        ;; Copyright (C) 2026 Tomaz Stih
        ;;
        ;; 2026-03-30   TS

        .module gpx_draw_rectangle
        .optsdcc -mz80 sdcccall(1)

        .globl  _gpx_draw_rectangle
        .globl  _gpx_draw_line
        .globl  __rect_cmp16s_lt
        .globl  __rect_unpack_norm

        .area   _CODE

        ;; ------------------------------------------------------------
        ;; void gpx_draw_rectangle(
        ;;   gpx_t *gpx, rect_t *r,
        ;;   color c, bmode m, uint8_t lpatt, const rect_t *clip)
        ;;
        ;; Arguments:
        ;;   HL = gpx
        ;;   DE = r
        ;;   stack: c, m, lpatt, clip
        ;;
        ;; Clobbers:
        ;;   AF, BC, DE, HL, IX
_gpx_draw_rectangle::
        push    ix
        ld      ix,#0
        add     ix,sp

        ;; preserve gpx pointer across local stack allocation
        ld      b,h                     ; gpx hi
        ld      c,l                     ; gpx lo

        ;; locals (14 bytes)
        ;; -1..-2   x0
        ;; -3..-4   x1
        ;; -5..-6   y0
        ;; -7..-8   y1
        ;; -9..-10  gpx
        ;; -11..-12 ytop = y0+1
        ;; -13..-14 ybot = y1-1
        ld      hl,#-14
        add     hl,sp
        ld      sp,hl

        ;; save gpx
        ld      -9(ix),c
        ld      -10(ix),b

        ;; if (r == NULL) return
        ld      a,d
        or      e
        jp      z,.dr_done

        ;; unpack + normalize rect into locals
        push    ix
        pop     hl
        call    __rect_unpack_norm

        ;; top edge
        ld      l,7(ix)
        ld      h,8(ix)
        push    hl                      ; clip

        ld      a,6(ix)
        dec     sp
        ld      hl,#0
        add     hl,sp
        ld      (hl),a                  ; lpatt

        ld      l,4(ix)
        ld      h,5(ix)
        push    hl                      ; c,m

        ld      l,-5(ix)
        ld      h,-6(ix)
        push    hl                      ; y1 = y0

        ld      l,-3(ix)
        ld      h,-4(ix)
        push    hl                      ; x1

        ld      l,-5(ix)
        ld      h,-6(ix)
        push    hl                      ; y0

        ld      l,-9(ix)
        ld      h,-10(ix)
        ld      e,-1(ix)
        ld      d,-2(ix)
        call    _gpx_draw_line

        ;; bottom edge
        ld      l,7(ix)
        ld      h,8(ix)
        push    hl                      ; clip

        ld      a,6(ix)
        dec     sp
        ld      hl,#0
        add     hl,sp
        ld      (hl),a                  ; lpatt

        ld      l,4(ix)
        ld      h,5(ix)
        push    hl                      ; c,m

        ld      l,-7(ix)
        ld      h,-8(ix)
        push    hl                      ; y1 = y0

        ld      l,-3(ix)
        ld      h,-4(ix)
        push    hl                      ; x1

        ld      l,-7(ix)
        ld      h,-8(ix)
        push    hl                      ; y0

        ld      l,-9(ix)
        ld      h,-10(ix)
        ld      e,-1(ix)
        ld      d,-2(ix)
        call    _gpx_draw_line

        ;; ytop = y0 + 1
        ld      l,-5(ix)
        ld      h,-6(ix)
        inc     hl
        ld      -11(ix),l
        ld      -12(ix),h

        ;; ybot = y1 - 1
        ld      l,-7(ix)
        ld      h,-8(ix)
        dec     hl
        ld      -13(ix),l
        ld      -14(ix),h

        ;; if (ybot < ytop) skip sides
        ld      l,-13(ix)
        ld      h,-14(ix)
        ld      e,-11(ix)
        ld      d,-12(ix)
        call    __rect_cmp16s_lt
        or      a
        jp      nz,.dr_done

        ;; left side, solid
        ld      l,7(ix)
        ld      h,8(ix)
        push    hl                      ; clip

        ld      a,#0xFF
        dec     sp
        ld      hl,#0
        add     hl,sp
        ld      (hl),a                  ; lpatt solid

        ld      l,4(ix)
        ld      h,5(ix)
        push    hl                      ; c,m

        ld      l,-13(ix)
        ld      h,-14(ix)
        push    hl                      ; y1

        ld      l,-1(ix)
        ld      h,-2(ix)
        push    hl                      ; x1 = x0

        ld      l,-11(ix)
        ld      h,-12(ix)
        push    hl                      ; y0

        ld      l,-9(ix)
        ld      h,-10(ix)
        ld      e,-1(ix)
        ld      d,-2(ix)
        call    _gpx_draw_line

        ;; right side, solid
        ld      l,7(ix)
        ld      h,8(ix)
        push    hl                      ; clip

        ld      a,#0xFF
        dec     sp
        ld      hl,#0
        add     hl,sp
        ld      (hl),a                  ; lpatt solid

        ld      l,4(ix)
        ld      h,5(ix)
        push    hl                      ; c,m

        ld      l,-13(ix)
        ld      h,-14(ix)
        push    hl                      ; y1

        ld      l,-3(ix)
        ld      h,-4(ix)
        push    hl                      ; x1 = x1

        ld      l,-11(ix)
        ld      h,-12(ix)
        push    hl                      ; y0

        ld      l,-9(ix)
        ld      h,-10(ix)
        ld      e,-3(ix)
        ld      d,-4(ix)
        call    _gpx_draw_line

.dr_done:
        ld      sp,ix
        pop     ix

        ;; callee cleanup: c(1), m(1), lpatt(1), clip(2) = 5
        pop     de
        ld      hl,#5
        add     hl,sp
        ld      sp,hl
        push    de
        ret
