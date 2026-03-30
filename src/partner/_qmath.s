        ;; _qmath.s
        ;;
        ;; Quick integer math helpers.

        .module _qmath
        .optsdcc -mz80 sdcccall(1)

        .globl  __abs_hl

        .area   _CODE

        ;; ------------------------------------------------------------
        ;; __abs_hl
        ;; Compute absolute value of signed 16-bit HL.
        ;;
        ;; Input:
        ;;   HL = value
        ;;
        ;; Output:
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
