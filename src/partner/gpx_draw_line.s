        ;; gpx_draw_line.s
        ;;
        ;; Partner line drawing with optional Cohen-Sutherland clipping.
        ;;
        ;; Pattern policy:
        ;;   known Partner hardware patterns -> EF9367 vector styles
        ;;   else -> software Bresenham using pixel command

        .module gpx_draw_line
        .optsdcc -mz80 sdcccall(1)

        .globl  _gpx_draw_line
        .globl  __gpx_cohen_sutherland
        .globl  __gpx_bresenham_line_local
        .globl  __ef9367_exec_cmd
        .globl  __ef9367_set_blit_mode
        .globl  __ef9367_set_color
        .globl  __ef9367_set_line_style
        .globl  __ef9367_set_xy
        .globl  __ef9367_get_delta_cmd
        .globl  __abs_hl

        .include "_ef9367-defs.inc"

        .equ    LPATT_SOLID,         0xFF
        .equ    LPATT_DOTTED_A,      0xCC
        .equ    LPATT_DOTTED_B,      0xAA
        .equ    LPATT_DASHED,        0xF0
        .equ    LPATT_DOT_DASH,      0xE4

        ;; locals (37 bytes)
        ;; -12..-11 x0
        ;; -10..-9  y0
        ;; -8..-7   x1
        ;; -6..-5   y1
        ;; -4       lpatt (working)
        ;; -2       lpatt return value
        ;; -1       vector command
        .equ    S_X0_LO,             -12
        .equ    S_X0_HI,             -11
        .equ    S_Y0_LO,             -10
        .equ    S_Y0_HI,             -9
        .equ    S_X1_LO,             -8
        .equ    S_X1_HI,             -7
        .equ    S_Y1_LO,             -6
        .equ    S_Y1_HI,             -5
        .equ    S_LPATT,             -4

        .equ    LPATT_RET,           -2
        .equ    VEC_CMD,             -1

        .area   _CODE

        ;; ------------------------------------------------------------
        ;; uint8_t gpx_draw_line(gpx_t *gpx,
        ;;                       coord x0, coord y0, coord x1, coord y1,
        ;;                       color c, bmode m, uint8_t lpatt,
        ;;                       const rect_t *clip)
        ;;
        ;; Input:
        ;;   HL = gpx (unused by this routine)
        ;;   DE = x0
        ;;   stack: y0, x1, y1, c, m, lpatt, clip
        ;;
        ;; Output:
        ;;   A = resulting lpatt
        ;;
        ;; Clobbers:
        ;;   AF, BC, DE, HL, IX, IY
_gpx_draw_line::
        push    ix
        ld      ix,#0
        add     ix,sp

        ld      hl,#-37
        add     hl,sp
        ld      sp,hl

        ;; Cache line endpoints into local state.
        ld      S_X0_LO(ix),e
        ld      S_X0_HI(ix),d

        ld      a,4(ix)
        ld      S_Y0_LO(ix),a
        ld      a,5(ix)
        ld      S_Y0_HI(ix),a

        ld      a,6(ix)
        ld      S_X1_LO(ix),a
        ld      a,7(ix)
        ld      S_X1_HI(ix),a

        ld      a,8(ix)
        ld      S_Y1_LO(ix),a
        ld      a,9(ix)
        ld      S_Y1_HI(ix),a

        ld      a,12(ix)
        ld      S_LPATT(ix),a
        ld      LPATT_RET(ix),a

        ;; Optional clipping:
        ;; if clip != NULL, run Cohen-Sutherland; otherwise draw as-is.
        ld      e,13(ix)
        ld      d,14(ix)
        ld      a,e
        or      d
        jr      z,.gdl_dispatch

        push    ix
        pop     hl
        ld      bc,#S_X0_LO
        add     hl,bc                  ;; HL = &state.x0
        call    __gpx_cohen_sutherland
        or      a
        jr      nz,.gdl_dispatch       ;; accepted

        ;; Rejected by clip window.
        jr      .gdl_return

.gdl_dispatch:
        ;; Apply requested blit mode and color once for this line.
        ld      a,11(ix)               ;; m
        call    __ef9367_set_blit_mode

        ld      a,10(ix)               ;; c
        call    __ef9367_set_color

        ;; Pattern-based path selection:
        ;; use EF9367 hardware style when pattern is recognized.
        ld      a,S_LPATT(ix)
        call    .gdl_hw_style_from_lpatt
        jr      c,.gdl_draw_hw
        jr      .gdl_draw_bres

.gdl_draw_hw:
        call    __ef9367_set_line_style
        call    .gdl_draw_vector
        jr      .gdl_return

.gdl_draw_bres:
        call    __gpx_bresenham_line_local

.gdl_return:
        ld      a,LPATT_RET(ix)

        ld      sp,ix
        pop     ix

        ;; callee cleanup: y0(2), x1(2), y1(2), c(1), m(1), lpatt(1), clip(2) = 11
        pop     de
        ld      hl,#11
        add     hl,sp
        ld      sp,hl
        push    de
        ret

        ;; ------------------------------------------------------------
        ;; Map lpatt to EF9367 CR2 hardware vector style.
        ;; Input:
        ;;   A = lpatt
        ;; Output:
        ;;   if recognized: A = EF9367_CR2_* style, carry=1
        ;;   else:          A = original lpatt, carry=0
.gdl_hw_style_from_lpatt:
        ld      c,a

        ;; solid
        cp      #LPATT_SOLID
        jr      z,.gdl_hw_solid

        ;; Match all rotated hardware-recognized patterns in one loop.
        ld      b,#8
.gdl_hw_rot_loop:
        cp      #0x33
        jr      z,.gdl_hw_dotted
        cp      #LPATT_DOTTED_B
        jr      z,.gdl_hw_dotted
        cp      #LPATT_DASHED
        jr      z,.gdl_hw_dashed
        cp      #LPATT_DOT_DASH
        jr      z,.gdl_hw_dot_dash
        rrca
        djnz    .gdl_hw_rot_loop

        ;; unsupported custom pattern -> software path.
        ld      a,c
        or      a                      ;; clears carry
        ret

.gdl_hw_solid:
        ld      a,#EF9367_CR2_SOLID
        scf
        ret

.gdl_hw_dotted:
        ld      a,#EF9367_CR2_DOTTED
        scf
        ret

.gdl_hw_dashed:
        ld      a,#EF9367_CR2_DASHED
        scf
        ret

.gdl_hw_dot_dash:
        ld      a,#EF9367_CR2_DOT_DASH
        scf
        ret

        ;; ------------------------------------------------------------
        ;; Draw clipped segment using EF9367 vector commands.
        ;; Uses recursive halving in delta space for >255 projection.
.gdl_draw_vector:
        ;; dx = x1 - x0
        ld      l,S_X1_LO(ix)
        ld      h,S_X1_HI(ix)
        ld      e,S_X0_LO(ix)
        ld      d,S_X0_HI(ix)
        or      a
        sbc     hl,de
        push    hl                     ;; save signed dx

        ;; Set origin to x0,y0.
        ex      de,hl                  ;; HL = x0
        ld      e,S_Y0_LO(ix)
        ld      d,S_Y0_HI(ix)
        call    __ef9367_set_xy

        ;; dy = y1 - y0
        ld      l,S_Y1_LO(ix)
        ld      h,S_Y1_HI(ix)
        or      a
        sbc     hl,de                  ;; DE still y0
        ex      de,hl                  ;; DE = signed dy
        pop     hl                     ;; HL = signed dx

        ;; Degenerate point (dx=0 && dy=0).
        ld      a,h
        or      l
        jr      nz,.gdl_vec_not_point
        ld      a,d
        or      e
        jr      nz,.gdl_vec_not_point
        xor     a
        out     (#EF9367_DX),a
        out     (#EF9367_DY),a
        ld      a,#0b00010001
        call    __ef9367_exec_cmd
        ret

.gdl_vec_not_point:
        ;; Build direction command and absolute deltas.
        call    __ef9367_get_delta_cmd
        ld      VEC_CMD(ix),a

        call    __abs_hl                ;; HL = abs(dx)
        ex      de,hl                  ;; DE = abs(dx), HL = signed dy
        call    __abs_hl                ;; HL = abs(dy)

        ;; Work queue: push pair as (dx,dy); pop as (dy,dx).
        push    de                     ;; dx
        push    hl                     ;; dy
        ld      b,#1                   ;; pair count

.gdl_vec_loop:
        pop     de                     ;; dy
        pop     hl                     ;; dx

        ;; Fits EF9367 delta register when both high bytes are 0.
        ld      a,d
        or      h
        jr      nz,.gdl_vec_divide

        ld      a,l
        out     (#EF9367_DX),a
        ld      a,e
        out     (#EF9367_DY),a
        ld      a,VEC_CMD(ix)
        call    __ef9367_exec_cmd
        djnz    .gdl_vec_loop
        ret

.gdl_vec_divide:
        ;; Split (dx,dy) into two halves:
        ;; first: floor/2, second: ceil/2
        ld      a,l
        and     #1
        ld      c,a
        srl     h
        rr      l
        push    hl                     ;; dx1
        ld      a,c
        or      a
        jr      z,.gdl_vec_dx2_ready
        inc     hl                     ;; dx2 = dx1 + 1
.gdl_vec_dx2_ready:

        ld      a,e
        and     #1
        ld      c,a
        srl     d
        rr      e
        push    de                     ;; dy1
        ld      a,c
        or      a
        jr      z,.gdl_vec_dy2_ready
        inc     de                     ;; dy2 = dy1 + 1
.gdl_vec_dy2_ready:

        push    hl                     ;; dx2
        push    de                     ;; dy2
        inc     b
        inc     b
        djnz    .gdl_vec_loop
        ret
