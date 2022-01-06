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
        ;; affects: everything
__tinyxy::
        exx                             ; alt set ON
        pop     bc                      ; bc'=return address
        pop     hl                      ; hl'=x
        pop     de                      ; de'=y
        exx                             ; alt set OFF
        pop     hl                      ; hl=moves
        pop     de                      ; d=clip low, e=num moves
        pop     bc                      ; c=clip high
        ;; clip ptr to bc.
        ld      b,c
        ld      c,d
        ;; restore stack
        push    bc
        push    de
        push    hl
        exx                             ; alt set ON
        push    de
        push    hl
        push    bc
        exx                             ; alt set OFF
        ;; check no. of moves.
        ;; contract: it will always be either 0 or larger than 2.
        ld      a,e                     ; number of moves to a
        cp      #0                      ; none?
        ret     z                       ; return.
        dec     e                       ; reduce number of moves by 2.
        dec     e                       ; for x and y origin!
        ;; now move to initial position, which is 
        ;; at x + dx, and y + dy. initial dx and dy
        ;; are bytes 0 and 1 of moves.
        ld      a,(hl)                  ; move 0 (dx) to a
        inc     hl                      ; next move
        exx                             ; alt set ON
        push    de                      ; store y
        ld      d,#0                    ; de=dx
        ld      e,a 
        add     hl,de                   ; x = x + dx
        pop     de                      ; de = y
        exx                             ; alt set OFF
        ld      a,(hl)                  ; dy to a
        inc     hl                      ; next move
        exx                             ; alt set ON
        push    hl                      ; store x
        ex      de,hl                   ; hl=y
        ld      d,#0
        ld      e,a                     ; de=dy
        add     hl,de                   ; hl=y+dy
        ex      de,hl                   ; de=y
        pop     hl                      ; hl=x
        call    ef9367_xy
        ;; get original coords back to alt regs.
        pop     bc
        pop     hl
        pop     de
        push    de
        push    hl
        push    bc
        exx                             ; alt set OFF
        ;; now hl=moves, e=number of moves, bc=clip ptr.
        call    __ef9367_tiny
        ret