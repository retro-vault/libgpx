        ;; crt0-shot.s
        ;;
        ;; Startup used only when capturing the manual's screenshots.
        ;;
        ;; Identical to the real startup files except that it halts after
        ;; main() instead of returning to BASIC or CP/M, so the emulator
        ;; stops with the finished picture still on screen.
        ;;
        ;; GPL2 License (see: LICENSE)
        ;; Copyright (C) 2026 Tomaz Stih
        ;;
        ;; 2026-08-26   TS

        .module crt0_shot

        .globl  _main
        .globl  s__INITIALIZED
        .globl  s__INITIALIZER
        .globl  l__INITIALIZER

        .area   _CODE
        ;; ------------------------------------------------------------
        ;; init
        ;; Program entry. Sets up a private stack, copies the C
        ;; initializers so initialized statics hold their values, calls
        ;; main(), and hands control back to the host when it returns.
        ;;
        ;; Arguments:
        ;;   none
        ;;
        ;; Clobbers:
        ;;   everything; nothing is live on entry
        ;;
        ;; References:
        ;;   _main
        ;;   .gsinit
init::
        ld      sp,#__stack
        call    .gsinit
        call    _main
        halt

        .area   _GSINIT
        .area   _GSFINAL
        .area   _HOME
        .area   _INITIALIZER
        .area   _INITFINAL
        .area   _INITIALIZED
        .area   _DATA
        .area   _BSS

        .area   _GSINIT
.gsinit:
        ld      de,#s__INITIALIZED
        ld      hl,#s__INITIALIZER
        ld      bc,#l__INITIALIZER
        ld      a,b
        or      a,c
        jr      z,.gs_none
        ldir
.gs_none:
        .area   _GSFINAL
        ret

        .area   _DATA
        .area   _BSS
        .ds     512
__stack::
