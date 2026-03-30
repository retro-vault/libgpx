        ;; _rect_helpers.s
        ;;
        ;; Signed 16-bit rectangle helpers:
        ;;  - __rect_cmp16s_lt
        ;;  - __rect_unpack_norm

        .module _rect_helpers
        .optsdcc -mz80 sdcccall(1)

        .globl  __rect_cmp16s_lt
        .globl  __rect_unpack_norm

        .area   _CODE

        ;; ------------------------------------------------------------
        ;; __rect_cmp16s_lt
        ;; Input:
        ;;   HL = a
        ;;   DE = b
        ;;
        ;; Output:
        ;;   A = 1 when (a < b), else 0
        ;;
        ;; Clobbers:
        ;;   AF
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
        ;; Unpack rect_t from DE into caller frame at HL (caller IX value):
        ;;   [-1..-2] x0, [-3..-4] x1, [-5..-6] y0, [-7..-8] y1
        ;; and normalize so x0<=x1 and y0<=y1.
        ;;
        ;; Input:
        ;;   DE = const rect_t *src
        ;;   HL = caller frame base (IX)
        ;;
        ;; Output:
        ;;   normalized rectangle written to caller frame
        ;;
        ;; Clobbers:
        ;;   AF, BC, DE, HL, IX
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

        ;; y0
        ld      a,(de)
        ld      -5(ix),a
        inc     de
        ld      a,(de)
        ld      -6(ix),a
        inc     de

        ;; x1
        ld      a,(de)
        ld      -3(ix),a
        inc     de
        ld      a,(de)
        ld      -4(ix),a
        inc     de

        ;; y1
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
