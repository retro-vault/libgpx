        ;; crt0-zx.s
        ;;
        ;; Minimal ZX Spectrum startup for demo2. Linked first at 0x8000,
        ;; it preserves BASIC's registers, initializes C statics, calls
        ;; main(), and returns to BASIC if main() returns.
        ;;
        ;; GPL2 License (see: LICENSE)
        ;; Copyright (C) 2026 Tomaz Stih

        .module crt0_zx
        .globl  _main
        .globl  s__INITIALIZED
        .globl  s__INITIALIZER
        .globl  l__INITIALIZER

        .area   _CODE
        ;; ------------------------------------------------------------
        ;; init
        ;; Program entry from BASIC via USR. Saves BASIC's registers and
        ;; stack pointer, gives C its own stack, copies the C initializers,
        ;; and calls main(); returning restores all of it so BASIC carries
        ;; on as if nothing had happened.
        ;;
        ;; Arguments:
        ;;   none
        ;;
        ;; Clobbers:
        ;;   nothing; every register BASIC needs is saved and restored
        ;;
        ;; References:
        ;;   _main
        ;;   .gsinit
        ;; ------------------------------------------------------------
init::
        ld      (#__store_sp),sp
        ld      sp,#__stack

        push    af
        push    bc
        push    de
        push    hl
        push    ix
        push    iy
        ex      af,af'
        push    af
        exx
        push    bc
        push    de
        push    hl

        ld      iy,#0x5c3a
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
        jr      z,.gsinit_none
        ldir
.gsinit_none:
        .area   _GSFINAL
        ret

        .area   _BSS
__store_sp:
        .ds     2
        .ds     512
__stack::
