        ;; _gpx_store_background.s
        ;;
        ;; Private Amstrad CPC save-under background capture.
        ;;
        ;; Inputs:
        ;;   HL = destination background bmp_t *
        ;;   DE = x (0..CPC_WIDTH-1)
        ;;   B  = y (0..CPC_HEIGHT-1)
        ;;   C  = visible width  (1..16)
        ;;   A  = visible height (1..16)
        ;;
        ;; Saves the visible screen area into HL as a valid standard 1bpp
        ;; bmp_t with stride=2. Bytes/rows clipped off-screen remain zero
        ;; because the payload is cleared first.
        ;;
        ;; The capture is always in the eight-pixels-per-byte form the rest
        ;; of the library uses for bitmaps, so in mode 1 -- where a screen
        ;; byte carries four pixels in its high nibble -- each eight-pixel
        ;; group is gathered from the two screen bytes it occupies. That is
        ;; the exact mirror of the blitter's scatter, so a captured
        ;; background redraws through gpx_draw_bmp unchanged.
        ;;
        ;; GPL2 License (see: LICENSE)
        ;; Copyright (C) 2026 Tomaz Stih
        ;;
        ;; 2026-08-26   TS

        .module _gpx_store_background
        .optsdcc -mz80 sdcccall(1)

        .include "_cpc-defs.inc"

        .globl  __gpx_store_background
        .globl  __vid_rowaddr
        .globl  __vid_nextrow
        .globl  __cpc_mode1

        .equ    BG_HEADER_SIZE,          5
        .equ    BG_PAYLOAD_SIZE,         32

        .equ    B_BG_LO,                 -2
        .equ    B_BG_HI,                 -1
        .equ    B_VISW,                  -3
        .equ    B_ROWCNT,                -4
        .equ    B_DSTROW_LO,             -5
        .equ    B_SHIFT,                 -6
        .equ    B_GROUP,                 -7
        .equ    B_DSTROW_HI,             -8

        .area   _CODE

        ;; ------------------------------------------------------------
        ;; __gpx_store_background
        ;;
        ;; Arguments:
        ;;   HL = destination bmp_t*, DE = x, B = y, C = width, A = height
        ;;
        ;; Clobbers:
        ;;   AF, BC, DE, HL, IX, IY
        ;;
        ;; References:
        ;;   __vid_rowaddr, __vid_nextrow
__gpx_store_background::
        push    iy                      ; preserve caller IY (used as dest ptr)
        push    hl
        push    ix
        ld      ix,#0
        add     ix,sp

        ld      hl,#-8
        add     hl,sp
        ld      sp,hl

        ld      B_VISW(ix),c
        ld      B_ROWCNT(ix),a
        ld      B_DSTROW_LO(ix),b       ; parks y until the group is known

        ;; pixel-in-group and group index: the pattern period is eight
        ;; pixels in both modes, so this split is mode independent
        ld      a,e
        and     #0x07
        ld      B_SHIFT(ix),a
        ld      a,e
        srl     d
        rra
        srl     d
        rra
        srl     d
        rra
        ld      B_GROUP(ix),a           ; 0..79

        ;; clear the payload so clipped bytes and rows read back as zero
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
        push    hl
        pop     iy                      ; IY = payload write pointer, +2/row

        ;; first row address, then one __vid_nextrow per row
        ld      b,B_DSTROW_LO(ix)
        call    __vid_rowaddr
        ld      a,(__cpc_mode1)
        or      a
        ld      a,B_GROUP(ix)
        jr      z,.gsb_base_wide
        add     a,a                     ; two screen bytes per group
.gsb_base_wide:
        add     a,l
        ld      l,a
        jr      nc,.gsb_base_ok
        inc     h
.gsb_base_ok:
        ld      B_DSTROW_LO(ix),l
        ld      B_DSTROW_HI(ix),h

.gsb_row_loop:
        ld      a,B_ROWCNT(ix)
        or      a
        jp      z,.gsb_done

        ld      l,B_DSTROW_LO(ix)
        ld      h,B_DSTROW_HI(ix)

        ;; Gather up to three eight-pixel groups into D:E:C.
        call    .gsb_group
        ld      d,a
        xor     a
        ld      e,a
        ld      c,a

        ld      b,B_SHIFT(ix)
        ld      a,B_VISW(ix)
        add     a,b
        cp      #9
        jr      c,.gsb_src_ready
        push    af
        call    .gsb_group
        ld      e,a
        pop     af
        cp      #17
        jr      c,.gsb_src_ready
        call    .gsb_group
        ld      c,a
.gsb_src_ready:

        ;; align the first captured pixel to bit 7
        ld      a,b
        or      a
        jr      z,.gsb_shift_done
.gsb_shift_loop:
        sla     c
        rl      e
        rl      d
        djnz    .gsb_shift_loop
.gsb_shift_done:

        ;; mask off everything past the visible width
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
        pop     iy                      ; restore caller IY
        ret

        ;; ------------------------------------------------------------
        ;; .gsb_group
        ;;
        ;; Read the eight-pixel group at (HL) as one byte and step HL to the
        ;; next group. In mode 1 that means gathering the high nibbles of the
        ;; two screen bytes the group occupies.
        ;;
        ;; Clobbers:
        ;;   AF, HL
        ;; ------------------------------------------------------------
.gsb_group:
        ld      a,(__cpc_mode1)
        or      a
        jr      z,.gsb_group_wide
        push    bc
        ld      a,(hl)
        and     #0xF0
        ld      b,a
        inc     hl
        ld      a,(hl)
        inc     hl
        rrca
        rrca
        rrca
        rrca
        and     #0x0F
        or      b
        pop     bc
        ret
.gsb_group_wide:
        ld      a,(hl)
        inc     hl
        ret
