        ;; plot.s
        ;; 
        ;; fast pixel on speccy
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
        pop     hl		                ; return address
        pop     bc                      ; bc=x (c=x)
        pop     de                      ; de=y (e=y)
        ld      b,e                     ; b=y, c=x
        ;; restore stack
        push    de
        push    bc
        push    hl
        call    vid_rowaddr             ; hl=row address, a=l
        ld      b,c                     ; store x to b
        srl     c                       ; x=x/8 (byte offset)
        srl     c
        srl     c	
        add     c                       ; l=l+c, we know this wont overflow
        ld      l,a                     ; hl has the correct byte for x		
        ld      a,b                     ; return x to acc
        and     #0x07                   ; get bottom 3 bits
        jr      nz,plot_shift           ; if 0 we dont shift
        ld      a,#0x80                 ; a=0b10000000
        jr      plot_shift_done
plot_shift:		
        ld      b,a                     ; b=counter
        ld      a,#0x80                 ; a=0b10000000
plot_loop:
        srl	a
        djnz    plot_loop
plot_shift_done:
        ld      d,a                     ; store a
        or      (hl)                    ; merge bit with background
        ;; a has the pattern,
        ;; hl is the correct address
        ld      (hl),a
        ld      a,d                     ; restore a
        ret