        ;; plot.s
        ;; 
        ;; not so fast pixel on partner
		;;
        ;; MIT License (see: LICENSE)
        ;; Copyright (C) 2021 Tomaz Stih
        ;;
		;; 2021-08-09   tstih
        .module plot

        .globl  __plotxy

        .area   _CODE

        ;; ------------------------------
        ;; void _plotxy(coord x, coord y)
        ;; ------------------------------
        ;; fast on-screen pixel 
__plotxy::
        pop     bc                      ; return address
        pop     hl                      ; hl=x
        pop     de                      ; de=y
        ;; restore stack
        push    de
        push    hl
        push    bc
        ;; goto x,y
        call    ef9367_xy
        ;; and draw pixel
        call    __ef9367_put_pixel
        ret