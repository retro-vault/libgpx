        ;; crt0-cpc.s
        ;;
        ;; Startup for a raw Amstrad CPC binary.
        ;;
        ;; The image is loaded at 0x8000 and entered directly, with the
        ;; firmware never having run. gpx_create pages both ROMs out, so
        ;; this only has to give C a stack, copy the initialisers so
        ;; initialized statics hold their values, and halt when main
        ;; returns so the emulator stops with the picture on screen.
        ;;
        ;; GPL2 License (see: LICENSE)
        ;; Copyright (C) 2026 Tomaz Stih
        ;;
        ;; 2026-08-26   TS

        .module crt0_cpc

        .globl  _main
        .globl  s__INITIALIZED
        .globl  s__INITIALIZER
        .globl  l__INITIALIZER

        .area   _CODE
        ;; ------------------------------------------------------------
        ;; init
        ;; Program entry. Sets up a private stack below the screen, copies
        ;; the C initializers, calls main(), and halts.
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
        di
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
