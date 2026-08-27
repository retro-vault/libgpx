        ;; _gpx_sprite_blit_raw.s
        ;;
        ;; Private ZX Spectrum raw sprite blitter.
        ;;
        ;; Inputs:
        ;;   A = standard bitmap mode
        ;;       0 => transparent zero bits
        ;;       1 => copy zero bits too
        ;;   B = y (0..191)
        ;;   C = x (0..255)
        ;;   HL = bmp_t *
        ;;
        ;; Supported formats:
        ;;   standard 1bpp, stride 1..2
        ;;   masked 1bpp,   stride 1..2
        ;;
        ;; Policy:
        ;;   - no top/left clipping
        ;;   - right/bottom clipping only
        ;;   - max size 16x16
        ;;
        ;; GPL2 License (see: LICENSE)
        ;; Copyright (C) 2026 Tomaz Stih
        ;;
        ;; 2026-08-25   TS

        .module _gpx_sprite_blit_raw
        .optsdcc -mz80 sdcccall(1)

        .globl  __gpx_sprite_blit_raw
        .globl  __vid_rowaddr
        .globl  __vid_nextrow
        .globl  __gpx_ffshr

        .equ    BMP_SIG_ENC_MASK,        0xF0
        .equ    BMP_SIG_1BPP,            0x00
        .equ    BMP_SIG_1BPP_MASK,       0x10
        .equ    SCRHEIGHT,               192

        .equ    P_SRCAND_LO,             -2
        .equ    P_SRCAND_HI,             -1
        .equ    P_SRCOR_LO,              -4
        .equ    P_SRCOR_HI,              -3
        .equ    P_ROWADV_LO,             -6
        .equ    P_ROWADV_HI,             -5
        .equ    P_STDMODE,               -7
        .equ    P_STRIDE,                -8
        .equ    P_HLEFT,                 -9
        ;; Destination row pointer, derived once and then stepped by
        ;; __vid_nextrow. The low slot was the old per-row y counter, which
        ;; only existed to rebuild the row address every row; the high slot
        ;; is the one byte the frame grew by.
        .equ    P_DSTROW_LO,             -10
        .equ    P_DSTROW_HI,             -22
        .equ    P_SHIFT,                 -11
        .equ    P_XBYTE,                 -12
        .equ    P_INS0,                  -13
        .equ    P_INS1,                  -14
        .equ    P_INS2,                  -15
        .equ    P_SPAN,                  -16
        .equ    P_MASKED,                -17
        .equ    P_VISW,                  -18
        .equ    P_AND0,                  -19
        .equ    P_AND1,                  -20
        .equ    P_AND2,                  -21

        .macro  LD16HL off
        ld      l,off(ix)
        ld      h,off+1(ix)
        .endm

        .macro  ST16HL off
        ld      off(ix),l
        ld      off+1(ix),h
        .endm

        .macro  LD16DE off
        ld      e,off(ix)
        ld      d,off+1(ix)
        .endm

        .macro  ST16DE off
        ld      off(ix),e
        ld      off+1(ix),d
        .endm

        .area   _CODE

__gpx_sprite_blit_raw:
        ld      d,h
        ld      e,l
        push    iy                      ; preserve caller IY (pinned OR src ptr)
        push    ix
        ld      ix,#0
        add     ix,sp

        ld      hl,#-22
        add     hl,sp
        ld      sp,hl

        ld      P_STDMODE(ix),a
        ld      P_DSTROW_LO(ix),b       ; parks y until xbyte is known
        ld      l,e
        ld      h,d

        ld      a,c
        and     #0x07
        ld      P_SHIFT(ix),a

        ld      a,c
        srl     a
        srl     a
        srl     a
        ld      P_XBYTE(ix),a

        ld      a,(hl)
        and     #BMP_SIG_ENC_MASK
        cp      #BMP_SIG_1BPP
        jr      z,.gbr_std
        cp      #BMP_SIG_1BPP_MASK
        jr      z,.gbr_masked
        jp      .gbr_done

.gbr_std:
        xor     a
        ld      P_MASKED(ix),a
        jr      .gbr_sig_done

.gbr_masked:
        ld      a,#1
        ld      P_MASKED(ix),a

.gbr_sig_done:
        ld      a,(hl)
        and     #0x0F
        inc     a
        cp      #3
        jp      nc,.gbr_done
        ld      P_STRIDE(ix),a

        inc     hl
        ld      a,(hl)
        or      a
        jp      z,.gbr_done
        cp      #17
        jp      nc,.gbr_done
        ld      d,a

        inc     hl
        ld      a,(hl)
        or      a
        jp      z,.gbr_done
        cp      #17
        jp      nc,.gbr_done
        ld      e,a

        ld      a,d
        dec     a
        add     a,c
        jr      nc,.gbr_no_right_clip
        ld      a,c
        cpl
        inc     a
        jr      .gbr_visw_done
.gbr_no_right_clip:
        ld      a,d
.gbr_visw_done:
        ld      P_VISW(ix),a

        ld      a,e
        dec     a
        add     a,b
        cp      #SCRHEIGHT
        jr      c,.gbr_no_bottom_clip
        ld      a,#SCRHEIGHT
        sub     b
        jr      .gbr_h_done
.gbr_no_bottom_clip:
        ld      a,e
.gbr_h_done:
        ld      P_HLEFT(ix),a
        or      a
        jp      z,.gbr_done

        ld      de,#3
        add     hl,de

        ld      a,P_MASKED(ix)
        or      a
        jr      z,.gbr_ptrs_std

        ST16HL  P_SRCAND_LO
        ld      e,P_STRIDE(ix)
        ld      d,#0x00
        add     hl,de
        ST16HL  P_SRCOR_LO
        ld      a,P_STRIDE(ix)
        add     a,a
        ld      e,a
        ld      d,#0x00
        ST16DE  P_ROWADV_LO
        jr      .gbr_ptrs_done

.gbr_ptrs_std:
        ST16HL  P_SRCOR_LO
        xor     a
        ld      P_SRCAND_LO(ix),a
        ld      P_SRCAND_HI(ix),a
        ld      e,P_STRIDE(ix)
        ld      d,#0x00
        ST16DE  P_ROWADV_LO

.gbr_ptrs_done:
        ;; Pin the OR-plane source pointer in IY for the row loop (linear,
        ;; advanced by ROWADV/row). Survives __vid_rowaddr; no per-row IX
        ;; round-trip of this pointer. (AND plane stays in IX, masked-only.)
        ld      l,P_SRCOR_LO(ix)
        ld      h,P_SRCOR_HI(ix)
        push    hl
        pop     iy

        ;; left-keep = ~(0xff >> shift) (shift 0 -> keep nothing = 0)
        ld      a,P_SHIFT(ix)
        call    __gpx_ffshr
        cpl
        ld      d,a

        ld      a,P_SHIFT(ix)
        add     a,P_VISW(ix)
        ld      e,a
        add     a,#7
        srl     a
        srl     a
        srl     a
        ld      P_SPAN(ix),a

        ;; right-keep = 0xff >> ((shift+visw) & 7), 0 -> 0
        ld      a,e
        and     #0x07
        jr      z,.gbr_rk_store         ; A = 0 stands
        call    __gpx_ffshr
.gbr_rk_store:
        ld      e,a

        ld      a,P_SPAN(ix)
        cp      #1
        jr      nz,.gbr_span2_or3
        ld      a,d
        or      e
        cpl
        ld      P_INS0(ix),a
        jr      .gbr_setup_and

.gbr_span2_or3:
        ld      a,d
        cpl
        ld      P_INS0(ix),a

        ld      a,P_SPAN(ix)
        cp      #2
        jr      nz,.gbr_span3
        ld      a,e
        cpl
        ld      P_INS1(ix),a
        jr      .gbr_setup_and

.gbr_span3:
        ld      a,#0xFF
        ld      P_INS1(ix),a
        ld      a,e
        cpl
        ld      P_INS2(ix),a

.gbr_setup_and:
        ;; A plain sprite's AND plane is a constant, so shift it once here
        ;; rather than rebuilding the identical bytes on every row.
        ld      a,P_MASKED(ix)
        or      a
        jr      nz,.gbr_first_row
        ld      a,P_STDMODE(ix)
        or      a
        jr      z,.gbr_std_transparent
        xor     a
        ld      d,a
        ld      e,a
        jr      .gbr_std_shift
.gbr_std_transparent:
        ld      d,#0xFF
        ld      e,#0xFF
.gbr_std_shift:
        xor     a
        ld      b,a
        ld      a,P_SHIFT(ix)
        or      a
        jr      z,.gbr_std_done
.gbr_std_loop:
        srl     d
        rr      e
        rr      b
        dec     a
        jr      nz,.gbr_std_loop
.gbr_std_done:
        ld      P_AND0(ix),d
        ld      P_AND1(ix),e
        ld      P_AND2(ix),b

.gbr_first_row:
        ;; First destination row address, derived once. Every later row is one
        ;; __vid_nextrow away. The row base low byte is a multiple of 0x20 and
        ;; xbyte is 0..31, so the add cannot carry.
        ld      b,P_DSTROW_LO(ix)       ; y, parked at entry
        call    __vid_rowaddr
        ld      a,P_XBYTE(ix)
        add     a,l
        ld      P_DSTROW_LO(ix),a
        ld      P_DSTROW_HI(ix),h

.gbr_row_loop:
        ld      a,P_HLEFT(ix)
        or      a
        jp      z,.gbr_done

        ld      l,P_DSTROW_LO(ix)
        ld      h,P_DSTROW_HI(ix)
        push    hl

        ld      a,P_MASKED(ix)
        or      a
        jr      z,.gbr_or_plane         ; plain: AND bytes are already set

        LD16DE  P_SRCAND_LO
        ex      de,hl
        ld      d,(hl)
        ld      a,P_STRIDE(ix)
        cp      #2
        jr      nz,.gbr_and_second_ff
        inc     hl
        ld      e,(hl)
        jr      .gbr_and_ready
.gbr_and_second_ff:
        ld      e,#0xFF
        jr      .gbr_and_ready

.gbr_and_ready:
        ;; shift AND plane into D:E:B, park in the frame
        xor     a
        ld      b,a
        ld      a,P_SHIFT(ix)
        or      a
        jr      z,.gbr_and_shift_done
.gbr_and_shift_loop:
        srl     d
        rr      e
        rr      b
        dec     a
        jr      nz,.gbr_and_shift_loop
.gbr_and_shift_done:
        ld      P_AND0(ix),d
        ld      P_AND1(ix),e
        ld      P_AND2(ix),b

.gbr_or_plane:
        ;; OR plane straight from the pinned source into B:C, shifted
        ;; into B:C:D — stays in registers through composition
        ld      b,0(iy)
        ld      a,P_STRIDE(ix)
        cp      #2
        jr      nz,.gbr_or_second_zero
        ld      c,1(iy)
        jr      .gbr_or_ready
.gbr_or_second_zero:
        xor     a
        ld      c,a
.gbr_or_ready:
        xor     a
        ld      d,a
        ld      a,P_SHIFT(ix)
        or      a
        jr      z,.gbr_or_shift_done
        ld      e,a
.gbr_or_shift_loop:
        srl     b
        rr      c
        rr      d
        dec     e
        jr      nz,.gbr_or_shift_loop
.gbr_or_shift_done:
        pop     hl                      ; destination

        ;; compose: new = (old & ANDn) | ORn, then merge under INSn via
        ;; old ^ ((old ^ new) & INSn)
        ld      a,(hl)
        ld      e,a
        and     P_AND0(ix)
        or      b
        xor     e
        and     P_INS0(ix)
        xor     e
        ld      (hl),a

        ld      a,P_SPAN(ix)
        cp      #1
        jr      z,.gbr_next_row

        inc     hl
        ld      a,(hl)
        ld      e,a
        and     P_AND1(ix)
        or      c
        xor     e
        and     P_INS1(ix)
        xor     e
        ld      (hl),a

        ld      a,P_SPAN(ix)
        cp      #2
        jr      z,.gbr_next_row

        inc     hl
        ld      a,(hl)
        ld      e,a
        and     P_AND2(ix)
        or      d
        xor     e
        and     P_INS2(ix)
        xor     e
        ld      (hl),a

.gbr_next_row:
        ;; A sprite is at most 16x16, so a row stride is at most 4 bytes:
        ;; 8-bit adds throughout, with a carry into the high byte.
        ld      e,P_ROWADV_LO(ix)
        ld      d,#0x00
        add     iy,de                   ; pinned OR source pointer

        ld      a,P_MASKED(ix)
        or      a
        jr      z,.gbr_after_and_advance
        ld      a,P_ROWADV_LO(ix)
        add     a,P_SRCAND_LO(ix)
        ld      P_SRCAND_LO(ix),a
        jr      nc,.gbr_after_and_advance
        inc     P_SRCAND_HI(ix)

.gbr_after_and_advance:
        ;; Step the destination one display row instead of rebuilding the
        ;; interleaved address from y.
        ld      l,P_DSTROW_LO(ix)
        ld      h,P_DSTROW_HI(ix)
        call    __vid_nextrow
        ld      P_DSTROW_LO(ix),l
        ld      P_DSTROW_HI(ix),h

        ld      a,P_HLEFT(ix)
        dec     a
        ld      P_HLEFT(ix),a
        jp      .gbr_row_loop

.gbr_done:
        ld      sp,ix
        pop     ix
        pop     iy                      ; restore caller IY
        ret
