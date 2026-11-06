        ;; Solid vertical spans avoid general Bresenham setup and clipping.
        ;; Patterned/reversed segments retain the complete public raster.
        ;; GPL2 License (see LICENSE), Copyright (C) 2026 Tomaz Stih.
        .module _gpx_vline
        .optsdcc-mz80 sdcccall(1)
        .globl  __gpx_vline, __gpx_bresenham_line, __rect_cmp16s_lt
        .globl  __clip_seg, __rect_screen, __ret_clean11
        .globl  __vid_rowaddr, __vid_nextrow_carry, __gpx_xbyte
        .globl  __cpc_pixmask
        .area   _CODE
__gpx_vline::
        push    ix
        ld      ix,#0
        add     ix,sp
        push    iy
        ld      a,12(ix)
        cp      #255
        jp      nz,.fallback
        ld      l,8(ix)
        ld      h,9(ix)
        ld      e,4(ix)
        ld      d,5(ix)
        call    __rect_cmp16s_lt
        jp      c,.fallback
        ld      l,6(ix)
        ld      h,7(ix)
        ld      e,l
        ld      d,h
        ld      iy,#__rect_screen
        call    __clip_seg
        jp      c,.reject
        ld      c,13(ix)
        ld      b,14(ix)
        ld      a,b
        or      c
        jr      z,.y
        push    bc
        pop     iy
        call    __clip_seg
        jp      c,.reject
.y:
        ld      l,4(ix)
        ld      h,5(ix)
        ld      e,8(ix)
        ld      d,9(ix)
        ld      iy,#__rect_screen+2
        call    __clip_seg
        jp      c,.reject
        ld      c,13(ix)
        ld      b,14(ix)
        ld      a,b
        or      c
        jr      z,.visible
        ld      iy,#2
        add     iy,bc
        call    __clip_seg
        jp      c,.reject
.visible:
        ld      a,e
        sub     l
        inc     a
        push    af                      ; inclusive row count, <= 200
        ld      b,l
        call    __vid_rowaddr
        push    hl
        ld      l,6(ix)
        ld      h,7(ix)
        call    __gpx_xbyte
        pop     hl
        add     a,l
        ld      l,a
        jr      nc,.address
        inc     h
.address:
        ld      a,(__cpc_pixmask)
        and     6(ix)
        ld      b,a
        ld      a,#128
        jr      z,.mask
.shift:
        rrca
        djnz    .shift
.mask:
        ld      d,a
        ld      e,a
        ld      a,11(ix)
        rrca
        jr      nc,.copy
        ld      d,#0
        jr      .mode
.copy:
        ld      a,10(ix)
        rrca
        jr      nc,.mode
        ld      e,#0
.mode:
        pop     af
        ld      b,a
.loop:
        ld      a,(hl)
        or      d
        xor     e
        ld      (hl),a
        ld      a,h
        add     a,#8
        ld      h,a
        jr      nc,.next
        call    __vid_nextrow_carry
.next:
        djnz    .loop
.reject:
        ld      a,12(ix)
        pop     iy
        pop     ix
        jp      __ret_clean11
.fallback:
        ld      e,6(ix)
        ld      d,7(ix)
        pop     iy
        pop     ix
        jp      __gpx_bresenham_line
