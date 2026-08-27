        ;; _qmath.s
        ;;
        ;; Quick integer math helpers.
        ;;
        ;; GPL2 License (see: LICENSE)
        ;; Copyright (C) 2026 Tomaz Stih
        ;;
        ;; 2026-03-30   TS

        .module _qmath
        .optsdcc -mz80 sdcccall(1)

        .globl  __abs_hl

        .area   _CODE

        ;; ------------------------------------------------------------
        ;; __abs_hl
        ;; Compute absolute value of signed 16-bit HL.
        ;;
        ;; Arguments:
        ;;   HL = value
        ;;
        ;; Return:
        ;;   HL = abs(value)
        ;;
        ;; Clobbers:
        ;;   AF, HL
__abs_hl:
        bit     7,h
        ret     z
        xor     a
        sub     l
        ld      l,a
        sbc     a,a
        sub     h
        ld      h,a
        ret
