        ;; crt0.s
        ;;
        ;; Minimal ZX Spectrum startup for the demo1 sample.
        ;;
        ;; Linked first with _CODE at 0x8000. Saves every register, opens
        ;; channel 2 so ROM text output works, copies the C initializers,
        ;; runs main(), then restores and returns to BASIC. Also supplies
        ;; putchar/getchar on top of the ROM routines.
        ;;
        ;; GPL2 License (see: LICENSE)
        ;; Copyright (C) 2026 Tomaz Stih
        ;;
        ;; 2026-08-25   TS

        .module crt0
        .globl  _main
        .globl  _putchar
        .globl  _getchar
        .globl  s__INITIALIZED
        .globl  s__INITIALIZER
        .globl  l__INITIALIZER

        .area   _CODE

        ld      (#__store_sp),sp
        ld      sp,#__stack

        push    af
        push    bc
        push    de
        push    hl
        push    ix
        push    iy
        ex      af, af'
        push    af
        exx
        push    bc
        push    de
        push    hl

        ld      iy,#0x5c3a
        ld      a,#2
        call    0x1601

        call    .gsinit

        call    _main

        pop     hl
        pop     de
        pop     bc
        pop     af
        exx
        ex      af,af'
        pop     iy
        pop     ix
        pop     hl
        pop     de
        pop     bc
        pop     af

        ld      sp,(#__store_sp)
        ret

        ;; ------------------------------------------------------------
        ;; _putchar
        ;; Write one character through the ROM's channel 2 print routine,
        ;; translating LF to the CR the ROM expects.
        ;;
        ;; Signature:
        ;;   int putchar(int c)
        ;;
        ;; Arguments:
        ;;   L = character
        ;;
        ;; Return:
        ;;   HL = the character written
        ;;
        ;; Clobbers:
        ;;   AF, HL
_putchar::
        ld      a,l
        cp      #0x0a
        jr      nz, .putchar_emit
        ld      a,#0x0d
.putchar_emit:
        push    iy
        ld      iy,#0x5c3a
        rst     0x10
        pop     iy
        ld      l,a
        ld      h,#0x00
        ret

        ;; ------------------------------------------------------------
        ;; _getchar
        ;; Read one character through the ROM's keyboard routine,
        ;; translating the CR it returns into LF.
        ;;
        ;; Signature:
        ;;   int getchar(void)
        ;;
        ;; Return:
        ;;   HL = the character read
        ;;
        ;; Clobbers:
        ;;   AF, HL
_getchar::
        push    iy
        ld      iy,#0x5c3a
        call    0x15e6
        pop     iy
        cp      #0x0d
        jr      nz, .getchar_done
        ld      a,#0x0a
.getchar_done:
        ld      l,a
        ld      h,#0x00
        ret

        .area   _GSINIT
        .area   _GSFINAL
        .area   _HOME
        .area   _INITIALIZER
        .area   _INITFINAL
        .area   _INITIALIZED
        .area   _DATA
        .area   _BSS

        .area _GSINIT
.gsinit:
        ld      de, #s__INITIALIZED
        ld      hl, #s__INITIALIZER
        ld      bc, #l__INITIALIZER
        ld      a, b
        or      a, c
        jr      z, .gsinit_none
        ldir
.gsinit_none:
        .area _GSFINAL
        ret

        .area _DATA
        .area _BSS
__store_sp:
        .word 1
        .ds 512
__stack::
