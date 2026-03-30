        ;; _gpx_get_system_font.s
        ;;
        ;; Return Partner system font blob.

        .module _gpx_get_system_font
        .optsdcc -mz80 sdcccall(1)

        .globl  _gpx_get_system_font
        .globl  _gpx_font_12x16_tiny

        .area   _CODE

        ;; const font_t *gpx_get_system_font(void)
        ;;   DE = font pointer
_gpx_get_system_font::
        ld      de,#_gpx_font_12x16_tiny
        ret
