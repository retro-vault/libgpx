        ;; line.s
        ;; 
        ;; line drawing primitives
		;;
        ;; MIT License (see: LICENSE)
        ;; Copyright (C) 2021 Tomaz Stih
        ;;
		;; 2021-09-27   tstih
        .module line

        .globl  __hline
        .globl  __vline
        .globl  __line

        .area   _CODE

        ;; ----------------------------------------
        ;; void _hline(coord x0, coord x1, coord y)
        ;; ----------------------------------------
        ;; fast horizontal line drawing
__hline::
        pop     hl                      ; return address
        exx
        pop     hl                      ; hl'=x0
        pop     bc                      ; bc'=x1
        pop     de                      ; de'=y
        ;; restore stack
        push    de
        push    bc
        push    hl
        exx
        push    hl
        exx
        ;; goto x,y (hl=x, de=y)
        push    hl                      ; store x0
        push    bc                      ; store x1
        call    ef9367_xy
        pop     hl                      ; restore x1
        pop     de                      ; restore x0
        ;; and draw deltas
        or      a                       ; clera carry
        sbc     hl,de                   ; line length to hl
        call    __ef9367_hline
        ;; game over
        exx
        ret

        ;; ----------------------------------------
        ;; void _vline(coord x, coord y0, coord y1)
        ;; ----------------------------------------
        ;; fast horizontal line drawing
__vline::
        pop     hl                      ; return address
        exx
        pop     hl                      ; hl'=x
        pop     de                      ; de'=y0
        pop     bc                      ; bc'=y1
        ;; restore stack
        push    bc
        push    de
        push    hl
        exx
        push    hl
        exx
        ;; goto x,y (hl=x, de=y)
        push    de                      ; store y0
        push    bc                      ; store y1
        call    ef9367_xy
        pop     hl                      ; restore y1
        pop     de                      ; restore y0
        ;; and draw deltas
        or      a                       ; clear carry
        sbc     hl,de                   ; line length to hl
        call    __ef9367_vline
        ;; game over
        exx
        ret

        ;; --------------------------------------------------
        ;; void _line(coord x0, coord y0, coord x1, coord y1)
        ;; --------------------------------------------------
        ;; draw line, just rewire to hardware function, it will
        ;; pick arguments and return to original caller
__line::
        jp      __ef9367_draw_line