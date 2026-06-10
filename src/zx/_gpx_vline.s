        ;; _gpx_vline.s
        ;;
        ;; Fast vertical line helper:
        ;;  - assumes y0 <= y1 (sorted)
        ;;  - quick clip reject against clip rectangle
        ;;  - clips y to clip bounds
        ;;  - draws by row stepping at fixed x bit
        ;;  - preserves pattern phase (skip + drawn span)

        .module _gpx_vline
        .optsdcc -mz80 sdcccall(1)

        .globl  __gpx_vline
        .globl  __rect_cmp16s_lt
        .globl  __clip_seg
        .globl  __vid_rowaddr
        .globl  __vid_nextrow

        .area   _CODE

        ;; ------------------------------------------------------------
        ;; __gpx_vline
        ;;
        ;; Signature is identical to gpx_draw_line():
        ;;   HL = gpx
        ;;   DE = x0
        ;;   stack: y0, x1, y1, c, m, lpatt, clip
        ;;
        ;; Returns:
        ;;   A = updated lpatt, or unchanged lpatt on reject.
__gpx_vline::
        push    ix
        ld      ix,#0
        add     ix,sp

        ;; locals (11 bytes):
        ;; -1..-2  y0
        ;; -3..-4  y1
        ;; -5      y0 original low
        ;; -6      patt current
        ;; -7      mask
        ;; -8..-9  remaining count
        ;; -10..-11 x
        ld      hl,#-11
        add     hl,sp
        ld      sp,hl

        ;; cache x/y
        ld      -10(ix),e              ;; x lo
        ld      -11(ix),d              ;; x hi
        ld      a,4(ix)
        ld      -1(ix),a               ;; y0 lo
        ld      -5(ix),a               ;; y0 original lo
        ld      a,5(ix)
        ld      -2(ix),a               ;; y0 hi
        ld      a,8(ix)
        ld      -3(ix),a               ;; y1 lo
        ld      a,9(ix)
        ld      -4(ix),a               ;; y1 hi

        ;; optional clip
        ld      a,13(ix)
        or      14(ix)
        jr      nz,gvl_clip_checks
        jp      gvl_draw

gvl_clip_checks:
        ;; BC = clip pointer
        ld      c,13(ix)
        ld      b,14(ix)

        ;; if (x < clip->x0) reject
        ld      l,-10(ix)
        ld      h,-11(ix)              ;; HL = x
        ld      e,c
        ld      d,b                    ;; DE = clip ptr
        ex      de,hl                  ;; HL = clip ptr, DE = x
        ld      a,(hl)
        inc     hl
        ld      h,(hl)
        ld      l,a                    ;; HL = clip->x0
        ex      de,hl                  ;; HL = x, DE = clip->x0
        call    __rect_cmp16s_lt
        jp      nz,gvl_reject

        ;; if (clip->x1 < x) reject
        ld      l,c
        ld      h,b
        ld      de,#4
        add     hl,de                  ;; &clip->x1
        ld      a,(hl)
        inc     hl
        ld      h,(hl)
        ld      l,a                    ;; HL = clip->x1
        ld      e,-10(ix)
        ld      d,-11(ix)              ;; DE = x
        call    __rect_cmp16s_lt
        jp      nz,gvl_reject

        ;; primary Y-axis clip via shared __clip_seg (BC = clip ptr).
        ;; IY = &clip->y0 (= clip+2); clip->y1 is at IY+4 (= clip+6).
        ld      iy,#2
        add     iy,bc
        ld      l,-1(ix)
        ld      h,-2(ix)               ;; HL = y0
        ld      e,-3(ix)
        ld      d,-4(ix)               ;; DE = y1
        call    __clip_seg
        jp      c,gvl_reject
        ld      -1(ix),l
        ld      -2(ix),h               ;; y0 = clamped lo
        ld      -3(ix),e
        ld      -4(ix),d               ;; y1 = clamped hi

gvl_draw:
        ;; patt = ror(lpatt, (y0 - y0_orig) & 7)
        ld      a,-1(ix)
        sub     -5(ix)
        and     #0x07                  ;; Z set when shift==0, A=shift
        ld      b,a                    ;; B = rotate count
        ld      a,12(ix)               ;; A = lpatt
        jr      z,gvl_patt_ready
gvl_patt_rot:
        rrca
        djnz    gvl_patt_rot
gvl_patt_ready:
        ld      -6(ix),a

        ;; mask = 0x80 >> (x & 7)
        ld      a,-10(ix)
        and     #0x07
        ld      b,a
        ld      a,#0x80
        jr      z,gvl_mask_ready
gvl_mask_loop:
        srl     a
        djnz    gvl_mask_loop
gvl_mask_ready:
        ld      -7(ix),a

        ;; HL = row pointer for y0 at x byte
        ld      b,-1(ix)               ;; y0 low
        call    __vid_rowaddr
        ld      a,-10(ix)
        srl     a
        srl     a
        srl     a
        add     a,l
        ld      l,a
        jr      nc,gvl_ptr_ok
        inc     h
gvl_ptr_ok:
        ;; preserve row pointer (dest) while computing count
        push    hl
        ;; count = (y1 - y0 + 1) -> DE
        ld      l,-3(ix)
        ld      h,-4(ix)               ;; HL = y1
        ld      e,-1(ix)
        ld      d,-2(ix)               ;; DE = y0
        or      a
        sbc     hl,de
        inc     hl                     ;; HL = count
        ex      de,hl                  ;; DE = count
        pop     hl                     ;; HL = dest row pointer

        ;; --- hot loop state held in registers ---
        ;;   B  = patt (rotates per row)
        ;;   C  = mask (invariant)
        ;;   DE = remaining row count
        ;;   HL = dest VRAM pointer
        ;; __vid_nextrow preserves BC/DE; gvl_apply_mask clobbers only A and E
        ;; (count lo), so DE is pushed around it. No (ix) access in the loop.
        ld      b,-6(ix)               ;; B = patt
        ld      c,-7(ix)               ;; C = mask

gvl_loop:
        ;; draw current point if pattern LSB set
        ld      a,b
        and     #0x01
        jr      z,gvl_after_plot
        ld      a,c                    ;; A = mask byte
        push    de                     ;; protect count (apply clobbers E)
        call    gvl_apply_mask
        pop     de

gvl_after_plot:
        dec     de                     ;; remaining--
        ld      a,e
        or      d
        jr      z,gvl_done

        rrc     b                      ;; patt = ror(patt)
        call    __vid_nextrow
        jr      gvl_loop

gvl_done:
        ;; return current pattern (already used for last pixel)
        ld      a,b
        jr      gvl_return

gvl_reject:
        ;; unchanged lpatt on reject
        ld      a,12(ix)

gvl_return:
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
        ;; Apply mask in A to (HL) using mode/color.
        ;; ------------------------------------------------------------
gvl_apply_mask:
        ld      e,a
        ld      a,11(ix)               ;; mode
        bit     0,a
        jr      nz,gvl_apply_xor
        ld      a,10(ix)               ;; color
        bit     0,a
        jr      nz,gvl_apply_set

        ;; clear
        ld      a,e
        cpl
        and     (hl)
        ld      (hl),a
        ret

gvl_apply_set:
        ;; set
        ld      a,e
        or      (hl)
        ld      (hl),a
        ret

gvl_apply_xor:
        ;; xor
        ld      a,e
        xor     (hl)
        ld      (hl),a
        ret
