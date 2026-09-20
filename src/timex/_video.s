        ;; _video.s
        ;;
        ;; Timex high-resolution VRAM address helpers. Each display file has
        ;; ZX Spectrum row ordering; adjacent logical bytes alternate between
        ;; the files at 0x4000 and 0x6000.
        ;;
        ;; GPL2 License (see: LICENSE)
        ;; Copyright (C) 2026 Tomaz Stih

        .module _video
        .optsdcc -mz80 sdcccall(1)

        .include "_timex-defs.inc"

        .globl  __vid_rowaddr
        .globl  __vid_byteaddr
        .globl  __vid_nextcol
        .globl  __vid_prevcol
        .globl  __vid_nextrow
        .globl  __vid_prevrow
        .globl  __vid_nextrow_carry
        .globl  __vid_prevrow_carry

        .area   _CODE

        ;; ------------------------------------------------------------
        ;; __vid_rowaddr
        ;; B = y (0..191); return HL = primary-file row base.
        ;; Clobbers: AF, HL.
        ;; ------------------------------------------------------------
__vid_rowaddr::
        ld      a,b
        and     #0x07
        or      #(TIMEX_VRAM0 >> 8)
        ld      h,a
        ld      a,b
        rrca
        rrca
        rrca
        and     #0x18
        or      h
        ld      h,a
        ld      a,b
        rla
        rla
        and     #0xE0
        ld      l,a
        ret

        ;; ------------------------------------------------------------
        ;; __vid_byteaddr
        ;; HL = primary-file row base, A = logical byte column (0..63).
        ;; Return the physical address for that byte. Only AF/HL are changed.
        ;; Clobbers: AF, HL.
        ;; ------------------------------------------------------------
__vid_byteaddr::
        bit     0,a
        jr      nz,.vba_secondary
        rrca                            ; even: A = column / 2
        and     #0x1F
        add     a,l
        ld      l,a
        ret     nc
        inc     h
        ret
.vba_secondary:
        rrca                            ; odd: A = column / 2, carry ignored
        and     #0x1F
        add     a,l
        ld      l,a
        jr      nc,.vba_second_file
        inc     h
.vba_second_file:
        set     5,h                     ; odd logical byte: secondary file
        ret

        ;; ------------------------------------------------------------
        ;; __vid_nextcol
        ;; Move right one logical byte. Bit 5 of H selects the display file.
        ;; Clobbers: AF, HL.
        ;; ------------------------------------------------------------
__vid_nextcol::
        bit     5,h
        jr      nz,.vnc_from_second
        set     5,h
        ret
.vnc_from_second:
        res     5,h
        inc     hl
        ret

        ;; ------------------------------------------------------------
        ;; __vid_prevcol
        ;; Move left one logical byte. Bit 5 of H selects the display file.
        ;; Clobbers: AF, HL.
        ;; ------------------------------------------------------------
__vid_prevcol::
        bit     5,h
        jr      z,.vpc_from_primary
        res     5,h
        ret
.vpc_from_primary:
        dec     hl
        set     5,h
        ret

        ;; ------------------------------------------------------------
        ;; __vid_nextrow
        ;; Spectrum-format vertical stepping works in either display file.
        ;; Clobbers: AF, HL.
        ;; ------------------------------------------------------------
__vid_nextrow::
        inc     h
        ld      a,h
        and     #0x07
        ret     nz

        ;; ------------------------------------------------------------
        ;; __vid_nextrow_carry
        ;; Finish a downward step across an eight-line character boundary.
        ;; Clobbers: AF, HL.
        ;; ------------------------------------------------------------
__vid_nextrow_carry::
        ld      a,l
        add     a,#0x20
        ld      l,a
        ret     c
        ld      a,h
        sub     #0x08
        ld      h,a
        ret

        ;; ------------------------------------------------------------
        ;; __vid_prevrow
        ;; Spectrum-format upward stepping in either display file.
        ;; Clobbers: AF, HL.
        ;; ------------------------------------------------------------
__vid_prevrow::
        dec     h
        ld      a,h
        and     #0x07
        cp      #0x07
        ret     nz

        ;; ------------------------------------------------------------
        ;; __vid_prevrow_carry
        ;; Finish an upward step across an eight-line character boundary.
        ;; Clobbers: AF, HL.
        ;; ------------------------------------------------------------
__vid_prevrow_carry::
        ld      a,l
        sub     #0x20
        ld      l,a
        ret     c
        ld      a,h
        add     a,#0x08
        ld      h,a
        ret
