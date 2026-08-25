        ;; _video.s
        ;;
        ;; ZX Spectrum VRAM row helpers shared by line/pixel routines.

        .module _video
        .optsdcc -mz80 sdcccall(1)

        .globl  __vid_rowaddr
        .globl  __vid_nextrow
        .globl  __vid_prevrow
        .globl  __vid_nextrow_carry
        .globl  __vid_prevrow_carry

        .area   _CODE

        ;; __vid_rowaddr
        ;;   B  = y (0..191)
        ;;   HL = row base address in ZX pixel VRAM (0x4000..0x57E0)
__vid_rowaddr::
        ld      a,b
        and     #0x07
        or      #0x40
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

        ;; __vid_nextrow
        ;;   HL = current row base
        ;;   HL = next row base
        ;; Works on x-offset pointers too (bits 0..4 of L untouched).
        ;; Clobbers A only; preserves BC/DE and the alternate set.
__vid_nextrow::
        inc     h
        ld      a,h
        and     #0x07
        ret     nz                     ;; seven rows in eight end here

        ;; Hot loops inline the three instructions above and enter here with
        ;; `call z`, paying the call only on the one row in eight that
        ;; crosses a character cell.
__vid_nextrow_carry::
        ld      a,l
        add     a,#0x20
        ld      l,a
        ret     c

        ld      a,h
        sub     #0x08
        ld      h,a
        ret

        ;; __vid_prevrow
        ;;   HL = current row (or x-offset) address
        ;;   HL = address one pixel row up
        ;; Exact inverse of __vid_nextrow. Clobbers A only.
__vid_prevrow::
        dec     h
        ld      a,h
        and     #0x07
        cp      #0x07
        ret     nz                     ;; seven rows in eight end here

__vid_prevrow_carry::
        ld      a,l
        sub     #0x20
        ld      l,a
        ret     c

        ld      a,h
        add     a,#0x08
        ld      h,a
        ret
