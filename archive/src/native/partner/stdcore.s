        ;; stdcore.s
        ;; 
        ;; standard library FAST and TINY replacements
		;;
        ;; MIT License (see: LICENSE)
        ;; Copyright (C) 2021 Tomaz Stih
        ;;
		;; 08.09.2021   tstih
        .module std

        .globl  __memcpy

        .area   _CODE

        ;; ------------------------------------------------------
		;; void _memcpy (void* dst, void* src, unsigned int num);
        ;; ------------------------------------------------------
        ;; copy memory block
        ;; affect:  bc, de, hl, hl'
__memcpy::
        exx                             ; alt set for ret. addr
        pop     hl                      ; return address
        exx		
        pop     de                      ; de=dest
        pop     hl                      ; hl=src
        pop     bc                      ; bc=count
        push    bc
        push    hl
        push    de
        exx
        push    hl
        exx		
        ;; stack is restored
        ldir
        ret