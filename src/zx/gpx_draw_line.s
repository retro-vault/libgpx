        ;; gpx_draw_line.s
        ;;
        ;; ZX Spectrum line dispatcher under src-zx-spectrum test area.

        .module gpx_draw_line
        .optsdcc -mz80 sdcccall(1)

        .globl  _gpx_draw_line
        .globl  _gpx_draw_pixel
        
        .globl  __gpx_hline
        .globl  __gpx_vline
        .globl  __gpx_bresenham_line
        .globl  __rect_cmp16s_lt

        .area   _CODE

        ;; ------------------------------------------------------------
        ;; _gpx_draw_line
        ;; Dispatch strategy:
        ;;   if x0==x1 and y0==y1 -> draw pixel
        ;;   else if x0==x1       -> vertical line routine
        ;;   else if y0==y1       -> horizontal line routine
        ;;   else                 -> Bresenham routine
        ;;
        ;; Signature:
        ;;   uint8_t gpx_draw_line(gpx_t *gpx,
        ;;                         coord x0, coord y0, coord x1, coord y1,
        ;;                         color c, bmode m, uint8_t lpatt,
        ;;                         const rect_t *clip)
        ;;
        ;; Arguments:
        ;;   HL = gpx
        ;;   DE = x0
        ;;   stack: y0, x1, y1, c, m, lpatt, clip
_gpx_draw_line::
        push    ix
        ld      ix,#0
        add     ix,sp

        ;; x0 == x1 ?
        ld      a,e
        cp      6(ix)
        jr      nz,.gl_not_v
        ld      a,d
        cp      7(ix)
        jr      nz,.gl_not_v

        ;; y0 == y1 ?
        ld      a,4(ix)
        cp      8(ix)
        jr      nz,.gl_vline
        ld      a,5(ix)
        cp      9(ix)
        jr      nz,.gl_vline

        ;; single pixel
        ;; honor lpatt first bit for degenerate segment
        ld      a,12(ix)
        and     #0x01
        jr      z,.gl_single_done

        ;; call gpx_draw_pixel(gpx, x0, y0, c, m, clip)
        ld      l,13(ix)
        ld      h,14(ix)
        push    hl                    ;; clip

        ld      l,10(ix)
        ld      h,11(ix)
        push    hl                    ;; color, mode

        ld      l,4(ix)
        ld      h,5(ix)
        push    hl                    ;; y0

        call    _gpx_draw_pixel

.gl_single_done:

        ;; For a degenerate line, preserve lpatt as-is.
        ld      a,12(ix)

        ;; epilogue + callee cleanup: 11 bytes
        pop     ix
        pop     de
        ld      hl,#11
        add     hl,sp
        ld      sp,hl
        push    de
        ret

.gl_vline:
        ;; Fast vline assumes y0 <= y1. If reversed, use Bresenham.
        push    de
        ld      l,8(ix)                 ;; y1
        ld      h,9(ix)
        ld      e,4(ix)                 ;; y0
        ld      d,5(ix)
        call    __rect_cmp16s_lt        ;; y1 < y0 ?
        pop     de
        jr      nz,.gl_bres

        pop     ix
        jp      __gpx_vline

.gl_not_v:
        ;; y0 == y1 ?
        ld      a,4(ix)
        cp      8(ix)
        jr      nz,.gl_bres
        ld      a,5(ix)
        cp      9(ix)
        jr      nz,.gl_bres

        ;; Fast hline assumes x0 <= x1. If reversed, use Bresenham.
        ld      l,6(ix)               ;; x1
        ld      h,7(ix)
        call    __rect_cmp16s_lt      ;; x1 < x0 ?
        jr      nz,.gl_bres
        pop     ix
        jp      __gpx_hline

.gl_bres:
        pop     ix
        jp      __gpx_bresenham_line
