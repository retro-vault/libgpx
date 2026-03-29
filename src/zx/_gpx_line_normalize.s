        ;; _gpx_line_normalize.s
        ;;
        ;; Ensure line endpoint order by x:
        ;;   x0 <= x1
        ;; If swapped, y endpoints are swapped too.

        .module _gpx_line_normalize
        .optsdcc -mz80 sdcccall(1)

        .globl  _gpx_line_normalize
        .globl  __rect_cmp16s_lt

        .area   _CODE

        ;; ------------------------------------------------------------
        ;; _gpx_line_normalize
        ;; Input:
        ;;   HL = gpx_line_state_t *s
        ;;
        ;; Layout:
        ;;   +0 x0, +2 y0, +4 x1, +6 y1, +8 lpatt
        ;;
        ;; Output:
        ;;   DE = s
        ;;
        ;; Clobbers:
        ;;   AF, BC, DE, HL, IX
_gpx_line_normalize::
        push    ix
        push    hl
        pop     ix                      ;; IX = s

        ;; if (x1 < x0) swap endpoints
        ld      l,4(ix)                 ;; HL = x1
        ld      h,5(ix)
        ld      e,0(ix)                 ;; DE = x0
        ld      d,1(ix)
        call    __rect_cmp16s_lt
        jr      z,.gln_done

        ;; swap x0 <-> x1
        ld      c,e                     ;; BC = old x0
        ld      b,d
        ld      e,l                     ;; DE = old x1
        ld      d,h
        ld      0(ix),e                 ;; x0 = old x1
        ld      1(ix),d
        ld      4(ix),c                 ;; x1 = old x0
        ld      5(ix),b

        ;; swap y0 <-> y1
        ld      l,6(ix)                 ;; HL = y1
        ld      h,7(ix)
        ld      e,2(ix)                 ;; DE = y0
        ld      d,3(ix)
        ld      c,e                     ;; BC = old y0
        ld      b,d
        ld      e,l                     ;; DE = old y1
        ld      d,h
        ld      2(ix),e                 ;; y0 = old y1
        ld      3(ix),d
        ld      6(ix),c                 ;; y1 = old y0
        ld      7(ix),b

.gln_done:
        push    ix
        pop     de                      ;; return s
        pop     ix
        ret
