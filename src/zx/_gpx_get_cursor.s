        ;; _gpx_get_cursor.s
        ;;
        ;; Map cursor type id to a stock cursor bitmap.

        .module _gpx_get_cursor
        .optsdcc -mz80 sdcccall(1)

        .globl  _gpx_get_cursor
        .globl  _gpx_get_stock_bmp

        .equ    GPX_CURSOR_ARROW, 0x00
        .equ    GPX_CURSOR_HAND,  0x01
        .equ    GPX_CURSOR_WAIT,  0x02
        .equ    GPX_CURSOR_TEXT,  0x03

        .equ    GPXSB_CURSOR_CLASSIC,   0x00
        .equ    GPXSB_CURSOR_HOURGLASS, 0x02
        .equ    GPXSB_CURSOR_CARET,     0x03
        .equ    GPXSB_CURSOR_HAND,      0x04

        .area   _CODE

        ;; bmp_t *gpx_get_cursor(uint8_t type)
        ;;   A = type
        ;;   DE = bmp pointer
_gpx_get_cursor::
        cp      #GPX_CURSOR_HAND
        jr      z,.hand
        cp      #GPX_CURSOR_WAIT
        jr      z,.wait
        cp      #GPX_CURSOR_TEXT
        jr      z,.text

        ld      a,#GPXSB_CURSOR_CLASSIC
        jp      _gpx_get_stock_bmp

.hand:
        ld      a,#GPXSB_CURSOR_HAND
        jp      _gpx_get_stock_bmp

.wait:
        ld      a,#GPXSB_CURSOR_HOURGLASS
        jp      _gpx_get_stock_bmp

.text:
        ld      a,#GPXSB_CURSOR_CARET
        jp      _gpx_get_stock_bmp
