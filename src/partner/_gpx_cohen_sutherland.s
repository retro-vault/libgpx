        ;; _gpx_cohen_sutherland.s
        ;;
        ;; Cohen-Sutherland line clip with exact parametric intersections.
        ;;
        ;; Replaces the earlier bisection-based implementation: coordinate
        ;; -pair bisection converges on the clipped edge axis but leaves
        ;; the transverse coordinate unsupervised (it tracks the chord of
        ;; rounded midpoints, not the line), drifting up to the length of
        ;; a grazing run. The intersection here is computed from the line
        ;; equation with unsigned 16-bit magnitudes:
        ;;     n = a0 +/- |a1-a0| * |edge-b0| / |b1-b0|
        ;; using a 16x16->32 shift-add multiply and a 32/16 restoring
        ;; divide (the numerator high word is provably below the divisor,
        ;; so 16 quotient bits always suffice). Truncating semantics match
        ;; a C int32 expression bit for bit.
        ;;
        ;; Edge priority: TOP, BOTTOM, RIGHT, LEFT. A rect with swapped
        ;; corners rejects every line (both outcodes share a bit).
        ;;
        ;; Re-entrant: all state lives in registers and the stack frame.
        ;;
        ;; GPL2 License (see: LICENSE)
        ;; Copyright (C) 2026 Tomaz Stih
        ;;
        ;; 2026-07-13   TS

        .module _gpx_cohen_sutherland
        .optsdcc -mz80 sdcccall(1)

        .globl  __gpx_cohen_sutherland
        .globl  __rect_cmp16s_lt

        ;; frame locals (IX-relative)
        .equ    L_S,    -2              ; state ptr (x0,y0,x1,y1 words)
        .equ    L_R,    -4              ; rect ptr
        .equ    L_NB,   -6              ; word: clip-edge coordinate
        .equ    L_SIGN, -7              ; folded sign of the offset
        .equ    L_AXIS, -8              ; 0 = x-flavor (T/B), 1 = y (R/L)
        .equ    L_A0,   -10             ; word: intersection base coord

        ;; state-field offsets
        .equ    SO_X0,  0
        .equ    SO_Y0,  2
        .equ    SO_X1,  4
        .equ    SO_Y1,  6

        .area   _CODE

        ;; ------------------------------------------------------------
        ;; __gpx_cohen_sutherland
        ;; Clip a line to a rectangle, in place.
        ;;
        ;; Signature:
        ;;   uint8_t gpx_cohen_sutherland(gpx_line_state_t *s,
        ;;                                const rect_t *r)
        ;;
        ;; Arguments:
        ;;   HL = s, four consecutive words x0,y0,x1,y1, clipped in place
        ;;   DE = r
        ;;
        ;; Return:
        ;;   A = 1 accepted and clipped, 0 rejected entirely
        ;;
        ;; Clobbers:
        ;;   AF, BC, DE, HL, IY
        ;;
        ;; References:
        ;;   __rect_cmp16s_lt
        ;; ------------------------------------------------------------
__gpx_cohen_sutherland::
        push    ix
        ld      ix,#0
        add     ix,sp
        push    hl                      ; L_S
        push    de                      ; L_R
        ld      hl,#-6                  ; NB, SIGN, AXIS, A0
        add     hl,sp
        ld      sp,hl
        push    de
        pop     iy                      ; IY = rect (field access)

.cs_loop:
        xor     a                       ; endpoint 0
        call    .cs_outc
        ld      b,a                     ; B = c0
        ld      a,#SO_X1                ; endpoint 1
        call    .cs_outc                ; A = c1 (B preserved)
        ld      c,a
        or      b
        jp      z,.cs_accept
        ld      a,b
        and     c
        jp      nz,.cs_reject

        push    bc                      ; save which-endpoint (B = c0)
        ld      a,b
        or      a
        jr      nz,.cs_disp
        ld      a,c

        ;; edge select (priority T, B, R, L): NB = edge value, AXIS flavor
.cs_disp:
        bit     2,a                     ; TOP
        jr      z,.cd_notT
        ld      e,2(iy)
        ld      d,3(iy)
        xor     a
        jr      .cs_edge
.cd_notT:
        bit     3,a                     ; BOTTOM
        jr      z,.cd_notB
        ld      e,6(iy)
        ld      d,7(iy)
        xor     a
        jr      .cs_edge
.cd_notB:
        bit     1,a                     ; RIGHT
        jr      z,.cd_left
        ld      e,4(iy)
        ld      d,5(iy)
        ld      a,#1
        jr      .cs_edge
.cd_left:
        ld      e,0(iy)                 ; LEFT
        ld      d,1(iy)
        ld      a,#1
.cs_edge:
        ld      L_NB(ix),e
        ld      L_NB+1(ix),d
        ld      L_AXIS(ix),a

        ;; ---- intersection: n = a0 +/- m1*m2/m3 ----
        ;; P = |x1 - x0| (sign parked in B), Q = |y1 - y0| (sign in A)
        ld      a,#SO_X0
        call    .cs_ldst
        ex      de,hl                   ; DE = x0
        ld      a,#SO_X1
        call    .cs_ldst                ; HL = x1
        call    .cs_absd
        ld      b,a
        push    hl                      ; park P
        ld      a,#SO_Y0
        call    .cs_ldst
        ex      de,hl
        ld      a,#SO_Y1
        call    .cs_ldst
        call    .cs_absd                ; HL = Q, A = sQ
        xor     b
        ld      L_SIGN(ix),a            ; sP ^ sQ (m2 sign folded below)
        pop     de                      ; DE = P, HL = Q

        ld      a,L_AXIS(ix)
        or      a
        jr      nz,.ci_yflav
        ;; x-flavor: m1 = P, m3 = Q, b0 = y0, a0 = x0
        push    de                      ; [m1 = P]
        push    hl                      ; park m3 = Q
        ld      a,#SO_X0
        call    .cs_ldst
        ld      L_A0(ix),l
        ld      L_A0+1(ix),h
        ld      a,#SO_Y0
        jr      .ci_m2
.ci_yflav:
        ;; y-flavor: m1 = Q, m3 = P, b0 = x0, a0 = y0
        push    hl                      ; [m1 = Q]
        push    de                      ; park m3 = P
        ld      a,#SO_Y0
        call    .cs_ldst
        ld      L_A0(ix),l
        ld      L_A0+1(ix),h
        ld      a,#SO_X0
.ci_m2:
        call    .cs_ldst
        ex      de,hl                   ; DE = b0
        ld      l,L_NB(ix)
        ld      h,L_NB+1(ix)            ; HL = edge value
        call    .cs_absd                ; HL = m2 = |nb - b0|, A = sign
        ex      de,hl                   ; DE = m2
        ld      l,a
        ld      a,L_SIGN(ix)
        xor     l
        ld      L_SIGN(ix),a
        pop     hl                      ; m3
        pop     bc                      ; m1
        push    hl                      ; park m3
        call    .cs_mul16               ; DE:HL = m1 * m2
        ex      de,hl                   ; HL = hi, DE = lo
        pop     bc                      ; m3
        call    .cs_div                 ; DE = quotient
        ld      l,L_A0(ix)
        ld      h,L_A0+1(ix)
        ld      a,L_SIGN(ix)
        or      a
        jr      z,.ci_add
        sbc     hl,de                   ; carry clear from or above
        jr      .cs_put
.ci_add:
        add     hl,de

        ;; ---- write the moved endpoint back into the state ----
.cs_put:
        ex      de,hl                   ; DE = computed coordinate
        ld      l,L_NB(ix)
        ld      h,L_NB+1(ix)            ; HL = edge value
        ld      a,L_AXIS(ix)
        or      a
        jr      nz,.cp_go               ; y-flavor: x = NB, y = computed
        ex      de,hl                   ; x-flavor: x = computed, y = NB
.cp_go:
        ;; HL = new x, DE = new y; target = out endpoint (c0 != 0 -> p0)
        pop     bc                      ; B = c0
        ld      a,b
        or      a
        ld      a,#SO_X0
        jr      nz,.cp_off
        ld      a,#SO_X1
.cp_off:
        push    hl                      ; save new x
        ld      l,L_S(ix)
        ld      h,L_S+1(ix)
        add     a,l
        ld      l,a
        jr      nc,.cp_ptr
        inc     h
.cp_ptr:
        pop     bc                      ; BC = new x
        ld      (hl),c
        inc     hl
        ld      (hl),b
        inc     hl
        ld      (hl),e
        inc     hl
        ld      (hl),d
        jp      .cs_loop

.cs_accept:
        ld      a,#1
        jr      .cs_done
.cs_reject:
        xor     a
.cs_done:
        ld      sp,ix
        pop     ix
        ret

        ;; ------------------------------------------------------------
        ;; .cs_outc: outcode of a state endpoint vs the rect (IY)
        ;;   IN:  A = state offset (0 = p0, 4 = p1)
        ;;   OUT: A = code (L=1, R=2, T=4, B=8)
        ;; Preserves B; clobbers C, DE, HL.
        ;; ------------------------------------------------------------
.cs_outc:
        ld      l,L_S(ix)
        ld      h,L_S+1(ix)
        add     a,l
        ld      l,a
        jr      nc,.co_pt
        inc     h
.co_pt:
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        inc     hl
        ld      a,(hl)
        inc     hl
        ld      h,(hl)
        ld      l,a                     ; HL = py, DE = px
        push    hl                      ; preserve py while comparing px
        ex      de,hl                   ; HL = px
        ld      c,#0
        ;; L: px < rx0 ?
        ld      e,0(iy)
        ld      d,1(iy)
        call    __rect_cmp16s_lt
        jr      z,.co_r
        set     0,c
.co_r:
        ;; R: rx1 < px ?
        ex      de,hl                   ; comparator left px in HL
        ld      l,4(iy)
        ld      h,5(iy)
        call    __rect_cmp16s_lt
        jr      z,.co_t
        set     1,c
.co_t:
        ;; T: py < ry0 ?
        pop     hl                      ; HL = py
        ld      e,2(iy)
        ld      d,3(iy)
        call    __rect_cmp16s_lt
        jr      z,.co_b
        set     2,c
.co_b:
        ;; B: ry1 < py ?
        ex      de,hl                   ; comparator left py in HL
        ld      l,6(iy)
        ld      h,7(iy)
        call    __rect_cmp16s_lt
        jr      z,.co_ret
        set     3,c
.co_ret:
        ld      a,c
        ret

        ;; .cs_ldst: HL = state word at offset A.
.cs_ldst:
        ld      l,L_S(ix)
        ld      h,L_S+1(ix)
        add     a,l
        ld      l,a
        jr      nc,.cl_rd
        inc     h
.cl_rd:
        ld      a,(hl)
        inc     hl
        ld      h,(hl)
        ld      l,a
        ret

        ;; .cs_absd: HL = |HL - DE| (signed operands), A = 1 iff HL < DE.
        ;; Preserves BC.
.cs_absd:
        call    __rect_cmp16s_lt
        jr      z,.ca_sub
        ex      de,hl
.ca_sub:
        or      a                       ; clear carry, keep A
        sbc     hl,de
        ret

        ;; DE:HL = DE * BC (unsigned 16x16 -> 32)
.cs_mul16:
        ld      hl,#0
        ld      a,#16
.cm_loop:
        add     hl,hl
        rl      e
        rl      d
        jr      nc,.cm_next
        add     hl,bc
        jr      nc,.cm_next
        inc     de
.cm_next:
        dec     a
        jr      nz,.cm_loop
        ret

        ;; DE = HL:DE / BC (requires HL < BC; quotient < 2^16 guaranteed),
        ;; HL = remainder
.cs_div:
        ld      a,#16
.cd_loop:
        sla     e
        rl      d
        adc     hl,hl
        jr      c,.cd_s17
        sbc     hl,bc
        jr      nc,.cd_one
        add     hl,bc
        jr      .cd_next
.cd_s17:
        or      a
        sbc     hl,bc
.cd_one:
        inc     e
.cd_next:
        dec     a
        jr      nz,.cd_loop
        ret
