        ;; gpx_draw_bmp.s
        ;;
        ;; Partner bitmap renderer in assembly:
        ;;  - tiny move streams (compact + legacy headers)
        ;;
        ;; GPL2 License (see: LICENSE)
        ;; Copyright (C) 2026 Tomaz Stih
        ;;
        ;; 2026-07-13   TS

        .module gpx_draw_bmp
        .optsdcc -mz80 sdcccall(1)

        .globl  _gpx_draw_bmp
        .globl  _gpx_draw_bmp_xor
        .globl  __gpx_draw_bmp_mode
        .globl  __gpx_bmp_invert
        .globl  _gpx_draw_line
        .globl  __rect_cmp16s_lt
        .globl  __ef9367_set_xy_fast
        .globl  __gpx_vec_x0
        .globl  __gpx_vec_y0
        .globl  __gpx_vec_x1
        .globl  __gpx_vec_y1
        .globl  __ef9367_set_blit_mode
        .globl  __ef9367_set_color
        .globl  __ef9367_set_pen
        .globl  __ef9367_set_line_style

        .include "_ef9367-defs.inc"

        .equ    BMP_ENC_TINY,          0x02
        .equ    BMP_ENC_TINY_MASK,     0x03

        .equ    CO_FORE,               0x01
        .equ    CO_BACK,               0x00
        .equ    BM_CPY,                0x00
        .equ    BM_XOR,                0x01
        .equ    LPATT_SOLID,           0xFF

        ;; locals (12 bytes); y and clip stay in their consumed argument slots
        .equ    L_GPX_LO,              -1
        .equ    L_GPX_HI,              -2
        .equ    L_X_LO,                -3
        .equ    L_X_HI,                -4
        .equ    L_Y_LO,                 4
        .equ    L_Y_HI,                 5
        .equ    L_CLIP_LO,              8
        .equ    L_CLIP_HI,              9

        .equ    L_MODE,                -5
        .equ    L_BOXW,                -6
        .equ    L_BOXH,                -7
        .equ    L_MOVES,               -8
        .equ    L_X0_LO,               -9
        .equ    L_X0_HI,               -10
        .equ    L_Y0_LO,               -11
        .equ    L_Y0_HI,               -12

        .area   _CODE

        ;; ------------------------------------------------------------
        ;; void gpx_draw_bmp(
        ;;   gpx_t *gpx, coord x, coord y, bmp_t *b, const rect_t *clip)
        ;;
        ;; Arguments:
        ;;   HL = gpx
        ;;   DE = x
        ;;   stack: y, b, clip
        ;;
        ;; Clobbers:
        ;;   AF, BC, DE, HL, IY (IX is preserved)
        ;; XOR entry: same signature, strokes drawn in BM_XOR (used by
        ;; the show/hide sprite pair; XOR twice restores the screen).
_gpx_draw_bmp_xor::
        xor     a
        ld      (__gpx_bmp_invert),a    ; stock colours
        ld      a,#BM_XOR
        jr      .bmp_entry
_gpx_draw_bmp::
        xor     a
        ld      (__gpx_bmp_invert),a    ; stock colours, A already BM_CPY

        ;; ------------------------------------------------------------
        ;; __gpx_draw_bmp_mode
        ;; As gpx_draw_bmp, but the caller chooses the blit mode and may ask
        ;; for the stroke colours to be swapped. gpx_draw_text uses this so
        ;; the colour and mode it was given actually reach the glyphs; the
        ;; public entry has no room for them in its signature.
        ;;
        ;; Arguments:
        ;;   A = blit mode, and __gpx_bmp_invert already set:
        ;;       0 draws the bitmap's own colours, 1 swaps ink and paper
        ;;   otherwise as gpx_draw_bmp
        ;;
        ;; Clobbers:
        ;;   AF, BC, DE, HL, IY (IX is preserved)
__gpx_draw_bmp_mode::
.bmp_entry:
        push    ix
        ld      ix,#0
        add     ix,sp

        ;; preserve gpx pointer across local stack allocation
        ld      b,h                     ; gpx hi
        ld      c,l                     ; gpx lo

        ld      hl,#-12
        add     hl,sp
        ld      sp,hl
        ld      L_MODE(ix),a            ; stroke blit mode (CPY or XOR)

        ;; cache args
        ld      L_GPX_LO(ix),c
        ld      L_GPX_HI(ix),b
        ld      L_X_LO(ix),e
        ld      L_X_HI(ix),d

        ;; gpx and bmp must be non-null
        ld      a,b
        or      c
        jp      z,.bmp_done
        ld      l,6(ix)
        ld      h,7(ix)
        ld      a,h
        or      l
        jp      z,.bmp_done

        ;; encoding nibble
        ld      a,(hl)
        and     #0xE0                   ; both tiny signature variants

        cp      #(BMP_ENC_TINY << 4)
        jp      nz,.bmp_done

        ;; ------------------------------------------------------------
        ;; tiny move-stream path
.bmp_tiny:
        ;; tiny payload supports two on-wire header layouts:
        ;;   compact: +0 sig, +1 w, +2 h, +3 size_lo, +4 size_hi, +5 data
        ;;   legacy:  +0 sig, +1 w, +2 h, +3 moves,            +4 data
        inc     hl
        ld      a,(hl)                  ; declared width (box pre-clip)
        ld      L_BOXW(ix),a
        inc     hl
        ld      a,(hl)                  ; declared height
        ld      L_BOXH(ix),a
        inc     hl
        ld      a,(hl)                  ; size low
        ld      L_MOVES(ix),a
        inc     hl
        ld      a,(hl)                  ; size high (compact) or first move (legacy)
        or      a
        jr      nz,.bmp_tiny_legacy

        ;; compact data pointer = b + 5
        inc     hl
        jr      .bmp_tiny_have_dat

.bmp_tiny_legacy:
        ;; Legacy Tiny glyphs store width-1 and height-1. Convert them to
        ;; extents for the box pre-clip; compact cursor records above already
        ;; store literal dimensions.
        inc     L_BOXW(ix)
        inc     L_BOXH(ix)

        ;; legacy data pointer = b + 4
        ;; HL already points to first move byte

.bmp_tiny_have_dat:
        ld      a,L_MOVES(ix)
        or      a
        jp      z,.bmp_done

        push    hl                      ; stream pointer across box clipping

        ;; ---- box pre-clip (per-bitmap clip box, tiny_clip_t idea) ----
        ;; The declared w x h box bounds every stroke: box fully inside
        ;; the clip -> strokes skip per-stroke clipping (clip := NULL);
        ;; fully outside -> nothing to draw; straddling keeps per-stroke
        ;; Cohen-Sutherland. Degenerate w/h = 0 skips the optimization so
        ;; contract-breaking assets keep the old behavior. Uses the
        ;; L_X0/L_Y0 stroke scratch (initialized right below).
        ld      a,L_CLIP_LO(ix)
        or      L_CLIP_HI(ix)
        jp      z,.bmp_box_done
        ld      a,L_BOXW(ix)
        or      a
        jp      z,.bmp_box_done
        ld      a,L_BOXH(ix)
        or      a
        jp      z,.bmp_box_done
        ;; box x1 -> L_X0, box y1 -> L_Y0 (scratch)
        ld      l,L_X_LO(ix)
        ld      h,L_X_HI(ix)
        ld      e,L_BOXW(ix)
        ld      d,#0
        add     hl,de
        dec     hl
        ld      L_X0_LO(ix),l
        ld      L_X0_HI(ix),h
        ld      l,L_Y_LO(ix)
        ld      h,L_Y_HI(ix)
        ld      e,L_BOXH(ix)
        ld      d,#0
        add     hl,de
        dec     hl
        ld      L_Y0_LO(ix),l
        ld      L_Y0_HI(ix),h
        ld      l,L_CLIP_LO(ix)
        ld      h,L_CLIP_HI(ix)
        push    hl
        pop     iy                      ; IY = clip fields
        ld      b,#1                    ; fully-inside until disproven
        ;; The comparison helper returns A=0/1 and corresponding Z flags.
        ;; x axis
        ld      e,0(iy)
        ld      d,1(iy)                 ; DE = cx0
        ld      l,L_X0_LO(ix)
        ld      h,L_X0_HI(ix)
        call    __rect_cmp16s_lt        ; box_x1 < cx0 -> fully outside
        jp      nz,.bmp_done
        ld      l,L_X_LO(ix)
        ld      h,L_X_HI(ix)
        call    __rect_cmp16s_lt        ; x < cx0 -> not fully inside
        jr      z,.bmp_box_x1
        ld      b,#0
.bmp_box_x1:
        ld      l,4(iy)
        ld      h,5(iy)                 ; HL = cx1
        ld      e,L_X_LO(ix)
        ld      d,L_X_HI(ix)
        call    __rect_cmp16s_lt        ; cx1 < x -> fully outside
        jp      nz,.bmp_done
        ld      e,L_X0_LO(ix)
        ld      d,L_X0_HI(ix)
        call    __rect_cmp16s_lt        ; cx1 < box_x1 -> not fully inside
        jr      z,.bmp_box_y0
        ld      b,#0
.bmp_box_y0:
        ;; y axis
        ld      e,2(iy)
        ld      d,3(iy)                 ; DE = cy0
        ld      l,L_Y0_LO(ix)
        ld      h,L_Y0_HI(ix)
        call    __rect_cmp16s_lt        ; box_y1 < cy0 -> fully outside
        jp      nz,.bmp_done
        ld      l,L_Y_LO(ix)
        ld      h,L_Y_HI(ix)
        call    __rect_cmp16s_lt        ; y < cy0 -> not fully inside
        jr      z,.bmp_box_y1
        ld      b,#0
.bmp_box_y1:
        ld      l,6(iy)
        ld      h,7(iy)                 ; HL = cy1
        ld      e,L_Y_LO(ix)
        ld      d,L_Y_HI(ix)
        call    __rect_cmp16s_lt        ; cy1 < y -> fully outside
        jp      nz,.bmp_done
        ld      e,L_Y0_LO(ix)
        ld      d,L_Y0_HI(ix)
        call    __rect_cmp16s_lt        ; cy1 < box_y1 -> not fully inside
        jr      z,.bmp_box_class
        ld      b,#0
.bmp_box_class:
        ld      a,b
        or      a
        jr      z,.bmp_box_done         ; straddling: keep per-stroke clip
        xor     a                       ; fully inside: strokes skip C-S
        ld      L_CLIP_LO(ix),a
        ld      L_CLIP_HI(ix),a
.bmp_box_done:
        pop     iy                      ; stream pointer for the whole loop

        ;; Track running endpoints in the shared block. Unclipped strokes
        ;; issue packed short-vector commands; clipped strokes pass these
        ;; coordinates to the line renderer.
        ;; x0 = x, y0 = y (no origin bytes in payload)
        ld      l,L_X_LO(ix)
        ld      h,L_X_HI(ix)
        ld      (__gpx_vec_x0),hl

        ld      l,L_Y_LO(ix)
        ld      h,L_Y_HI(ix)
        ld      (__gpx_vec_y0),hl

        ;; Blit mode and line style are the same for every stroke of this
        ;; bitmap, so program them once here rather than per stroke. Both are
        ;; cached, but even a cache hit costs a call.
        ld      a,L_MODE(ix)
        call    __ef9367_set_blit_mode
        ld      a,#EF9367_CR2_SOLID
        call    __ef9367_set_line_style

        ;; An unclipped stream runs entirely on the GDP cursor, including
        ;; pen-up moves. Only clipped streams need software endpoints.
        ld      a,L_CLIP_LO(ix)
        or      L_CLIP_HI(ix)
        jp      z,.bmp_native

.bmp_tiny_loop:
        ld      c,0(iy)                 ; C = move byte
        inc     iy

        ;; x1 = x0 +/- dx
        ld      a,c
        rlca
        rlca
        rlca
        and     #0x03
        ld      e,a
        ld      d,#0x00
        ld      hl,(__gpx_vec_x0)
        bit     1,c
        jr      z,.bmp_dx_add
        or      a
        sbc     hl,de
        jr      .bmp_dx_done
.bmp_dx_add:
        add     hl,de
.bmp_dx_done:
        ld      (__gpx_vec_x1),hl

        ;; y1 = y0 +/- dy
        ld      a,c
        rrca
        rrca
        rrca
        and     #0x03
        ld      e,a
        ld      d,#0x00
        ld      hl,(__gpx_vec_y0)
        bit     2,c
        jr      z,.bmp_dy_add
        or      a
        sbc     hl,de
        jr      .bmp_dy_done
.bmp_dy_add:
        add     hl,de
.bmp_dy_done:
        ld      (__gpx_vec_y1),hl

        ;; Neither ink bit means pen-up; bit 0 takes priority for eraser.
        ld      a,c
        and     #0x81
        jr      z,.bmp_tiny_advance
        rra                             ; carry = background flag
        sbc     a,a
        inc     a                       ; foreground = 1, background = 0
        ld      b,a
        ld      a,(__gpx_bmp_invert)
        xor     b
        ld      b,a
.bmp_stroke_clipped:
        push    iy                      ; line clipping borrows IY
        ;; gpx_draw_line(gpx, x0, y0, x1, y1, color, L_MODE, 0xFF, clip)
        ld      l,L_CLIP_LO(ix)
        ld      h,L_CLIP_HI(ix)
        push    hl                      ; clip

        ld      a,#LPATT_SOLID
        push    af                      ; lpatt
        inc     sp

        ld      l,b                     ; color
        ld      h,L_MODE(ix)            ; CPY normally, XOR for sprites
        push    hl                      ; c,m

        ld      hl,(__gpx_vec_y1)
        push    hl                      ; y1

        ld      hl,(__gpx_vec_x1)
        push    hl                      ; x1

        ld      hl,(__gpx_vec_y0)
        push    hl                      ; y0

        ld      l,L_GPX_LO(ix)
        ld      h,L_GPX_HI(ix)
        ld      de,(__gpx_vec_x0)
        call    _gpx_draw_line
        pop     iy

.bmp_tiny_advance:
        ;; x0 = x1, y0 = y1, in place in the shared endpoint block
        ld      hl,(__gpx_vec_x1)
        ld      (__gpx_vec_x0),hl
        ld      hl,(__gpx_vec_y1)
        ld      (__gpx_vec_y0),hl

        dec     L_MOVES(ix)
        jp      nz,.bmp_tiny_loop
        jr      .bmp_done

.bmp_native:
        ;; The GDP owns the unclipped cursor. Short commands encode all
        ;; four delta bits directly, so no software coordinate arithmetic or
        ;; writes to DX/DY are needed, even for a pen-up move.
        ld      hl,(__gpx_vec_x0)
        ld      de,(__gpx_vec_y0)
        call    __ef9367_set_xy_fast
        ld      b,L_MOVES(ix)
        ld      a,(__gpx_bmp_invert)
        ld      e,a                     ; fixed ink/paper inversion
        ld      d,#0xFF                 ; no cached pen/colour choice yet
.bmp_native_loop:
        ld      c,0(iy)
        inc     iy
        ld      a,c
        and     #0x81                   ; raw ink choice, independent of delta
        cp      d
        jr      z,.bmp_native_wait      ; same state needs no GDP helper call
        ld      d,a
        push    bc                      ; setters borrow C; B is loop count
        or      a
        jr      z,.bmp_native_pen       ; neither ink bit: pen up
        rra                             ; carry = background flag
        sbc     a,a
        inc     a                       ; foreground = 1, background = 0
        xor     e                       ; fixed ink/paper inversion
        call    __ef9367_set_color
        ld      a,#1                    ; pen down
.bmp_native_pen:
        call    __ef9367_set_pen
        pop     bc
.bmp_native_wait:
        in      a,(EF9367_STS_NI)
        and     #EF9367_STS_NI_READY
        jr      z,.bmp_native_wait
        ld      a,c
        or      #0x81                   ; short vector, oblique direction
        xor     #0x04                   ; the GDP Y axis points upwards
        out     (#EF9367_CMD),a
        djnz    .bmp_native_loop
        ld      a,#1
        call    __ef9367_set_pen        ; later primitives expect a lowered pen

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

        .area   _DATA

        ;; Set by __gpx_draw_bmp_mode's caller: 1 swaps each stroke's ink
        ;; and paper, which is how gpx_draw_text honours a CO_BACK request.
__gpx_bmp_invert::
        .db     0x00
