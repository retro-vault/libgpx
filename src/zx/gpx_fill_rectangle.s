        ;; gpx_fill_rectangle.s
        ;;
        ;; Rectangle fill renderer:
        ;;  - normalizes rectangle coordinates
        ;;  - pattern is applied per row, MSB-first from x0
        ;;  - dispatches each row through fast __gpx_hline

        .module gpx_fill_rectangle
        .optsdcc -mz80 sdcccall(1)

        .globl  _gpx_fill_rectangle
        .globl  __gpx_hline_raw8
        .globl  __rect_unpack_norm
        .globl  __rect_cmp16s_lt

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

        ;; locals (18 bytes)
        ;; -1..-2   x0
        ;; -3..-4   x1
        ;; -5..-6   y0
        ;; -7..-8   y1
        ;; -9..-10  gpx
        ;; -11..-12 y0 original / ycur
        ;; -13      fpatt idx
        ;; -14..-15 fpatt ptr
        ;; -16      fpatt len
        ;; -17      row lpatt (LSB-first for __gpx_hline)
        ;; -18      x phase shift ((x0 clipped - x0 original) & 7)
        ld      hl,#-18
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

        ;; preserve original y0 for pattern-phase alignment
        ld      a,-5(ix)
        ld      -11(ix),a
        ld      a,-6(ix)
        ld      -12(ix),a
        ;; preserve original x0 low for x-phase alignment
        ld      a,-1(ix)
        ld      -18(ix),a

        ;; clamp X to screen first:
        ;;   [x0..x1] ∩ [0..(gpx->width - 1)]
        ;;
        ;; if (x1 < 0) return
        ld      l,-3(ix)
        ld      h,-4(ix)               ;; HL = x1
        ld      de,#0x0000             ;; DE = 0
        call    __rect_cmp16s_lt
        jp      nz,.fr_done

        ;; if ((gpx->width - 1) < x0) return
        ld      l,-9(ix)
        ld      h,-10(ix)              ;; HL = gpx
        ld      e,(hl)
        inc     hl
        ld      d,(hl)                 ;; DE = gpx->width
        dec     de                     ;; DE = gpx->width - 1
        push    de
        ld      l,e
        ld      h,d                    ;; HL = width-1
        ld      e,-1(ix)
        ld      d,-2(ix)               ;; DE = x0
        call    __rect_cmp16s_lt
        pop     de
        jp      nz,.fr_done

        ;; if (x0 < 0) x0 = 0
        ld      a,-2(ix)
        bit     7,a
        jr      z,.fr_no_screen_clip_left
        xor     a
        ld      -1(ix),a
        ld      -2(ix),a

.fr_no_screen_clip_left:
        ;; if ((gpx->width - 1) < x1) x1 = gpx->width - 1
        ld      l,-9(ix)
        ld      h,-10(ix)              ;; HL = gpx
        ld      e,(hl)
        inc     hl
        ld      d,(hl)                 ;; DE = gpx->width
        dec     de                     ;; DE = gpx->width - 1
        push    de
        ld      l,e
        ld      h,d                    ;; HL = width-1
        ld      e,-3(ix)
        ld      d,-4(ix)               ;; DE = x1
        call    __rect_cmp16s_lt
        pop     de
        jr      z,.fr_screen_clip_x_done
        ld      -3(ix),l
        ld      -4(ix),h

.fr_screen_clip_x_done:
        ;; clamp Y to screen:
        ;;   [y0..y1] ∩ [0..(gpx->height - 1)]
        ;;
        ;; if (y1 < 0) return
        ld      l,-7(ix)
        ld      h,-8(ix)               ;; HL = y1
        ld      de,#0x0000             ;; DE = 0
        call    __rect_cmp16s_lt
        jp      nz,.fr_done

        ;; if ((gpx->height - 1) < y0) return
        ld      l,-9(ix)
        ld      h,-10(ix)              ;; HL = gpx
        inc     hl
        inc     hl                     ;; &gpx->height
        ld      a,(hl)
        inc     hl
        ld      h,(hl)
        ld      l,a                    ;; HL = gpx->height
        dec     hl                     ;; HL = gpx->height - 1
        ld      e,-5(ix)
        ld      d,-6(ix)               ;; DE = y0
        call    __rect_cmp16s_lt
        jp      nz,.fr_done

        ;; if (y0 < 0) y0 = 0
        ld      a,-6(ix)
        bit     7,a
        jr      z,.fr_no_screen_clip_top
        xor     a
        ld      -5(ix),a
        ld      -6(ix),a

.fr_no_screen_clip_top:
        ;; if ((gpx->height - 1) < y1) y1 = gpx->height - 1
        ld      l,-9(ix)
        ld      h,-10(ix)              ;; HL = gpx
        inc     hl
        inc     hl                     ;; &gpx->height
        ld      a,(hl)
        inc     hl
        ld      h,(hl)
        ld      l,a                    ;; HL = gpx->height
        dec     hl                     ;; HL = gpx->height - 1
        ld      e,-7(ix)
        ld      d,-8(ix)               ;; DE = y1
        call    __rect_cmp16s_lt
        jr      z,.fr_screen_clip_done
        ld      -7(ix),l
        ld      -8(ix),h

.fr_screen_clip_done:
        ;; optional clip visible range once:
        ;;   [x0..x1] ∩ [clip->x0..clip->x1]
        ;;   [y0..y1] ∩ [clip->y0..clip->y1]
        ld      a,9(ix)
        or      10(ix)
        jp      z,.fr_phase_setup

        ;; if (x1 < clip->x0) return
        ld      l,-3(ix)
        ld      h,-4(ix)               ;; HL = x1
        push    hl
        ld      l,9(ix)
        ld      h,10(ix)               ;; HL = &clip->x0
        ld      e,(hl)
        inc     hl
        ld      d,(hl)                 ;; DE = clip->x0
        pop     hl                     ;; HL = x1
        call    __rect_cmp16s_lt
        jp      nz,.fr_done

        ;; if (clip->x1 < x0) return
        ld      l,9(ix)
        ld      h,10(ix)
        ld      de,#4
        add     hl,de                  ;; &clip->x1
        ld      a,(hl)
        inc     hl
        ld      h,(hl)
        ld      l,a                    ;; HL = clip->x1
        ld      e,-1(ix)
        ld      d,-2(ix)               ;; DE = x0
        call    __rect_cmp16s_lt
        jp      nz,.fr_done

        ;; if (x0 < clip->x0) x0 = clip->x0
        ld      l,-1(ix)
        ld      h,-2(ix)               ;; HL = x0
        ld      e,9(ix)
        ld      d,10(ix)
        ex      de,hl                  ;; HL = clip ptr, DE = x0
        ld      a,(hl)
        inc     hl
        ld      h,(hl)
        ld      l,a                    ;; HL = clip->x0
        ex      de,hl                  ;; HL = x0, DE = clip->x0
        call    __rect_cmp16s_lt
        jr      z,.fr_no_clip_left
        ld      -1(ix),e
        ld      -2(ix),d

.fr_no_clip_left:
        ;; if (clip->x1 < x1) x1 = clip->x1
        ld      l,9(ix)
        ld      h,10(ix)
        ld      de,#4
        add     hl,de                  ;; &clip->x1
        ld      a,(hl)
        inc     hl
        ld      h,(hl)
        ld      l,a                    ;; HL = clip->x1
        ld      e,-3(ix)
        ld      d,-4(ix)               ;; DE = x1
        call    __rect_cmp16s_lt
        jr      z,.fr_clip_y_range
        ld      -3(ix),l
        ld      -4(ix),h

.fr_clip_y_range:
        ;; if (y1 < clip->y0) return
        ld      l,-7(ix)
        ld      h,-8(ix)
        ld      e,9(ix)
        ld      d,10(ix)
        ex      de,hl
        inc     hl
        inc     hl
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ex      de,hl
        call    __rect_cmp16s_lt
        jp      nz,.fr_done

        ;; if (clip->y1 < y0) return
        ld      l,9(ix)
        ld      h,10(ix)
        ld      de,#6
        add     hl,de
        ld      a,(hl)
        inc     hl
        ld      h,(hl)
        ld      l,a
        ld      e,-5(ix)
        ld      d,-6(ix)
        call    __rect_cmp16s_lt
        jp      nz,.fr_done

        ;; if (y0 < clip->y0) y0 = clip->y0
        ld      l,-5(ix)
        ld      h,-6(ix)
        ld      e,9(ix)
        ld      d,10(ix)
        ex      de,hl
        inc     hl
        inc     hl
        ld      a,(hl)
        inc     hl
        ld      h,(hl)
        ld      l,a
        ex      de,hl
        call    __rect_cmp16s_lt
        jr      z,.fr_no_clip_top
        ld      -5(ix),e
        ld      -6(ix),d

.fr_no_clip_top:
        ;; if (clip->y1 < y1) y1 = clip->y1
        ld      l,9(ix)
        ld      h,10(ix)
        ld      de,#6
        add     hl,de
        ld      a,(hl)
        inc     hl
        ld      h,(hl)
        ld      l,a
        ld      e,-7(ix)
        ld      d,-8(ix)
        call    __rect_cmp16s_lt
        jr      z,.fr_phase_setup
        ld      -7(ix),l
        ld      -8(ix),h

.fr_phase_setup:
        ;; x phase shift = (x0_clipped - x0_original) & 7
        ld      a,-1(ix)
        sub     -18(ix)
        and     #0x07
        ld      -18(ix),a

.fr_idx_setup:
        ;; idx = (y0_clipped - y0_original) % fpatt_len
        ld      l,-5(ix)
        ld      h,-6(ix)
        ld      e,-11(ix)
        ld      d,-12(ix)
        xor     a
        sbc     hl,de
.fr_idx_mod:
        ld      a,h
        or      a
        jr      nz,.fr_idx_sub
        ld      a,l
        cp      -16(ix)
        jr      c,.fr_idx_done
.fr_idx_sub:
        ld      a,l
        sub     -16(ix)
        ld      l,a
        ld      a,h
        sbc     a,#0x00
        ld      h,a
        jr      .fr_idx_mod
.fr_idx_done:
        ld      a,l
        ld      -13(ix),a

        ;; start from first visible row
        ld      a,-5(ix)
        ld      -11(ix),a
        ld      a,-6(ix)
        ld      -12(ix),a

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

        ;; apply x phase once-clipped: lpatt = ror(lpatt, xshift)
        ld      a,-18(ix)
        or      a
        jr      z,.fr_row_patt_ready
        ld      b,a
        ld      a,-17(ix)
.fr_row_rot_loop:
        rrca
        djnz    .fr_row_rot_loop
        ld      -17(ix),a

.fr_row_patt_ready:
        ;; __gpx_hline_raw8(gpx, x0, ycur, x1, ycur, c, m, row_lpatt, clip)
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
        call    __gpx_hline_raw8

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
