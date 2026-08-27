        ;; _rect_helpers.s
        ;;
        ;; Minimal signed 16-bit compare helper.
        ;;
        ;; GPL2 License (see: LICENSE)
        ;; Copyright (C) 2026 Tomaz Stih
        ;;
        ;; 2026-08-25   TS

        .module _rect_helpers
        .optsdcc -mz80 sdcccall(1)

        .include "_cpc-defs.inc"

        .globl  __rect_cmp16s_lt
        .globl  __rect_unpack_norm
        .globl  __clip_seg
        .globl  __rect_screen
        .globl  __ret_clean11

        .area   _CODE

        ;; ------------------------------------------------------------
        ;; __ret_clean11
        ;;
        ;; Shared callee-cleanup tail for the line-family entry points
        ;; (draw_line/hline/vline/bresenham all clean 11 stack bytes).
        ;; Enter via jp with the return value in A and the caller frame
        ;; already unwound to [ret][args]. Clobbers DE/HL.
        ;; ------------------------------------------------------------
__ret_clean11:
        pop     de                      ; return address
        ld      hl,#11
        add     hl,sp
        ld      sp,hl
        push    de
        ret

        ;; ------------------------------------------------------------
        ;; __rect_screen
        ;;
        ;; The whole display as a rect_t, so a screen clamp is just another
        ;; __clip_seg pass instead of open-coded 16-bit compares in every
        ;; primitive. x1 depends on the display mode, so this lives in RAM
        ;; and gpx_create fills it in.
        ;; ------------------------------------------------------------
        .area   _DATA
__rect_screen::
        .dw     0
        .dw     0
        .dw     (CPC_W_640 - 1)
        .dw     (CPC_HEIGHT - 1)

        .area   _CODE

        ;; ------------------------------------------------------------
        ;; __clip_seg
        ;;
        ;; 1-D segment clip against one clip-rect axis (primary axis):
        ;;   reject if (clip_hi < seg_lo) || (seg_hi < clip_lo)
        ;;   else clamp seg_lo = max(seg_lo, clip_lo),
        ;;             seg_hi = min(seg_hi, clip_hi)
        ;;   reject if the clamp inverted the span (swapped clip rect)
        ;;
        ;; Pure register I/O so any caller's local layout works:
        ;;   IN:  HL = seg_lo, DE = seg_hi
        ;;        IY = &clip primary-axis lo field (hi field is at IY+4,
        ;;             which holds for both x0/x1 and y0/y1 in rect_t).
        ;;   OUT: HL = clamped seg_lo, DE = clamped seg_hi
        ;;        CARRY set  => reject (segment outside clip on this axis)
        ;;        CARRY clear => keep (HL/DE updated)
        ;;
        ;; Relies on __rect_cmp16s_lt preserving BC/DE/HL (only A changes).
        ;; Preserves IX and IY; uses A, BC, DE, HL and one stack slot.
        ;; ------------------------------------------------------------
__clip_seg:
        ;; Clamp both ends, then reject if the clamp inverted the span. That
        ;; single test subsumes the two early rejects this used to do: if
        ;; seg_hi < clip_lo or clip_hi < seg_lo, the clamped span is inverted
        ;; by construction. Five signed compares become three.
        ld      b,h
        ld      c,l                     ; BC = seg_lo
        push    de                      ; stack: [seg_hi]

        ;; seg_lo = max(seg_lo, clip_lo)
        ld      e,0(iy)
        ld      d,1(iy)                 ; DE = clip_lo, HL = seg_lo
        call    __rect_cmp16s_lt
        jr      nc,.cs_lo_ok
        ld      c,e
        ld      b,d                     ; seg_lo = clip_lo
.cs_lo_ok:
        pop     de                      ; DE = seg_hi

        ;; seg_hi = min(seg_hi, clip_hi)
        ld      l,4(iy)
        ld      h,5(iy)                 ; HL = clip_hi
        call    __rect_cmp16s_lt        ; clip_hi < seg_hi ?
        jr      nc,.cs_hi_ok
        ld      e,l
        ld      d,h                     ; seg_hi = clip_hi
.cs_hi_ok:

        ;; inverted span => nothing visible on this axis
        ld      l,e
        ld      h,d                     ; HL = seg_hi
        ld      e,c
        ld      d,b                     ; DE = seg_lo
        call    __rect_cmp16s_lt        ; seg_hi < seg_lo ?
        ex      de,hl                   ; HL = seg_lo, DE = seg_hi
        ret     c                       ; carry already set => reject
        or      a                       ; carry clear => keep
        ret


        ;; uint8_t _rect_cmp16s_lt(coord a, coord b)
        ;;   HL = a
        ;;   DE = b
        ;; returns A=1 when (a < b), else A=0
__rect_cmp16s_lt:
        ;; CARRY set when HL < DE (signed), clear otherwise. Clobbers A only;
        ;; BC, DE and HL are preserved. Callers branch on carry directly, so
        ;; none of them pays an `or a` to test a 0/1 return any more.
        ;;
        ;; Both operands are on-screen coordinates most of the time, so the
        ;; high bytes are both zero and a plain 8-bit compare answers it.
        ld      a,h
        or      d
        jr      nz,.rc_wide
        ld      a,l
        cp      e
        ret

.rc_wide:
        ld      a,h
        xor     d
        jp      m,.rc_diff              ; signs differ
        ld      a,h
        cp      d
        ret     nz                      ; carry = (hi < hi)
        ld      a,l
        cp      e
        ret                             ; carry = (lo < lo)

.rc_diff:
        ;; different signs: the negative one is the smaller
        ld      a,h
        rlca                            ; carry = sign bit of HL
        ret

        ;; ------------------------------------------------------------
        ;; __rect_unpack_norm
        ;;
        ;; Unpack rect_t from DE into caller frame at HL (caller IX value)
        ;; using caller-local layout:
        ;;   [-1..-2] x0, [-3..-4] x1, [-5..-6] y0, [-7..-8] y1
        ;; and normalize endpoints so x0<=x1 and y0<=y1.
        ;;
        ;;   DE = const rect_t *src (x0,y0,x1,y1 in struct order)
        ;;   HL = caller frame base (IX)
        ;; ------------------------------------------------------------
__rect_unpack_norm:
        push    ix
        push    hl
        pop     ix

        ;; x0
        ld      a,(de)
        ld      -1(ix),a
        inc     de
        ld      a,(de)
        ld      -2(ix),a
        inc     de

        ;; y0 -> [-5..-6]
        ld      a,(de)
        ld      -5(ix),a
        inc     de
        ld      a,(de)
        ld      -6(ix),a
        inc     de

        ;; x1 -> [-3..-4]
        ld      a,(de)
        ld      -3(ix),a
        inc     de
        ld      a,(de)
        ld      -4(ix),a
        inc     de

        ;; y1 -> [-7..-8]
        ld      a,(de)
        ld      -7(ix),a
        inc     de
        ld      a,(de)
        ld      -8(ix),a

        ;; if (x1 < x0) swap
        ld      l,-3(ix)
        ld      h,-4(ix)
        ld      e,-1(ix)
        ld      d,-2(ix)
        call    __rect_cmp16s_lt
        jr      nc,.ru_x_ok

        ld      c,-1(ix)
        ld      b,-2(ix)
        ld      a,-3(ix)
        ld      -1(ix),a
        ld      a,-4(ix)
        ld      -2(ix),a
        ld      a,c
        ld      -3(ix),a
        ld      a,b
        ld      -4(ix),a

.ru_x_ok:
        ;; if (y1 < y0) swap
        ld      l,-7(ix)
        ld      h,-8(ix)
        ld      e,-5(ix)
        ld      d,-6(ix)
        call    __rect_cmp16s_lt
        jr      nc,.ru_done

        ld      c,-5(ix)
        ld      b,-6(ix)
        ld      a,-7(ix)
        ld      -5(ix),a
        ld      a,-8(ix)
        ld      -6(ix),a
        ld      a,c
        ld      -7(ix),a
        ld      a,b
        ld      -8(ix),a

.ru_done:
        pop     ix
        ret
