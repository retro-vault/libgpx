        ;; crt0.s
        ;;
        ;; Minimal CP/M startup for the Iskra Delta Partner demo.
        ;;
        ;; Linked first with --code-loc 0x100 so entry lands at the start
        ;; of the TPA (keep this the first link object). Copies the C
        ;; initializers (GSINIT) so initialized statics hold their values,
        ;; runs on a private stack, and warm-boots back to CP/M should
        ;; main() ever return.

        .module crt0
        .globl  _main
        .globl  s__INITIALIZED
        .globl  s__INITIALIZER
        .globl  l__INITIALIZER

        .area   _CODE
init::
        ld      (#__store_sp),sp
        ld      sp,#__stack
        call    gsinit
        call    _main
        ld      sp,(#__store_sp)
        jp      0x0000                  ;; CP/M warm boot

        .area   _GSINIT
        .area   _GSFINAL
        .area   _HOME
        .area   _INITIALIZER
        .area   _INITFINAL
        .area   _INITIALIZED
        .area   _DATA
        .area   _BSS

        .area   _GSINIT
gsinit:
        ld      de, #s__INITIALIZED
        ld      hl, #s__INITIALIZER
        ld      bc, #l__INITIALIZER
        ld      a, b
        or      a, c
        jr      z, gsinit_none
        ldir
gsinit_none:
        .area   _GSFINAL
        ret

        .area   _BSS
__store_sp:
        .ds     2
        .ds     512
__stack::
