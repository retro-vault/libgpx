        ;; gpx_create.s
        ;;
        ;; Timex/Sinclair 512x192 high-resolution graphics bring-up.
        ;;
        ;; GPL2 License (see: LICENSE)
        ;; Copyright (C) 2026 Tomaz Stih

        .module gpx_create
        .optsdcc -mz80 sdcccall(1)

        .include "_timex-defs.inc"

        .globl  _gpx_create
        .globl  _gpx_clrscr
        .globl  __gpx_ctx
        .globl  __gpx_data

        .equ    GPX_TEXT_BG_OPAQUE,     0x00
        .equ    SCRPAGES,               0x01

        .area   _CODE

        ;; ------------------------------------------------------------
        ;; _gpx_create
        ;; gpx_t *gpx_create(gmode mode)
        ;; A = mode (ignored: the Timex backend has one fixed layout)
        ;; DE = address of the static graphics context
        ;; Clobbers: AF, BC, DE, HL.
        ;; ------------------------------------------------------------
_gpx_create::
        ld      a,#TIMEX_HIRES_BW
        out     (#TIMEX_VIDEO_PORT),a
        call    _gpx_clrscr
        xor     a
        ld      (__gpx_data+5),a
        ld      de,#__gpx_data
        ld      (__gpx_ctx),de
        ret

        .area   _DATA

__gpx_ctx::
        .dw     __gpx_data

__gpx_data::
        .dw     TIMEX_WIDTH
        .dw     TIMEX_HEIGHT
        .db     SCRPAGES
        .db     GPX_TEXT_BG_OPAQUE
