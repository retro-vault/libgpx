        ;; _gpx_mode.s
        ;;
        ;; Fixed packing data retained behind the internal interface used by
        ;; the 16-bit-coordinate raster routines.
        ;;
        ;; GPL2 License (see: LICENSE)
        ;; Copyright (C) 2026 Tomaz Stih

        .module _gpx_mode
        .optsdcc -mz80 sdcccall(1)

        .include "_timex-defs.inc"

        .globl  __timex_mode1
        .globl  __timex_solid
        .globl  __timex_pixmask
        .globl  __timex_width
        .globl  __gpx_maskmap

        .area   _CODE

__gpx_maskmap::
        .db     0x80,0x40,0x20,0x10,0x08,0x04,0x02,0x01

        .area   _DATA

        ;; Always select the eight-pixel-per-byte branch.
__timex_mode1::
        .db     0
__timex_solid::
        .db     TIMEX_SOLID
__timex_pixmask::
        .db     TIMEX_PIXMASK
__timex_width::
        .dw     TIMEX_WIDTH
