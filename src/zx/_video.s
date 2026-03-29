        ;; _video.s
        ;;
        ;; ZX Spectrum VRAM row helpers shared by line/pixel routines.

        .module _video
        .optsdcc -mz80 sdcccall(1)

        .globl  __vid_rowaddr
        .globl  __vid_nextrow
        .globl  vid_rowaddr
        .globl  vid_nextrow

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

vid_rowaddr::
        jp      __vid_rowaddr

        ;; __vid_nextrow
        ;;   HL = current row base
        ;;   HL = next row base
__vid_nextrow::
        inc     h
        ld      a,h
        and     #0x07
        jr      nz,.vn_done

        ld      a,l
        add     a,#0x20
        ld      l,a
        jr      c,.vn_done

        ld      a,h
        sub     #0x08
        ld      h,a

.vn_done:
        ret

vid_nextrow::
        jp      __vid_nextrow
