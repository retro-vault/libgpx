        ;; tiny.s
        ;; 
        ;; Draw tiny.
		;;
        ;; MIT License (see: LICENSE)
        ;; Copyright (C) 2021 Tomaz Stih
        ;;
		;; 13.08.2021   tstih
        .module tiny

        .globl  __tinyxy

        .area   _CODE

        ;; -------------------
        ;; extern void _tinyxy(
        ;;    coord x, 
        ;;    coord y, 
        ;;    uint8_t *moves,
        ;;    uint8_t num);
        ;; -------------------
        ;; draw tiny moves at x,y, 
        ;; affects: just about everything
__tinyxy::
        pop     bc                      ; return address
        pop     hl                      ; hl=x
        pop     de                      ; de=y
        exx
        pop     hl                      ; hl'=moves
        pop     de                      ; e'=num
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
        ;; now hl=moves, e=number of omves
        call    __ef9367_tiny
        exx
        ret