        ;; _gpx_draw_bmp_mode_internal.s
        ;;
        ;; Thin adapter for mode/color bitmap draws.
        ;;
        ;; Keeps the public gpx_draw_bmp() API unchanged while routing
        ;; non-default color/mode draws through the shared bitmap clip core.

        .module _gpx_draw_bmp_mode_internal
        .optsdcc -mz80 sdcccall(1)

        .globl  _gpx_draw_bmp_mode_internal
        .globl  _gpx_draw_bmp
        .globl  _gpx_draw_bmp_clip
        .globl  __gpx_bmp_color
        .globl  __gpx_bmp_mode

        .area   _CODE

        ;; void gpx_draw_bmp_mode_internal(
        ;;   gpx_t *gpx,            HL
        ;;   coord x,               DE
        ;;   coord y,               SP+2
        ;;   bmp_t *b,              SP+4
        ;;   color c,               SP+6
        ;;   bmode m,               SP+7
        ;;   const rect_t *clip)    SP+8
_gpx_draw_bmp_mode_internal::
        push    ix
        ld      ix,#0
        add     ix,sp

        ;; Preserve gpx in BC. X remains in DE.
        ld      b,h
        ld      c,l

        ;; Publish draw mode for shared bitmap renderer.
        ld      a,8(ix)               ;; color
        ld      (__gpx_bmp_color),a
        ld      a,9(ix)               ;; bmode
        ld      (__gpx_bmp_mode),a

        ;; Build stack args expected by _gpx_draw_bmp/_gpx_draw_bmp_clip:
        ;; y, bmp, clip
        ld      l,10(ix)
        ld      h,11(ix)
        push    hl                    ;; clip

        ld      l,6(ix)
        ld      h,7(ix)
        push    hl                    ;; bmp

        ld      l,4(ix)
        ld      h,5(ix)
        push    hl                    ;; y

        ;; Restore gpx register arg.
        ld      h,b
        ld      l,c

        ;; Default mode/color can use the fast _gpx_draw_bmp path.
        ld      a,(__gpx_bmp_mode)
        or      a
        jr      nz,.gbmi_call_clip
        ld      a,(__gpx_bmp_color)
        cp      #0x01
        jr      nz,.gbmi_call_clip
        call    _gpx_draw_bmp
        jr      .gbmi_done_call

.gbmi_call_clip:
        call    _gpx_draw_bmp_clip

.gbmi_done_call:
        ld      sp,ix
        pop     ix

        ;; callee cleanup: y(2), b(2), c(1), m(1), clip(2)
        pop     de
        ld      hl,#8
        add     hl,sp
        ld      sp,hl
        push    de
        ret
