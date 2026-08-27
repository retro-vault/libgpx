        ;; gpx_height.s
        ;;
        ;; Partner display height accessor.
        ;;
        ;; GPL2 License (see: LICENSE)
        ;; Copyright (C) 2026 Tomaz Stih
        ;;
        ;; 2026-03-30   TS

        .module gpx_height
        .optsdcc -mz80 sdcccall(1)

        .globl  _gpx_height
        .globl  __gpx_ctx

        .area   _CODE

        ;; ------------------------------------------------------------
        ;; _gpx_height
        ;; Height of the active display in pixels. Returns zero when no
        ;; context exists yet, so a caller that skipped gpx_create gets a
        ;; harmless answer rather than reading a null pointer.
        ;;
        ;; Signature:
        ;;   dim gpx_height(void)
        ;;
        ;; Return:
        ;;   DE = height in pixels, or 0 before gpx_create
        ;;
        ;; Clobbers:
        ;;   AF, DE, HL
        ;;
        ;; References:
        ;;   __gpx_ctx
_gpx_height::
        ld      hl,(__gpx_ctx)          ; HL = active gpx_t*
        ld      a,h
        or      l
        jr      nz,.have_ctx
        ld      de,#0x0000
        ret

.have_ctx:
        inc     hl                      ; +2 => height
        inc     hl
        ld      e,(hl)                  ; height lo
        inc     hl
        ld      d,(hl)                  ; height hi
        ret
