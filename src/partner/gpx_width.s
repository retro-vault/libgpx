        ;; gpx_width.s
        ;;
        ;; Partner display width accessor.

        .module gpx_width
        .optsdcc -mz80 sdcccall(1)

        .globl  _gpx_width
        .globl  __gpx_ctx

        .area   _CODE

        ;; dim gpx_width(void)
_gpx_width::
        ld      hl,(__gpx_ctx)          ;; HL = active gpx_t*
        ld      a,h
        or      l
        jr      nz,.have_ctx
        ld      de,#0x0000
        ret

.have_ctx:
        ld      e,(hl)                  ;; width lo
        inc     hl
        ld      d,(hl)                  ;; width hi
        ret
