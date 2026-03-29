        ;; _gpx_get_system_font.s
        ;;
        ;; Return pointer to the default UI font blob.

        .module _gpx_get_system_font
        .optsdcc -mz80 sdcccall(1)

        .globl  _gpx_get_system_font
        .globl  _gpx_font_envy

        .area   _CODE

        ;; const font_t *gpx_get_system_font(void)
_gpx_get_system_font::
        ld      de,#_gpx_font_envy
        ret
