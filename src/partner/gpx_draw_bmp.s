        ;; gpx_draw_bmp.s
        ;;
        ;; Partner bitmap renderer in assembly:
        ;;  - tiny move streams (compact + legacy headers)

        .module gpx_draw_bmp
        .optsdcc -mz80 sdcccall(1)

        .globl  _gpx_draw_bmp
        .globl  _gpx_draw_line

        .equ    BMP_ENC_TINY,          0x02
        .equ    BMP_ENC_TINY_MASK,     0x03

        .equ    CO_FORE,               0x01
        .equ    CO_BACK,               0x00
        .equ    BM_CPY,                0x00
        .equ    LPATT_SOLID,           0xFF

        ;; locals (40 bytes)
        .equ    L_GPX_LO,              -1
        .equ    L_GPX_HI,              -2
        .equ    L_X_LO,                -3
        .equ    L_X_HI,                -4
        .equ    L_Y_LO,                -5
        .equ    L_Y_HI,                -6
        .equ    L_BMP_LO,              -7
        .equ    L_BMP_HI,              -8
        .equ    L_CLIP_LO,             -9
        .equ    L_CLIP_HI,             -10

        .equ    L_W_LO,                -11
        .equ    L_W_HI,                -12
        .equ    L_H_LO,                -13
        .equ    L_H_HI,                -14
        .equ    L_MOVES,               -33
        .equ    L_I,                   -34
        .equ    L_X0_LO,               -35
        .equ    L_X0_HI,               -36
        .equ    L_Y0_LO,               -37
        .equ    L_Y0_HI,               -38
        .equ    L_DAT_LO,              -39
        .equ    L_DAT_HI,              -40

        .area   _CODE

        ;; ------------------------------------------------------------
        ;; void gpx_draw_bmp(
        ;;   gpx_t *gpx, coord x, coord y, bmp_t *b, const rect_t *clip)
        ;;
        ;; Input:
        ;;   HL = gpx
        ;;   DE = x
        ;;   stack: y, b, clip
        ;;
        ;; Clobbers:
        ;;   AF, BC, DE, HL, IX
_gpx_draw_bmp::
        push    ix
        ld      ix,#0
        add     ix,sp

        ;; preserve gpx pointer across local stack allocation
        ld      b,h                     ;; gpx hi
        ld      c,l                     ;; gpx lo

        ld      hl,#-40
        add     hl,sp
        ld      sp,hl

        ;; cache args
        ld      L_GPX_LO(ix),c
        ld      L_GPX_HI(ix),b
        ld      L_X_LO(ix),e
        ld      L_X_HI(ix),d
        ld      a,4(ix)
        ld      L_Y_LO(ix),a
        ld      a,5(ix)
        ld      L_Y_HI(ix),a
        ld      a,6(ix)
        ld      L_BMP_LO(ix),a
        ld      a,7(ix)
        ld      L_BMP_HI(ix),a
        ld      a,8(ix)
        ld      L_CLIP_LO(ix),a
        ld      a,9(ix)
        ld      L_CLIP_HI(ix),a

        ;; gpx and bmp must be non-null
        ld      a,b
        or      c
        jp      z,.bmp_done
        ld      a,L_BMP_LO(ix)
        or      L_BMP_HI(ix)
        jp      z,.bmp_done

        ;; encoding nibble
        ld      l,L_BMP_LO(ix)
        ld      h,L_BMP_HI(ix)
        ld      a,(hl)
        and     #0xF0
        rrca
        rrca
        rrca
        rrca

        cp      #BMP_ENC_TINY
        jp      z,.bmp_tiny
        cp      #BMP_ENC_TINY_MASK
        jp      z,.bmp_tiny
        jp      .bmp_done

        ;; ------------------------------------------------------------
        ;; tiny move-stream path
.bmp_tiny:
        ;; tiny payload supports two on-wire header layouts:
        ;;   compact: +0 sig, +1 w, +2 h, +3 size_lo, +4 size_hi, +5 data
        ;;   legacy:  +0 sig, +1 w, +2 h, +3 moves,            +4 data
        ld      l,L_BMP_LO(ix)
        ld      h,L_BMP_HI(ix)
        inc     hl
        inc     hl
        inc     hl
        ld      a,(hl)                  ;; size low
        ld      L_MOVES(ix),a
        inc     hl
        ld      a,(hl)                  ;; size high (compact) or first move (legacy)
        or      a
        jr      z,.bmp_tiny_compact
        jr      .bmp_tiny_legacy

.bmp_tiny_compact:
        ;; compact data pointer = b + 5
        inc     hl
        jr      .bmp_tiny_have_dat

.bmp_tiny_legacy:
        ;; legacy data pointer = b + 4
        ;; HL already points to first move byte

.bmp_tiny_have_dat:
        ld      a,L_MOVES(ix)
        or      a
        jp      z,.bmp_done

        ld      L_DAT_LO(ix),l
        ld      L_DAT_HI(ix),h

        ;; x0 = x, y0 = y (no origin bytes in payload)
        ld      l,L_X_LO(ix)
        ld      h,L_X_HI(ix)
        ld      L_X0_LO(ix),l
        ld      L_X0_HI(ix),h

        ld      l,L_Y_LO(ix)
        ld      h,L_Y_HI(ix)
        ld      L_Y0_LO(ix),l
        ld      L_Y0_HI(ix),h

        ;; i = 0
        xor     a
        ld      L_I(ix),a

.bmp_tiny_loop:
        ld      a,L_I(ix)
        cp      L_MOVES(ix)
        jp      nc,.bmp_done

        ;; mv = data[i]
        ld      l,L_DAT_LO(ix)
        ld      h,L_DAT_HI(ix)
        ld      e,a
        ld      d,#0x00
        add     hl,de
        ld      a,(hl)
        ld      c,a                     ;; C = move byte

        ;; x1 = x0 +/- dx
        ld      a,c
        and     #0x60
        rrca
        rrca
        rrca
        rrca
        rrca
        and     #0x03
        ld      e,a
        ld      d,#0x00
        ld      l,L_X0_LO(ix)
        ld      h,L_X0_HI(ix)
        ld      a,c
        bit     1,a
        jr      z,.bmp_dx_add
        or      a
        sbc     hl,de
        jr      .bmp_dx_done
.bmp_dx_add:
        add     hl,de
.bmp_dx_done:
        ld      L_W_LO(ix),l            ;; reuse locals as x1
        ld      L_W_HI(ix),h

        ;; y1 = y0 +/- dy
        ld      a,c
        and     #0x18
        rrca
        rrca
        rrca
        and     #0x03
        ld      e,a
        ld      d,#0x00
        ld      l,L_Y0_LO(ix)
        ld      h,L_Y0_HI(ix)
        ld      a,c
        bit     2,a
        jr      z,.bmp_dy_add
        or      a
        sbc     hl,de
        jr      .bmp_dy_done
.bmp_dy_add:
        add     hl,de
.bmp_dy_done:
        ld      L_H_LO(ix),l            ;; reuse locals as y1
        ld      L_H_HI(ix),h

        ;; color code: (bit0 ? 2 : 0) + (bit7 ? 1 : 0)
        ld      b,#0
        ld      a,c
        bit     0,a
        jr      z,.bmp_cc_b7
        ld      b,#2
.bmp_cc_b7:
        bit     7,a
        jr      z,.bmp_cc_done
        inc     b
.bmp_cc_done:
        ;; draw only for fore/back
        ld      a,b
        cp      #1
        jr      z,.bmp_tiny_fore
        cp      #2
        jr      z,.bmp_tiny_back
        cp      #3
        jr      z,.bmp_tiny_back
        jr      .bmp_tiny_advance

.bmp_tiny_fore:
        ld      b,#CO_FORE
        jr      .bmp_tiny_draw
.bmp_tiny_back:
        ld      b,#CO_BACK

.bmp_tiny_draw:
        ;; gpx_draw_line(gpx, x0, y0, x1, y1, color, BM_CPY, 0xFF, clip)
        ld      l,L_CLIP_LO(ix)
        ld      h,L_CLIP_HI(ix)
        push    hl                     ;; clip

        ld      a,#LPATT_SOLID
        dec     sp
        ld      hl,#0
        add     hl,sp
        ld      (hl),a                 ;; lpatt

        ld      l,b                     ;; color
        ld      h,#BM_CPY
        push    hl                     ;; c,m

        ld      l,L_H_LO(ix)
        ld      h,L_H_HI(ix)
        push    hl                     ;; y1

        ld      l,L_W_LO(ix)
        ld      h,L_W_HI(ix)
        push    hl                     ;; x1

        ld      l,L_Y0_LO(ix)
        ld      h,L_Y0_HI(ix)
        push    hl                     ;; y0

        ld      l,L_GPX_LO(ix)
        ld      h,L_GPX_HI(ix)
        ld      e,L_X0_LO(ix)
        ld      d,L_X0_HI(ix)
        call    _gpx_draw_line

.bmp_tiny_advance:
        ;; x0 = x1, y0 = y1
        ld      a,L_W_LO(ix)
        ld      L_X0_LO(ix),a
        ld      a,L_W_HI(ix)
        ld      L_X0_HI(ix),a
        ld      a,L_H_LO(ix)
        ld      L_Y0_LO(ix),a
        ld      a,L_H_HI(ix)
        ld      L_Y0_HI(ix),a

        ;; i++
        ld      a,L_I(ix)
        inc     a
        ld      L_I(ix),a
        jp      .bmp_tiny_loop

.bmp_done:
        ld      sp,ix
        pop     ix

        ;; callee cleanup: y(2), bmp(2), clip(2) = 6
        pop     de
        ld      hl,#6
        add     hl,sp
        ld      sp,hl
        push    de
        ret
