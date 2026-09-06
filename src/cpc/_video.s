        ;; _video.s
        ;;
        ;; Amstrad CPC VRAM row helpers shared by line/pixel routines.
        ;;
        ;; GPL2 License (see: LICENSE)
        ;; Copyright (C) 2026 Tomaz Stih
        ;;
        ;; 2026-08-26   TS

        .module _video
        .optsdcc -mz80 sdcccall(1)

        .include "_cpc-defs.inc"

        .globl  __vid_rowaddr
        .globl  __vid_nextrow
        .globl  __vid_prevrow
        .globl  __vid_nextrow_carry
        .globl  __vid_prevrow_carry

        .area   _CODE

        ;; ------------------------------------------------------------
        ;; __vid_rowaddr
        ;; Base address of a pixel row in CPC display memory. The CPC
        ;; splits the screen into eight banks 0x800 apart, each holding
        ;; every eighth scanline at 80 bytes per line.
        ;;
        ;; The text row's offset is n * 80 = (n * 5) * 16: two byte
        ;; doublings, an add and four word doublings -- cheaper in bytes than the
        ;; fifty-byte table it replaces, and it needs no register beyond A
        ;; and HL, which callers depend on. n is at most 24, so 5n still
        ;; fits a byte and the high half stays clear until the last shifts.
        ;; This runs once per primitive rather than once per row, so the
        ;; handful of extra T-states does not show.
        ;;
        ;; Arguments:
        ;;   B = y (0..199)
        ;;
        ;; Return:
        ;;   HL = row base in VRAM (0xC000..0xFFB0)
        ;;
        ;; Clobbers:
        ;;   AF, HL
__vid_rowaddr::
        ld      a,b
        rrca
        rrca
        rrca
        and     #0x1F                   ; y >> 3, the text row (0..24)
        ld      l,a
        add     a,a
        add     a,a                     ; 4n, still under 128
        add     a,l                     ; 5n, still under 256
        ld      l,a
        ld      h,#0x00
        add     hl,hl
        add     hl,hl
        add     hl,hl
        add     hl,hl                   ; n * 80, under 0x0800

        ;; The three fields do not overlap: the table leaves bits 0..2 of
        ;; H, the bank sits in bits 3..5 and the screen base in 6..7.
        ld      a,b
        and     #0x07
        rlca
        rlca
        rlca                            ; (y & 7) << 3
        or      #(CPC_VRAM >> 8)
        or      h
        ld      h,a
        ret

        ;; ------------------------------------------------------------
        ;; __vid_nextrow
        ;; Step a VRAM pointer down one pixel row. Works on pointers that
        ;; already carry an x offset, because L is only touched on the
        ;; one row in eight that leaves the bank.
        ;;
        ;; Arguments:
        ;;   HL = current row base, or a row pointer with an x offset
        ;;
        ;; Return:
        ;;   HL = the same pointer one pixel row further down
        ;;
        ;; Clobbers:
        ;;   AF
__vid_nextrow::
        ld      a,h
        add     a,#(CPC_BANK_STEP >> 8)
        ld      h,a
        ret     nc                      ; seven rows in eight end here

        ;; ------------------------------------------------------------
        ;; __vid_nextrow_carry
        ;; The bank-crossing half of __vid_nextrow. Hot loops inline the
        ;; three-instruction fast path and enter here with `call c`, so
        ;; they pay a call only on the eighth row. Stepping out of the
        ;; last bank carries out of the address, which leaves H holding
        ;; the row offset's high bits and makes the fix-up an add.
        ;;
        ;; Arguments:
        ;;   HL = row pointer whose bank field has just wrapped
        ;;
        ;; Return:
        ;;   HL = the same x offset on the first row of the next text row
        ;;
        ;; Clobbers:
        ;;   AF
__vid_nextrow_carry::
        ld      a,l
        add     a,#CPC_ROW_BYTES
        ld      l,a
        ld      a,h
        adc     a,#(CPC_VRAM >> 8)
        ld      h,a
        ret

        ;; ------------------------------------------------------------
        ;; __vid_prevrow
        ;; Step a VRAM pointer up one pixel row; the exact inverse of
        ;; __vid_nextrow, and equally safe on x-offset pointers.
        ;;
        ;; Arguments:
        ;;   HL = current row base, or a row pointer with an x offset
        ;;
        ;; Return:
        ;;   HL = the same pointer one pixel row further up
        ;;
        ;; Clobbers:
        ;;   AF
__vid_prevrow::
        ld      a,h
        sub     #(CPC_BANK_STEP >> 8)
        ld      h,a
        cp      #(CPC_VRAM >> 8)
        ret     nc                      ; seven rows in eight end here

        ;; ------------------------------------------------------------
        ;; __vid_prevrow_carry
        ;; The bank-crossing half of __vid_prevrow, entered the same way
        ;; __vid_nextrow_carry is.
        ;;
        ;; Arguments:
        ;;   HL = row pointer that has just stepped below the screen base
        ;;
        ;; Return:
        ;;   HL = the same x offset on the last row of the previous text row
        ;;
        ;; Clobbers:
        ;;   AF
__vid_prevrow_carry::
        ld      a,l
        sub     #CPC_ROW_BYTES
        ld      l,a
        ld      a,h
        sbc     a,#0xC0                 ; add 0x40 minus borrow: bank 0 -> 7
        ld      h,a
        ret

