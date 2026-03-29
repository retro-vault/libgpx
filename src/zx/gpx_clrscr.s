        ;; gpx_clrscr.s
        ;;
        ;; ZX Spectrum clear-screen primitive.
        ;; Clears pixel VRAM, restores default attributes and black border.

        .module gpx_clrscr
        .optsdcc -mz80 sdcccall(1)

        .globl  _gpx_clrscr

        .equ    VMEMBEG, 0x4000
        .equ    VMEMSZE, 0x1800
        .equ    ATTRSZE, 0x02ff
        .equ    BDRPORT, 0xfe

        .area   _CODE

        ;; void gpx_clrscr(void)
_gpx_clrscr::
        ;; clear pixel area (0x4000..0x57ff)
        ld      hl,#VMEMBEG
        ld      de,#VMEMBEG+1
        ld      bc,#VMEMSZE-1
        ld      (hl),#0x00
        ldir

        ;; set attributes (0x5800..0x5aff):
        ;;   paper = white (light gray on composite displays), ink = black
        ld      hl,#VMEMBEG+VMEMSZE
        ld      de,#VMEMBEG+VMEMSZE+1
        ld      bc,#ATTRSZE
        ld      (hl),#0x38
        ldir

        ;; border = white (same tone family as paper)
        ld      a,#0x07
        out     (#BDRPORT),a
        ret
