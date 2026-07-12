        ;; gpx_draw_line.s
        ;;
        ;; ZX Spectrum line dispatcher.
        ;;
        ;; Frame-less: args are peeked SP-relative (no IX), so the fast
        ;; hline/vline/bresenham targets receive the caller frame untouched
        ;; via tail jumps.

        .module gpx_draw_line
        .optsdcc -mz80 sdcccall(1)

        .globl  _gpx_draw_line
        .globl  _gpx_draw_pixel

        .globl  __gpx_hline
        .globl  __gpx_bresenham_line
        .globl  __rect_cmp16s_lt
        .globl  __ret_clean11

        .area   _CODE

        ;; ------------------------------------------------------------
        ;; _gpx_draw_line
        ;; Dispatch strategy:
        ;;   if x0==x1 and y0==y1 -> draw pixel
        ;;   else if x0==x1       -> vertical line routine (y0<=y1)
        ;;   else if y0==y1       -> horizontal line routine (x0<=x1)
        ;;   else                 -> Bresenham routine
        ;;
        ;; Signature:
        ;;   uint8_t gpx_draw_line(gpx_t *gpx,
        ;;                         coord x0, coord y0, coord x1, coord y1,
        ;;                         color c, bmode m, uint8_t lpatt,
        ;;                         const rect_t *clip)
        ;;
        ;; Arguments:
        ;;   HL = gpx (unused), DE = x0
        ;;   stack: [ret][y0 @2][x1 @4][y1 @6][c @8][m @9][lpatt @10][clip @11]
_gpx_draw_line::
        ld      hl,#2
        add     hl,sp                  ;; HL -> y0
        ld      c,(hl)
        inc     hl
        ld      b,(hl)                 ;; BC = y0
        inc     hl                     ;; HL -> x1

        ;; x0 == x1 ?
        ld      a,(hl)
        cp      e
        jr      nz,.gl_not_v
        inc     hl
        ld      a,(hl)
        cp      d
        jr      nz,.gl_not_v

        ;; y0 == y1 ?
        inc     hl                     ;; HL -> y1
        ld      a,(hl)
        cp      c
        jr      nz,.gl_bres            ;; vertical: bres has a fast path
        inc     hl
        ld      a,(hl)
        cp      b
        jr      nz,.gl_bres

        ;; single pixel: honor lpatt bit0
        ld      hl,#10
        add     hl,sp                  ;; HL -> lpatt
        ld      a,(hl)
        and     #0x01
        jr      z,.gl_single_done

        ;; call gpx_draw_pixel(gpx, x0, y0, c, m, clip); DE = x0 stays live
        inc     hl                     ;; HL -> clip
        ld      a,(hl)
        inc     hl
        ld      h,(hl)
        ld      l,a
        push    hl                     ;; clip

        ld      hl,#10                 ;; c,m moved down by the push
        add     hl,sp
        ld      a,(hl)
        inc     hl
        ld      h,(hl)
        ld      l,a
        push    hl                     ;; c,m

        push    bc                     ;; y0

        call    _gpx_draw_pixel        ;; pops its 6 arg bytes

.gl_single_done:
        ;; degenerate line: return lpatt unrotated
        ld      hl,#10
        add     hl,sp
        ld      a,(hl)
        jp      __ret_clean11          ;; callee cleanup: 11 bytes

.gl_not_v:
        ;; y0 == y1 ?
        ld      hl,#6
        add     hl,sp                  ;; HL -> y1
        ld      a,(hl)
        cp      c
        jr      nz,.gl_bres
        inc     hl
        ld      a,(hl)
        cp      b
        jr      nz,.gl_bres

        ;; fast hline assumes x0 <= x1; reversed goes through Bresenham
        ld      hl,#4
        add     hl,sp
        ld      a,(hl)
        inc     hl
        ld      h,(hl)
        ld      l,a                    ;; HL = x1
        call    __rect_cmp16s_lt       ;; x1 < x0 ?
        jr      nz,.gl_bres
        jp      __gpx_hline

.gl_bres:
        jp      __gpx_bresenham_line
