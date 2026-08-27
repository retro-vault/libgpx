        ;; _gpx_mode.s
        ;;
        ;; The active Amstrad CPC display mode, as data.
        ;;
        ;; One library serves 640x200 and 320x200. The two modes differ only
        ;; in how many pixels a byte holds and which bits of it they are, so
        ;; instead of two builds the mode-dependent paths read these four
        ;; values. gpx_create() writes them once.
        ;;
        ;; The split is deliberately coarse: a mode test costs a load and a
        ;; compare, so it sits once per run, once per row or once per byte,
        ;; never once per pixel. The pixel mask table is shared, because pen
        ;; 1 lives in the high nibble in mode 1 and so both modes walk the
        ;; mask down from bit 7.
        ;;
        ;; GPL2 License (see: LICENSE)
        ;; Copyright (C) 2026 Tomaz Stih
        ;;
        ;; 2026-08-26   TS

        .module _gpx_mode
        .optsdcc -mz80 sdcccall(1)

        .include "_cpc-defs.inc"

        .globl  __cpc_mode1
        .globl  __cpc_solid
        .globl  __cpc_pixmask
        .globl  __cpc_width
        .globl  __gpx_maskmap

        .area   _CODE

        ;; ------------------------------------------------------------
        ;; __gpx_maskmap
        ;; Pixel mask by position within the byte. Mode 2 uses all eight
        ;; entries, mode 1 the first four; the rest of the table is what a
        ;; mode 2 byte's lower pixels need, so one table serves both.
        ;; ------------------------------------------------------------
__gpx_maskmap::
        .db     0x80,0x40,0x20,0x10,0x08,0x04,0x02,0x01


        .area   _DATA

        ;; Nonzero while the 320x200 mode is active.
__cpc_mode1::
        .db     0

        ;; Every pixel of a byte set to pen 1: 0xFF in mode 2, 0xF0 in mode 1.
__cpc_solid::
        .db     CPC_SOLID_640

        ;; x & this = the pixel's position within its byte.
__cpc_pixmask::
        .db     CPC_PIXMASK_640

        ;; Display width in pixels, also mirrored into __rect_screen.
__cpc_width::
        .dw     CPC_W_640
