        ;; _gpx_bresenham_line.s
        ;;
        ;; Diagonal line renderer: clip first, then draw fast.
        ;;
        ;; The segment is clipped up front with Cohen-Sutherland against the
        ;; effective rect = clip ∩ screen (screen alone when clip is NULL),
        ;; in full signed 16-bit space, so arbitrarily far off-screen
        ;; endpoints cost a handful of intersections instead of one plot
        ;; call per off-screen pixel. The dash pattern is pre-rotated by the
        ;; skipped major-axis distance so the phase matches an unclipped
        ;; draw. The surviving segment lies inside the display, so the raster
        ;; loops run entirely in registers: main set holds count/pattern/
        ;; masks/VRAM pointer, alternate set holds err/dx/dy, A' holds the
        ;; step directions. No per-pixel bounds or clip checks remain.
        ;;
        ;; Semantics byte-match the oracle stub (tests/zx/stub/gpx_stub.c):
        ;; same C-S edge order (T,B,R,L), same truncating-division
        ;; intersection, same skip rule, same raster loop, same return
        ;; pattern. A clip rect with swapped corners draws nothing.
        ;;
        ;; Re-entrant: all state lives in registers and the stack frame.
        ;;
        ;; GPL2 License (see: LICENSE)
        ;; Copyright (C) 2026 Tomaz Stih
        ;;
        ;; 2026-08-25   TS

        .module _gpx_bresenham_line
        .optsdcc -mz80 sdcccall(1)

        .include "_cpc-defs.inc"

        .globl  __gpx_bresenham_line
        .globl  __rect_cmp16s_lt
        .globl  __ret_clean11
        .globl  __vid_rowaddr
        .globl  __vid_nextrow
        .globl  __vid_nextrow_carry
        .globl  __vid_prevrow_carry
        .globl  __vid_prevrow
        .globl  __cpc_mode1
        .globl  __cpc_pixmask
        .globl  __cpc_width

        ;; outcode bits (stub order/priority: T, B, R, L)
        .equ    OC_LEFT,   0
        .equ    OC_RIGHT,  1
        .equ    OC_TOP,    2
        .equ    OC_BOTTOM, 3

        ;; frame locals (IX-relative)
        ;; x reaches 639 here, so every x-side local is a word. y still
        ;; fits a byte: the screen is 200 lines tall in both modes.
        .equ    L_X0,     -2            ; word: clipped-in-progress x0
        .equ    L_EX0,    -4            ; word: effective clip x (post-clamp)
        .equ    L_EX1,    -6            ; word
        .equ    L_EY0,    -7            ; byte: effective clip y
        .equ    L_EY1,    -8            ; byte
        .equ    L_SKIPB,  -10           ; word: original major-axis start
        .equ    L_FLAGS,  -11           ; bit0 = major axis is x (|odx|>=|ody|)
        .equ    L_AXIS,   -12           ; isect flavor: 0 = x (T/B), 1 = y (R/L)
        .equ    L_NB,     -14           ; word: clip-edge coordinate for isect
        .equ    L_SIGN,   -15           ; byte: folded sign of isect offset
        .equ    L_DX,     -17           ; word: post-clip |dx|
        .equ    L_DY,     -19           ; word: post-clip |dy|
        .equ    L_A0,     -21           ; word: isect base coordinate
        .equ    L_STEPS,  -23           ; word: raster steps still to run
        .equ    L_SIZE,   24

        ;; args after push ix (callee cleans 11 bytes)
        ;;   HL = gpx (unused), DE = x0
        .equ    A_Y0,   4               ; word (mutated in place by C-S)
        .equ    A_X1,   6               ; word (mutated in place by C-S)
        .equ    A_Y1,   8               ; word (mutated in place by C-S)
        .equ    A_C,    10
        .equ    A_M,    11
        .equ    A_LP,   12              ; lpatt (skip-rotated in place)
        .equ    A_CLIP, 13

        .area   _CODE

        ;; ------------------------------------------------------------
        ;; __gpx_bresenham_line
        ;; Draw a clipped, patterned line. Cohen-Sutherland runs first
        ;; against clip intersected with the screen, the pattern is
        ;; pre-rotated by the skipped major-axis distance so the phase
        ;; matches an unclipped draw, and the surviving segment is then
        ;; rastered entirely in registers with no per-pixel bounds check.
        ;;
        ;; Arguments:
        ;;   DE = x0
        ;;   stack, relative to the frame: A_Y0, A_X1, A_Y1 (all mutated
        ;;   in place by the clipper), A_C, A_M, A_LP, A_CLIP
        ;;
        ;; Return:
        ;;   A = the pattern rotated by the number of pixels drawn, so
        ;;       chained segments keep their phase
        ;;
        ;; Clobbers:
        ;;   AF, BC, DE, HL, IX, and the alternate set
        ;;
        ;; References:
        ;;   __rect_cmp16s_lt
        ;;   __vid_rowaddr
        ;;   __vid_nextrow, __vid_nextrow_carry
        ;;   __vid_prevrow_carry
        ;;   __ret_clean11
__gpx_bresenham_line::
        push    ix
        ld      ix,#0
        add     ix,sp
        ld      hl,#-L_SIZE
        add     hl,sp
        ld      sp,hl

        ld      L_X0(ix),e
        ld      L_X0+1(ix),d

        ;; original |dx| vs |dy| picks the skip axis (before clipping)
        ld      l,A_X1(ix)
        ld      h,A_X1+1(ix)
        ld      e,L_X0(ix)
        ld      d,L_X0+1(ix)
        call    .bl_absd                ; HL = |odx|
        push    hl
        ld      l,A_Y1(ix)
        ld      h,A_Y1+1(ix)
        ld      e,A_Y0(ix)
        ld      d,A_Y0+1(ix)
        call    .bl_absd                ; HL = |ody|
        pop     de                      ; DE = |odx|
        or      a
        sbc     hl,de                   ; |ody| - |odx| (unsigned)
        jr      c,.bl_sb_x              ; ody < odx -> x major
        jr      z,.bl_sb_x              ; equal     -> x major
        xor     a
        ld      L_FLAGS(ix),a
        ld      a,A_Y0(ix)
        ld      L_SKIPB(ix),a
        ld      a,A_Y0+1(ix)
        ld      L_SKIPB+1(ix),a
        jr      .bl_eff
.bl_sb_x:
        ld      a,#1
        ld      L_FLAGS(ix),a
        ld      a,L_X0(ix)
        ld      L_SKIPB(ix),a
        ld      a,L_X0+1(ix)
        ld      L_SKIPB+1(ix),a

        ;; ---- effective clip rect: (clip ∩ screen) as four bytes ----
.bl_eff:
        xor     a
        ld      L_EX0(ix),a
        ld      L_EX0+1(ix),a
        ld      L_EY0(ix),a
        ld      hl,(__cpc_width)
        dec     hl
        ld      L_EX1(ix),l
        ld      L_EX1+1(ix),h
        ld      a,#(CPC_HEIGHT - 1)
        ld      L_EY1(ix),a

        ld      l,A_CLIP(ix)
        ld      h,A_CLIP+1(ix)
        ld      a,h
        or      l
        jr      z,.bl_cs_loop           ; no clip: screen rect stands

        ld      e,(hl)                  ; x0c
        inc     hl
        ld      d,(hl)
        inc     hl
        push    de
        ld      e,(hl)                  ; y0c
        inc     hl
        ld      d,(hl)
        inc     hl
        push    de
        ld      e,(hl)                  ; x1c
        inc     hl
        ld      d,(hl)
        inc     hl
        ld      c,(hl)                  ; y1c
        inc     hl
        ld      h,(hl)
        ld      l,c                     ; HL = y1c
        ld      b,d
        ld      c,e                     ; BC = x1c
        pop     de                      ; DE = y0c
        ;; swapped clip (y1c < y0c) draws nothing
        call    __rect_cmp16s_lt
        jp      c,.bl_rej1
        ;; clamp y0c (DE) -> EY0
        bit     7,d
        jr      nz,.bl_cy1              ; y0c<0 -> keep 0
        ld      a,d
        or      a
        jp      nz,.bl_rej1             ; y0c>255: below screen -> empty
        ld      a,e
        cp      #CPC_HEIGHT
        jp      nc,.bl_rej1             ; y0c below the screen -> empty
        ld      L_EY0(ix),a
.bl_cy1:
        ;; clamp y1c (HL) -> EY1
        bit     7,h
        jp      nz,.bl_rej1             ; y1c<0: above screen -> empty
        ld      a,h
        or      a
        jr      nz,.bl_cx               ; y1c>255 -> keep the bottom row
        ld      a,l
        cp      #CPC_HEIGHT
        jr      nc,.bl_cx               ; below the screen -> keep it
        ld      L_EY1(ix),a
.bl_cx:
        pop     de                      ; DE = x0c
        ;; swapped clip (x1c < x0c) draws nothing
        ld      l,c
        ld      h,b                     ; HL = x1c
        call    __rect_cmp16s_lt
        jp      c,.bl_reject
        ;; clamp x0c (DE) -> EX0 = max(0, x0c), reject if past the right edge
        bit     7,d
        jr      nz,.bl_cx1              ; x0c < 0 -> keep 0
        push    hl                      ; x1c
        ex      de,hl                   ; HL = x0c
        ld      de,(__cpc_width)
        call    __rect_cmp16s_lt        ; carry when x0c < width
        jr      c,.bl_cx0_keep
        pop     hl
        jp      .bl_reject              ; x0c off the right edge -> empty
.bl_cx0_keep:
        ld      L_EX0(ix),l
        ld      L_EX0+1(ix),h
        pop     hl                      ; HL = x1c
.bl_cx1:
        ;; clamp x1c (HL) -> EX1 = min(width-1, x1c)
        bit     7,h
        jp      nz,.bl_reject           ; x1c < 0 -> empty
        ld      de,(__cpc_width)
        dec     de
        call    __rect_cmp16s_lt        ; carry when x1c < width-1
        jr      nc,.bl_cs_loop          ; beyond the edge -> keep width-1
        ld      L_EX1(ix),l
        ld      L_EX1+1(ix),h

        ;; ---- Cohen-Sutherland loop (16-bit, cold) ----
.bl_cs_loop:
        ld      l,L_X0(ix)
        ld      h,L_X0+1(ix)
        ld      e,A_Y0(ix)
        ld      d,A_Y0+1(ix)
        call    .bl_outc
        ld      b,a                     ; B = c0
        ld      l,A_X1(ix)
        ld      h,A_X1+1(ix)
        ld      e,A_Y1(ix)
        ld      d,A_Y1+1(ix)
        call    .bl_outc                ; A = c1 (B preserved)
        ld      c,a
        or      b
        jr      z,.bl_accept            ; both inside
        ld      a,b
        and     c
        jp      nz,.bl_reject           ; share an outside half-plane
        push    bc                      ; save which-endpoint (B = c0)
        ld      a,b
        or      a
        jr      nz,.bl_disp
        ld      a,c
.bl_disp:
        bit     OC_TOP,a
        jp      nz,.bl_edge_t
        bit     OC_BOTTOM,a
        jp      nz,.bl_edge_b
        bit     OC_RIGHT,a
        jp      nz,.bl_edge_r
        jp      .bl_edge_l

        ;; ---- accept: rotate pattern by skipped major distance ----
.bl_accept:
        ld      a,L_FLAGS(ix)
        and     #0x01
        jr      z,.bl_sk_y
        ld      l,L_X0(ix)
        ld      h,L_X0+1(ix)
        jr      .bl_sk_go
.bl_sk_y:
        ld      l,A_Y0(ix)
        ld      h,A_Y0+1(ix)
.bl_sk_go:
        ld      e,L_SKIPB(ix)
        ld      d,L_SKIPB+1(ix)
        call    .bl_absd                ; HL = skip distance
        ld      a,l
        and     #0x07
        jr      z,.bl_setup
        ld      b,a
        ld      a,A_LP(ix)
.bl_sk_rot:
        rrca
        djnz    .bl_sk_rot
        ld      A_LP(ix),a

        ;; ---- raster setup: dx is 16-bit, dy fits a byte ----
.bl_setup:
        ld      c,#0                    ; C = direction flags
        ld      l,A_X1(ix)
        ld      h,A_X1+1(ix)
        ld      e,L_X0(ix)
        ld      d,L_X0+1(ix)
        or      a
        sbc     hl,de
        jr      nc,.bl_dxp
        set     0,c                     ; x runs left
        ex      de,hl
        ld      hl,#0
        or      a
        sbc     hl,de                   ; HL = |dx|
.bl_dxp:
        ld      L_DX(ix),l
        ld      L_DX+1(ix),h
        ld      a,A_Y1(ix)
        sub     A_Y0(ix)
        jr      nc,.bl_dyp
        neg
        set     1,c                     ; y runs up
.bl_dyp:
        ld      L_DY(ix),a
        xor     a
        ld      L_DY+1(ix),a
        ld      a,c
        ex      af,af'                  ; A' = direction flags

        exx                             ; alt: BC=dy, DE=dx, HL=err
        ld      b,L_DY+1(ix)
        ld      c,L_DY(ix)
        ld      d,L_DX+1(ix)
        ld      e,L_DX(ix)
        ld      a,L_FLAGS(ix)
        and     #0x01
        jr      z,.bl_err_y
        ld      h,d                     ; err = dx/2
        ld      l,e
        srl     h
        rr      l
        jr      .bl_err_ok
.bl_err_y:
        ld      a,c                     ; err = -(dy/2)
        srl     a
        ld      l,a
        ld      h,#0
        or      a
        jr      z,.bl_err_ok
        xor     a
        sub     l
        ld      l,a
        sbc     a,a
        ld      h,a
.bl_err_ok:
        exx

        ;; mask = the byte's top pixel walked right by (x0 & CPC_PIX_MASK)
        ld      a,(__cpc_pixmask)
        and     L_X0(ix)
        ld      b,a
        ld      a,#0x80
        jr      z,.bl_mask_ok
.bl_mask_sh:
        srl     a
        djnz    .bl_mask_sh
.bl_mask_ok:
        ;; plot = (byte | D) ^ E:  set D=M,E=0; clear D=M,E=M; xor D=0,E=M
        ld      d,a
        ld      e,a
        ld      a,A_M(ix)
        and     #0x01
        jr      z,.bl_m_cpy
        ld      d,#0                    ; xor
        jr      .bl_m_ok
.bl_m_cpy:
        ld      a,A_C(ix)
        and     #0x01
        jr      z,.bl_m_ok              ; clear: D=E=M
        ld      e,#0                    ; set
.bl_m_ok:
        ;; HL = VRAM addr of (x0,y0)
        ld      b,A_Y0(ix)
        call    __vid_rowaddr           ; preserves BC and DE
        push    de
        ld      e,L_X0(ix)
        ld      d,L_X0+1(ix)
        push    hl
        ex      de,hl
        call    __gpx_xbyte             ; A = x0 >> CPC_PIX_SHIFT, 0..79
        pop     hl
        add     a,l
        ld      l,a
        jr      nc,.bl_addr_ok
        inc     h                       ; a CPC row base is not 32-aligned
.bl_addr_ok:
        pop     de

        ld      c,A_LP(ix)              ; C = pattern
        ld      a,L_FLAGS(ix)
        and     #0x01
        jr      z,.bl_go_y
        ld      a,L_DX(ix)              ; steps = dx
        ld      L_STEPS(ix),a
        ld      a,L_DX+1(ix)
        ld      L_STEPS+1(ix),a
        or      L_DX(ix)
        jp      z,.bl_last              ; clipped to a single pixel
        call    .bl_chunk               ; B = this chunk's step count
        ;; The x direction and the display mode are both fixed for the whole
        ;; line, so together they pick one of four rasters once, here. Neither
        ;; is looked at again while the line draws.
        ex      af,af'
        bit     0,a
        jr      nz,.bx_go_left          ; branch before swapping the flags back
        ex      af,af'
        ld      a,(__cpc_mode1)
        or      a
        jp      nz,.bxrn_loop
        jp      .bxrw_loop
.bx_go_left:
        ex      af,af'
        ld      a,(__cpc_mode1)
        or      a
        jp      nz,.bxln_loop
        jp      .bxlw_loop
.bl_go_y:
        ld      b,L_DY(ix)              ; steps = dy (under 200)
        ld      a,b
        or      a
        jp      z,.bl_last              ; clipping collapsed it to one pixel
        ld      a,L_DX(ix)
        or      L_DX+1(ix)              ; Z <=> dx == 0, i.e. a vertical
        ;; The y direction and the display mode are both fixed for the whole
        ;; line, so they pick one of four rasters once, here. A' carries the
        ;; direction flags, so the dx test is parked in F' while bit 1 is read
        ;; out of it and then handed back.
        ex      af,af'
        bit     1,a                     ; upward?
        jr      nz,.bl_go_yup
        ex      af,af'                  ; flags back: Z still says dx == 0
        jr      nz,.bl_go_ydown
        jp      .bv_loop                ; downward vertical: fast path
.bl_go_ydown:
        ld      a,(__cpc_mode1)
        or      a
        jp      nz,.bydn_loop
        jp      .bydw_loop
.bl_go_yup:
        ex      af,af'                  ; direction flags back into A'
        ld      a,(__cpc_mode1)         ; an upward vertical has no fast path:
        or      a                       ; the generic raster handles dx == 0
        jp      nz,.byun_loop
        jp      .byuw_loop

        ;; ---- x-major rasters: B=steps C=patt D/E=masks HL=vram ----
        ;; alt: HL'=err DE'=dx BC'=dy; A' bit1=up
        ;;
        ;; Four variants: one per x direction, times one per display mode.
        ;; Both are constant for the whole line, so choosing the raster once
        ;; at entry removes every per-pixel test of either. That includes the
        ;; mask advance, which used to be a call into a shared helper that
        ;; re-read __cpc_mode1 for every pixel; the call, the return and the
        ;; load together came to roughly 55 of the 141 T-states a pixel cost.
        ;;
        ;; The tails differ only in how the mask leaves its byte:
        ;;
        ;;   mode 2  eight pixels to a byte, so the mask simply rotates and
        ;;           the bit rotated out is the carry -- which also leaves it
        ;;           at the far end, ready for the next byte, free of charge.
        ;;   mode 1  four pixels, in the high nibble, so a rotate would walk
        ;;           the mask into the plane-2 bits. The end position is
        ;;           recognised before rotating and the mask is rebuilt at the
        ;;           other end by three doublings (or halvings), which leaves
        ;;           a zero selector zero without needing a branch per half.
        ;;
        ;; The wrap arm sits out of line so that the common path falls
        ;; straight into the loop branch, and so that the body stays inside
        ;; djnz's reach now that the mask advance is inlined into it.
        ;;
        ;;   BL_XLOOP lp,np,yup,xadv,rot,wrap,narrow,right
        .macro  BL_XLOOP lp,np,yup,xadv,rot,wrap,narrow,right
lp:
        rrc     c                       ; carry = pattern bit, C rotated for
        jr      nc,np                   ; the next step in the same op
        ld      a,(hl)
        or      d
        xor     e
        ld      (hl),a
np:
        exx
        or      a
        sbc     hl,bc                   ; err -= dy
        exx                             ; flags survive exx
        jp      p,xadv                  ; err >= 0: no y step
        exx
        add     hl,de                   ; err += dx
        exx
        ex      af,af'
        bit     1,a
        jr      nz,yup
        ex      af,af'
        call    __vid_nextrow
        jr      xadv
yup:
        ex      af,af'
        call    __vid_prevrow
xadv:
        ld      a,d
        or      e                       ; A = live mask, before the step
        .if     narrow
         .if    right
        and     #0x10                   ; last pixel of the nibble?
         .else
        and     #0x80                   ; first pixel of the nibble?
         .endif
        jr      nz,wrap
         .if    right
        rrc     d
        rrc     e
         .else
        rlc     d
        rlc     e
         .endif
        .else
         .if    right
        rrc     d
        rrc     e
        rrca                            ; carry = the bit rotated out
         .else
        rlc     d
        rlc     e
        rlca
         .endif
        jr      c,wrap
        .endif
rot:
        djnz    lp
        call    .bl_chunk               ; dx can exceed 255 on this machine
        ld      a,b
        or      a
        jp      nz,lp
        jp      .bl_last
wrap:
        .if     narrow
        ld      a,d
         .if    right
        add     a,a                     ; 0x10 -> 0x80, and 0x00 -> 0x00
        add     a,a
        add     a,a
         .else
        rrca                            ; 0x80 -> 0x10, and 0x00 -> 0x00
        rrca
        rrca
         .endif
        ld      d,a
        ld      a,e
         .if    right
        add     a,a
        add     a,a
        add     a,a
         .else
        rrca
        rrca
        rrca
         .endif
        ld      e,a
        .endif
        .if     right
        inc     hl
        .else
        dec     hl
        .endif
        jp      rot
        .endm

        BL_XLOOP .bxrw_loop,.bxrw_np,.bxrw_yup,.bxrw_xadv,.bxrw_rot,.bxrw_wrap,0,1
        BL_XLOOP .bxrn_loop,.bxrn_np,.bxrn_yup,.bxrn_xadv,.bxrn_rot,.bxrn_wrap,1,1
        BL_XLOOP .bxlw_loop,.bxlw_np,.bxlw_yup,.bxlw_xadv,.bxlw_rot,.bxlw_wrap,0,0
        BL_XLOOP .bxln_loop,.bxln_np,.bxln_yup,.bxln_xadv,.bxln_rot,.bxln_wrap,1,0


        ;; ---- shared tail: final pixel + return pattern ----
.bl_last:
        bit     0,c
        jr      z,.bl_retp
        ld      a,(hl)
        or      d
        xor     e
        ld      (hl),a
.bl_retp:
        ld      a,c
.bl_done:
        ld      sp,ix
        pop     ix
        jp      __ret_clean11

.bl_rej1:                               ; reject with one word still stacked
        pop     de
.bl_reject:
        ld      a,A_LP(ix)              ; untouched original pattern
        jr      .bl_done

        ;; ---- y-major rasters: B=steps C=patt D/E=masks HL=vram ----
        ;; alt: HL'=err DE'=dx BC'=dy; A' bit0=left
        ;;
        ;; Four variants again, this time on y direction and display mode.
        ;; The y direction matters more here than it does in the x-major
        ;; raster: a y-major line steps y on *every* pixel, so reading the
        ;; flag out of A' cost 24 T-states a pixel (two ex af,af', a bit and
        ;; a branch) for a value that cannot change while the line draws.
        ;;
        ;; The x step is the conditional one here, so the x direction is
        ;; still read per step -- but the mask advance below it is inlined
        ;; and mode-specialised, exactly as in the x-major raster.
        ;;
        ;;   BL_YLOOP lp,np,xleft,xrwrap,xlwrap,yadv,rot,narrow,up
        .macro  BL_YLOOP lp,np,xleft,xrwrap,xlwrap,yadv,rot,narrow,up
lp:
        rrc     c                       ; carry = pattern bit, C rotated for
        jr      nc,np                   ; the next step in the same op
        ld      a,(hl)
        or      d
        xor     e
        ld      (hl),a
np:
        exx
        or      a
        adc     hl,de                   ; err += dx (adc sets S/Z)
        exx                             ; flags survive exx
        jp      m,yadv                  ; err < 0: no x step
        jr      z,yadv                  ; err == 0: no x step
        exx
        or      a
        sbc     hl,bc                   ; err -= dy
        exx
        ex      af,af'
        bit     0,a
        jr      nz,xleft
        ex      af,af'
        ld      a,d
        or      e                       ; A = live mask, before the step
        .if     narrow
        and     #0x10                   ; last pixel of the nibble?
        jr      nz,xrwrap
        rrc     d
        rrc     e
        .else
        rrc     d
        rrc     e
        rrca                            ; carry = the bit rotated out
        jr      c,xrwrap
        .endif
        jr      yadv
xleft:
        ex      af,af'
        ld      a,d
        or      e
        .if     narrow
        and     #0x80                   ; first pixel of the nibble?
        jr      nz,xlwrap
        rlc     d
        rlc     e
        .else
        rlc     d
        rlc     e
        rlca
        jr      c,xlwrap
        .endif
yadv:
        .if     up
        ld      a,h                     ; inlined __vid_prevrow fast path
        sub     #(CPC_BANK_STEP >> 8)
        ld      h,a
        cp      #(CPC_VRAM >> 8)
        jr      nc,rot
        call    __vid_prevrow_carry
        .else
        ld      a,h                     ; inlined __vid_nextrow fast path
        add     a,#(CPC_BANK_STEP >> 8)
        ld      h,a
        jr      nc,rot
        call    __vid_nextrow_carry
        .endif
rot:
        djnz    lp
        jp      .bl_last

        ;; The byte-crossing arms sit out here so the common path above runs
        ;; straight through. In mode 2 the rotate has already put the mask at
        ;; the far end of the byte; in mode 1 it has to be rebuilt there.
xrwrap:
        .if     narrow
        ld      a,d
        add     a,a                     ; 0x10 -> 0x80, and 0x00 -> 0x00
        add     a,a
        add     a,a
        ld      d,a
        ld      a,e
        add     a,a
        add     a,a
        add     a,a
        ld      e,a
        .endif
        inc     hl
        jp      yadv
xlwrap:
        .if     narrow
        ld      a,d
        rrca                            ; 0x80 -> 0x10, and 0x00 -> 0x00
        rrca
        rrca
        ld      d,a
        ld      a,e
        rrca
        rrca
        rrca
        ld      e,a
        .endif
        dec     hl
        jp      yadv
        .endm

        BL_YLOOP .bydw_loop,.bydw_np,.bydw_xl,.bydw_xrw,.bydw_xlw,.bydw_yadv,.bydw_rot,0,0
        BL_YLOOP .bydn_loop,.bydn_np,.bydn_xl,.bydn_xrw,.bydn_xlw,.bydn_yadv,.bydn_rot,1,0
        BL_YLOOP .byuw_loop,.byuw_np,.byuw_xl,.byuw_xrw,.byuw_xlw,.byuw_yadv,.byuw_rot,0,1
        BL_YLOOP .byun_loop,.byun_np,.byun_xl,.byun_xrw,.byun_xlw,.byun_yadv,.byun_rot,1,1

        ;; ---- vertical fast path: dx == 0, y increasing ----
        ;; With dx = 0 the y-major loop never steps x, so no err
        ;; bookkeeping is needed: plot, next row, rotate pattern.
        ;; B=steps C=patt D/E=masks HL=vram. ~105 T/pixel.
.bv_loop:
        rrc     c                       ; carry = pattern bit, C rotated for
        jr      nc,.bv_np               ; the next step in the same op
        ld      a,(hl)
        or      d
        xor     e
        ld      (hl),a
.bv_np:
        ld      a,h                     ; inlined __vid_nextrow fast path
        add     a,#(CPC_BANK_STEP >> 8)
        ld      h,a
        jr      nc,.bl_step3
        call    __vid_nextrow_carry
.bl_step3:
        djnz    .bv_loop
        jp      .bl_last

        ;; ---- C-S edge handlers ----
        ;; stack holds pushed BC (B = c0 = which endpoint moves)
.bl_edge_t:
        call    .bl_eqy
        jr      z,.bl_rejpop
        ld      a,L_EY0(ix)
        ld      L_NB(ix),a
        xor     a
        ld      L_NB+1(ix),a
        call    .bl_isect_x             ; HL = nx
        jr      .bl_put_xy
.bl_edge_b:
        call    .bl_eqy
        jr      z,.bl_rejpop
        ld      a,L_EY1(ix)
        ld      L_NB(ix),a
        xor     a
        ld      L_NB+1(ix),a
        call    .bl_isect_x
        jr      .bl_put_xy
.bl_edge_r:
        call    .bl_eqx
        jr      z,.bl_rejpop
        ld      a,L_EX1(ix)
        ld      L_NB(ix),a
        ld      a,L_EX1+1(ix)
        ld      L_NB+1(ix),a
        call    .bl_isect_y             ; HL = ny
        jr      .bl_put_yx
.bl_edge_l:
        call    .bl_eqx
        jr      z,.bl_rejpop
        ld      a,L_EX0(ix)
        ld      L_NB(ix),a
        ld      a,L_EX0+1(ix)
        ld      L_NB+1(ix),a
        call    .bl_isect_y

.bl_put_yx:                             ; HL = ny computed, nx = NB
        ex      de,hl                   ; DE = ny
        ld      l,L_NB(ix)
        ld      h,L_NB+1(ix)            ; HL = nx
        jr      .bl_put
.bl_put_xy:                             ; HL = nx computed, ny = NB
        ld      e,L_NB(ix)
        ld      d,L_NB+1(ix)            ; DE = ny
.bl_put:
        pop     bc                      ; B = c0
        ld      a,b
        or      a
        jr      z,.bl_put1
        ld      L_X0(ix),l              ; move endpoint 0
        ld      L_X0+1(ix),h
        ld      A_Y0(ix),e
        ld      A_Y0+1(ix),d
        jp      .bl_cs_loop
.bl_put1:
        ld      A_X1(ix),l              ; move endpoint 1
        ld      A_X1+1(ix),h
        ld      A_Y1(ix),e
        ld      A_Y1+1(ix),d
        jp      .bl_cs_loop

.bl_rejpop:
        pop     bc
        jp      .bl_reject

        ;; ---- helpers ----

        ;; outcode of (HL=x, DE=y) vs effective rect. A = code, clobbers C.
.bl_outc:
        ld      c,#0
        bit     7,h
        jr      z,.bo_x2
        set     OC_LEFT,c               ; x < 0
        jr      .bo_y
.bo_x2:
        ;; x < EX0 ?  (both non-negative, so an unsigned 16-bit compare)
        push    de
        ld      e,L_EX0(ix)
        ld      d,L_EX0+1(ix)
        call    .bo_cmp                 ; carry when HL < DE
        pop     de
        jr      nc,.bo_x3
        set     OC_LEFT,c
        jr      .bo_y
.bo_x3:
        ;; EX1 < x ?
        push    de
        ld      e,L_EX1(ix)
        ld      d,L_EX1+1(ix)
        ex      de,hl
        call    .bo_cmp                 ; carry when EX1 < x
        ex      de,hl
        pop     de
        jr      nc,.bo_y
        set     OC_RIGHT,c
.bo_y:
        bit     7,d
        jr      z,.bo_y1
        set     OC_TOP,c                ; y < 0
        jr      .bo_ret
.bo_y1:
        ld      a,d
        or      a
        jr      z,.bo_y2
        set     OC_BOTTOM,c             ; y past the bottom of the screen
        jr      .bo_ret
.bo_y2:
        ld      a,e
        cp      L_EY0(ix)
        jr      nc,.bo_y3
        set     OC_TOP,c
        jr      .bo_ret
.bo_y3:
        ld      a,L_EY1(ix)
        cp      e
        jr      nc,.bo_ret
        set     OC_BOTTOM,c
.bo_ret:
        ld      a,c
        ret

        ;; Unsigned 16-bit HL < DE, carry set when true. Only reached with
        ;; non-negative values, so it needs no sign folding.
.bo_cmp:
        push    hl
        or      a
        sbc     hl,de
        pop     hl
        ret

        ;; endpoint equality tests (Z set when equal / parallel to edge)
.bl_eqy:
        ld      a,A_Y0(ix)
        cp      A_Y1(ix)
        ret     nz
        ld      a,A_Y0+1(ix)
        cp      A_Y1+1(ix)
        ret
.bl_eqx:
        ld      a,L_X0(ix)
        cp      A_X1(ix)
        ret     nz
        ld      a,L_X0+1(ix)
        cp      A_X1+1(ix)
        ret

        ;; HL = |HL - DE| (signed operands), A = 1 iff HL < DE.
        ;; Callers fold that A into a product sign, so the 0/1 value is part
        ;; of the contract and is synthesized from the compare's carry here.
.bl_absd:
        call    __rect_cmp16s_lt        ; carry set iff HL < DE
        sbc     a,a                     ; 0xFF on carry, else 0x00
        and     #0x01                   ; A = 1 iff HL < DE (carry cleared)
        jr      z,.ba_sub
        ex      de,hl
.ba_sub:
        or      a                       ; clear carry, keep A
        sbc     hl,de
        ret

        ;; intersection: n = a0 +/- m1*m2/m3 (magnitudes u16, trunc division)
        ;;   x-flavor (T/B edges): a = x, b = y, NB = edge y
        ;;   y-flavor (R/L edges): a = y, b = x, NB = edge x
        ;; Both flavors need P = |x1-x0| and Q = |y1-y0|; they only swap
        ;; the m1 (numerator) / m3 (divisor) roles, the m2 base coordinate
        ;; and the a0 base, so P/Q are computed once and arranged after.
.bl_isect_x:
        xor     a
        jr      .bl_isect
.bl_isect_y:
        ld      a,#1
.bl_isect:
        ld      L_AXIS(ix),a
        ld      l,A_X1(ix)              ; P = |x1 - x0|, sign in B
        ld      h,A_X1+1(ix)
        ld      e,L_X0(ix)
        ld      d,L_X0+1(ix)
        call    .bl_absd
        ld      b,a                     ; B survives .bl_absd
        push    hl                      ; park P
        ld      l,A_Y1(ix)              ; Q = |y1 - y0|, sign in A
        ld      h,A_Y1+1(ix)
        ld      e,A_Y0(ix)
        ld      d,A_Y0+1(ix)
        call    .bl_absd
        xor     b
        ld      L_SIGN(ix),a            ; sP ^ sQ (m2 sign folded below)
        pop     de                      ; DE = P, HL = Q
        ld      a,L_AXIS(ix)
        or      a
        jr      nz,.bi_yflav
        ;; x-flavor: m1 = P, m3 = Q, b0 = y0, a0 = x0
        push    de                      ; [m1 = P]
        push    hl                      ; park m3 = Q
        ld      a,L_X0(ix)
        ld      L_A0(ix),a
        ld      a,L_X0+1(ix)
        ld      L_A0+1(ix),a
        ld      e,A_Y0(ix)              ; b0 = y0
        ld      d,A_Y0+1(ix)
        jr      .bi_m2
.bi_yflav:
        ;; y-flavor: m1 = Q, m3 = P, b0 = x0, a0 = y0
        push    hl                      ; [m1 = Q]
        push    de                      ; park m3 = P
        ld      a,A_Y0(ix)
        ld      L_A0(ix),a
        ld      a,A_Y0+1(ix)
        ld      L_A0+1(ix),a
        ld      e,L_X0(ix)              ; b0 = x0
        ld      d,L_X0+1(ix)
.bi_m2:
        ld      l,L_NB(ix)              ; m2 = |nb - b0|
        ld      h,#0
        call    .bl_absd
        ex      de,hl                   ; DE = m2
        ld      l,a                     ; fold m2 sign
        ld      a,L_SIGN(ix)
        xor     l
        ld      L_SIGN(ix),a
        pop     hl                      ; m3
        pop     bc                      ; m1
        push    hl                      ; park m3
        call    .bl_mul16               ; DE:HL = m1 * m2
        ex      de,hl                   ; HL = hi, DE = lo
        pop     bc                      ; m3
        call    .bl_div                 ; DE = quotient (hi < m3 guaranteed)
        ld      l,L_A0(ix)
        ld      h,L_A0+1(ix)
        ld      a,L_SIGN(ix)
        or      a
        jr      z,.bi_add
        sbc     hl,de                   ; carry cleared by or above
        ret
.bi_add:
        add     hl,de
        ret

        ;; DE:HL = DE * BC (unsigned 16x16 -> 32)
.bl_mul16:
        ld      hl,#0
        ld      a,#16
.bm_loop:
        add     hl,hl
        rl      e
        rl      d
        jr      nc,.bm_next
        add     hl,bc
        jr      nc,.bm_next
        inc     de
.bm_next:
        dec     a
        jr      nz,.bm_loop
        ret

        ;; DE = HL:DE / BC (requires HL < BC; that holds: quotient < 2^16),
        ;; HL = remainder
.bl_div:
        ld      a,#16
.bd_loop:
        sla     e
        rl      d
        adc     hl,hl
        jr      c,.bd_s17               ; 17-bit remainder: subtract always
        sbc     hl,bc                   ; trial (carry clear from adc)
        jr      nc,.bd_one
        add     hl,bc
        jr      .bd_next
.bd_s17:
        or      a
        sbc     hl,bc
.bd_one:
        inc     e                       ; quotient bit (bit0 vacated by sla)
.bd_next:
        dec     a
        jr      nz,.bd_loop
        ret

        ;; ------------------------------------------------------------
        ;; .bl_chunk
        ;;
        ;; Hand the x-major raster its next run of steps. dx reaches 639 in
        ;; mode 2, which does not fit djnz's counter, so the loop runs in
        ;; chunks of at most 255. Everything the raster carries -- pattern,
        ;; masks, VRAM pointer and the alternate set's error term -- lives
        ;; in registers this does not touch, so a chunk boundary is
        ;; invisible to the line being drawn.
        ;;
        ;; Return:
        ;;   B = steps in this chunk, 0 when the line is finished
        ;;
        ;; Clobbers:
        ;;   AF, B
        ;; ------------------------------------------------------------
.bl_chunk:
        ld      a,L_STEPS+1(ix)
        or      a
        jr      nz,.bl_chunk_full
        ld      b,L_STEPS(ix)           ; under 256 left: take them all
        xor     a
        ld      L_STEPS(ix),a
        ret
.bl_chunk_full:
        ld      b,#255
        ld      a,L_STEPS(ix)
        sub     #255
        ld      L_STEPS(ix),a
        ld      a,L_STEPS+1(ix)
        sbc     a,#0x00
        ld      L_STEPS+1(ix),a
        ret
