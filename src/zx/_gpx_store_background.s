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

        .equ    BG_HEADER_SIZE,          5
        .equ    BG_PAYLOAD_SIZE,         32

        .equ    B_BG_LO,                 -2
        .equ    B_BG_HI,                 -1
        .equ    B_VISW,                  -3
        .equ    B_ROWCNT,                -4
        .equ    B_YCUR,                  -5
        .equ    B_SHIFT,                 -6
        .equ    B_XBYTE,                 -7

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
        push    hl
        push    ix
        ld      ix,#0
        add     ix,sp

        ld      hl,#-7
        add     hl,sp
        ld      sp,hl

        ld      B_VISW(ix),d
        ld      B_ROWCNT(ix),e
        ld      B_YCUR(ix),b

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
        ST16HL  B_BG_LO

.gsb_row_loop:
        ld      a,B_ROWCNT(ix)
        or      a
        jp      z,.gsb_done

        ld      b,B_YCUR(ix)
        call    __vid_rowaddr
        ld      a,B_XBYTE(ix)
        add     a,l
        ld      l,a
        jr      nc,.gsb_row_ptr_ok
        inc     h
.gsb_row_ptr_ok:
        ld      d,(hl)
        xor     a
        ld      e,a
        ld      c,a

        ld      a,B_SHIFT(ix)
        ld      b,a
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
        and     a
        rl      c
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
        LD16HL  B_BG_LO
        ld      (hl),d
        inc     hl
        ld      (hl),e
        inc     hl
        ST16HL  B_BG_LO

        ld      a,B_YCUR(ix)
        inc     a
        ld      B_YCUR(ix),a

        ld      a,B_ROWCNT(ix)
        dec     a
        ld      B_ROWCNT(ix),a
        jp      .gsb_row_loop

.gsb_done:
        ld      sp,ix
        pop     ix
        pop     hl
        ret
