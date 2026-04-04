        ;; gpx_height.s
        ;;
        ;; ZX Spectrum display height accessor.

        .module gpx_height
        .optsdcc -mz80 sdcccall(1)

        .globl  _gpx_height
        .globl  __gpx_ctx

        .area   _CODE

        ;; dim gpx_height(void)
_gpx_height::
        ld      hl,(__gpx_ctx)          ;; HL = active gpx_t*
        inc     hl                      ;; +2 => height
        inc     hl
        ld      e,(hl)                  ;; height lo
        inc     hl
        ld      d,(hl)                  ;; height hi
        ret
