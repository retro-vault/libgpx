        ;; _gpx_get_stock_bmp.s
        ;;
        ;; Resolve stock bitmap id to Partner cursor bitmap blob.
        ;;
        ;; GPL2 License (see: LICENSE)
        ;; Copyright (C) 2026 Tomaz Stih
        ;;
        ;; 2026-03-30   TS

        .module _gpx_get_stock_bmp
        .optsdcc -mz80 sdcccall(1)

        .globl  _gpx_get_stock_bmp
        .globl  _gpx_cur_classic_tiny
        .globl  _gpx_cur_std_tiny
        .globl  _gpx_cur_hourglass_tiny
        .globl  _gpx_cur_caret_tiny
        .globl  _gpx_cur_hand_tiny

        .equ    GPXSB_CURSOR_CLASSIC,   0x00
        .equ    GPXSB_CURSOR_STD,       0x01
        .equ    GPXSB_CURSOR_HOURGLASS, 0x02
        .equ    GPXSB_CURSOR_CARET,     0x03
        .equ    GPXSB_CURSOR_HAND,      0x04

        .area   _CODE

        ;; ------------------------------------------------------------
        ;; _gpx_get_stock_bmp
        ;; Built-in artwork by id, in the tiny move-stream format this
        ;; backend draws. Using these keeps a program portable, since the
        ;; payload format itself is machine-specific.
        ;;
        ;; Signature:
        ;;   bmp_t *gpx_get_stock_bmp(uint8_t which)
        ;;
        ;; Arguments:
        ;;   A = which, one of the GPXSB_* ids
        ;;
        ;; Return:
        ;;   DE = bmp_t*, or 0 when the id is not known here
        ;;
        ;; Clobbers:
        ;;   AF, DE
_gpx_get_stock_bmp::
        cp      #GPXSB_CURSOR_CLASSIC
        jr      z,.classic
        cp      #GPXSB_CURSOR_STD
        jr      z,.std
        cp      #GPXSB_CURSOR_HOURGLASS
        jr      z,.hourglass
        cp      #GPXSB_CURSOR_CARET
        jr      z,.caret
        cp      #GPXSB_CURSOR_HAND
        jr      z,.hand

        ld      de,#0x0000
        ret

.classic:
        ld      de,#_gpx_cur_classic_tiny
        ret
.std:
        ld      de,#_gpx_cur_std_tiny
        ret
.hourglass:
        ld      de,#_gpx_cur_hourglass_tiny
        ret
.caret:
        ld      de,#_gpx_cur_caret_tiny
        ret
.hand:
        ld      de,#_gpx_cur_hand_tiny
        ret
