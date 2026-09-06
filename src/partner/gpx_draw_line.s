        ;; gpx_draw_line.s
        ;;
        ;; Partner line drawing with optional Cohen-Sutherland clipping.
        ;;
        ;; Solid lines use the EF9367 vector generator. Longer horizontal
        ;; patterns use exact native 2-on/2-off or 4-on/4-off styles when
        ;; possible; XOR also composes two shifted native strokes. Every
        ;; other pattern follows the shared software Bresenham contract.
        ;; Pattern phase and finite endpoints are preserved in all cases.
        ;;
        ;; GPL2 License (see: LICENSE)
        ;; Copyright (C) 2026 Tomaz Stih
        ;;
        ;; 2026-03-30   TS

        .module gpx_draw_line
        .optsdcc -mz80 sdcccall(1)

        .globl  _gpx_draw_line
        .globl  __gpx_hline
        .globl  __ret_clean11
        .globl  __gpx_cohen_sutherland
        .globl  __gpx_bresenham_line_local
        .globl  __ef9367_exec_cmd
        .globl  __ef9367_wait_ready
        .globl  __ef9367_set_blit_mode
        .globl  __ef9367_set_color
        .globl  __ef9367_set_line_style
        .globl  __ef9367_set_xy_fast
        .globl  __gpx_draw_vector
        .globl  __gpx_native_horizontal
        .globl  __gpx_vec_x0
        .globl  __ef9367_get_delta_cmd
        .globl  __abs_hl

        .include "_ef9367-defs.inc"

        .equ    LPATT_SOLID,         0xFF

        ;; locals (15 bytes)
        ;; -12..-11 x0
        ;; -10..-9  y0
        ;; -8..-7   x1
        ;; -6..-5   y1
        ;; -4       lpatt (working)
        ;; -2       lpatt return value
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

        ;; Clip-skip bookkeeping. A clipped patterned line must come out with
        ;; the phase it would have had if the whole line had been drawn and
        ;; the outside part simply not shown, so the pattern is pre-rotated
        ;; by how far along the major axis clipping skipped. The axis is
        ;; chosen from the original, pre-clip deltas, x winning ties -- the
        ;; same rule the ZX backend uses.
        .equ    SKIP_BASE_LO,        -15
        .equ    SKIP_BASE_HI,        -14
        .equ    SKIP_MAJOR_X,        -13

        ;; Word offsets into the endpoint block __gpx_draw_vector is given.
        .equ    VEC_X0,              0
        .equ    VEC_Y0,              2
        .equ    VEC_X1,              4
        .equ    VEC_Y1,              6

        .area   _CODE

        ;; ------------------------------------------------------------
        ;; uint8_t gpx_draw_line(gpx_t *gpx,
        ;;                       coord x0, coord y0, coord x1, coord y1,
        ;;                       color c, bmode m, uint8_t lpatt,
        ;;                       const rect_t *clip)
        ;;
        ;; Arguments:
        ;;   HL = gpx (unused by this routine)
        ;;   DE = x0
        ;;   stack: y0, x1, y1, c, m, lpatt, clip
        ;;
        ;; Return:
        ;;   A = resulting lpatt
        ;;
        ;; Clobbers:
        ;;   AF, BC, DE, HL, IX, IY
_gpx_draw_line::
__gpx_hline::
        push    ix
        ld      ix,#0
        add     ix,sp

        ld      hl,#-15
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
        or      a
        jp      z,.gdl_return           ; rotating an empty pattern stays empty

        ;; Optional clipping:
        ;; if clip != NULL, run Cohen-Sutherland; otherwise draw as-is.
        ld      e,13(ix)
        ld      d,14(ix)
        ld      a,e
        or      d
        jp      z,.gdl_dispatch

        ;; A solid pattern is rotation invariant; only patterned lines need
        ;; the original major axis and the skipped distance.
        ld      a,S_LPATT(ix)
        inc     a
        jr      z,.gdl_skip_done

        ;; Pick the skip axis and its origin before clipping moves them.
        ld      l,S_X1_LO(ix)
        ld      h,S_X1_HI(ix)
        ld      e,S_X0_LO(ix)
        ld      d,S_X0_HI(ix)
        or      a
        sbc     hl,de
        call    __abs_hl                ; HL = |odx|
        push    hl
        ld      l,S_Y1_LO(ix)
        ld      h,S_Y1_HI(ix)
        ld      e,S_Y0_LO(ix)
        ld      d,S_Y0_HI(ix)
        or      a
        sbc     hl,de
        call    __abs_hl                ; HL = |ody|
        pop     de                      ; DE = |odx|
        or      a
        sbc     hl,de                   ; |ody| - |odx|
        jr      c,.gdl_skip_x           ; |ody| < |odx| -> x major
        jr      z,.gdl_skip_x           ; tie           -> x major
        xor     a                       ; y major
        ld      SKIP_MAJOR_X(ix),a
        ld      a,S_Y0_LO(ix)
        ld      SKIP_BASE_LO(ix),a
        ld      a,S_Y0_HI(ix)
        ld      SKIP_BASE_HI(ix),a
        jr      .gdl_skip_done
.gdl_skip_x:
        ld      a,#1
        ld      SKIP_MAJOR_X(ix),a
        ld      a,S_X0_LO(ix)
        ld      SKIP_BASE_LO(ix),a
        ld      a,S_X0_HI(ix)
        ld      SKIP_BASE_HI(ix),a
.gdl_skip_done:

        push    ix
        pop     hl
        ld      bc,#S_X0_LO
        add     hl,bc                   ; HL = &state.x0
        ld      e,13(ix)                ; reload clip: the work above used DE
        ld      d,14(ix)
        call    __gpx_cohen_sutherland
        or      a
        jr      z,.gdl_return           ; rejected by clip window

        ld      a,S_LPATT(ix)
        inc     a
        jr      z,.gdl_dispatch

        ;; Accepted: advance the pattern past the skipped part.
        ld      a,SKIP_MAJOR_X(ix)
        or      a
        jr      z,.gdl_skip_use_y
        ld      l,S_X0_LO(ix)
        ld      h,S_X0_HI(ix)
        jr      .gdl_skip_have
.gdl_skip_use_y:
        ld      l,S_Y0_LO(ix)
        ld      h,S_Y0_HI(ix)
.gdl_skip_have:
        ld      e,SKIP_BASE_LO(ix)
        ld      d,SKIP_BASE_HI(ix)
        or      a
        sbc     hl,de
        call    __abs_hl                ; HL = skipped major-axis distance
        ld      a,l
        and     #0x07
        jr      z,.gdl_dispatch
        ld      b,a
        ld      a,LPATT_RET(ix)
.gdl_skip_rot:
        rrca
        djnz    .gdl_skip_rot
        ld      LPATT_RET(ix),a
        jr      .gdl_dispatch

.gdl_dispatch:
        ;; Apply requested blit mode and color once for this line.
        ld      a,11(ix)                ; m
        call    __ef9367_set_blit_mode

        ld      a,10(ix)                ; c
        call    __ef9367_set_color

        ;; A solid line goes directly to the EF9367 vector generator.
        ;; The patterned kernel selects exact native horizontal styles or
        ;; finite XOR compositions where applicable, then scalar fallback.
        ;;
        ;; For a slanted solid line the chip picks its own interior pixels,
        ;; and they are not quite the ones the ZX backend's Bresenham picks
        ;; -- about one pixel of disagreement along the run. That is a
        ;; deliberate trade: walking diagonals in software here instead
        ;; measured 84x slower (an 880-pixel diagonal goes from 5,686 to
        ;; 477,576 T-states). Endpoints, clipping and every pattern still
        ;; match the ZX backend exactly; only interior pixels of a slanted
        ;; solid line differ.
        ld      a,S_LPATT(ix)
        inc     a                       ; FF -> solid style 0
        jr      nz,.gdl_draw_bres
        call    __ef9367_set_line_style
        ;; The frame already holds x0,y0,x1,y1 as four consecutive words in
        ;; the order the renderer wants, so it draws straight out of there.
        push    ix
        pop     hl
        ld      de,#S_X0_LO
        add     hl,de
        push    hl
        pop     iy
        call    __gpx_draw_vector
        jr      .gdl_return

.gdl_draw_bres:
        call    __gpx_bresenham_line_local

.gdl_return:
        ld      a,LPATT_RET(ix)

        ld      sp,ix
        pop     ix

        ;; ------------------------------------------------------------
        ;; __ret_clean11
        ;; Callee cleanup for a return address followed by eleven bytes.
        ;; Clobbers: DE, HL and flags. Preserves A.
__ret_clean11::
        pop     de
        ld      hl,#11
        add     hl,sp
        ld      sp,hl
        push    de
        ret

        ;; ------------------------------------------------------------
        ;; __gpx_draw_vector
        ;; Draw one solid vector between the endpoints in __gpx_vec_x0 ..
        ;; __gpx_vec_y1, using EF9367 vector commands and recursive halving
        ;; in delta space when a projection exceeds the 8-bit DELTA
        ;; registers.
        ;;
        ;; The endpoints come in by pointer so both callers can hand over
        ;; storage they already have: gpx_draw_line points at the clipped
        ;; coordinates in its own frame, and the tiny-bitmap stroke renderer
        ;; points at __gpx_vec_x0, reaching this directly instead of
        ;; marshalling eleven bytes of arguments through the public entry.
        ;;
        ;; Colour, blit mode and line style must already be programmed.
        ;;
        ;; Arguments:
        ;;   IY = &{x0, y0, x1, y1}, four consecutive words
        ;;
        ;; Clobbers:
        ;;   AF, BC, DE, HL
__gpx_draw_vector::
        ;; dx = x1 - x0
        ld      l,VEC_X1(iy)
        ld      h,VEC_X1+1(iy)
        ld      e,VEC_X0(iy)
        ld      d,VEC_X0+1(iy)
        or      a
        sbc     hl,de
        push    hl                      ; save signed dx

        ;; Set origin to x0,y0.
        ex      de,hl                   ; HL = x0
        ld      e,VEC_Y0(iy)
        ld      d,VEC_Y0+1(iy)
        call    __ef9367_set_xy_fast    ; keeps DE = y0

        ;; dy = y1 - y0
        ld      l,VEC_Y1(iy)
        ld      h,VEC_Y1+1(iy)
        or      a
        sbc     hl,de                   ; DE still y0
        ex      de,hl                   ; DE = signed dy
        pop     hl                      ; HL = signed dx

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
        jp      __ef9367_exec_cmd

.gdl_vec_not_point:
        ;; Build direction command and absolute deltas.
        call    __ef9367_get_delta_cmd
        ld      c,a                     ; command survives every queued half

        call    __abs_hl                ; HL = abs(dx)
        ex      de,hl                   ; DE = abs(dx), HL = signed dy
        call    __abs_hl                ; HL = abs(dy)

        ;; Visible horizontal vectors can use complete 256-pixel chunks.
        ;; Adjacent inclusive 255-delta commands otherwise share an endpoint
        ;; and cancel that pixel under XOR. The native row kernel advances
        ;; its next origin by 256 and therefore visits each pixel once.
        ld      a,d
        or      a                       ; short vectors cannot repeat a split endpoint
        jr      z,.gdl_vec_queue
        ld      a,h
        or      l                       ; abs(dy) == 0?
        jr      nz,.gdl_vec_queue
        ld      a,VEC_X0+1(iy)
        or      VEC_X1+1(iy)
        and     #0xFC                   ; retain original wrap handling offscreen
        jr      nz,.gdl_vec_queue
        ld      l,VEC_X0(iy)
        ld      h,VEC_X0+1(iy)
        ld      b,#0xFF
        jp      __gpx_native_horizontal

.gdl_vec_queue:
        ;; The first pair is already in registers. Only recursively queued
        ;; halves need the stack; avoid a push/pop round trip for every glyph.
        ex      de,hl                   ; HL=dx, DE=dy
        ld      b,#1                    ; pair count
        jr      .gdl_vec_check

.gdl_vec_loop:
        pop     de                      ; dy
        pop     hl                      ; dx

.gdl_vec_check:
        ;; Fits EF9367 delta register when both high bytes are 0.
        ld      a,d
        or      h
        jr      nz,.gdl_vec_divide

        call    __ef9367_wait_ready     ; fence before changing a live delta
        ld      a,l
        out     (#EF9367_DX),a
        ld      a,e
        out     (#EF9367_DY),a
        ld      a,c
        out     (#EF9367_CMD),a         ; no intervening command needs a fence
        djnz    .gdl_vec_loop
        ret

.gdl_vec_divide:
        ;; Split (dx,dy) into two halves:
        ;; first: floor/2, second: ceil/2
        srl     h
        rr      l                       ; carry = the discarded odd bit
        push    hl                      ; dx1 (PUSH preserves carry)
        jr      nc,.gdl_vec_dx2_ready
        inc     hl                      ; dx2 = dx1 + 1
.gdl_vec_dx2_ready:

        srl     d
        rr      e                       ; carry = the discarded odd bit
        push    de                      ; dy1 (PUSH preserves carry)
        jr      nc,.gdl_vec_dy2_ready
        inc     de                      ; dy2 = dy1 + 1
.gdl_vec_dy2_ready:

        push    hl                      ; dx2
        push    de                      ; dy2
        inc     b                       ; replace one pending pair with two
        jr      .gdl_vec_loop

        .area   _DATA

        ;; Endpoint scratch for callers that have no suitable block of their
        ;; own (the tiny-bitmap stroke renderer). The direction command lives
        ;; in C. gpx_draw_line points the renderer at its
        ;; own frame instead and never touches the scratch.
__gpx_vec_x0::
        .dw     0x0000
__gpx_vec_y0::
        .dw     0x0000
__gpx_vec_x1::
        .dw     0x0000
__gpx_vec_y1::
        .dw     0x0000
