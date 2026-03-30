        ;; gpx_height.s
        ;;
        ;; Partner display height accessor.

        .module gpx_height
        .optsdcc -mz80 sdcccall(1)

        .globl  _gpx_height
        .globl  __gpx_ctx

        .area   _CODE

        ;; dim gpx_height(void)
_gpx_height::
        ld      hl,(__gpx_ctx)          ;; HL = active gpx_t*
        ld      a,h
        or      l
        jr      nz,.have_ctx
        ld      de,#0x0000
        ret

.have_ctx:
        inc     hl                      ;; +2 => height
        inc     hl
        ld      e,(hl)                  ;; height lo
        inc     hl
        ld      d,(hl)                  ;; height hi
        ret
