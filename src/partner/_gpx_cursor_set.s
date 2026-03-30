        ;; _gpx_cursor_set.s
        ;;
        ;; Validate and store current Partner cursor bitmap.

        .module _gpx_cursor_set
        .optsdcc -mz80 sdcccall(1)

        .globl  _gpx_cursor_set
        .globl  __gpx_cursor_current
        .globl  _gpx_cur_classic_tiny

        .equ    BMP_ENC_MASK,          0xF0
        .equ    BMP_ENC_MAX_VALID,     0x40

        .area   _CODE

        ;; void gpx_cursor_set(bmp_t *cursor)
        ;; Input:
        ;;   HL = cursor pointer
        ;;
        ;; Clobbers:
        ;;   AF, HL
_gpx_cursor_set::
        ;; NULL -> default classic cursor.
        ld      a,h
        or      l
        jr      z,.default_cursor

        ;; Accept known bitmap encodings (high nibble 0x0..0x3).
        ld      a,(hl)
        and     #BMP_ENC_MASK
        cp      #BMP_ENC_MAX_VALID
        jr      c,.set_cursor

.default_cursor:
        ld      hl,#_gpx_cur_classic_tiny

.set_cursor:
        ld      (__gpx_cursor_current),hl
        ret

        .area   _DATA
__gpx_cursor_current::
        .dw     _gpx_cur_classic_tiny
