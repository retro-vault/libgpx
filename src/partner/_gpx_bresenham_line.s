        ;; _gpx_bresenham_line.s
        ;;
        ;; Partner software Bresenham renderer used for custom line patterns.

        .module _gpx_bresenham_line
        .optsdcc -mz80 sdcccall(1)

        .globl  __gpx_bresenham_line_local
        .globl  __cs_rect_cmp16s_lt
        .globl  __ef9367_set_xy
        .globl  __ef9367_exec_cmd

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

        .equ    BS_SX,               -37
        .equ    BS_SY,               -36
        .equ    BS_DX_LO,            -35
        .equ    BS_DX_HI,            -34
        .equ    BS_DY_LO,            -33
        .equ    BS_DY_HI,            -32
        .equ    BS_ERR_LO,           -31
        .equ    BS_ERR_HI,           -30
        .equ    BS_E2_LO,            -29
        .equ    BS_E2_HI,            -28
        .equ    BS_NDY_LO,           -27
        .equ    BS_NDY_HI,           -26

        .area   _CODE

        ;; ------------------------------------------------------------
        ;; __gpx_bresenham_line_local
        ;; Draw line using software Bresenham and EF9367 pixel command.
        ;;
        ;; Input:
        ;;   IX = pointer to gpx_draw_line local frame.
        ;;
        ;; Frame fields used:
        ;;   S_X0/S_Y0, S_X1/S_Y1, LPATT_RET, BS_* scratch
        ;;
        ;; Output:
        ;;   LPATT_RET rotated across plotted segment.
        ;;
        ;; Clobbers:
        ;;   AF, BC, DE, HL
__gpx_bresenham_line_local:
        ;; dx + sx
        ;; if (x1 < x0) { sx=-1; dx=x0-x1; } else { sx=+1; dx=x1-x0; }
        ld      l,S_X1_LO(ix)
        ld      h,S_X1_HI(ix)          ;; HL = x1
        ld      e,S_X0_LO(ix)
        ld      d,S_X0_HI(ix)          ;; DE = x0
        call    __cs_rect_cmp16s_lt
        or      a
        jr      z,.gbl_dx_pos

        ld      a,#0xFF
        ld      BS_SX(ix),a
        ld      l,S_X0_LO(ix)
        ld      h,S_X0_HI(ix)          ;; HL = x0
        ld      e,S_X1_LO(ix)
        ld      d,S_X1_HI(ix)          ;; DE = x1
        or      a
        sbc     hl,de
        jr      .gbl_dx_done

.gbl_dx_pos:
        ld      a,#0x01
        ld      BS_SX(ix),a
        ld      l,S_X1_LO(ix)
        ld      h,S_X1_HI(ix)          ;; HL = x1
        ld      e,S_X0_LO(ix)
        ld      d,S_X0_HI(ix)          ;; DE = x0
        or      a
        sbc     hl,de

.gbl_dx_done:
        ld      BS_DX_LO(ix),l
        ld      BS_DX_HI(ix),h

        ;; dy + sy
        ld      l,S_Y1_LO(ix)
        ld      h,S_Y1_HI(ix)          ;; HL = y1
        ld      e,S_Y0_LO(ix)
        ld      d,S_Y0_HI(ix)          ;; DE = y0
        call    __cs_rect_cmp16s_lt
        or      a
        jr      z,.gbl_dy_pos

        ld      a,#0xFF
        ld      BS_SY(ix),a
        ld      l,S_Y0_LO(ix)
        ld      h,S_Y0_HI(ix)          ;; HL = y0
        ld      e,S_Y1_LO(ix)
        ld      d,S_Y1_HI(ix)          ;; DE = y1
        or      a
        sbc     hl,de
        jr      .gbl_dy_done

.gbl_dy_pos:
        ld      a,#0x01
        ld      BS_SY(ix),a
        ld      l,S_Y1_LO(ix)
        ld      h,S_Y1_HI(ix)          ;; HL = y1
        ld      e,S_Y0_LO(ix)
        ld      d,S_Y0_HI(ix)          ;; DE = y0
        or      a
        sbc     hl,de

.gbl_dy_done:
        ld      BS_DY_LO(ix),l
        ld      BS_DY_HI(ix),h

        ;; err = dx - dy
        ld      l,BS_DX_LO(ix)
        ld      h,BS_DX_HI(ix)
        ld      e,BS_DY_LO(ix)
        ld      d,BS_DY_HI(ix)
        or      a
        sbc     hl,de
        ld      BS_ERR_LO(ix),l
        ld      BS_ERR_HI(ix),h

.gbl_loop:
        ;; pattern bit
        ld      a,LPATT_RET(ix)
        and     #0x01
        jr      z,.gbl_after_plot

        ld      l,S_X0_LO(ix)
        ld      h,S_X0_HI(ix)
        ld      e,S_Y0_LO(ix)
        ld      d,S_Y0_HI(ix)
        call    .gbl_put_pixel

.gbl_after_plot:
        ;; done?
        ld      a,S_X0_LO(ix)
        cp      S_X1_LO(ix)
        jr      nz,.gbl_step
        ld      a,S_X0_HI(ix)
        cp      S_X1_HI(ix)
        jr      nz,.gbl_step
        ld      a,S_Y0_LO(ix)
        cp      S_Y1_LO(ix)
        jr      nz,.gbl_step
        ld      a,S_Y0_HI(ix)
        cp      S_Y1_HI(ix)
        jp      z,.gbl_done

.gbl_step:
        ;; e2 = err * 2
        ld      l,BS_ERR_LO(ix)
        ld      h,BS_ERR_HI(ix)
        add     hl,hl
        ld      BS_E2_LO(ix),l
        ld      BS_E2_HI(ix),h

        ;; neg_dy = -dy
        ld      l,BS_DY_LO(ix)
        ld      h,BS_DY_HI(ix)
        ld      a,l
        cpl
        ld      l,a
        ld      a,h
        cpl
        ld      h,a
        inc     hl
        ld      BS_NDY_LO(ix),l
        ld      BS_NDY_HI(ix),h

        ;; if (e2 > -dy)
        ld      l,BS_NDY_LO(ix)
        ld      h,BS_NDY_HI(ix)        ;; HL = -dy
        ld      e,BS_E2_LO(ix)
        ld      d,BS_E2_HI(ix)         ;; DE = e2
        call    __cs_rect_cmp16s_lt    ;; (-dy < e2)?
        or      a
        jr      z,.gbl_skip_x

        ;; err -= dy
        ld      l,BS_ERR_LO(ix)
        ld      h,BS_ERR_HI(ix)
        ld      e,BS_DY_LO(ix)
        ld      d,BS_DY_HI(ix)
        or      a
        sbc     hl,de
        ld      BS_ERR_LO(ix),l
        ld      BS_ERR_HI(ix),h

        ;; x0 += sx
        ld      a,BS_SX(ix)
        cp      #0xFF
        jr      z,.gbl_x_dec
        ld      l,S_X0_LO(ix)
        ld      h,S_X0_HI(ix)
        inc     hl
        ld      S_X0_LO(ix),l
        ld      S_X0_HI(ix),h
        jr      .gbl_skip_x

.gbl_x_dec:
        ld      l,S_X0_LO(ix)
        ld      h,S_X0_HI(ix)
        dec     hl
        ld      S_X0_LO(ix),l
        ld      S_X0_HI(ix),h

.gbl_skip_x:
        ;; if (e2 < dx)
        ld      l,BS_E2_LO(ix)
        ld      h,BS_E2_HI(ix)         ;; HL = e2
        ld      e,BS_DX_LO(ix)
        ld      d,BS_DX_HI(ix)         ;; DE = dx
        call    __cs_rect_cmp16s_lt
        or      a
        jr      z,.gbl_rot

        ;; err += dx
        ld      l,BS_ERR_LO(ix)
        ld      h,BS_ERR_HI(ix)
        ld      e,BS_DX_LO(ix)
        ld      d,BS_DX_HI(ix)
        add     hl,de
        ld      BS_ERR_LO(ix),l
        ld      BS_ERR_HI(ix),h

        ;; y0 += sy
        ld      a,BS_SY(ix)
        cp      #0xFF
        jr      z,.gbl_y_dec
        ld      l,S_Y0_LO(ix)
        ld      h,S_Y0_HI(ix)
        inc     hl
        ld      S_Y0_LO(ix),l
        ld      S_Y0_HI(ix),h
        jr      .gbl_rot

.gbl_y_dec:
        ld      l,S_Y0_LO(ix)
        ld      h,S_Y0_HI(ix)
        dec     hl
        ld      S_Y0_LO(ix),l
        ld      S_Y0_HI(ix),h

.gbl_rot:
        ld      a,LPATT_RET(ix)
        rrca
        ld      LPATT_RET(ix),a
        jp      .gbl_loop

.gbl_done:
        ret

        ;; Plot one pixel at HL=x, DE=y using current hardware mode.
.gbl_put_pixel:
        call    __ef9367_set_xy
        ld      a,#EF9367_CMD_PLOT
        call    __ef9367_exec_cmd
        ret
