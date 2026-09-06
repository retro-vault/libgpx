        ;; gpx_draw_pixel.s
        ;;
        ;; Partner pixel primitive with optional clipping.
        ;; The public wrapper and shared shapes use the same register core.
        ;;
        ;; GPL2 License (see: LICENSE)
        ;; Copyright (C) 2026 Tomaz Stih
        ;;
        ;; 2026-03-30   TS

        .module gpx_draw_pixel
        .optsdcc -mz80 sdcccall(1)

        .globl  _gpx_draw_pixel
        .globl  __gpx_plot_raw
        .globl  __gdata
        .globl  __ef9367_set_blit_mode
        .globl  __ef9367_set_color
        .globl  __ef9367_set_xy
        .globl  __ef9367_exec_cmd

        .include "_ef9367-defs.inc"

        .equ    EF9367_CMD_PLOT,       0x80

        .area   _CODE

        ;; ------------------------------------------------------------
        ;; void gpx_draw_pixel(gpx_t *gpx, coord x, coord y,
        ;;                     color c, bmode m, const rect_t *clip)
        ;; HL = gpx (ignored), DE = x
        ;; stack: y(2), c(1), m(1), clip(2); callee cleans all six bytes.
        ;; Clobbers:
        ;;   AF, BC, DE, HL and the alternate set; preserves IX/IY.
_gpx_draw_pixel::
        exx
        pop     bc                      ; return address in alternate BC
        exx
        pop     hl                      ; y
        pop     af                      ; A = mode, carry = color bit 0
        rla
        and     #0x03                   ; packed color/mode
        pop     bc                      ; clip
        exx
        push    bc
        exx
        ;; fall through: the core returns straight to the public caller

        ;; ------------------------------------------------------------
        ;; __gpx_plot_raw (same interface on all three backends)
        ;; DE = x, HL = y (signed 16-bit), BC = clip (0 => screen only)
        ;; A: bit 0 = color (CO_FORE), bit 1 = mode (BM_XOR)
        ;; Clobbers:
        ;;   AF, BC, DE, HL; preserves IX/IY and alternate registers.
__gpx_plot_raw::
        push    af

        ;; Unsigned upper bounds also reject all negative coordinates.
        ld      a,d
        cp      #4                      ; x < 1024
        jr      nc,.pr_reject
        ld      a,(__gdata+3)
        dec     a                       ; heights 256/512 have low byte 0
        cp      h
        jr      c,.pr_reject

        ld      a,b
        or      c
        jr      z,.pr_plot
        push    ix
        push    bc
        pop     ix                      ; clip, keeping x/y in DE/HL

        ;; Screen coordinates are nonnegative: a negative lower edge
        ;; passes immediately, a negative upper edge rejects immediately.
        bit     7,1(ix)
        jr      nz,.pr_y0
        ld      a,e
        sub     0(ix)
        ld      a,d
        sbc     a,1(ix)
        jr      c,.pr_clip_out
.pr_y0:
        bit     7,3(ix)
        jr      nz,.pr_x1
        ld      a,l
        sub     2(ix)
        ld      a,h
        sbc     a,3(ix)
        jr      c,.pr_clip_out
.pr_x1:
        bit     7,5(ix)
        jr      nz,.pr_clip_out
        ld      a,4(ix)
        sub     e
        ld      a,5(ix)
        sbc     a,d
        jr      c,.pr_clip_out
        bit     7,7(ix)
        jr      nz,.pr_clip_out
        ld      a,6(ix)
        sub     l
        ld      a,7(ix)
        sbc     a,h
        jr      c,.pr_clip_out
        pop     ix

.pr_plot:
        pop     af
        push    af
        rrca
        and     #1
        call    __ef9367_set_blit_mode
        pop     af
        and     #1
        call    __ef9367_set_color
        ex      de,hl                   ; hardware helper takes x in HL
        call    __ef9367_set_xy
        ld      a,#EF9367_CMD_PLOT
        jp      __ef9367_exec_cmd

.pr_clip_out:
        pop     ix
.pr_reject:
        pop     af
        ret
