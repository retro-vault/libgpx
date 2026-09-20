        ;; gpx_clrscr.s
        ;;
        ;; Timex/Sinclair high-resolution screen clear.
        ;;
        ;; GPL2 License (see: LICENSE)
        ;; Copyright (C) 2026 Tomaz Stih

        .module gpx_clrscr
        .optsdcc -mz80 sdcccall(1)

        .include "_timex-defs.inc"

        .globl  _gpx_clrscr

        .area   _CODE

        ;; ------------------------------------------------------------
        ;; _gpx_clrscr
        ;; Clear the 6 KiB pixel portion of both display files. The attribute
        ;; tails are not fetched by the SCLD in 512-pixel mode.
        ;; Clobbers: AF, BC, HL.
        ;; ------------------------------------------------------------
_gpx_clrscr::
        ld      hl,#TIMEX_VRAM0
        call    .cls_bitmap
        ld      hl,#TIMEX_VRAM1
        ;; fall through

.cls_bitmap:
        ld      b,#0x18                 ; 24 pages = 6144 bytes
        xor     a
.cls_page:
        ld      c,#0x20                 ; 32 * 8 stores per page
.cls_row:
        ld      (hl),a
        inc     l
        ld      (hl),a
        inc     l
        ld      (hl),a
        inc     l
        ld      (hl),a
        inc     l
        ld      (hl),a
        inc     l
        ld      (hl),a
        inc     l
        ld      (hl),a
        inc     l
        ld      (hl),a
        inc     l
        dec     c
        jr      nz,.cls_row
        inc     h
        djnz    .cls_page
        ret
