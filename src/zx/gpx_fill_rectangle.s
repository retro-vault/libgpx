        ;; gpx_fill_rectangle.s
        ;;
        ;; Rectangle fill renderer (strict semantic path):
        ;;  - normalizes rectangle coordinates
        ;;  - pattern is applied per row, MSB-first from x0
        ;;  - clipping is delegated to gpx_draw_pixel

        .module gpx_fill_rectangle
        .optsdcc -mz80 sdcccall(1)

        .globl  _gpx_fill_rectangle
        .globl  _gpx_draw_pixel
        .globl  __rect_cmp16s_lt
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

        ;; locals (20 bytes)
        ;; -1..-2   x0
        ;; -3..-4   x1
        ;; -5..-6   y0
        ;; -7..-8   y1
        ;; -9..-10  gpx
        ;; -11..-12 xcur
        ;; -13..-14 ycur
        ;; -15      fpatt idx
        ;; -16..-17 fpatt ptr
        ;; -18      fpatt len
        ;; -19      row pattern
        ;; -20      row mask
        ld      hl,#-20
        add     hl,sp
        ld      sp,hl

        ;; save gpx
        ld      -9(ix),l
        ld      -10(ix),h

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
        ld      -16(ix),a
        ld      a,7(ix)
        ld      -17(ix),a
        ld      a,8(ix)
        ld      -18(ix),a

        ;; unpack + normalize rect into locals
        push    ix
        pop     hl
        call    __rect_unpack_norm

        ;; ycur = y0, idx = 0
        ld      a,-5(ix)
        ld      -13(ix),a
        ld      a,-6(ix)
        ld      -14(ix),a
        xor     a
        ld      -15(ix),a

.fr_row_loop:
        ;; row pattern = fpatt[idx]
        ld      l,-16(ix)
        ld      h,-17(ix)
        ld      e,-15(ix)
        ld      d,#0x00
        add     hl,de
        ld      a,(hl)
        ld      -19(ix),a

        ;; xcur = x0, mask = 0x80
        ld      a,-1(ix)
        ld      -11(ix),a
        ld      a,-2(ix)
        ld      -12(ix),a
        ld      a,#0x80
        ld      -20(ix),a

.fr_col_loop:
        ;; if (row_pattern & mask) draw pixel
        ld      a,-19(ix)
        and     -20(ix)
        jr      z,.fr_skip_pixel

        ld      l,9(ix)
        ld      h,10(ix)
        push    hl                     ;; clip

        ld      l,4(ix)
        ld      h,5(ix)
        push    hl                     ;; c,m

        ld      l,-13(ix)
        ld      h,-14(ix)
        push    hl                     ;; y

        ld      l,-9(ix)
        ld      h,-10(ix)
        ld      e,-11(ix)
        ld      d,-12(ix)
        call    _gpx_draw_pixel

.fr_skip_pixel:
        ;; end of row when xcur == x1
        ld      a,-11(ix)
        cp      -3(ix)
        jr      nz,.fr_step_x
        ld      a,-12(ix)
        cp      -4(ix)
        jr      z,.fr_row_done

.fr_step_x:
        ;; xcur++
        ld      l,-11(ix)
        ld      h,-12(ix)
        inc     hl
        ld      -11(ix),l
        ld      -12(ix),h

        ;; mask >>= 1 ; wrap to 0x80
        ld      a,-20(ix)
        srl     a
        jr      nz,.fr_store_mask
        ld      a,#0x80
.fr_store_mask:
        ld      -20(ix),a

        jp      .fr_col_loop

.fr_row_done:
        ;; if (ycur == y1) complete
        ld      a,-13(ix)
        cp      -7(ix)
        jr      nz,.fr_next_row
        ld      a,-14(ix)
        cp      -8(ix)
        jr      z,.fr_done

.fr_next_row:
        ;; ycur++
        ld      l,-13(ix)
        ld      h,-14(ix)
        inc     hl
        ld      -13(ix),l
        ld      -14(ix),h

        ;; idx = (idx + 1) % fpatt_len
        ld      a,-15(ix)
        inc     a
        cp      -18(ix)
        jr      c,.fr_store_idx
        xor     a
.fr_store_idx:
        ld      -15(ix),a

        jp      .fr_row_loop

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
