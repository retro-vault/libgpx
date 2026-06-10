        ;; gpx_draw_pixel.s
        ;;
        ;; ZX Spectrum pixel primitive.

        .module gpx_draw_pixel
        .optsdcc -mz80 sdcccall(1)

        .globl  _gpx_draw_pixel
        .globl  __vid_rowaddr

        .area   _CODE

        ;; void gpx_draw_pixel(
        ;;   gpx_t *gpx,        HL (ignored)
        ;;   coord x,           DE
        ;;   coord y,           SP+2 (2 bytes)
        ;;   color c,           SP+4 (1 byte)
        ;;   bmode m,           SP+5 (1 byte)
        ;;   const rect_t *clip SP+6 (2 bytes)
        ;;
        ;; Callee cleans 6 bytes from stack.
_gpx_draw_pixel::
        push    ix
        ld      ix,#0
        add     ix,sp

        ;; x must be in [0,255]
        ld      a,d
        or      a
        jp      m,.dpx_exit
        jp      nz,.dpx_exit

        ;; y must be in [0,191]
        ld      a,5(ix)
        or      a
        jp      m,.dpx_exit
        jp      nz,.dpx_exit
        ld      a,4(ix)
        cp      #192
        jp      nc,.dpx_exit

        ;; Keep x low byte for draw stage.
        ld      c,e

        ;; no clip pointer => screen-bounds checks above are enough
        ld      a,8(ix)
        or      9(ix)
        jr      z,.dpx_draw

        ;; clip pointer in HL
        ld      l,8(ix)
        ld      h,9(ix)

        ;; if (x < clip->x0) reject
        ld      e,(hl)                 ;; x0 lo
        inc     hl
        ld      a,(hl)                 ;; x0 hi
        bit     7,a
        jr      nz,.dpx_clip_y0        ;; negative x0 => pass
        or      a
        jp      nz,.dpx_exit           ;; x0 >= 256 => reject
        ld      a,c
        cp      e
        jp      c,.dpx_exit

.dpx_clip_y0:
        ;; if (y < clip->y0) reject
        inc     hl
        ld      e,(hl)                 ;; y0 lo
        inc     hl
        ld      a,(hl)                 ;; y0 hi
        bit     7,a
        jr      nz,.dpx_clip_x1        ;; negative y0 => pass
        or      a
        jp      nz,.dpx_exit           ;; y0 >= 256 => reject
        ld      a,4(ix)
        cp      e
        jp      c,.dpx_exit

.dpx_clip_x1:
        ;; if (x > clip->x1) reject
        inc     hl
        ld      e,(hl)                 ;; x1 lo
        inc     hl
        ld      a,(hl)                 ;; x1 hi
        bit     7,a
        jp      nz,.dpx_exit           ;; negative x1 => reject
        or      a
        jr      nz,.dpx_clip_y1        ;; x1 >= 256 => pass
        ld      a,e
        cp      c                      ;; x1 < x ?
        jp      c,.dpx_exit

.dpx_clip_y1:
        ;; if (y > clip->y1) reject
        inc     hl
        ld      e,(hl)                 ;; y1 lo
        inc     hl
        ld      a,(hl)                 ;; y1 hi
        bit     7,a
        jp      nz,.dpx_exit           ;; negative y1 => reject
        or      a
        jr      nz,.dpx_draw           ;; y1 >= 256 => pass
        ld      a,e
        cp      4(ix)                  ;; y1 < y ?
        jp      c,.dpx_exit

.dpx_draw:
        ld      b,4(ix)                ;; B = y low

        ;; HL = row base for y
        call    __vid_rowaddr

        ;; HL += x>>3
        ld      a,c
        srl     a
        srl     a
        srl     a
        add     a,l
        ld      l,a

        ;; E = mask = 0x80 >> (x & 7)
        ld      a,c
        and     #0x07
        ld      b,a                    ;; shift count
        ld      a,#0x80
        jr      z,.dpx_mask_ready
.dpx_mask_loop:
        srl     a
        djnz    .dpx_mask_loop
.dpx_mask_ready:
        ld      e,a

        ;; mode bit0: XOR when set
        ld      a,7(ix)
        bit     0,a
        jr      nz,.dpx_xor

        ;; BM_CPY: color bit0 decides set/clear
        ld      a,6(ix)
        bit     0,a
        jr      nz,.dpx_set

        ;; clear pixel
        ld      a,e
        cpl
        and     (hl)
        ld      (hl),a
        jp      .dpx_exit

.dpx_set:
        ;; set pixel
        ld      a,e
        or      (hl)
        ld      (hl),a
        jp      .dpx_exit

.dpx_xor:
        ;; xor pixel
        ld      a,e
        xor     (hl)
        ld      (hl),a

.dpx_exit:
        pop     ix

        ;; callee cleanup: 6 bytes (y,c,m,clip)
        pop     de
        ld      hl,#6
        add     hl,sp
        ld      sp,hl
        push    de
        ret
