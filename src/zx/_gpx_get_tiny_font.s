        ;; _gpx_get_tiny_font.s
        ;;
        ;; Return pointer to the tiny font blob.
        ;;
        ;; Size-optimized policy: tiny font currently aliases the
        ;; system font payload to keep total ZX GPX footprint < 8 KiB.

        .module _gpx_get_tiny_font
        .optsdcc -mz80 sdcccall(1)

        .globl  _gpx_get_tiny_font
        .globl  _gpx_font_envy

        .area   _CODE

        ;; const font_t *gpx_get_tiny_font(void)
_gpx_get_tiny_font::
        ld      de,#_gpx_font_envy
        ret
