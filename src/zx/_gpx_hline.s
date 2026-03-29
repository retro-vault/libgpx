        ;; _gpx_hline.s
        ;;
        ;; Fast horizontal line helper:
        ;;  - assumes x0 <= x1 (sorted)
        ;;  - quick clip reject against clip rectangle
        ;;  - clips x to clip bounds
        ;;  - draws by bytes (start/stop masks + full middle bytes)
        ;;  - preserves pattern phase (skip + drawn span)

        .module _gpx_hline
        .optsdcc -mz80 sdcccall(1)

        .globl  __gpx_hline
        .globl  __rect_cmp16s_lt
        .globl  __vid_rowaddr

        .area   _CODE

        ;; ------------------------------------------------------------
        ;; __gpx_hline
        ;;
        ;; Signature is identical to gpx_draw_line():
        ;;   HL = gpx
        ;;   DE = x0
        ;;   stack: y0, x1, y1, c, m, lpatt, clip
        ;;
        ;; Returns:
        ;;   A = updated lpatt, or unchanged lpatt on reject.
__gpx_hline::
        push    ix
        ld      ix,#0
        add     ix,sp

        ;; locals (11 bytes):
        ;; -1..-2  x0
        ;; -3..-4  x1
        ;; -5      x0 original low
        ;; -6      patt_start
        ;; -7      patt_byte
        ;; -8      mask_first
        ;; -9      mask_last
        ;; -10     byte_lo
        ;; -11     byte_hi
        ld      hl,#-11
        add     hl,sp
        ld      sp,hl

        ;; cache x0/x1
        ld      -2(ix),e               ;; x0 lo
        ld      -1(ix),d               ;; x0 hi
        ld      -5(ix),e               ;; x0 original lo
        ld      a,6(ix)
        ld      -4(ix),a               ;; x1 lo
        ld      a,7(ix)
        ld      -3(ix),a               ;; x1 hi

        ;; optional clip
        ld      a,13(ix)
        or      14(ix)
        jr      nz,ghl_clip_checks
        jp      ghl_draw

ghl_clip_checks:
        ;; BC = clip pointer
        ld      c,13(ix)
        ld      b,14(ix)

        ;; if (y < clip->y0) reject
        ld      l,c
        ld      h,b
        inc     hl
        inc     hl                     ;; &clip->y0
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ld      l,4(ix)                ;; y
        ld      h,5(ix)
        call    __rect_cmp16s_lt
        jp      nz,ghl_reject

        ;; if (clip->y1 < y) reject
        ld      l,c
        ld      h,b
        ld      de,#6
        add     hl,de                  ;; &clip->y1
        ld      a,(hl)
        inc     hl
        ld      h,(hl)
        ld      l,a                    ;; HL = clip->y1
        ld      e,4(ix)
        ld      d,5(ix)                ;; DE = y
        call    __rect_cmp16s_lt
        jp      nz,ghl_reject

        ;; if (clip->x1 < x0) reject
        ld      l,c
        ld      h,b
        ld      de,#4
        add     hl,de                  ;; &clip->x1
        ld      a,(hl)
        inc     hl
        ld      h,(hl)
        ld      l,a                    ;; HL = clip->x1
        ld      e,-2(ix)
        ld      d,-1(ix)               ;; DE = x0
        call    __rect_cmp16s_lt
        jp      nz,ghl_reject

        ;; if (x1 < clip->x0) reject
        ld      l,-4(ix)
        ld      h,-3(ix)               ;; HL = x1
        push    hl
        ld      l,c
        ld      h,b                    ;; HL = &clip->x0
        ld      e,(hl)
        inc     hl
        ld      d,(hl)                 ;; DE = clip->x0
        pop     hl                     ;; HL = x1
        call    __rect_cmp16s_lt
        jp      nz,ghl_reject

        ;; if (x0 < clip->x0) x0 = clip->x0
        ld      l,-2(ix)
        ld      h,-1(ix)               ;; HL = x0
        ld      e,c
        ld      d,b
        ex      de,hl                  ;; HL = clip ptr, DE = x0
        ld      a,(hl)
        inc     hl
        ld      h,(hl)
        ld      l,a                    ;; HL = clip->x0
        ex      de,hl                  ;; HL = x0, DE = clip->x0
        call    __rect_cmp16s_lt
        jr      z,ghl_no_clip_left
        ld      -2(ix),e
        ld      -1(ix),d

ghl_no_clip_left:
        ;; if (clip->x1 < x1) x1 = clip->x1
        ld      l,c
        ld      h,b
        ld      de,#4
        add     hl,de                  ;; &clip->x1
        ld      a,(hl)
        inc     hl
        ld      h,(hl)
        ld      l,a                    ;; HL = clip->x1
        ld      e,-4(ix)
        ld      d,-3(ix)               ;; DE = x1
        call    __rect_cmp16s_lt
        jr      z,ghl_draw
        ld      -4(ix),l
        ld      -3(ix),h

ghl_draw:
        ;; patt_start = ror(lpatt, (x0 - x0_orig) & 7)
        ld      a,-2(ix)
        sub     -5(ix)
        and     #0x07
        ld      b,a
        ld      a,b
        or      a
        ld      a,12(ix)
        jr      z,ghl_pstart_store
ghl_pstart_rot:
        rrca
        djnz    ghl_pstart_rot
ghl_pstart_store:
        ld      -6(ix),a

        ;; n = x0 & 7
        ld      a,-2(ix)
        and     #0x07
        ld      c,a

        ;; patt_byte = rotl(reverse_bits(patt_start), (8 - n) & 7)
        ld      a,-6(ix)
        ld      d,#0
        ld      b,#8
ghl_rev_loop:
        rrca
        rl      d
        djnz    ghl_rev_loop

        ld      a,c
        or      a
        jr      z,ghl_pbyte_store
        ld      a,#8
        sub     c
        ld      c,a
        ld      a,d
ghl_pbyte_rot:
        rlca
        dec     c
        jr      nz,ghl_pbyte_rot
        ld      d,a
ghl_pbyte_store:
        ld      a,d
        ld      -7(ix),a

        ;; mask_first = 0xFF >> n
        ld      a,-2(ix)
        and     #0x07
        ld      b,a
        ld      a,#0xff
        jr      z,ghl_mfirst_store
ghl_mfirst_loop:
        srl     a
        djnz    ghl_mfirst_loop
ghl_mfirst_store:
        ld      -8(ix),a

        ;; mask_last = 0xFF << (7 - (x1 & 7))
        ld      a,-4(ix)
        and     #0x07
        ld      c,a
        ld      a,#7
        sub     c
        ld      b,a
        ld      a,#0xff
        jr      z,ghl_mlast_store
ghl_mlast_loop:
        sla     a
        djnz    ghl_mlast_loop
ghl_mlast_store:
        ld      -9(ix),a

        ;; byte_lo = x0 >> 3
        ld      a,-2(ix)
        srl     a
        srl     a
        srl     a
        ld      -10(ix),a

        ;; byte_hi = x1 >> 3
        ld      a,-4(ix)
        srl     a
        srl     a
        srl     a
        ld      -11(ix),a

        ;; HL = row base + byte_lo
        ld      b,4(ix)                ;; y low
        call    __vid_rowaddr
        ld      a,-10(ix)
        add     a,l
        ld      l,a
        jr      nc,ghl_row_ptr_ok
        inc     h
ghl_row_ptr_ok:
        ;; single-byte span?
        ld      a,-10(ix)
        cp      -11(ix)
        jr      nz,ghl_multi_byte

        ld      a,-8(ix)
        and     -9(ix)
        and     -7(ix)
        call    ghl_apply_mask
        jr      ghl_ret_pattern

ghl_multi_byte:
        ;; first byte
        ld      a,-7(ix)
        and     -8(ix)
        call    ghl_apply_mask

        ;; middle full bytes count = byte_hi - byte_lo - 1
        ld      a,-11(ix)
        sub     -10(ix)
        dec     a
        jr      z,ghl_last_byte
        ld      b,a
ghl_mid_loop:
        inc     hl
        ld      a,-7(ix)
        call    ghl_apply_mask
        djnz    ghl_mid_loop

ghl_last_byte:
        inc     hl
        ld      a,-7(ix)
        and     -9(ix)
        call    ghl_apply_mask

ghl_ret_pattern:
        ;; return patt = ror(patt_start, (x1-x0) & 7)
        ld      a,-4(ix)
        sub     -2(ix)
        and     #0x07
        ld      b,a
        ld      a,b
        or      a
        ld      a,-6(ix)
        jr      z,ghl_return
ghl_pret_rot:
        rrca
        djnz    ghl_pret_rot
        jr      ghl_return

ghl_reject:
        ;; unchanged lpatt on reject
        ld      a,12(ix)

ghl_return:
        ld      sp,ix
        pop     ix
        pop     hl
        pop     bc
        pop     bc
        pop     bc
        pop     bc
        pop     bc
        inc     sp
        jp      (hl)

        ;; ------------------------------------------------------------
        ;; Apply masked byte in A to (HL) using mode/color arguments.
        ;; ------------------------------------------------------------
ghl_apply_mask:
        push    bc
        ld      e,a
        ld      a,11(ix)               ;; mode
        bit     0,a
        jr      nz,ghl_apply_xor
        ld      a,10(ix)               ;; color
        bit     0,a
        jr      nz,ghl_apply_set

        ;; clear selected bits
        ld      a,e
        cpl
        and     (hl)
        ld      (hl),a
        jr      ghl_apply_done

ghl_apply_set:
        ;; set selected bits
        ld      a,e
        or      (hl)
        ld      (hl),a
        jr      ghl_apply_done

ghl_apply_xor:
        ;; xor selected bits
        ld      a,e
        xor     (hl)
        ld      (hl),a
ghl_apply_done:
        pop     bc
        ret
