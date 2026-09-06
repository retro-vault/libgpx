        ;; tiny_modes.s
        ;;
        ;; Tiny bitmap test bridges: public draw_bmp arguments, internal mode.
        ;;
        ;; GPL2 License (see: LICENSE)
        ;; Copyright (C) 2026 Tomaz Stih
        .module tiny_modes
        .optsdcc -mz80 sdcccall(1)
        .globl  _draw_plain_xor
        .globl  _draw_invert
        .globl  _draw_invert_xor
        .globl  __gpx_bmp_invert
        .globl  __gpx_draw_bmp_mode
        .area   _CODE

        ;; ------------------------------------------------------------
        ;; Public draw_bmp ABI, internal XOR/inversion choices.
        ;; Arguments: HL = gpx, DE = x; stack = y, bmp, clip.
        ;; Clobbers: AF, BC, DE, HL, IY.
_draw_plain_xor::
        xor     a
        ld      (__gpx_bmp_invert),a
        inc     a
        jp      __gpx_draw_bmp_mode

_draw_invert::
        ld      a,#1
        ld      (__gpx_bmp_invert),a
        xor     a
        jp      __gpx_draw_bmp_mode

_draw_invert_xor::
        ld      a,#1
        ld      (__gpx_bmp_invert),a
        jp      __gpx_draw_bmp_mode
