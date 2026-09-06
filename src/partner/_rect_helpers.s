        ;; _rect_helpers.s
        ;;
        ;; Signed 16-bit rectangle helpers:
        ;;  - __rect_cmp16s_lt
        ;;  - __rect_unpack_norm
        ;;
        ;; GPL2 License (see: LICENSE)
        ;; Copyright (C) 2026 Tomaz Stih
        ;;
        ;; 2026-03-30   TS

        .module _rect_helpers
        .optsdcc -mz80 sdcccall(1)

        .globl  __rect_cmp16s_lt
        .globl  __rect_unpack_norm

        .area   _CODE

        ;; ------------------------------------------------------------
        ;; __rect_cmp16s_lt
        ;; Arguments:
        ;;   HL = a
        ;;   DE = b
        ;;
        ;; Return:
        ;;   A = 1 when (a < b), else 0; Z reflects A, carry is clear
        ;;
        ;; Clobbers:
        ;;   AF
__rect_cmp16s_lt:
        ;; Signed subtraction: overflow flips the interpretation of bit 7.
        ;; Bytewise arithmetic leaves both operands available to the caller.
        ld      a,l
        sub     e
        ld      a,h
        sbc     a,d
        jp      po,.rc_sign
        xor     #0x80
.rc_sign:
        rlca
        and     #1
        ret

        ;; ------------------------------------------------------------
        ;; __rect_unpack_norm
        ;;
        ;; Unpack rect_t from DE into caller frame at HL (caller IX value):
        ;;   [-1..-2] x0, [-3..-4] x1, [-5..-6] y0, [-7..-8] y1
        ;; and normalize so x0<=x1 and y0<=y1.
        ;;
        ;; Arguments:
        ;;   DE = const rect_t *src
        ;;   HL = caller frame base (IX)
        ;;
        ;; Return:
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
        jr      z,.ru_x_ok

        ld      -1(ix),l                ; HL = x1, DE = x0, still intact
        ld      -2(ix),h
        ld      -3(ix),e
        ld      -4(ix),d

.ru_x_ok:
        ;; if (y1 < y0) swap
        ld      l,-7(ix)
        ld      h,-8(ix)
        ld      e,-5(ix)
        ld      d,-6(ix)
        call    __rect_cmp16s_lt
        jr      z,.ru_done

        ld      -5(ix),l                ; HL = y1, DE = y0, still intact
        ld      -6(ix),h
        ld      -7(ix),e
        ld      -8(ix),d

.ru_done:
        pop     ix
        ret
