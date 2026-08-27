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
        .globl  __rect_cmp16s_lt
        .globl  __ef9367_max_y

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
        ;;   AF, BC, DE, HL
__gpx_bresenham_line_local:
        ;; ---- dx and the x step direction ----
        ld      l,S_X1_LO(ix)
        ld      h,S_X1_HI(ix)           ; HL = x1
        ld      e,S_X0_LO(ix)
        ld      d,S_X0_HI(ix)           ; DE = x0
        ld      (__bs_x0),de            ; loop origin
        call    __rect_cmp16s_lt        ; A = (x1 < x0)
        or      a
        jr      z,.gbl_dx_pos

        ld      a,#0xFF                 ; walk left
        ld      (__bs_sx),a
        ld      hl,(__bs_x0)            ; HL = x0
        ld      e,S_X1_LO(ix)
        ld      d,S_X1_HI(ix)           ; DE = x1
        or      a
        sbc     hl,de                   ; dx = x0 - x1
        jr      .gbl_dx_done

.gbl_dx_pos:
        ld      a,#0x01                 ; walk right
        ld      (__bs_sx),a
        ld      l,S_X1_LO(ix)
        ld      h,S_X1_HI(ix)           ; HL = x1
        ld      de,(__bs_x0)            ; DE = x0
        or      a
        sbc     hl,de                   ; dx = x1 - x0

.gbl_dx_done:
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
        jr      z,.gbl_dy_pos

        ld      a,#0x01                 ; y0 falls, so ty rises
        ld      (__bs_sty),a
        ld      l,S_Y0_LO(ix)
        ld      h,S_Y0_HI(ix)           ; HL = y0
        ld      e,S_Y1_LO(ix)
        ld      d,S_Y1_HI(ix)           ; DE = y1
        or      a
        sbc     hl,de                   ; dy = y0 - y1
        jr      .gbl_dy_done

.gbl_dy_pos:
        ld      a,#0xFF                 ; y0 rises, so ty falls
        ld      (__bs_sty),a
        ld      l,S_Y1_LO(ix)
        ld      h,S_Y1_HI(ix)           ; HL = y1
        ld      e,S_Y0_LO(ix)
        ld      d,S_Y0_HI(ix)           ; DE = y0
        or      a
        sbc     hl,de                   ; dy = y1 - y0

.gbl_dy_done:
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
        ld      (__bs_n),hl

        ld      c,LPATT_RET(ix)         ; pattern rides in C from here on

.gbl_loop:
        ;; ---- plot, if this pattern bit is set ----
        bit     0,c
        jr      z,.gbl_after_plot

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
        ld      hl,(__bs_n)
        ld      a,h
        or      l
        jr      z,.gbl_done
        dec     hl
        ld      (__bs_n),hl

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
        rrc     c
        jp      .gbl_loop

.gbl_done:
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
        ;;   HL = x, DE = steps remaining, B = pattern
.gbl_horizontal:
        ;; Fence before touching Y: a plot already in flight reads it.
.gbl_h_ywait:
        in      a,(EF9367_STS_NI)
        and     #EF9367_STS_NI_READY
        jr      z,.gbl_h_ywait
        ld      hl,(__bs_ty)
        ld      a,l
        out     (#EF9367_YPOS_LO),a
        ld      a,h
        out     (#EF9367_YPOS_HI),a

        ld      de,(__bs_dx)            ; steps remaining
        ld      hl,(__bs_x0)            ; running x
        ld      b,LPATT_RET(ix)         ; pattern
        ld      a,(__bs_sx)
        inc     a                       ; 0xFF -> 0, so Z means walk left
        jr      z,.gbl_h_lloop

.gbl_h_rloop:
        bit     0,b
        jr      z,.gbl_h_rnext
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
        ld      a,d
        or      e
        jr      z,.gbl_h_done
        dec     de
        inc     hl
        rrc     b
        jr      .gbl_h_rloop

.gbl_h_lloop:
        bit     0,b
        jr      z,.gbl_h_lnext
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
        ld      a,d
        or      e
        jr      z,.gbl_h_done
        dec     de
        dec     hl
        rrc     b
        jr      .gbl_h_lloop

.gbl_h_done:
        ld      LPATT_RET(ix),b         ; hand the rotated pattern back
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
__bs_n:
        .dw     0x0000
__bs_sx:
        .db     0x00
__bs_sty:
        .db     0x00
