        ;; gpx_draw_pixel.s
        ;;
        ;; Partner pixel primitive with optional clipping.

        .module gpx_draw_pixel
        .optsdcc -mz80 sdcccall(1)

        .globl  _gpx_draw_pixel
        .globl  __gdata
        .globl  __ef9367_set_blit_mode
        .globl  __ef9367_set_color
        .globl  __ef9367_set_xy
        .globl  __ef9367_exec_cmd

        .include "_ef9367-defs.inc"

        .equ    EF9367_CMD_PLOT,       0x80
        .equ    SCRWIDTH_HI,           0x04      ;; x < 1024

        ;; locals (4 bytes)
        .equ    P_X_LO,               -4
        .equ    P_X_HI,               -3
        .equ    P_Y_LO,               -2
        .equ    P_Y_HI,               -1

        .area   _CODE

        ;; ------------------------------------------------------------
        ;; void gpx_draw_pixel(
        ;;   gpx_t *gpx,        HL (ignored)
        ;;   coord x,           DE
        ;;   coord y,           SP+2 (2 bytes)
        ;;   color c,           SP+4 (1 byte)
        ;;   bmode m,           SP+5 (1 byte)
        ;;   const rect_t *clip SP+6 (2 bytes)
        ;;
        ;; Callee cleans 6 bytes from stack.
        ;;
        ;; Clobbers:
        ;;   AF, BC, DE, HL, IX, IY
_gpx_draw_pixel::
        push    ix
        ld      ix,#0
        add     ix,sp

        ld      hl,#-4
        add     hl,sp
        ld      sp,hl

        ;; Cache x and y.
        ld      P_X_LO(ix),e
        ld      P_X_HI(ix),d
        ld      a,4(ix)
        ld      P_Y_LO(ix),a
        ld      a,5(ix)
        ld      P_Y_HI(ix),a

        ;; x must be in [0,1023].
        ld      a,P_X_HI(ix)
        bit     7,a
        jp      nz,.dpx_exit
        cp      #SCRWIDTH_HI
        jp      nc,.dpx_exit

        ;; y must be in [0,height-1], height comes from __gdata.
        ld      a,P_Y_HI(ix)
        bit     7,a
        jp      nz,.dpx_exit
        ld      l,P_Y_LO(ix)
        ld      h,P_Y_HI(ix)           ;; HL = y
        ld      de,(__gdata+2)          ;; DE = height
        or      a
        sbc     hl,de                  ;; y - height
        jp      nc,.dpx_exit           ;; reject when y >= height

        ;; Clip check when clip != NULL.
        ld      e,8(ix)
        ld      d,9(ix)
        ld      a,e
        or      d
        jr      z,.dpx_draw

        push    de
        pop     iy                     ;; IY = clip

        ;; reject if (x < clip->x0)
        ld      l,P_X_LO(ix)
        ld      h,P_X_HI(ix)
        ld      e,0(iy)
        ld      d,1(iy)
        call    .dpx_cmp16s_lt
        or      a
        jp      nz,.dpx_exit

        ;; reject if (x > clip->x1) => (clip->x1 < x)
        ld      l,4(iy)
        ld      h,5(iy)
        ld      e,P_X_LO(ix)
        ld      d,P_X_HI(ix)
        call    .dpx_cmp16s_lt
        or      a
        jp      nz,.dpx_exit

        ;; reject if (y < clip->y0)
        ld      l,P_Y_LO(ix)
        ld      h,P_Y_HI(ix)
        ld      e,2(iy)
        ld      d,3(iy)
        call    .dpx_cmp16s_lt
        or      a
        jp      nz,.dpx_exit

        ;; reject if (y > clip->y1) => (clip->y1 < y)
        ld      l,6(iy)
        ld      h,7(iy)
        ld      e,P_Y_LO(ix)
        ld      d,P_Y_HI(ix)
        call    .dpx_cmp16s_lt
        or      a
        jp      nz,.dpx_exit

.dpx_draw:
        ;; Apply mode/color and emit one hardware plot command.
        ld      a,7(ix)                ;; bmode
        call    __ef9367_set_blit_mode
        ld      a,6(ix)                ;; color
        call    __ef9367_set_color
        ld      l,P_X_LO(ix)
        ld      h,P_X_HI(ix)
        ld      e,P_Y_LO(ix)
        ld      d,P_Y_HI(ix)
        call    __ef9367_set_xy
        ld      a,#EF9367_CMD_PLOT
        call    __ef9367_exec_cmd

.dpx_exit:
        ld      sp,ix
        pop     ix

        ;; callee cleanup: y(2), c(1), m(1), clip(2) = 6 bytes
        pop     de
        ld      hl,#6
        add     hl,sp
        ld      sp,hl
        push    de
        ret

        ;; ------------------------------------------------------------
        ;; uint8_t dpx_cmp16s_lt(coord a, coord b)
        ;; Input:
        ;;   HL = a
        ;;   DE = b
        ;;
        ;; Output:
        ;;   A = 1 if (a < b), else 0
        ;;
        ;; Clobbers:
        ;;   AF, HL
.dpx_cmp16s_lt:
        ;; If signs differ, the negative value is smaller.
        ld      a,h
        xor     d
        jp      m,.dpx_cmp_sign_diff

        ;; Same sign: signed compare via subtraction.
        or      a
        sbc     hl,de
        jr      c,.dpx_cmp_true
        xor     a
        ret

.dpx_cmp_sign_diff:
        bit     7,h
        jr      nz,.dpx_cmp_true
        xor     a
        ret

.dpx_cmp_true:
        ld      a,#1
        ret
