        ;; gpx_fill_rectangle.s
        ;;
        ;; Partner rectangle fill renderer:
        ;;  - normalizes rectangle coordinates
        ;;  - clips once (screen + optional clip)
        ;;  - emits raw horizontal lines (no per-line clipping)
        ;;  - keeps fill pattern phase stable under clipping
        ;;
        ;; GPL2 License (see: LICENSE)
        ;; Copyright (C) 2026 Tomaz Stih
        ;;
        ;; 2026-03-30   TS

        .module gpx_fill_rectangle
        .optsdcc -mz80 sdcccall(1)

        .globl  _gpx_fill_rectangle
        .globl  __gpx_horizontal_prepared
        .globl  __rect_cmp16s_lt
        .globl  __rect_unpack_norm
        .globl  __ef9367_set_blit_mode
        .globl  __ef9367_set_color

        .area   _CODE

        ;; locals (30 bytes)
        .equ    R_X0_LO,               -1
        .equ    R_X0_HI,               -2
        .equ    R_X1_LO,               -3
        .equ    R_X1_HI,               -4
        .equ    R_Y0_LO,               -5
        .equ    R_Y0_HI,               -6
        .equ    R_Y1_LO,               -7
        .equ    R_Y1_HI,               -8
        .equ    R_GPX_LO,              -9
        .equ    R_GPX_HI,              -10

        .equ    V_X0_LO,               -11
        .equ    V_X0_HI,               -12
        .equ    V_X1_LO,               -13
        .equ    V_X1_HI,               -14
        .equ    V_Y0_LO,               -15
        .equ    V_Y0_HI,               -16
        .equ    V_Y1_LO,               -17
        .equ    V_Y1_HI,               -18

        .equ    C_X0_LO,               -19
        .equ    C_X0_HI,               -20
        .equ    C_X1_LO,               -21
        .equ    C_X1_HI,               -22
        .equ    C_Y0_LO,               -23
        .equ    C_Y0_HI,               -24
        .equ    C_Y1_LO,               -25
        .equ    C_Y1_HI,               -26

        .equ    Y_CUR_LO,              -27
        .equ    Y_CUR_HI,              -28
        .equ    ROW_IDX,               -29
        .equ    X_ROT,                 -30

        ;; ------------------------------------------------------------
        ;; void gpx_fill_rectangle(
        ;;   gpx_t *gpx, rect_t *r,
        ;;   color c, bmode m,
        ;;   uint8_t *fpatt, uint8_t fpatt_len,
        ;;   const rect_t *clip)
        ;;
        ;; Arguments:
        ;;   HL = gpx
        ;;   DE = r
        ;;   stack: c, m, fpatt, fpatt_len, clip
        ;;
        ;; Clobbers:
        ;;   AF, BC, DE, HL, AF'. IX and IY are preserved.
_gpx_fill_rectangle::
        push    ix
        ld      ix,#0
        add     ix,sp

        ;; preserve register arguments across local stack allocation
        ld      b,h                     ; gpx hi
        ld      c,l                     ; gpx lo

        ld      hl,#-30
        add     hl,sp
        ld      sp,hl

        ;; if (gpx == NULL) return
        ld      a,b
        or      c
        jp      z,.fr_done

        ;; if (r == NULL) return
        ld      a,d
        or      e
        jp      z,.fr_done

        ;; if (fpatt == NULL) return
        ld      a,6(ix)
        or      7(ix)
        jp      z,.fr_done

        ;; if (fpatt_len == 0) return
        ld      a,8(ix)
        or      a
        jp      z,.fr_done

        ;; save gpx
        ld      R_GPX_LO(ix),c
        ld      R_GPX_HI(ix),b

        ;; unpack + normalize r into R_*
        push    ix
        pop     hl
        call    __rect_unpack_norm

        ;; visible = normalized rect
        ld      a,R_X0_LO(ix)
        ld      V_X0_LO(ix),a
        ld      a,R_X0_HI(ix)
        ld      V_X0_HI(ix),a
        ld      a,R_X1_LO(ix)
        ld      V_X1_LO(ix),a
        ld      a,R_X1_HI(ix)
        ld      V_X1_HI(ix),a
        ld      a,R_Y0_LO(ix)
        ld      V_Y0_LO(ix),a
        ld      a,R_Y0_HI(ix)
        ld      V_Y0_HI(ix),a
        ld      a,R_Y1_LO(ix)
        ld      V_Y1_LO(ix),a
        ld      a,R_Y1_HI(ix)
        ld      V_Y1_HI(ix),a

        ;; clip visible low bounds to 0
        ld      a,V_X0_HI(ix)
        bit     7,a
        jr      z,.fr_vx0_ok
        xor     a
        ld      V_X0_LO(ix),a
        ld      V_X0_HI(ix),a
.fr_vx0_ok:
        ld      a,V_Y0_HI(ix)
        bit     7,a
        jr      z,.fr_vy0_ok
        xor     a
        ld      V_Y0_LO(ix),a
        ld      V_Y0_HI(ix),a
.fr_vy0_ok:
        ;; screen high bounds from gpx->width-1 and gpx->height-1
        ld      l,R_GPX_LO(ix)
        ld      h,R_GPX_HI(ix)
        ld      e,(hl)                  ; width lo
        inc     hl
        ld      d,(hl)                  ; width hi
        dec     de                      ; width-1

        ;; if ((width-1) < vis.x1) vis.x1 = width-1
        push    de
        ld      l,e
        ld      h,d
        ld      e,V_X1_LO(ix)
        ld      d,V_X1_HI(ix)
        call    __rect_cmp16s_lt
        pop     de
        or      a
        jr      z,.fr_x1_ok
        ld      V_X1_LO(ix),e
        ld      V_X1_HI(ix),d
.fr_x1_ok:
        ld      l,R_GPX_LO(ix)
        ld      h,R_GPX_HI(ix)
        inc     hl
        inc     hl
        ld      e,(hl)                  ; height lo
        inc     hl
        ld      d,(hl)                  ; height hi
        dec     de                      ; height-1

        ;; if ((height-1) < vis.y1) vis.y1 = height-1
        push    de
        ld      l,e
        ld      h,d
        ld      e,V_Y1_LO(ix)
        ld      d,V_Y1_HI(ix)
        call    __rect_cmp16s_lt
        pop     de
        or      a
        jr      z,.fr_y1_ok
        ld      V_Y1_LO(ix),e
        ld      V_Y1_HI(ix),d
.fr_y1_ok:
        ;; reject if vis.x1 < vis.x0
        ld      l,V_X1_LO(ix)
        ld      h,V_X1_HI(ix)
        ld      e,V_X0_LO(ix)
        ld      d,V_X0_HI(ix)
        call    __rect_cmp16s_lt
        jp      nz,.fr_done

        ;; reject if vis.y1 < vis.y0
        ld      l,V_Y1_LO(ix)
        ld      h,V_Y1_HI(ix)
        ld      e,V_Y0_LO(ix)
        ld      d,V_Y0_HI(ix)
        call    __rect_cmp16s_lt
        jp      nz,.fr_done

        ;; optional user clip
        ld      a,9(ix)
        or      10(ix)
        jp      z,.fr_clip_done

        ;; unpack clip into C_* (and normalize)
        ld      e,9(ix)
        ld      d,10(ix)

        ;; The clip fields use the same layout, displaced by 18 bytes.
        push    ix
        pop     hl
        ld      bc,#-18
        add     hl,bc
        call    __rect_unpack_norm

        ;; vis.x0 = max(vis.x0, clip.x0)
        ld      l,V_X0_LO(ix)
        ld      h,V_X0_HI(ix)
        ld      e,C_X0_LO(ix)
        ld      d,C_X0_HI(ix)
        call    __rect_cmp16s_lt
        jr      z,.fr_ix0_ok
        ld      V_X0_LO(ix),e
        ld      V_X0_HI(ix),d
.fr_ix0_ok:
        ;; vis.y0 = max(vis.y0, clip.y0)
        ld      l,V_Y0_LO(ix)
        ld      h,V_Y0_HI(ix)
        ld      e,C_Y0_LO(ix)
        ld      d,C_Y0_HI(ix)
        call    __rect_cmp16s_lt
        jr      z,.fr_iy0_ok
        ld      V_Y0_LO(ix),e
        ld      V_Y0_HI(ix),d
.fr_iy0_ok:
        ;; vis.x1 = min(vis.x1, clip.x1)
        ld      l,C_X1_LO(ix)
        ld      h,C_X1_HI(ix)
        ld      e,V_X1_LO(ix)
        ld      d,V_X1_HI(ix)
        call    __rect_cmp16s_lt
        jr      z,.fr_ix1_ok
        ld      V_X1_LO(ix),l
        ld      V_X1_HI(ix),h
.fr_ix1_ok:
        ;; vis.y1 = min(vis.y1, clip.y1)
        ld      l,C_Y1_LO(ix)
        ld      h,C_Y1_HI(ix)
        ld      e,V_Y1_LO(ix)
        ld      d,V_Y1_HI(ix)
        call    __rect_cmp16s_lt
        jr      z,.fr_iy1_ok
        ld      V_Y1_LO(ix),l
        ld      V_Y1_HI(ix),h
.fr_iy1_ok:
        ;; reject invalid after user clip
        ld      l,V_X1_LO(ix)
        ld      h,V_X1_HI(ix)
        ld      e,V_X0_LO(ix)
        ld      d,V_X0_HI(ix)
        call    __rect_cmp16s_lt
        jp      nz,.fr_done

        ld      l,V_Y1_LO(ix)
        ld      h,V_Y1_HI(ix)
        ld      e,V_Y0_LO(ix)
        ld      d,V_Y0_HI(ix)
        call    __rect_cmp16s_lt
        jp      nz,.fr_done

.fr_clip_done:
        ;; row_idx = (vis.y0 - norm.y0) % fpatt_len
        ld      l,V_Y0_LO(ix)
        ld      h,V_Y0_HI(ix)
        ld      e,R_Y0_LO(ix)
        ld      d,R_Y0_HI(ix)
        or      a
        sbc     hl,de

        ;; Bound phase setup for far-off-screen origins. Keep the common
        ;; case where the offset already fits outside the division loop.
        ld      c,8(ix)                 ; fpatt_len
        ld      a,h
        or      a
        jr      nz,.fr_mod_div
        ld      a,l
        cp      c
        jr      c,.fr_mod_done
.fr_mod_div:
        ld      b,#16
        xor     a
.fr_mod_loop:
        add     hl,hl
        rla
        jr      c,.fr_mod_sub
        cp      c
        jr      c,.fr_mod_next
.fr_mod_sub:
        sub     c
.fr_mod_next:
        djnz    .fr_mod_loop
.fr_mod_done:
        ld      ROW_IDX(ix),a

        ;; xrot = (vis.x0 - norm.x0) & 7
        ld      a,V_X0_LO(ix)
        sub     R_X0_LO(ix)
        and     #0x07
        ld      X_ROT(ix),a

        ;; ycur = vis.y0
        ld      a,V_Y0_LO(ix)
        ld      Y_CUR_LO(ix),a
        ld      a,V_Y0_HI(ix)
        ld      Y_CUR_HI(ix),a

        ;; Blit mode and colour are the same for every row, so program them
        ;; once. Only the line style can change from row to row, because each
        ;; row takes its own byte out of the fill pattern.
        ld      a,5(ix)                 ; m
        call    __ef9367_set_blit_mode
        ld      a,4(ix)                 ; c
        call    __ef9367_set_color

.fr_row_loop:
        ;; row pattern = fpatt[row_idx]
        ld      l,6(ix)
        ld      h,7(ix)
        ld      e,ROW_IDX(ix)
        ld      d,#0x00
        add     hl,de
        ld      a,(hl)
        or      a
        jr      z,.fr_row_done          ; zero pattern cannot draw any pixel
        cp      #0xFF
        jr      z,.fr_row_draw          ; FF stays FF under reversal/rotation

        ;; A fill takes its pattern MSB-first from the rectangle's left edge
        ;; -- the same way the ZX backend does it, and the same way the
        ;; bitmap payloads in this library are laid out. The row renderer
        ;; below consumes a pattern LSB-first, the way a line's lpatt
        ;; rotates, so reverse the byte here. Doing it on this side keeps
        ;; both backends drawing identical fills.
        ld      c,a
        ld      b,#8
.fr_rev_loop:
        rr      c                       ; next source bit, low end first
        rla                             ; ...lands at the high end of A
        djnz    .fr_rev_loop

        ;; Rotate the row pattern right by xrot. Both the pattern and the
        ;; count stay in registers: spilling each to the frame cost over a
        ;; hundred T-states per bit, and this runs for every row of a fill.
        ld      b,X_ROT(ix)
        inc     b                       ; djnz form: xrot 0 means no rotate
        jr      .fr_rot_test
.fr_rot_loop:
        rrca
.fr_rot_test:
        djnz    .fr_rot_loop
.fr_row_draw:
        ;; The rectangle already clipped this row and programmed its mode.
        ;; Pass coordinates directly to the frame-free patterned renderer.
        ld      l,V_X0_LO(ix)
        ld      h,V_X0_HI(ix)
        ld      e,V_X1_LO(ix)
        ld      d,V_X1_HI(ix)
        ld      c,Y_CUR_LO(ix)
        ld      b,Y_CUR_HI(ix)
        call    __gpx_horizontal_prepared

.fr_row_done:
        ;; if (ycur == vis.y1) done
        ld      a,Y_CUR_LO(ix)
        cp      V_Y1_LO(ix)
        jr      nz,.fr_next_row
        ld      a,Y_CUR_HI(ix)
        cp      V_Y1_HI(ix)
        jr      z,.fr_done

.fr_next_row:
        ;; ycur++
        ld      l,Y_CUR_LO(ix)
        ld      h,Y_CUR_HI(ix)
        inc     hl
        ld      Y_CUR_LO(ix),l
        ld      Y_CUR_HI(ix),h

        ;; row_idx = (row_idx + 1) % fpatt_len
        ld      a,ROW_IDX(ix)
        inc     a
        cp      8(ix)
        jr      c,.fr_store_row_idx
        xor     a
.fr_store_row_idx:
        ld      ROW_IDX(ix),a
        jp      .fr_row_loop

.fr_done:
        ld      sp,ix
        pop     ix

        ;; callee cleanup: c(1), m(1), fpatt(2), fpatt_len(1), clip(2) = 7
        pop     de
        ld      hl,#7
        add     hl,sp
        ld      sp,hl
        push    de
        ret
