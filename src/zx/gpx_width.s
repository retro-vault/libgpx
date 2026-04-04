        ;; gpx_width.s
        ;;
        ;; ZX Spectrum display width accessor.

        .module gpx_width
        .optsdcc -mz80 sdcccall(1)

        .globl  _gpx_width
        .globl  __gpx_ctx

        .area   _CODE

        ;; dim gpx_width(void)
_gpx_width::
        ld      hl,(__gpx_ctx)          ;; HL = active gpx_t*
        ld      e,(hl)                  ;; width lo
        inc     hl
        ld      d,(hl)                  ;; width hi
        ret
