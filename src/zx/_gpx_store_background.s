        ;; _gpx_store_background.s
        ;;
        ;; Private ZX Spectrum save-under background capture.
        ;;
        ;; Inputs:
        ;;   HL = destination background bmp_t *
        ;;   B = y
        ;;   C = x
        ;;   D = visible width  (1..16)
        ;;   E = visible height (1..16)
        ;;
        ;; Saves the visible screen area into HL as a valid standard 1bpp
        ;; bmp_t with stride=2. Bytes/rows clipped off-screen remain zero
        ;; because the payload is cleared first.

        .module _gpx_store_background
        .optsdcc -mz80 sdcccall(1)

        .globl  __gpx_store_background
        .globl  __vid_rowaddr
        .globl  __vid_nextrow

        .equ    BG_HEADER_SIZE,          5
        .equ    BG_PAYLOAD_SIZE,         32

        .equ    B_BG_LO,                 -2
        .equ    B_BG_HI,                 -1
        .equ    B_VISW,                  -3
        .equ    B_ROWCNT,                -4
        ;; Destination row pointer, derived once and then stepped. The low
        ;; slot was the per-row y counter that only existed to rebuild the
        ;; interleaved row address every row.
        .equ    B_DSTROW_LO,             -5
        .equ    B_SHIFT,                 -6
        .equ    B_XBYTE,                 -7
        .equ    B_DSTROW_HI,             -8

        .macro  LD16HL off
        ld      l,off(ix)
        ld      h,off+1(ix)
        .endm

        .macro  ST16HL off
        ld      off(ix),l
        ld      off+1(ix),h
        .endm

        .area   _CODE

__gpx_store_background:
        push    iy                     ;; preserve caller IY (used as dest ptr)
        push    hl
        push    ix
        ld      ix,#0
        add     ix,sp

        ld      hl,#-8
        add     hl,sp
        ld      sp,hl

        ld      B_VISW(ix),d
        ld      B_ROWCNT(ix),e
        ld      B_DSTROW_LO(ix),b      ;; parks y until xbyte is known

        ld      a,c
        and     #0x07
        ld      B_SHIFT(ix),a

        ld      a,c
        srl     a
        srl     a
        srl     a
        ld      B_XBYTE(ix),a

        ld      l,2(ix)
        ld      h,3(ix)
        ld      de,#BG_HEADER_SIZE
        add     hl,de
        push    hl
        ld      d,h
        ld      e,l
        inc     de
        ld      bc,#BG_PAYLOAD_SIZE-1
        ld      (hl),#0x00
        ldir
        pop     hl
        ;; Pin the payload write pointer in IY for the whole row loop
        ;; (linear, +2/row). Survives __vid_rowaddr/__vid_nextrow, so no
        ;; per-row IX round-trip of the dest pointer.
        push    hl
        pop     iy

        ;; First row address, derived once; later rows are one __vid_nextrow
        ;; away. The row base low byte is a multiple of 0x20 and xbyte is
        ;; 0..31, so the add cannot carry.
        ld      b,B_DSTROW_LO(ix)      ;; y, parked at entry
        call    __vid_rowaddr
        ld      a,B_XBYTE(ix)
        add     a,l
        ld      B_DSTROW_LO(ix),a
        ld      B_DSTROW_HI(ix),h

.gsb_row_loop:
        ld      a,B_ROWCNT(ix)
        or      a
        jp      z,.gsb_done

        ld      l,B_DSTROW_LO(ix)
        ld      h,B_DSTROW_HI(ix)
        ld      d,(hl)
        xor     a
        ld      e,a
        ld      c,a

        ld      b,B_SHIFT(ix)
        ld      a,B_VISW(ix)
        add     a,b
        cp      #9
        jr      c,.gsb_src_ready
        inc     hl
        ld      e,(hl)
        cp      #17
        jr      c,.gsb_src_ready
        inc     hl
        ld      c,(hl)
.gsb_src_ready:

        ;; B still holds B_SHIFT (set above, untouched through src gather).
        ld      a,b
        or      a
        jr      z,.gsb_shift_done
.gsb_shift_loop:
        sla     c                      ;; shifts a zero in and sets carry
        rl      e
        rl      d
        djnz    .gsb_shift_loop
.gsb_shift_done:

        ld      a,B_VISW(ix)
        cp      #8
        jr      nc,.gsb_first_full

        ld      b,a
        ld      a,#8
        sub     b
        ld      b,a
        ld      a,#0xFF
.gsb_mask0_loop:
        add     a,a
        djnz    .gsb_mask0_loop
        and     d
        ld      d,a
        xor     a
        ld      e,a
        jr      .gsb_store_row

.gsb_first_full:
        ld      a,B_VISW(ix)
        cp      #9
        jr      nc,.gsb_second_partial
        xor     a
        ld      e,a
        jr      .gsb_store_row

.gsb_second_partial:
        sub     #8
        cp      #8
        jr      z,.gsb_store_row
        ld      b,a
        ld      a,#8
        sub     b
        ld      b,a
        ld      a,#0xFF
.gsb_mask1_loop:
        add     a,a
        djnz    .gsb_mask1_loop
        and     e
        ld      e,a

.gsb_store_row:
        ld      0(iy),d
        ld      1(iy),e
        inc     iy
        inc     iy

        ld      l,B_DSTROW_LO(ix)
        ld      h,B_DSTROW_HI(ix)
        call    __vid_nextrow
        ld      B_DSTROW_LO(ix),l
        ld      B_DSTROW_HI(ix),h

        ld      a,B_ROWCNT(ix)
        dec     a
        ld      B_ROWCNT(ix),a
        jp      .gsb_row_loop

.gsb_done:
        ld      sp,ix
        pop     ix
        pop     hl
        pop     iy                     ;; restore caller IY
        ret
