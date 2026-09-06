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
        ;; because every captured row is masked and the unused tail is zeroed.
        ;;
        ;; The capture is always in the eight-pixels-per-byte form the rest
        ;; of the library uses for bitmaps, so in mode 1 -- where a screen
        ;; byte carries four pixels in its high nibble -- each eight-pixel
        ;; group is gathered from the two screen bytes it occupies. The
        ;; blitter restores that payload without changing the other plane.
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

        .equ    B_SHIFT,                 -1
        .equ    B_GROUPS,                -2

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
        push    hl
        push    ix
        ld      ix,#0
        add     ix,sp
        ld      hl,#-2
        add     hl,sp
        ld      sp,hl
        exx
        ld      b,a                     ; B' = rows remaining
        add     a,a
        neg
        add     a,#BG_PAYLOAD_SIZE
        ld      c,a                     ; C' = unused payload bytes
        exx

        ;; Pixel shift and source group count are invariant across rows.
        ld      a,e
        and     #7
        ld      B_SHIFT(ix),a
        add     a,c
        dec     a
        rrca
        rrca
        rrca
        and     #3
        inc     a
        ld      B_GROUPS(ix),a
        ld      a,e
        srl     d
        rra
        srl     d
        rra
        srl     d
        rra
        ld      e,a                     ; group index, 0..79

        ;; Form both output masks once, as a single 16-bit mask.
        push    bc                      ; y
        push    de                      ; destination group index
        ld      hl,#0xffff
        ld      a,#16
        sub     c
        ld      b,a
        jr      z,.gsb_mask_done
.gsb_mask_loop:
        add     hl,hl
        djnz    .gsb_mask_loop
.gsb_mask_done:
        push    hl                      ; output masks for alternate DE
        ld      l,2(ix)
        ld      h,3(ix)
        ld      de,#BG_HEADER_SIZE
        add     hl,de
        push    hl
        exx
        pop     hl                      ; HL' = payload destination
        pop     de                      ; D'/E' = output masks
        exx
        pop     de
        pop     bc

        call    __vid_rowaddr
        ld      a,(__cpc_mode1)
        or      a
        ld      a,e
        jr      z,.gsb_base_wide
        add     a,a
.gsb_base_wide:
        add     a,l
        ld      l,a
        jr      nc,.gsb_row_loop
        inc     h

.gsb_row_loop:
        push    hl                      ; retain the row base across the gather
        ld      b,B_GROUPS(ix)
        call    .gsb_group
        ld      d,a
        ld      e,#0
        ld      c,#0
        dec     b
        jr      z,.gsb_src_ready
        call    .gsb_group
        ld      e,a
        dec     b
        jr      z,.gsb_src_ready
        call    .gsb_group
        ld      c,a
.gsb_src_ready:
        ex      de,hl                   ; HL = first two eight-pixel groups
        ld      b,B_SHIFT(ix)
        ld      a,b
        or      a
        jr      z,.gsb_shift_done
        ld      a,c                     ; third group supplies incoming low bits
.gsb_shift_loop:
        add     a,a
        adc     hl,hl
        djnz    .gsb_shift_loop
.gsb_shift_done:
        ld      a,h
        exx
        and     d
        ld      (hl),a
        inc     hl
        exx
        ld      a,l
        exx
        and     e
        ld      (hl),a
        inc     hl
        dec     b
        exx                             ; EXX and POP preserve the row-count flags
        pop     hl
        jr      z,.gsb_clear
        call    __vid_nextrow
        jr      .gsb_row_loop

.gsb_clear:
        ;; The captured rows already contain fully masked output. Clear
        ;; only the unused tail, preserving the fixed 32-byte payload.
        exx
        ld      a,c
        or      a
        jr      z,.gsb_done
        ld      b,#0
        ld      d,h
        ld      e,l
        inc     de
        dec     c
        ld      (hl),b
        ldir
.gsb_done:
        ld      sp,ix
        pop     ix
        pop     hl
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
