        ;; _gpx_bresenham_line.s
        ;;
        ;; Partner software Bresenham renderer used for custom line patterns.
        ;;
        ;; Only patterns that gpx_draw_line cannot hand to an EF9367 hardware
        ;; vector style arrive here, but when they do this loop runs once per
        ;; pixel, so it is the hottest code in the backend -- a patterned fill
        ;; is tens of thousands of trips through it.
        ;;
        ;; Three things keep it cheap:
        ;;
        ;;  * The working set lives in static storage, not the caller's IX
        ;;    frame. A 16-bit value costs 16 T-states to load absolutely
        ;;    against 38 for the two IX-indexed byte loads it replaces. The
        ;;    library is already single-context (the EF9367 mode caches are
        ;;    global), so this gives up no re-entrancy that was not gone.
        ;;
        ;;  * Y is kept already reverse-transformed, as max_y - y. The EF9367
        ;;    counts Y up the screen and libgpx counts it down, so the plot
        ;;    would otherwise pay a load, a clear-carry and a 16-bit subtract
        ;;    per pixel. Stepping the transformed value in the opposite
        ;;    direction costs nothing and hoists all of that out of the loop.
        ;;
        ;;  * The pattern byte stays in C across the whole loop, including
        ;;    the plot, because nothing on that path touches BC.
        ;;
        ;; The pixels chosen are exactly those of the symmetric two-test
        ;; Bresenham this replaced; only the cost of reaching them changed.
        ;;
        ;; GPL2 License (see: LICENSE)
        ;; Copyright (C) 2026 Tomaz Stih
        ;;
        ;; 2026-07-13   TS

        .module _gpx_bresenham_line
        .optsdcc -mz80 sdcccall(1)

        .globl  __gpx_bresenham_line_local
        .globl  __gpx_horizontal_prepared
        .globl  __gpx_native_horizontal
        .globl  __rect_cmp16s_lt
        .globl  __ef9367_max_y
        .globl  __ef9367_cache_bmode
        .globl  __ef9367_set_line_style

        .include "_ef9367-defs.inc"

        .equ    EF9367_CMD_PLOT,     0x80

        ;; Shared frame layout (owned by gpx_draw_line.s / caller via IX):
        .equ    S_X0_LO,             -12
        .equ    S_X0_HI,             -11
        .equ    S_Y0_LO,             -10
        .equ    S_Y0_HI,             -9
        .equ    S_X1_LO,             -8
        .equ    S_X1_HI,             -7
        .equ    S_Y1_LO,             -6
        .equ    S_Y1_HI,             -5

        .equ    LPATT_RET,           -2

        .area   _CODE

        ;; ------------------------------------------------------------
        ;; __gpx_bresenham_line_local
        ;; Draw line using software Bresenham and EF9367 pixel commands.
        ;;
        ;; Arguments:
        ;;   IX = pointer to gpx_draw_line local frame (endpoints + pattern)
        ;;
        ;; Return:
        ;;   LPATT_RET rotated across the plotted segment.
        ;;
        ;; Clobbers:
        ;;   AF, BC, DE, HL, AF', BC'
__gpx_bresenham_line_local:
        ;; ---- dx and the x step direction ----
        ld      l,S_X1_LO(ix)
        ld      h,S_X1_HI(ix)           ; HL = x1
        ld      e,S_X0_LO(ix)
        ld      d,S_X0_HI(ix)           ; DE = x0
        ld      (__bs_x0),de            ; loop origin
        call    __rect_cmp16s_lt        ; A = (x1 < x0)
        or      a
        ld      a,#1                    ; x grows unless endpoints reverse
        jr      z,.gbl_dx_ordered
        ex      de,hl                   ; comparator preserves both operands
        ld      a,#0xFF
.gbl_dx_ordered:
        ld      (__bs_sx),a
        or      a
        sbc     hl,de

        ld      (__bs_dx),hl

        ;; ---- ty = max_y - y0, and the step that walks it ----
        ;; y0 rising means ty falling, so the stored step is the negation.
        ld      hl,(__ef9367_max_y)
        ld      e,S_Y0_LO(ix)
        ld      d,S_Y0_HI(ix)           ; DE = y0
        or      a
        sbc     hl,de
        ld      (__bs_ty),hl

        ;; ---- dy and the y step direction ----
        ld      l,S_Y1_LO(ix)
        ld      h,S_Y1_HI(ix)           ; HL = y1, DE still y0
        call    __rect_cmp16s_lt        ; A = (y1 < y0)
        or      a
        ld      a,#0xFF                 ; increasing y decreases GDP y
        jr      z,.gbl_dy_ordered
        ex      de,hl
        ld      a,#1
.gbl_dy_ordered:
        ld      (__bs_sty),a
        or      a
        sbc     hl,de

        ld      (__bs_dy),hl

        ;; A horizontal line is the common case by a wide margin -- every row
        ;; of every patterned fill is one -- and Bresenham degenerates for
        ;; it: y never moves and x steps on every pixel, so the error term
        ;; does nothing. Hoist Y out of the loop entirely (the EF9367 keeps
        ;; its cursor registers between commands, so it only has to be
        ;; written once) and walk x in a register.
        ld      a,h
        or      l
        jp      z,.gbl_horizontal

        ex      de,hl                   ; DE = dy

        ;; ---- err = dx - dy ----
        ld      hl,(__bs_dx)
        or      a
        sbc     hl,de
        ld      (__bs_err),hl

        ;; ---- n = max(dx, dy) ----
        ;; HL still holds dx - dy, so its sign picks the larger. The loop
        ;; advances x exactly dx times and y exactly dy times, so it lands on
        ;; (x1,y1) after exactly max(dx,dy) steps; counting them is the same
        ;; test as comparing both coordinates, for a fraction of the cost.
        bit     7,h                     ; dx - dy < 0 -> dy is the major axis
        ld      hl,(__bs_dx)
        jr      z,.gbl_n_have
        ld      hl,(__bs_dy)
.gbl_n_have:
        push    hl
        exx
        pop     bc                      ; BC' counts steps without RAM traffic
        exx

        ld      c,LPATT_RET(ix)         ; pattern rides in C from here on

.gbl_loop:
        ;; ---- plot, if this pattern bit is set ----
        rrc     c                       ; carry is this pixel's pattern bit
        jr      nc,.gbl_after_plot

        ;; Fence on READY: the previous plot uses X and Y as parameters, so
        ;; they must not move under it. Nothing is issued between here and
        ;; the command below, so that command needs no second fence.
.gbl_wait:
        in      a,(EF9367_STS_NI)
        and     #EF9367_STS_NI_READY
        jr      z,.gbl_wait

        ld      hl,(__bs_x0)
        ld      a,l
        out     (#EF9367_XPOS_LO),a
        ld      a,h
        out     (#EF9367_XPOS_HI),a
        ld      hl,(__bs_ty)            ; already reverse-transformed
        ld      a,l
        out     (#EF9367_YPOS_LO),a
        ld      a,h
        out     (#EF9367_YPOS_HI),a
        ld      a,#EF9367_CMD_PLOT
        out     (#EF9367_CMD),a

.gbl_after_plot:
        ;; ---- any steps left? ----
        exx
        ld      a,b
        or      c
        jr      z,.gbl_done
        dec     bc
        exx

        ;; ---- e2 = err * 2, kept in DE across both tests ----
        ld      hl,(__bs_err)
        add     hl,hl
        ex      de,hl                   ; DE = e2

        ;; ---- if (e2 > -dy), i.e. (e2 + dy) > 0 ----
        ;; dy is non-negative and both sides sit well inside 16 bits, so the
        ;; add cannot overflow.
        ld      hl,(__bs_dy)
        add     hl,de                   ; HL = e2 + dy
        bit     7,h
        jr      nz,.gbl_skip_x          ; negative -> not greater
        ld      a,h
        or      l
        jr      z,.gbl_skip_x           ; zero -> not greater

        ;; err -= dy. DE carries e2 into the second test, so park it rather
        ;; than spilling e2 and reloading it.
        ld      hl,(__bs_err)
        push    de
        ld      de,(__bs_dy)
        or      a
        sbc     hl,de
        pop     de
        ld      (__bs_err),hl

        ;; x0 += sx
        ld      hl,(__bs_x0)
        ld      a,(__bs_sx)
        inc     a                       ; 0xFF -> 0, so Z means step left
        jr      z,.gbl_x_dec
        inc     hl
        jr      .gbl_x_store
.gbl_x_dec:
        dec     hl
.gbl_x_store:
        ld      (__bs_x0),hl

.gbl_skip_x:
        ;; ---- if (e2 < dx), i.e. (e2 - dx) < 0 ----
        ld      hl,(__bs_dx)
        ex      de,hl                   ; HL = e2, DE = dx
        or      a
        sbc     hl,de                   ; HL = e2 - dx
        bit     7,h
        jr      z,.gbl_rot              ; not negative -> not less

        ;; err += dx -- DE already holds dx from the compare above
        ld      hl,(__bs_err)
        add     hl,de
        ld      (__bs_err),hl

        ;; ty += sty (the negated y step, see the header)
        ld      hl,(__bs_ty)
        ld      a,(__bs_sty)
        inc     a                       ; 0xFF -> 0, so Z means step down
        jr      z,.gbl_y_dec
        inc     hl
        jr      .gbl_y_store
.gbl_y_dec:
        dec     hl
.gbl_y_store:
        ld      (__bs_ty),hl

.gbl_rot:
        jp      .gbl_loop

.gbl_done:
        exx                             ; recover the pattern register set
        rlc     c                       ; return phase advances by steps, not pixels
        ld      LPATT_RET(ix),c         ; hand the rotated pattern back
        ret

        ;; ------------------------------------------------------------
        ;; Horizontal special case: dy == 0.
        ;;
        ;; Y is programmed once up front. Per pixel this leaves a fence, two
        ;; X writes and the plot command, against the general loop's two
        ;; coordinate loads, four register writes and two 16-bit error tests.
        ;; The step direction is resolved once into two loop bodies rather
        ;; than branched on every pixel.
        ;;
        ;; Registers through both loops:
        ;;   Core entry: HL=x, DE=steps, B=pattern, C=out-of-range flag.
        ;;   Scalar loop: HL=x, D=blocks, B=pixels in block, C=pattern.
        ;;   Rotating before the plot exposes the next bit through carry;
        ;;   DJNZ counts pixels without a 16-bit zero test at every pixel.
.gbl_horizontal:
        ld      hl,(__bs_ty)
        call    .gbl_h_set_y
        ld      de,(__bs_dx)            ; steps remaining
        ld      hl,(__bs_x0)            ; running x
        ld      b,LPATT_RET(ix)         ; pattern
        ld      a,h                     ; HL already holds x0
        or      S_X1_HI(ix)
        and     #0xFC
        ld      c,a                     ; nonzero excludes wrapping coordinates
        call    .gbl_h_core
        ld      LPATT_RET(ix),b
        ret

        ;; ------------------------------------------------------------
        ;; __gpx_horizontal_prepared
        ;; Draw an already clipped, nonempty horizontal row, left to right.
        ;; Mode and color have already been programmed by the caller.
        ;;
        ;; Arguments: HL=x0, DE=x1, BC=y, A=LSB-first pattern (1..FF).
        ;; Return: A=pattern rotated by x1-x0.
        ;; Clobbers: AF, BC, DE, HL, AF'. Preserves IX and IY.
__gpx_horizontal_prepared::
        push    af
        push    hl
        ex      de,hl
        or      a
        sbc     hl,de
        push    hl                      ; x1-x0
        ld      hl,(__ef9367_max_y)
        or      a
        sbc     hl,bc
        call    .gbl_h_set_y
        pop     de
        pop     hl
        pop     af
        ld      b,a
        ld      c,#0                    ; caller guarantees visible endpoints
        ld      a,#1
        ld      (__bs_sx),a
        call    .gbl_h_core
        ld      a,b
        ret

        ;; HL is the already transformed GDP y coordinate.
.gbl_h_set_y:
        in      a,(EF9367_STS_NI)
        and     #EF9367_STS_NI_READY
        jr      z,.gbl_h_set_y
        ld      a,l
        out     (#EF9367_YPOS_LO),a
        ld      a,h
        out     (#EF9367_YPOS_HI),a
        ret

.gbl_h_core:
        ld      a,b
        inc     a                       ; FF -> solid style zero, even for points
        jp      z,.gbl_h_native
        ;; Hardware setup pays for itself on longer, visible horizontal
        ;; spans. Keep the scalar path for tiny spans and coordinates that
        ;; can wrap the GDP's 12-bit cursor within a vector.
        ld      a,d
        or      a
        jr      nz,.gbl_h_try_style
        ld      a,e
        cp      #32
        jr      c,.gbl_h_scalar
.gbl_h_try_style:
        ld      a,c
        or      a
        jr      nz,.gbl_h_scalar
        ld      a,b
        rrca
        xor     b                       ; adjacent-bit transitions
        cp      #0xFF
        jp      z,.gbl_h_alternating
        cp      #0x55
        jp      z,.gbl_h_dotted
        cp      #0xAA
        jp      z,.gbl_h_dotted
        cp      #0x11
        jp      z,.gbl_h_dashed
        cp      #0x22
        jp      z,.gbl_h_dashed
        cp      #0x44
        jp      z,.gbl_h_dashed
        cp      #0x88
        jp      z,.gbl_h_dashed
        ;; After native and alternating patterns, equal nibbles identify
        ;; the remaining two-pass patterns: 11 and 77, plus rotations.
        ld      a,b
        rrca
        rrca
        rrca
        rrca
        xor     b
        jp      z,.gbl_h_xor_dashed
        inc     a                       ; opposite nibbles: remaining XOR basis
        jp      z,.gbl_h_xor_three
        ;; Copy can union two four-on strokes into a five/six/seven-on run.
        ;; Find its canonical rotation before peeling the visible prefix.
        ld      a,(__ef9367_cache_bmode)
        or      a
        jr      nz,.gbl_h_scalar
        ld      a,b
        ld      c,#8
.gbl_h_copy_run:
        cp      #0x1F
        jr      z,.gbl_h_copy_have
        cp      #0x3F
        jr      z,.gbl_h_copy_have
        cp      #0x7F
        jr      z,.gbl_h_copy_have
        rrca
        dec     c
        jr      nz,.gbl_h_copy_run
        jr      .gbl_h_scalar
.gbl_h_copy_have:
        ld      c,a
        ld      a,#0x82
        jp      .gbl_h_peel_setup
.gbl_h_scalar:
        ld      c,b                     ; pattern; B counts pixels within a block
        ld      b,e
        inc     b                       ; first block has (steps.low+1) pixels
        inc     d                       ; then steps.high complete 256-pixel blocks
        ld      a,(__bs_sx)
        inc     a                       ; 0xFF -> 0, so Z means walk left
        jr      z,.gbl_h_lloop

.gbl_h_rloop:
        rrc     c
        jr      nc,.gbl_h_rnext
.gbl_h_rwait:
        in      a,(EF9367_STS_NI)
        and     #EF9367_STS_NI_READY
        jr      z,.gbl_h_rwait
        ld      a,l
        out     (#EF9367_XPOS_LO),a
        ld      a,h
        out     (#EF9367_XPOS_HI),a
        ld      a,#EF9367_CMD_PLOT
        out     (#EF9367_CMD),a
.gbl_h_rnext:
        inc     hl
        djnz    .gbl_h_rloop
        dec     d
        jr      nz,.gbl_h_rloop
        jr      .gbl_h_done

.gbl_h_lloop:
        rrc     c
        jr      nc,.gbl_h_lnext
.gbl_h_lwait:
        in      a,(EF9367_STS_NI)
        and     #EF9367_STS_NI_READY
        jr      z,.gbl_h_lwait
        ld      a,l
        out     (#EF9367_XPOS_LO),a
        ld      a,h
        out     (#EF9367_XPOS_HI),a
        ld      a,#EF9367_CMD_PLOT
        out     (#EF9367_CMD),a
.gbl_h_lnext:
        dec     hl
        djnz    .gbl_h_lloop
        dec     d
        jr      nz,.gbl_h_lloop

.gbl_h_done:
        rlc     c                       ; expose the final endpoint's phase
        ld      b,c
        ret

        ;; Native styles start with an on run: 33 is 1100 in time order,
        ;; 0F is 11110000. Peel at most seven pixels to obtain that phase.
        ;; A vector includes its endpoint, so full chunks contain 256
        ;; pixels (DELTA=255); the next origin advances by 256, not 255.
.gbl_h_dotted:
        ld      c,#0x33
        ld      a,#1
        jr      .gbl_h_peel_setup
.gbl_h_dashed:
        ld      c,#0x0F
        ld      a,#2
.gbl_h_peel_setup:
        push    af
.gbl_h_peel:
        ld      a,b
        cp      c
        jr      z,.gbl_h_peel_done
        bit     0,b
        call    nz,.gbl_h_plot
        call    .gbl_h_advance
        rrc     b
        jr      .gbl_h_peel
.gbl_h_peel_done:
        pop     af
        bit     7,a
        jr      nz,.gbl_h_xor_first
        jp      .gbl_h_native

        ;; 33 XOR (33 starting one pixel later) = 55, over exactly the
        ;; requested finite interval. AA skips its first clear pixel.
        ;; Copy uses a union instead: 33 OR (33 << 1) = 77. All touched
        ;; pixels belong to the target, and repeated identical writes agree.
        ;; Other XOR compositions cannot use copy on an arbitrary old raster.
.gbl_h_xor_three:
        ld      c,#0x2D                 ; 0F XOR (0F << 1) XOR (0F << 2)
        ld      a,#0x82
        jr      .gbl_h_xor_check
.gbl_h_alternating:
        ld      c,#0x55
        ld      a,#0x81                 ; dotted, two XOR passes
        jr      .gbl_h_xor_check
.gbl_h_xor_dashed:
        ld      a,b
        and     #0x0F
        ld      c,a
        dec     a
        and     c                       ; one set nibble bit -> sparse 11
        ld      c,#0x11
        jr      z,.gbl_h_xor_have
        ld      c,#0x77                 ; three set nibble bits -> dense 77
.gbl_h_xor_have:
        ld      a,#0x82                 ; dashed, two XOR passes
.gbl_h_xor_check:
        push    af
        ld      a,(__ef9367_cache_bmode)
        dec     a                       ; BM_XOR is 1
        jr      nz,.gbl_h_xor_copy
        pop     af
        jp      .gbl_h_peel_setup
.gbl_h_xor_copy:
        pop     af
        ld      a,c
        cp      #0x77                   ; 33 OR (33 << 1) = 77 in copy mode
        jp      nz,.gbl_h_scalar
        ld      a,#0x81
        jp      .gbl_h_peel_setup
.gbl_h_xor_first:
        and     #3
        ld      c,a                     ; remember which native style was selected
        push    af                      ; native style for the second pass
        push    hl
        push    de
        push    bc
        call    .gbl_h_native
        ld      a,b
        ex      af,af'                  ; final logical pattern survives pass 2
        pop     bc
        pop     de
        pop     hl
        ld      a,c
        ld      c,#1
        cp      #2
        jr      nz,.gbl_h_xor_advance
        bit     4,b                     ; 2D's three passes advance one each
        jr      z,.gbl_h_xor_advance
        bit     5,b
        jr      z,.gbl_h_xor_advance
        inc     c                       ; copy 3F: second four-on run at +2
        bit     6,b
        jr      z,.gbl_h_xor_advance
        inc     c                       ; 77 XOR / 7F copy: second run at +3
.gbl_h_xor_advance:
        call    .gbl_h_advance
        dec     c
        jr      nz,.gbl_h_xor_advance
        ld      a,b
        cp      #0x2D
        jr      z,.gbl_h_third_pass
        pop     af
        call    .gbl_h_native
        jr      .gbl_h_composed_done
.gbl_h_third_pass:
        pop     af
        push    hl
        push    de
        call    .gbl_h_native
        pop     de
        pop     hl
        call    .gbl_h_advance
        ld      a,#2
        call    .gbl_h_native
.gbl_h_composed_done:
        ex      af,af'
        ld      b,a
        ret

        ;; HL advances one pixel in the line direction; DE loses one step.
        ;; Only the bounded prefix and second XOR origin use this helper.
.gbl_h_advance:
        dec     de
        ld      a,(__bs_sx)
        inc     a
        jr      z,.gbl_h_advance_left
        inc     hl
        ret
.gbl_h_advance_left:
        dec     hl
        ret

        ;; Plot one prefix pixel, retaining the pattern and native target.
.gbl_h_plot:
        in      a,(EF9367_STS_NI)
        and     #EF9367_STS_NI_READY
        jr      z,.gbl_h_plot
        ld      a,l
        out     (#EF9367_XPOS_LO),a
        ld      a,h
        out     (#EF9367_XPOS_HI),a
        ld      a,#EF9367_CMD_PLOT
        out     (#EF9367_CMD),a
        ret

        ;; A = style, HL = origin, DE = major steps, B = logical pattern.
        ;; Draw aligned native chunks, then rotate B by DE mod 8. The same
        ;; kernel serves both passes of the alternating XOR composition.
.gbl_h_native:
        push    bc
        call    __ef9367_set_line_style
        pop     bc
        ld      c,#0x10
        ld      a,(__bs_sx)
        inc     a
        jr      nz,.gbl_h_native_wait
        ld      c,#0x16
        ;; ------------------------------------------------------------
        ;; __gpx_native_horizontal
        ;; Internal continuation for solid vector callers that already
        ;; programmed Y and style: HL=x, DE=steps, B=pattern, C=command.
        ;; Return: B rotated by the number of major steps.
        ;; Clobbers: AF, BC, DE, HL. Preserves IX and IY.
__gpx_native_horizontal::
.gbl_h_native_wait:
        in      a,(EF9367_STS_NI)
        and     #EF9367_STS_NI_READY
        jr      z,.gbl_h_native_wait
        ld      a,l
        out     (#EF9367_XPOS_LO),a
        ld      a,h
        out     (#EF9367_XPOS_HI),a
        xor     a
        out     (#EF9367_DY),a
        ld      a,d
        or      a
        ld      a,#255
        jr      nz,.gbl_h_native_issue
        ld      a,e
.gbl_h_native_issue:
        out     (#EF9367_DX),a
        ld      a,c
        out     (#EF9367_CMD),a
        ld      a,d
        or      a
        jr      z,.gbl_h_native_done
        dec     d                       ; steps -= 256
        inc     h                       ; origin += 256, or -= 256 if left
        bit     1,c
        jr      z,.gbl_h_native_wait
        dec     h
        dec     h
        jr      .gbl_h_native_wait
.gbl_h_native_done:
        ld      a,e
        and     #7
        ret     z
.gbl_h_native_rot:
        rrc     b
        dec     a
        jr      nz,.gbl_h_native_rot
        ret

        .area   _DATA

        ;; Bresenham working set. Static rather than frame-resident: see the
        ;; note at the top of this file.
__bs_x0:
        .dw     0x0000
__bs_ty:
        .dw     0x0000                  ; max_y - y, ready to write to the GDP
__bs_dx:
        .dw     0x0000
__bs_dy:
        .dw     0x0000
__bs_err:
        .dw     0x0000
__bs_sx:
        .db     0x00
__bs_sty:
        .db     0x00
