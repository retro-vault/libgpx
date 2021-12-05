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
        ;;    uint8_t num,
        ;;    tiny_clip_t *clip);
        ;; -------------------
        ;; draw tiny moves at x,y, 
        ;; affects: just about everything
__tinyxy::
        pop     bc                      ; return address
        pop     hl                      ; hl=x
        pop     de                      ; de=y
        exx
        pop     hl                      ; hl'=moves
        pop     de                      ; d'=clip low, e'=num moves
        pop     bc                      ; c'=clip high
        ;; clip ptr to bc'.
        ld      b,c
        ld      c,d
        ;; restore stack
        push    bc
        push    de
        push    hl
        exx
        push    de
        push    hl
        push    bc
        ;; goto x,y
        call    ef9367_xy
        exx
        ;; now hl=moves, e=number of moves, bc=clip ptr.
        call    __ef9367_tiny
        exx
        ret