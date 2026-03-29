        ;; _gpx_get_stock_bmp.s
        ;;
        ;; Resolve stock bitmap id to cursor bitmap blob.

        .module _gpx_get_stock_bmp
        .optsdcc -mz80 sdcccall(1)

        .globl  _gpx_get_stock_bmp
        .globl  _gpx_cur_classic
        .globl  _gpx_cur_std
        .globl  _gpx_cur_hourglass
        .globl  _gpx_cur_caret
        .globl  _gpx_cur_hand

        .equ    GPXSB_CURSOR_CLASSIC,   0x00
        .equ    GPXSB_CURSOR_STD,       0x01
        .equ    GPXSB_CURSOR_HOURGLASS, 0x02
        .equ    GPXSB_CURSOR_CARET,     0x03
        .equ    GPXSB_CURSOR_HAND,      0x04

        .area   _CODE

        ;; bmp_t *gpx_get_stock_bmp(uint8_t which)
        ;;   A = which
        ;;   DE = bmp pointer (or 0)
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
        ld      de,#_gpx_cur_classic
        ret
.std:
        ld      de,#_gpx_cur_std
        ret
.hourglass:
        ld      de,#_gpx_cur_hourglass
        ret
.caret:
        ld      de,#_gpx_cur_caret
        ret
.hand:
        ld      de,#_gpx_cur_hand
        ret
