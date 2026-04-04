        ;; gpx_set_page.s
        ;;
        ;; Partner page-selection helper.

        .module gpx_set_page
        .optsdcc -mz80 sdcccall(1)

        .globl  _gpx_set_page
        .globl  __ef9367_wait_ready
        .globl  __ef9367_wait_vbl

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
        and     #PG_MASK                ;; keep only supported op bits
        ld      b,a                     ;; B = selector
        ret     z                       ;; no operation requested

        ld      a,l                     ;; page number
        and     #0x01                   ;; normalize to 0/1
        jr      z,.select
        or      #PIO_GR_CMN_WR_PG       ;; expand page=1 to bits 1:0 == 11

.select:
        and     b                       ;; keep only bits requested by op
        ld      c,a                     ;; C = selected page bits
        ld      a,b                     ;; selector
        cpl                             ;; invert selector
        ld      b,a                     ;; B = inverse selector

        call    __ef9367_wait_ready
        in      a,(PIO_GR_CMN)          ;; read current page control
        and     b                       ;; preserve untouched bits
        or      c                       ;; merge new page bits
        push    af                      ;; keep final register value

        ld      a,b
        cpl                             ;; recover selector
        and     #PIO_GR_CMN_DISP_PG     ;; display page changed?
        jr      z,.write
        call    __ef9367_wait_vbl       ;; avoid tearing on display flip

.write:
        pop     af
        out     (PIO_GR_CMN),a
        ret
