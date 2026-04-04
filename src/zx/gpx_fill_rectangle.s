        ;; gpx_fill_rectangle.s
        ;;
        ;; Rectangle fill renderer:
        ;;  - normalizes rectangle coordinates
        ;;  - pattern is applied per row, MSB-first from x0
        ;;  - dispatches each row through fast __gpx_hline

        .module gpx_fill_rectangle
        .optsdcc -mz80 sdcccall(1)

        .globl  _gpx_fill_rectangle
        .globl  __gpx_hline
        .globl  __rect_unpack_norm

        .area   _CODE

        ;; void gpx_fill_rectangle(
        ;;   gpx_t *gpx, rect_t *r,
        ;;   color c, bmode m, uint8_t *fpatt, uint8_t fpatt_len,
        ;;   const rect_t *clip)
        ;;
        ;; HL = gpx
        ;; DE = r
        ;; stack: c, m, fpatt, fpatt_len, clip
_gpx_fill_rectangle::
        push    ix
        ld      ix,#0
        add     ix,sp

        ;; preserve gpx across local stack allocation
        ld      b,h
        ld      c,l

        ;; locals (17 bytes)
        ;; -1..-2   x0
        ;; -3..-4   x1
        ;; -5..-6   y0
        ;; -7..-8   y1
        ;; -9..-10  gpx
        ;; -11..-12 ycur
        ;; -13      fpatt idx
        ;; -14..-15 fpatt ptr
        ;; -16      fpatt len
        ;; -17      row lpatt (LSB-first for __gpx_hline)
        ld      hl,#-17
        add     hl,sp
        ld      sp,hl

        ;; save gpx
        ld      -9(ix),c
        ld      -10(ix),b

        ;; if (r == NULL) return
        ld      a,d
        or      e
        jp      z,.fr_done

        ;; if (fpatt_len == 0) return
        ld      a,8(ix)
        or      a
        jp      z,.fr_done

        ;; save fpatt ptr + len
        ld      a,6(ix)
        ld      -14(ix),a
        ld      a,7(ix)
        ld      -15(ix),a
        ld      a,8(ix)
        ld      -16(ix),a

        ;; unpack + normalize rect into locals
        push    ix
        pop     hl
        call    __rect_unpack_norm

        ;; ycur = y0, idx = 0
        ld      a,-5(ix)
        ld      -11(ix),a
        ld      a,-6(ix)
        ld      -12(ix),a
        xor     a
        ld      -13(ix),a

.fr_row_loop:
        ;; row pattern = reverse_bits(fpatt[idx])
        ;; Fill uses MSB-first from x0, while __gpx_hline consumes lpatt LSB-first.
        ld      l,-14(ix)
        ld      h,-15(ix)
        ld      e,-13(ix)
        ld      d,#0x00
        add     hl,de
        ld      a,(hl)
        ld      c,#0x00
        ld      b,#0x08
.fr_rev_loop:
        rrca
        rl      c
        djnz    .fr_rev_loop
        ld      a,c
        ld      -17(ix),a

        ;; __gpx_hline(gpx, x0, ycur, x1, ycur, c, m, row_lpatt, clip)
        ld      l,9(ix)
        ld      h,10(ix)
        push    hl                     ;; clip

        ld      a,-17(ix)
        push    af
        inc     sp                     ;; lpatt

        ld      l,4(ix)
        ld      h,5(ix)
        push    hl                     ;; c,m

        ld      l,-11(ix)
        ld      h,-12(ix)
        push    hl                     ;; y1 (unused by hline)

        ld      l,-3(ix)
        ld      h,-4(ix)
        push    hl                     ;; x1

        ld      l,-11(ix)
        ld      h,-12(ix)
        push    hl                     ;; y0

        ld      l,-9(ix)
        ld      h,-10(ix)
        ld      e,-1(ix)
        ld      d,-2(ix)
        call    __gpx_hline

        ;; if (ycur == y1) complete
        ld      a,-11(ix)
        cp      -7(ix)
        jr      nz,.fr_next_row
        ld      a,-12(ix)
        cp      -8(ix)
        jr      z,.fr_done

.fr_next_row:
        ;; ycur++
        ld      l,-11(ix)
        ld      h,-12(ix)
        inc     hl
        ld      -11(ix),l
        ld      -12(ix),h

        ;; idx = (idx + 1) % fpatt_len
        ld      a,-13(ix)
        inc     a
        cp      -16(ix)
        jr      c,.fr_store_idx
        xor     a
.fr_store_idx:
        ld      -13(ix),a

        jr      .fr_row_loop

.fr_done:
        ld      sp,ix
        pop     ix

        ;; callee cleanup: c(1), m(1), fpatt(2), fpatt_len(1), clip(2) = 7
        pop     de
        ld      hl,#7
        add     hl,sp
        ld      sp,hl
        push    de
        ret
