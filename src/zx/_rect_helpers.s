        ;; _rect_helpers.s
        ;;
        ;; Minimal signed 16-bit compare helper.

        .module _rect_helpers
        .optsdcc -mz80 sdcccall(1)

        .globl  __rect_cmp16s_lt
        .globl  __rect_unpack_norm
        .globl  __clip_seg

        .area   _CODE

        ;; ------------------------------------------------------------
        ;; __clip_seg
        ;;
        ;; 1-D segment clip against one clip-rect axis (primary axis):
        ;;   reject if (clip_hi < seg_lo) || (seg_hi < clip_lo)
        ;;   else clamp seg_lo = max(seg_lo, clip_lo),
        ;;             seg_hi = min(seg_hi, clip_hi)
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
        ld      b,h
        ld      c,l                    ;; BC = seg_lo (survives cmp calls)
        push    de                     ;; stack: [seg_hi]

        ;; reject if seg_hi < clip_lo
        ex      de,hl                  ;; HL = seg_hi
        ld      e,0(iy)
        ld      d,1(iy)                ;; DE = clip_lo
        call    __rect_cmp16s_lt
        or      a
        jr      nz,.cs_reject

        ;; reject if clip_hi < seg_lo
        ld      l,4(iy)
        ld      h,5(iy)                ;; HL = clip_hi
        ld      e,c
        ld      d,b                    ;; DE = seg_lo
        call    __rect_cmp16s_lt
        or      a
        jr      nz,.cs_reject

        ;; clamp: if seg_lo < clip_lo -> seg_lo = clip_lo
        ld      l,c
        ld      h,b                    ;; HL = seg_lo
        ld      e,0(iy)
        ld      d,1(iy)                ;; DE = clip_lo
        call    __rect_cmp16s_lt
        or      a
        jr      z,.cs_lo_ok
        ld      c,0(iy)
        ld      b,1(iy)                ;; seg_lo = clip_lo
.cs_lo_ok:

        ;; clamp: if clip_hi < seg_hi -> seg_hi = clip_hi
        pop     hl                     ;; HL = seg_hi (stack balanced)
        ld      e,l
        ld      d,h                    ;; DE = seg_hi
        ld      l,4(iy)
        ld      h,5(iy)                ;; HL = clip_hi
        call    __rect_cmp16s_lt
        or      a
        jr      z,.cs_hi_ok
        ld      e,4(iy)
        ld      d,5(iy)                ;; seg_hi = clip_hi
.cs_hi_ok:
        ld      l,c
        ld      h,b                    ;; HL = seg_lo
        or      a                      ;; carry clear => keep
        ret

.cs_reject:
        pop     de                     ;; discard saved seg_hi (balance push)
        scf                            ;; carry set => reject
        ret

        ;; uint8_t _rect_cmp16s_lt(coord a, coord b)
        ;;   HL = a
        ;;   DE = b
        ;; returns A=1 when (a < b), else A=0
__rect_cmp16s_lt:
        ld      a,h
        xor     d
        jp      p,.rc_same_sign

        ;; different signs: negative is smaller
        bit     7,h
        jr      z,.rc_false
        ld      a,#1
        ret

.rc_same_sign:
        ld      a,h
        cp      d
        jr      c,.rc_true
        jr      nz,.rc_false
        ld      a,l
        cp      e
        jr      c,.rc_true

.rc_false:
        xor     a
        ret

.rc_true:
        ld      a,#1
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
        or      a
        jr      z,.ru_x_ok

        ld      a,-1(ix)
        ld      c,a
        ld      a,-2(ix)
        ld      b,a
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
        or      a
        jr      z,.ru_done

        ld      a,-5(ix)
        ld      c,a
        ld      a,-6(ix)
        ld      b,a
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
