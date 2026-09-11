        ;; gpx_draw_rectangle.s -- legacy all-edge entry.
        ;; GPL2 License (see: LICENSE), Copyright (C) 2026 Tomaz Stih

        .module gpx_draw_rectangle
        .optsdcc -mz80 sdcccall(1)

        .globl  _gpx_draw_rectangle
        .globl  _gpx_draw_box

        .area   _CODE

        ;; ------------------------------------------------------------
        ;; void gpx_draw_rectangle(gpx_t *gpx, rect_t *r, color c,
        ;;     bmode m, uint8_t lpatt, const rect_t *clip)
        ;; Clobbers: AF, BC, DE, HL, IX, IY and the alternate set.
_gpx_draw_rectangle::
        push    ix
        ld      ix,#0
        add     ix,sp
        push    hl
        push    de
        ld      l,7(ix)
        ld      h,8(ix)
        push    hl
        ld      a,6(ix)
        push    af
        inc     sp
        ld      l,4(ix)
        ld      h,5(ix)
        push    hl
        ld      a,#0x0f
        push    af
        inc     sp
        ld      e,-4(ix)
        ld      d,-3(ix)
        ld      l,-2(ix)
        ld      h,-1(ix)
        call    _gpx_draw_box
        ld      sp,ix
        pop     ix
        pop     hl
        pop     bc
        pop     bc
        inc     sp
        jp      (hl)
