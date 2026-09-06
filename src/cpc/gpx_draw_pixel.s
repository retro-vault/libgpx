        ;; gpx_draw_pixel.s
        ;;
        ;; Amstrad CPC pixel primitive.
        ;;
        ;; The drawing logic lives in a register-fed internal core
        ;; (__gpx_plot_raw) with no IX frame, so hot callers (Bresenham) can
        ;; plot a pixel without per-pixel frame setup/teardown. The public
        ;; gpx_draw_pixel is a thin wrapper that marshals its stack args into
        ;; the core's register interface.
        ;;
        ;; x reaches 639 here, so clipping retains its full 16-bit edges.
        ;; Screen bounds establish nonnegative points; signed clip checks
        ;; then reduce to sign tests and unsigned subtractions in registers.
        ;;
        ;; GPL2 License (see: LICENSE)
        ;; Copyright (C) 2026 Tomaz Stih
        ;;
        ;; 2026-08-26   TS

        .module gpx_draw_pixel
        .optsdcc -mz80 sdcccall(1)

        .include "_cpc-defs.inc"

        .globl  _gpx_draw_pixel
        .globl  __gpx_plot_raw
        .globl  __vid_rowaddr
        .globl  __gpx_xbyte
        .globl  __cpc_mode1
        .globl  __cpc_pixmask
        .globl  __cpc_width
        .globl  __gpx_maskmap

        .area   _CODE

        ;; ------------------------------------------------------------
        ;; void gpx_draw_pixel(
        ;;   gpx_t *gpx,        HL (ignored)
        ;;   coord x,           DE
        ;;   coord y,           stack
        ;;   color c,           stack (1 byte)
        ;;   bmode m,           stack (1 byte)
        ;;   const rect_t *clip stack (2 bytes)
        ;;
        ;; Callee cleans 6 bytes: args are popped straight into the
        ;; __gpx_plot_raw register interface (no IX frame, no epilogue).
        ;; Return address is parked in BC' while the stack is drained,
        ;; then pushed back so plot_raw's ret goes to the caller.
        ;;
        ;; Clobbers:
        ;;   AF, BC, DE, HL, and the alternate set
        ;;
        ;; References:
        ;;   __gpx_plot_raw
        ;; ------------------------------------------------------------
_gpx_draw_pixel::
        exx
        pop     bc                      ; BC' = return address
        exx
        pop     hl                      ; HL = y
        pop     af                      ; A = m, F = c (carry = color bit0)
        rla                             ; A = (m<<1) | color
        and     #0x03                   ; packed flags
        pop     bc                      ; BC = clip
        exx
        push    bc                      ; return address back on stack
        exx
        ;; fall through into __gpx_plot_raw (its ret returns to caller)

        ;; ------------------------------------------------------------
        ;; __gpx_plot_raw  (internal, register interface, no IX frame)
        ;;   DE = x (signed 16-bit)
        ;;   HL = y (signed 16-bit)
        ;;   BC = clip rect pointer (0 => no clip)
        ;;   A  = packed flags: bit0 = color (CO_FORE), bit1 = mode (BM_XOR)
        ;; Clobbers A, BC, DE, HL (and F). Preserves IX/IY.
        ;; ------------------------------------------------------------
__gpx_plot_raw:
        push    af                      ; preserve packed color/mode

        ;; y in [0, CPC_HEIGHT-1] ?
        ld      a,h
        or      a
        jp      nz,.pr_reject
        ld      a,l
        cp      #CPC_HEIGHT
        jp      nc,.pr_reject

        ;; x in [0, width-1] ?  One unsigned 16-bit compare does both ends:
        ;; a negative x is a huge unsigned value and fails the same test.
        ld      a,(__cpc_width)
        dec     a                       ; both widths have a nonzero low byte
        sub     e
        ld      a,(__cpc_width+1)
        sbc     a,d                     ; carry when width - 1 < x
        jp      c,.pr_reject
.pr_x_ok:

        ;; IX walks the clip while the point stays in DE/HL. Preserve it
        ;; for register-fed shape and line callers.
        ld      a,b
        or      c
        jr      z,.pr_plot
        push    ix
        push    bc
        pop     ix

        ;; A negative lower edge passes; all other x edges need 16 bits.
        bit     7,1(ix)
        jr      nz,.pr_y0
        ld      a,e
        sub     0(ix)
        ld      a,d
        sbc     a,1(ix)
        jr      c,.pr_clip_out
.pr_y0:
        ;; y is already in 0..199, so its high byte is zero.
        ld      a,3(ix)
        or      a
        jp      m,.pr_x1
        jr      nz,.pr_clip_out
        ld      a,l
        cp      2(ix)
        jr      c,.pr_clip_out
.pr_x1:
        bit     7,5(ix)
        jr      nz,.pr_clip_out
        ld      a,4(ix)
        sub     e
        ld      a,5(ix)
        sbc     a,d
        jr      c,.pr_clip_out

        ld      a,7(ix)
        or      a
        jp      m,.pr_clip_out
        jr      nz,.pr_clip_ok
        ld      a,6(ix)
        cp      l
        jr      c,.pr_clip_out
.pr_clip_ok:
        pop     ix

.pr_plot:
        ;; y fits a byte here, which frees HL for the mask table
        ld      b,l                     ; B = y

        ;; mask = the byte's top pixel walked right by (x & pixmask)
        ld      a,(__cpc_pixmask)
        and     e
        ld      hl,#__gpx_maskmap
        add     a,l
        ld      l,a
        jr      nc,.pr_mask_hi
        inc     h
.pr_mask_hi:
        ld      c,(hl)                  ; C = mask

        ;; byte index within the row, 0..79 in both modes
        ex      de,hl                   ; HL = x
        call    __gpx_xbyte             ; A = x >> CPC_PIX_SHIFT
        ld      d,a                     ; D = byte index

        ;; __vid_rowaddr takes y in B and leaves BC and DE alone
        call    __vid_rowaddr
        ld      a,d
        add     a,l
        ld      l,a
        jr      nc,.pr_ptr_ok
        inc     h
.pr_ptr_ok:
        ld      e,c                     ; E = mask
        pop     af                      ; A = packed color/mode

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

.pr_clip_out:
        pop     ix
.pr_reject:
        pop     af
        ret

