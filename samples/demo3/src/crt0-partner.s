        ;; crt0-partner.s
        ;;
        ;; Minimal CP/M startup for the libgpx manual examples on the
        ;; Iskra Delta Partner.
        ;;
        ;; Linked first with _CODE at 0x100 so entry lands at the start of
        ;; the TPA. Copies the C initializers, runs on a private stack, and
        ;; warm-boots back to CP/M if main() returns.
        ;;
        ;; GPL2 License (see: LICENSE)
        ;; Copyright (C) 2026 Tomaz Stih
        ;;
        ;; 2026-08-26   TS

        .module crt0
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
        ld      de, #s__INITIALIZED
        ld      hl, #s__INITIALIZER
        ld      bc, #l__INITIALIZER
        ld      a, b
        or      a, c
        jr      z, .gsinit_none
        ldir
.gsinit_none:
        .area   _GSFINAL
        ret

        .area   _BSS
__store_sp:
        .ds     2
        .ds     512
__stack::
