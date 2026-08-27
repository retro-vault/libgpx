        ;; crt0-partner.s
        ;;
        ;; Minimal CP/M startup for demo1 on the Iskra Delta Partner.
        ;; Linked first at 0x100, it initializes C statics, calls main(),
        ;; and warm-boots CP/M if main() returns.
        ;;
        ;; GPL2 License (see: LICENSE)
        ;; Copyright (C) 2026 Tomaz Stih

        .module crt0_partner
        .globl  _main
        .globl  s__INITIALIZED
        .globl  s__INITIALIZER
        .globl  l__INITIALIZER

        .area   _CODE
        ;; ------------------------------------------------------------
        ;; init
        ;; Program entry under CP/M. Keeps the CCP's stack pointer so the
        ;; warm boot below can hand control back cleanly, gives C its own
        ;; stack, copies the C initializers, and calls main().
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
        ;; ------------------------------------------------------------
init::
        ld      (#__store_sp),sp
        ld      sp,#__stack
        call    .gsinit
        call    _main
        ld      sp,(#__store_sp)
        jp      0x0000                  ; CP/M warm boot

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
