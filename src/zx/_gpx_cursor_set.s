        ;; _gpx_cursor_set.s
        ;;
        ;; Validate and store current cursor handle for future ZX
        ;; software cursor compositor integration.

        .module _gpx_cursor_set
        .optsdcc -mz80 sdcccall(1)

        .globl  _gpx_cursor_set
        .globl  __gpx_cursor_current
        .globl  _gpx_cur_classic

        .equ    BMP_ENC_MASK,      0xF0
        .equ    BMP_ENC_1BPP_MASK, 0x10
        .equ    BMP_ENC_1BPP_MASK_COMPACT, 0x30

        .area   _CODE

        ;; void gpx_cursor_set(bmp_t *cursor)
        ;;   HL = cursor pointer
_gpx_cursor_set::
        ld      a,h
        or      l
        jr      z,.default_cursor

        ld      a,(hl)
        and     #BMP_ENC_MASK
        cp      #BMP_ENC_1BPP_MASK
        jr      z,.set_cursor
        cp      #BMP_ENC_1BPP_MASK_COMPACT
        jr      nz,.default_cursor

.set_cursor:
        ld      (__gpx_cursor_current),hl
        ret

.default_cursor:
        ld      hl,#_gpx_cur_classic
        ld      (__gpx_cursor_current),hl
        ret

        .area   _DATA
__gpx_cursor_current::
        .ds     2
