        ;; gpx_set_page.s
        ;;
        ;; Partner page-selection helper.
        ;;
        ;; GPL2 License (see: LICENSE)
        ;; Copyright (C) 2026 Tomaz Stih
        ;;
        ;; 2026-04-04   TS

        .module gpx_set_page
        .optsdcc -mz80 sdcccall(1)

        .globl  _gpx_set_page
        .globl  __ef9367_wait_vbl
        .globl  __ef9367_set_gr_cmn
        .globl  __ef9367_gr_cmn

        .include "_ef9367-defs.inc"

        .equ    PG_MASK, (PIO_GR_CMN_DISP_PG|PIO_GR_CMN_WR_PG)

        .area   _CODE

        ;; ------------------------------------------------------------
        ;; void gpx_set_page(uint8_t op, uint8_t page)
        ;; Inputs:
        ;;   A = op flags (PG_DISPLAY/PG_WRITE, may be OR-ed)
        ;;   L = page number (only bit 0 is used)
        ;;
        ;; Clobbers:
        ;;   AF, BC
_gpx_set_page::
        and     #PG_MASK                ; keep only supported op bits
        ld      b,a                     ; B = selector
        ret     z                       ; no operation requested

        ld      a,l                     ; page number
        and     #0x01                   ; normalize to 0/1
        jr      z,.select
        or      #PIO_GR_CMN_WR_PG       ; expand page=1 to bits 1:0 == 11

.select:
        and     b                       ; keep only bits requested by op
        ld      c,a                     ; C = selected page bits
        ld      a,b                     ; selector
        cpl                             ; invert selector
        ld      b,a                     ; B = inverse selector

        ;; Port 0x30 reads back only the PIO's own output latch, so the
        ;; shadow -- not an IN -- is what the untouched bits come from.
        ld      a,(__ef9367_gr_cmn)     ; current board control latch
        and     b                       ; preserve untouched bits
        or      c                       ; merge new page bits
        push    af                      ; keep final register value

        ld      a,b
        cpl                             ; recover selector
        and     #PIO_GR_CMN_DISP_PG     ; display page changed?
        jr      z,.write
        call    __ef9367_wait_vbl       ; avoid tearing on display flip

.write:
        pop     af
        jp      __ef9367_set_gr_cmn     ; latch, shadow, sync first
