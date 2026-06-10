        ;; gpx_draw_pixel.s
        ;;
        ;; ZX Spectrum pixel primitive.
        ;;
        ;; The drawing logic lives in a register-fed internal core
        ;; (__gpx_plot_raw) with no IX frame, so hot callers (Bresenham) can
        ;; plot a pixel without per-pixel frame setup/teardown. The public
        ;; gpx_draw_pixel is a thin wrapper that marshals its stack args into
        ;; the core's register interface. Clip/bounds/plot behavior is byte
        ;; identical to the previous implementation (the oracle clips per pixel,
        ;; so this stays on the same path).

        .module gpx_draw_pixel
        .optsdcc -mz80 sdcccall(1)

        .globl  _gpx_draw_pixel
        .globl  __gpx_plot_raw
        .globl  __vid_rowaddr

        .area   _CODE

        ;; ------------------------------------------------------------
        ;; __gpx_plot_raw  (internal, register interface, no IX frame)
        ;;   DE = x (signed 16-bit)
        ;;   HL = y (signed 16-bit)
        ;;   BC = clip rect pointer (0 => no clip)
        ;;   A  = packed flags: bit0 = color (CO_FORE), bit1 = mode (BM_XOR)
        ;; Clobbers A, BC, DE, HL (and F). Preserves IX/IY.
        ;; ------------------------------------------------------------
__gpx_plot_raw:
        push    af                     ;; preserve packed color/mode (survives rowaddr)

        ;; x in [0,255]?  (hi byte must be 0)
        ld      a,d
        or      a
        jp      nz,.pr_reject
        ;; y in [0,191]?
        ld      a,h
        or      a
        jp      nz,.pr_reject
        ld      a,l
        cp      #192
        jp      nc,.pr_reject

        ;; optional clip (BC = rect ptr)
        ld      a,b
        or      c
        jr      z,.pr_plot_nl          ;; no clip: y lo in L, x lo in E

        ;; stash y lo in D (free, hi was 0), walk clip via HL
        ld      d,l                    ;; D = y
        ld      h,b
        ld      l,c                    ;; HL = clip ptr

        ;; if (x < clip->x0) reject
        ld      a,(hl)                 ;; x0 lo
        inc     hl
        ld      b,(hl)                 ;; x0 hi
        inc     hl                     ;; HL -> &y0
        bit     7,b
        jr      nz,.pr_cy0             ;; x0 < 0 => pass
        ld      c,a                    ;; save x0 lo
        ld      a,b
        or      a
        jp      nz,.pr_reject          ;; x0 >= 256 => x < x0 => reject
        ld      a,e                    ;; x
        cp      c
        jp      c,.pr_reject           ;; x < x0

.pr_cy0:
        ;; if (y < clip->y0) reject
        ld      a,(hl)                 ;; y0 lo
        inc     hl
        ld      b,(hl)                 ;; y0 hi
        inc     hl                     ;; HL -> &x1
        bit     7,b
        jr      nz,.pr_cx1
        ld      c,a
        ld      a,b
        or      a
        jp      nz,.pr_reject
        ld      a,d                    ;; y
        cp      c
        jp      c,.pr_reject

.pr_cx1:
        ;; if (x > clip->x1) reject  (== clip->x1 < x)
        ld      c,(hl)                 ;; x1 lo
        inc     hl
        ld      b,(hl)                 ;; x1 hi
        inc     hl                     ;; HL -> &y1
        bit     7,b
        jp      nz,.pr_reject          ;; x1 < 0 => reject
        ld      a,b
        or      a
        jr      nz,.pr_cy1             ;; x1 >= 256 => pass
        ld      a,c                    ;; x1 lo
        cp      e                      ;; x1 < x ?
        jp      c,.pr_reject

.pr_cy1:
        ;; if (y > clip->y1) reject
        ld      c,(hl)                 ;; y1 lo
        inc     hl
        ld      b,(hl)                 ;; y1 hi
        bit     7,b
        jp      nz,.pr_reject          ;; y1 < 0 => reject
        ld      a,b
        or      a
        jr      nz,.pr_plot            ;; y1 >= 256 => pass
        ld      a,c                    ;; y1 lo
        cp      d                      ;; y1 < y ?
        jp      c,.pr_reject

.pr_plot:
        ;; y in D, x in E
        ld      b,d
        jr      .pr_plot_common

.pr_plot_nl:
        ;; y in L, x in E
        ld      b,l

.pr_plot_common:
        ;; HL = row base for y (B); __vid_rowaddr preserves DE (x)
        call    __vid_rowaddr
        ld      a,e
        srl     a
        srl     a
        srl     a
        add     a,l
        ld      l,a
        jr      nc,.pr_ptr_ok
        inc     h
.pr_ptr_ok:
        ;; mask = 0x80 >> (x & 7)
        ld      a,e
        and     #0x07
        ld      b,a
        ld      a,#0x80
        jr      z,.pr_mask_ready
.pr_mask_loop:
        srl     a
        djnz    .pr_mask_loop
.pr_mask_ready:
        ld      e,a                    ;; E = mask
        pop     af                     ;; A = packed color/mode

        bit     1,a
        jr      nz,.pr_xor
        bit     0,a
        jr      nz,.pr_set

        ;; clear pixel
        ld      a,e
        cpl
        and     (hl)
        ld      (hl),a
        ret

.pr_set:
        ld      a,e
        or      (hl)
        ld      (hl),a
        ret

.pr_xor:
        ld      a,e
        xor     (hl)
        ld      (hl),a
        ret

.pr_reject:
        pop     af
        ret

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
        ;; ------------------------------------------------------------
_gpx_draw_pixel::
        push    ix
        ld      ix,#0
        add     ix,sp

        ;; packed = (color&1) | ((mode&1) << 1)
        ld      a,7(ix)                ;; mode
        and     #0x01
        add     a,a                    ;; -> bit1
        ld      b,a
        ld      a,6(ix)                ;; color
        and     #0x01
        or      b
        push    af                     ;; packed (DE=x must stay intact)

        ld      l,4(ix)
        ld      h,5(ix)                ;; HL = y
        ld      c,8(ix)
        ld      b,9(ix)                ;; BC = clip
        pop     af                     ;; A = packed
        call    __gpx_plot_raw

        pop     ix
        ;; callee cleanup: 6 bytes (y,c,m,clip)
        pop     de
        ld      hl,#6
        add     hl,sp
        ld      sp,hl
        push    de
        ret
