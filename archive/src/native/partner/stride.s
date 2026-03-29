        ;; stride.s
        ;; 
        ;; Draw stride.
		;;
        ;; MIT License (see: LICENSE)
        ;; Copyright (C) 2021 Tomaz Stih
        ;;
		;; 13.08.2021   tstih
        .module stride

        .globl  __stridexy

        .area   _CODE

        ;; -------------------
        ;; void _stridexy(
        ;;      coord x, 
        ;;      coord y, 
        ;;      void *data, 
        ;;      uint8_t start, 
        ;;      uint8_t end)
        ;; -------------------
        ;; draw stride (scan line) at x,y, left to right,
        ;; starting with bit start and ending with bit end
        ;; affects: just about everything
__stridexy::
        pop     bc                      ; return address
        pop     hl                      ; hl=x
        pop     de                      ; de=y
        exx
        pop     hl                      ; hl'=data
        pop     de                      ; e'-start, d'-end
        ;; restore stack
        push    de
        push    hl
        exx
        push    de
        push    hl
        push    bc
        ;; goto x,y
        call    ef9367_xy
        exx
        ;; now hl=data, e=start, d=end
        call    __ef9367_stride
        ret