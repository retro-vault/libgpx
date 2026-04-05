        ;; gpx_bmp.s
        ;;
        ;; Unified ZX bitmap blitter.
        ;;
        ;; All clipping is resolved up front in 16-bit space, then the
        ;; bitmap is drawn with byte-span composition directly into
        ;; display memory. No pixel fallback path remains here.
        ;;
        ;; Re-entrant/thread-safe: all mutable state lives on the stack.

        .module gpx_bmp
        .optsdcc -mz80 sdcccall(1)

        .globl  _gpx_draw_bmp
        .globl  _gpx_draw_bmp_clip
        .globl  __rect_cmp16s_lt

        .equ    SCRHEIGHT, 192
        .equ    BMP_SIG_ENC_MASK, 0xF0
        .equ    BMP_SIG_1BPP, 0x00
        .equ    BMP_SIG_1BPP_MASK, 0x10

        ;; stack-local bitmap workspace (IY-relative)
        .equ    L_X,                0
        .equ    L_XHI,              1
        .equ    L_Y,                2
        .equ    L_YHI,              3
        .equ    L_CLIP,             4
        .equ    L_BPTR,             6
        .equ    L_BW,               8
        .equ    L_BH,               9
        .equ    L_BSTRIDE,          10
        .equ    L_ROWSTRIDE_AND,    12
        .equ    L_ROWSTRIDE_OR,     14
        .equ    L_CLIP_X0,          16
        .equ    L_CLIP_X1,          18
        .equ    L_CLIP_Y0,          20
        .equ    L_CLIP_Y1,          22
        .equ    L_XEND,             24
        .equ    L_YEND,             26
        .equ    L_VISX0,            28
        .equ    L_VISX1,            30
        .equ    L_VISY0,            32
        .equ    L_VISY1,            34
        .equ    L_VISW,             36
        .equ    L_VISH,             37
        .equ    L_SRCX,             38
        .equ    L_SRCY,             39
        .equ    L_XBYTE,            40
        .equ    L_SRCBYTE,          41
        .equ    L_DBIT,             42
        .equ    L_SRCBIT,           43
        .equ    L_RSHIFT,           44
        .equ    L_LMASK,            45
        .equ    L_RMASK,            46
        .equ    L_SRCSPAN,          47
        .equ    L_DSTSPAN,          48
        .equ    L_DSTLAST,          49
        .equ    L_SRCROW,           50
        .equ    L_SRCROW_OR,        52
        .equ    L_SRCPTR,           54
        .equ    L_SRCPTR_OR,        56
        .equ    L_DSTPTR,           58
        .equ    L_ROWCNT,           60
        .equ    L_BYTECNT,          61
        .equ    L_YCUR,             62
        .equ    L_OLD,              63
        .equ    L_KEEP,             64
        .equ    L_INSIDE,           65
        .equ    L_FORE,             66
        .equ    L_ROT,              67
        .equ    L_REMAINDER,        68
        .equ    L_DRAW,             69
        .equ    L_REMAINDER_OR,     70
        .equ    L_ORBITS,           71
        .equ    L_IS_MASKED,        72
        .equ    L_DRAWMODE,         73
        .equ    L_SIZE,             74

        .macro  LD16HL off
        ld      l,off(iy)
        ld      h,off+1(iy)
        .endm

        .macro  ST16HL off
        ld      off(iy),l
        ld      off+1(iy),h
        .endm

        .macro  LD16DE off
        ld      e,off(iy)
        ld      d,off+1(iy)
        .endm

        .macro  ST16DE off
        ld      off(iy),e
        ld      off+1(iy),d
        .endm

        .area   _CODE

        ;; void gpx_draw_bmp(gpx_t *gpx, coord x, coord y, bmp_t *b, const rect_t *clip)
_gpx_draw_bmp::
        ;; Public API semantics:
        ;; - unmasked: draw 1 bits, skip 0 bits
        ;; - masked:   apply AND/OR pair
        ld      b,#0x80               ;; internal mode tag: keep legacy semantics
        ld      c,#0x01               ;; color = CO_FORE
        jr      gb_core

        ;; Internal entry used by text path.
        ;; Input:
        ;;   B = bmode
        ;;   C = color
_gpx_draw_bmp_clip::
gb_core:
        push    ix
        push    iy
        ld      ix,#0
        add     ix,sp
        ld      hl,#-L_SIZE
        add     hl,sp
        ld      sp,hl
        ld      iy,#0
        add     iy,sp

        ;; Precompute compositor behaviour once per call.
        ;; DRAWMODE:
        ;;   0 = legacy public gpx_draw_bmp semantics (skip source zero bits)
        ;;   1 = BM_CPY + CO_FORE (copy source bits)
        ;;   2 = BM_CPY + CO_BACK (copy inverted source bits)
        ;;   3 = BM_XOR
        ld      a,b
        bit     7,a
        jr      z,gb_mode_select
        xor     a
        ld      L_DRAWMODE(iy),a
        jr      gb_mode_done

gb_mode_select:
        ld      a,b
        bit     0,a
        jr      nz,gb_mode_xor_sel
        ld      a,c
        bit     0,a
        jr      nz,gb_mode_fore_sel
        ld      a,#2                   ;; BACK copy on OR bits
        ld      L_DRAWMODE(iy),a
        jr      gb_mode_done

 gb_mode_fore_sel:
        ld      a,#1                   ;; FORE copy on OR bits
        ld      L_DRAWMODE(iy),a
        jr      gb_mode_done

 gb_mode_xor_sel:
        ld      a,#3                   ;; XOR on OR bits
        ld      L_DRAWMODE(iy),a

 gb_mode_done:
        ;; Preserve incoming args.
        ld      L_X(iy),e
        ld      L_XHI(iy),d

        ;; Save clip pointer.
        ld      e,10(ix)
        ld      d,11(ix)
        ST16DE  L_CLIP

        ;; Load full y and bitmap pointer.
        ld      a,6(ix)
        ld      L_Y(iy),a
        ld      a,7(ix)
        ld      L_YHI(iy),a

        ld      e,8(ix)
        ld      d,9(ix)
        ST16DE  L_BPTR

        ;; Null bitmap -> return.
        ld      a,d
        or      e
        jp      z,gb_exit

        ;; Validate encoding + parse compact metadata.
        ex      de,hl                  ;; HL = b
        ld      a,(hl)
        and     #BMP_SIG_ENC_MASK
        cp      #BMP_SIG_1BPP
        jr      z,gb_sig_unmasked
        cp      #BMP_SIG_1BPP_MASK
        jr      z,gb_sig_masked
        jp      gb_exit

 gb_sig_unmasked:
        xor     a
        ld      L_IS_MASKED(iy),a
        jr      gb_sig_parse

 gb_sig_masked:
        ld      a,#1
        ld      L_IS_MASKED(iy),a

 gb_sig_parse:
        ld      a,(hl)
        and     #0x0F
        inc     a
        ld      L_BSTRIDE(iy),a
        xor     a
        ld      L_BSTRIDE+1(iy),a

        inc     hl
        ld      a,(hl)
        ld      L_BW(iy),a
        inc     hl
        ld      a,(hl)
        ld      L_BH(iy),a

        ld      a,L_BW(iy)
        or      a
        jp      z,gb_exit
        ld      a,L_BH(iy)
        or      a
        jp      z,gb_exit

        ;; draw_x1 = x + w - 1
        ld      a,L_BW(iy)
        dec     a
        ld      b,a
        ld      a,L_X(iy)
        add     a,b
        ld      L_XEND(iy),a
        ld      a,L_XHI(iy)
        adc     a,#0
        ld      L_XEND+1(iy),a

        ;; draw_y1 = y + h - 1
        ld      a,L_BH(iy)
        dec     a
        ld      b,a
        ld      a,L_Y(iy)
        add     a,b
        ld      L_YEND(iy),a
        ld      a,L_YHI(iy)
        adc     a,#0
        ld      L_YEND+1(iy),a

        ;; Effective clip = screen rect.
        xor     a
        ld      l,a
        ld      h,a
        ST16HL  L_CLIP_X0
        ST16HL  L_CLIP_Y0

        ld      l,#255
        ld      h,#0
        ST16HL  L_CLIP_X1
        ld      l,#(SCRHEIGHT-1)
        ld      h,#0
        ST16HL  L_CLIP_Y1

        ;; Intersect with optional clip rectangle when present.
        ld      a,L_CLIP(iy)
        ld      b,a
        ld      a,L_CLIP+1(iy)
        or      b
        jr      z,gb_clip_ready

        LD16HL  L_CLIP

        ;; max(screen_x0, clip->x0)
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        inc     hl
        push    hl
        ld      hl,#0
        call    __rect_cmp16s_lt       ;; 0 < clip_x0 ?
        pop     hl
        or      a
        jr      z,gb_clip_y0_load
        ST16DE  L_CLIP_X0

 gb_clip_y0_load:
        ;; max(screen_y0, clip->y0)
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        inc     hl
        push    hl
        ld      hl,#0
        call    __rect_cmp16s_lt       ;; 0 < clip_y0 ?
        pop     hl
        or      a
        jr      z,gb_clip_x1_load
        ST16DE  L_CLIP_Y0

 gb_clip_x1_load:
        ;; min(screen_x1, clip->x1)
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        inc     hl
        ld      c,e
        ld      b,d
        push    hl
        ld      l,c
        ld      h,b
        ld      de,#255
        call    __rect_cmp16s_lt       ;; clip_x1 < 255 ?
        pop     hl
        or      a
        jr      z,gb_clip_y1_load
        ld      a,c
        ld      L_CLIP_X1(iy),a
        ld      a,b
        ld      L_CLIP_X1+1(iy),a

 gb_clip_y1_load:
        ;; min(screen_y1, clip->y1)
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ld      c,e
        ld      b,d
        ld      l,c
        ld      h,b
        ld      de,#(SCRHEIGHT-1)
        call    __rect_cmp16s_lt       ;; clip_y1 < 191 ?
        or      a
        jr      z,gb_clip_ready
        ld      l,c
        ld      h,b
        ST16HL  L_CLIP_Y1

 gb_clip_ready:
        ;; Empty effective clip -> nothing visible.
        LD16HL  L_CLIP_X1
        LD16DE  L_CLIP_X0
        call    __rect_cmp16s_lt
        or      a
        jp      nz,gb_exit

        LD16HL  L_CLIP_Y1
        LD16DE  L_CLIP_Y0
        call    __rect_cmp16s_lt
        or      a
        jp      nz,gb_exit

        ;; Reject if draw rect does not intersect clip rect.
        LD16HL  L_XEND
        LD16DE  L_CLIP_X0
        call    __rect_cmp16s_lt       ;; draw_x1 < clip_x0 ?
        or      a
        jp      nz,gb_exit

        LD16HL  L_CLIP_X1
        LD16DE  L_X
        call    __rect_cmp16s_lt       ;; clip_x1 < draw_x0 ?
        or      a
        jp      nz,gb_exit

        LD16HL  L_YEND
        LD16DE  L_CLIP_Y0
        call    __rect_cmp16s_lt       ;; draw_y1 < clip_y0 ?
        or      a
        jp      nz,gb_exit

        LD16HL  L_CLIP_Y1
        LD16DE  L_Y
        call    __rect_cmp16s_lt       ;; clip_y1 < draw_y0 ?
        or      a
        jp      nz,gb_exit

        ;; visx0 = max(draw_x0, clip_x0)
        LD16HL  L_X
        ST16HL  L_VISX0
        LD16DE  L_CLIP_X0
        call    __rect_cmp16s_lt       ;; draw_x0 < clip_x0 ?
        or      a
        jr      z,gb_visy0_prep
        LD16HL  L_CLIP_X0
        ST16HL  L_VISX0

 gb_visy0_prep:
        ;; visy0 = max(draw_y0, clip_y0)
        LD16HL  L_Y
        ST16HL  L_VISY0
        LD16DE  L_CLIP_Y0
        call    __rect_cmp16s_lt       ;; draw_y0 < clip_y0 ?
        or      a
        jr      z,gb_visx1_prep
        LD16HL  L_CLIP_Y0
        ST16HL  L_VISY0

 gb_visx1_prep:
        ;; visx1 = min(draw_x1, clip_x1)
        LD16HL  L_XEND
        ST16HL  L_VISX1
        LD16DE  L_XEND
        LD16HL  L_CLIP_X1
        call    __rect_cmp16s_lt       ;; clip_x1 < draw_x1 ?
        or      a
        jr      z,gb_visy1_prep
        LD16HL  L_CLIP_X1
        ST16HL  L_VISX1

 gb_visy1_prep:
        ;; visy1 = min(draw_y1, clip_y1)
        LD16HL  L_YEND
        ST16HL  L_VISY1
        LD16DE  L_YEND
        LD16HL  L_CLIP_Y1
        call    __rect_cmp16s_lt       ;; clip_y1 < draw_y1 ?
        or      a
        jr      z,gb_skips
        LD16HL  L_CLIP_Y1
        ST16HL  L_VISY1

 gb_skips:
        ;; Source skip is the clipped-away left/top part.
        ld      a,L_VISX0(iy)
        ld      b,a
        ld      a,L_X(iy)
        cpl
        inc     a
        add     a,b
        ld      L_SRCX(iy),a

        ld      a,L_VISY0(iy)
        ld      b,a
        ld      a,L_Y(iy)
        cpl
        inc     a
        add     a,b
        ld      L_SRCY(iy),a

        ;; visw = visx1 - visx0 + 1
        ld      a,L_VISX1(iy)
        ld      b,a
        ld      a,L_VISX0(iy)
        cpl
        inc     a
        add     a,b
        inc     a
        ld      L_VISW(iy),a
        or      a
        jp      z,gb_exit

        ;; vish = visy1 - visy0 + 1
        ld      a,L_VISY1(iy)
        ld      b,a
        ld      a,L_VISY0(iy)
        cpl
        inc     a
        add     a,b
        inc     a
        ld      L_VISH(iy),a
        or      a
        jp      z,gb_exit

        ;; Destination x byte / bit.
        ld      a,L_VISX0(iy)
        ld      b,a
        and     #0x07
        ld      L_DBIT(iy),a
        ld      a,b
        srl     a
        srl     a
        srl     a
        ld      L_XBYTE(iy),a

        ;; Source x byte / bit.
        ld      a,L_SRCX(iy)
        ld      b,a
        and     #0x07
        ld      L_SRCBIT(iy),a
        ld      a,b
        srl     a
        srl     a
        srl     a
        ld      L_SRCBYTE(iy),a

        ;; rshift = (dbit - srcbit) & 7
        ld      a,L_DBIT(iy)
        ld      b,a
        ld      a,L_SRCBIT(iy)
        ld      c,a
        ld      a,b
        sub     c
        and     #0x07
        ld      L_RSHIFT(iy),a

        ;; lmask = ~(0xff >> dbit)
        ld      a,L_DBIT(iy)
        or      a
        jr      z,gb_lmask_zero
        ld      b,a
        ld      a,#0xff
 gb_lmask_loop:
        srl     a
        djnz    gb_lmask_loop
        cpl
        ld      L_LMASK(iy),a
        jr      gb_lmask_done

 gb_lmask_zero:
        xor     a
        ld      L_LMASK(iy),a

 gb_lmask_done:
        ;; rmask = 0xff >> ((dbit + visw) & 7), with 0 -> 0
        ld      a,L_DBIT(iy)
        ld      b,a
        ld      a,L_VISW(iy)
        add     a,b
        and     #0x07
        jr      z,gb_rmask_zero
        ld      b,a
        ld      a,#0xff
 gb_rmask_loop:
        srl     a
        djnz    gb_rmask_loop
        ld      L_RMASK(iy),a
        jr      gb_rmask_done

 gb_rmask_zero:
        xor     a
        ld      L_RMASK(iy),a

 gb_rmask_done:
        ;; srcspan = (srcbit + visw + 7) >> 3
        xor     a
        ld      h,a
        ld      a,L_SRCBIT(iy)
        ld      l,a
        ld      a,L_VISW(iy)
        add     a,l
        ld      l,a
        jr      nc,gb_srcspan_add7
        inc     h

 gb_srcspan_add7:
        ld      a,l
        add     a,#7
        ld      l,a
        jr      nc,gb_srcspan_div
        inc     h

 gb_srcspan_div:
        srl     h
        rr      l
        srl     h
        rr      l
        srl     h
        rr      l
        ld      a,l
        ld      L_SRCSPAN(iy),a

        ;; dstspan = (dbit + visw + 7) >> 3
        xor     a
        ld      h,a
        ld      a,L_DBIT(iy)
        ld      l,a
        ld      a,L_VISW(iy)
        add     a,l
        ld      l,a
        jr      nc,gb_dstspan_add7
        inc     h

 gb_dstspan_add7:
        ld      a,l
        add     a,#7
        ld      l,a
        jr      nc,gb_dstspan_div
        inc     h

 gb_dstspan_div:
        srl     h
        rr      l
        srl     h
        rr      l
        srl     h
        rr      l
        ld      a,l
        ld      L_DSTSPAN(iy),a
        dec     a
        ld      L_DSTLAST(iy),a

        ;; Source row pointers + independent row strides.
        LD16HL  L_BPTR
        ld      de,#5
        add     hl,de

        ld      a,L_IS_MASKED(iy)
        or      a
        jr      z,gb_rows_unmasked

        ;; masked rows
        ST16HL  L_SRCROW

        LD16DE  L_BSTRIDE
        add     hl,de
        ST16HL  L_SRCROW_OR

        LD16HL  L_BSTRIDE
        add     hl,hl
        ST16HL  L_ROWSTRIDE_AND
        ST16HL  L_ROWSTRIDE_OR
        jr      gb_rows_skip_y

 gb_rows_unmasked:
        ST16HL  L_SRCROW_OR
        ld      hl,#gb_ff_pad
        ST16HL  L_SRCROW
        xor     a
        ld      l,a
        ld      h,a
        ST16HL  L_ROWSTRIDE_AND
        LD16HL  L_BSTRIDE
        ST16HL  L_ROWSTRIDE_OR

 gb_rows_skip_y:
        ld      a,L_SRCY(iy)
        or      a
        jr      z,gb_rows_skip_x

 gb_rows_skip_loop:
        LD16HL  L_SRCROW
        LD16DE  L_ROWSTRIDE_AND
        add     hl,de
        ST16HL  L_SRCROW

        LD16HL  L_SRCROW_OR
        LD16DE  L_ROWSTRIDE_OR
        add     hl,de
        ST16HL  L_SRCROW_OR

        ld      a,L_SRCY(iy)
        dec     a
        ld      L_SRCY(iy),a
        jr      nz,gb_rows_skip_loop

 gb_rows_skip_x:
        ld      a,L_SRCBYTE(iy)
        or      a
        jr      z,gb_rows_ready

        ld      e,a
        ld      d,#0

        LD16HL  L_SRCROW_OR
        add     hl,de
        ST16HL  L_SRCROW_OR

        ld      a,L_IS_MASKED(iy)
        or      a
        jr      z,gb_rows_ready

        LD16HL  L_SRCROW
        add     hl,de
        ST16HL  L_SRCROW

 gb_rows_ready:
        xor     a
        ld      L_ROWCNT(iy),a
        ld      a,L_VISY0(iy)
        ld      L_YCUR(iy),a

 gb_row_loop:
        ;; done when rowcnt == vish
        ld      a,L_ROWCNT(iy)
        ld      b,a
        ld      a,L_VISH(iy)
        cp      b
        jp      z,gb_exit

        ;; row destination base + xbyte
        ld      a,L_YCUR(iy)
        ld      b,a
        call    gb_rowaddr
        ld      a,L_XBYTE(iy)
        add     a,l
        ld      l,a
        ST16HL  L_DSTPTR

        LD16HL  L_SRCROW
        ST16HL  L_SRCPTR
        LD16HL  L_SRCROW_OR
        ST16HL  L_SRCPTR_OR

        xor     a
        ld      L_REMAINDER(iy),a
        ld      L_REMAINDER_OR(iy),a
        ld      L_BYTECNT(iy),a

 gb_col_loop_compose:
        ld      a,L_BYTECNT(iy)
        ld      c,a
        ld      a,L_DSTSPAN(iy)
        cp      c
        jp      z,gb_next_row

        ;; old destination byte
        LD16HL  L_DSTPTR
        ld      a,(hl)
        ld      L_OLD(iy),a

        ;; keep mask for outside bits (left/right edges)
        xor     a
        ld      L_KEEP(iy),a

        ld      a,c
        or      a
        jr      nz,gb_not_first
        ld      a,L_LMASK(iy)
        ld      L_KEEP(iy),a

 gb_not_first:
        ld      a,L_DSTLAST(iy)
        cp      c
        jr      nz,gb_keep_ready
        ld      a,L_KEEP(iy)
        ld      b,a
        ld      a,L_RMASK(iy)
        or      b
        ld      L_KEEP(iy),a

 gb_keep_ready:
        ld      a,L_KEEP(iy)
        cpl
        ld      L_INSIDE(iy),a

        ;; read source bytes if bytecnt < srcspan
        ld      a,L_SRCSPAN(iy)
        cp      c
        jr      z,gb_no_src
        jr      c,gb_no_src

        ;; AND source byte (mask plane or synthetic 0xFF row)
        LD16HL  L_SRCPTR
        ld      a,(hl)
        inc     hl
        ST16HL  L_SRCPTR
        ld      L_ROT(iy),a

        ld      a,L_RSHIFT(iy)
        or      a
        jr      z,gb_and_rot_done
        ld      b,a
        ld      a,L_ROT(iy)
 gb_and_rot_loop:
        rrca
        djnz    gb_and_rot_loop
        ld      L_ROT(iy),a

 gb_and_rot_done:
        ld      a,L_LMASK(iy)
        cpl
        ld      b,a
        ld      a,L_ROT(iy)
        and     b
        ld      b,a
        ld      a,L_REMAINDER(iy)
        or      b
        ld      L_FORE(iy),a

        ;; next AND remainder = rot & lmask
        ld      a,L_ROT(iy)
        ld      b,a
        ld      a,L_LMASK(iy)
        and     b
        ld      L_REMAINDER(iy),a

        ;; OR source byte
        LD16HL  L_SRCPTR_OR
        ld      a,(hl)
        inc     hl
        ST16HL  L_SRCPTR_OR
        ld      L_ROT(iy),a

        ld      a,L_RSHIFT(iy)
        or      a
        jr      z,gb_or_rot_done
        ld      b,a
        ld      a,L_ROT(iy)
 gb_or_rot_loop:
        rrca
        djnz    gb_or_rot_loop
        ld      L_ROT(iy),a

 gb_or_rot_done:
        ld      a,L_LMASK(iy)
        cpl
        ld      b,a
        ld      a,L_ROT(iy)
        and     b
        ld      b,a
        ld      a,L_REMAINDER_OR(iy)
        or      b
        ld      L_ORBITS(iy),a

        ;; next OR remainder = rot & lmask
        ld      a,L_ROT(iy)
        ld      b,a
        ld      a,L_LMASK(iy)
        and     b
        ld      L_REMAINDER_OR(iy),a
        jr      gb_have_src

 gb_no_src:
        ;; flush pending carry bits from both planes
        ld      a,L_REMAINDER(iy)
        ld      L_FORE(iy),a
        xor     a
        ld      L_REMAINDER(iy),a

        ld      a,L_REMAINDER_OR(iy)
        ld      L_ORBITS(iy),a
        xor     a
        ld      L_REMAINDER_OR(iy),a

 gb_have_src:
        ld      a,L_DRAWMODE(iy)
        or      a
        jr      nz,gb_mode_compose

        ;; Default public semantics.
        ld      a,L_FORE(iy)
        ld      b,a
        ld      a,L_INSIDE(iy)
        and     b
        ld      L_FORE(iy),a

        ld      a,L_OLD(iy)
        ld      b,a
        ld      a,L_FORE(iy)
        and     b
        ld      L_DRAW(iy),a

        ld      a,L_ORBITS(iy)
        ld      b,a
        ld      a,L_INSIDE(iy)
        and     b
        ld      b,a

        ld      a,L_DRAW(iy)
        or      b
        ld      L_DRAW(iy),a
        jr      gb_store_out

 gb_mode_compose:
        ;; Mode-aware semantics operate on source bits (OR plane) only.
        ld      a,L_ORBITS(iy)
        ld      b,a
        ld      a,L_INSIDE(iy)
        and     b
        ld      L_ORBITS(iy),a

        ld      a,L_DRAWMODE(iy)
        cp      #3
        jr      z,gb_mode_xor
        cp      #2
        jr      z,gb_mode_back

        ;; FORE copy: write source bits directly.
        ld      a,L_ORBITS(iy)
        ld      L_DRAW(iy),a
        jr      gb_store_out

 gb_mode_back:
        ;; BACK copy: write inverted source bits directly.
        ld      a,L_ORBITS(iy)
        cpl
        ld      L_DRAW(iy),a
        jr      gb_store_out

 gb_mode_xor:
        ;; XOR: flip OR bits only.
        ld      a,L_OLD(iy)
        ld      b,a
        ld      a,L_ORBITS(iy)
        xor     b
        ld      L_DRAW(iy),a

 gb_store_out:
        ;; out = (old & keep) | (draw & inside)
        ld      a,L_DRAW(iy)
        ld      b,a
        ld      a,L_INSIDE(iy)
        and     b
        ld      b,a

        ld      a,L_OLD(iy)
        ld      c,a
        ld      a,L_KEEP(iy)
        and     c
        or      b
        LD16HL  L_DSTPTR
        ld      (hl),a

        ;; advance destination pointer + counter
        LD16HL  L_DSTPTR
        inc     hl
        ST16HL  L_DSTPTR

        ld      a,L_BYTECNT(iy)
        inc     a
        ld      L_BYTECNT(iy),a
        jp      gb_col_loop_compose

 gb_next_row:
        ;; advance source rows
        LD16HL  L_SRCROW
        LD16DE  L_ROWSTRIDE_AND
        add     hl,de
        ST16HL  L_SRCROW

        LD16HL  L_SRCROW_OR
        LD16DE  L_ROWSTRIDE_OR
        add     hl,de
        ST16HL  L_SRCROW_OR

        ;; ycur++, rowcnt++
        ld      a,L_YCUR(iy)
        inc     a
        ld      L_YCUR(iy),a

        ld      a,L_ROWCNT(iy)
        inc     a
        ld      L_ROWCNT(iy),a
        jp      gb_row_loop

 gb_exit:
        ;; callee cleanup: y(2), b(2), clip(2)
        ld      sp,ix
        pop     iy
        pop     ix
        pop     de
        ld      hl,#6
        add     hl,sp
        ld      sp,hl
        push    de
        ret

        ;; Given y in b (0..191), return row address in hl.
 gb_rowaddr:
        ld      a,b
        and     #0x07
        or      #0x40
        ld      h,a
        ld      a,b
        rrca
        rrca
        rrca
        and     #0x18
        or      h
        ld      h,a
        ld      a,b
        rla
        rla
        and     #0xe0
        ld      l,a
        ret

 gb_ff_pad:
        .db     0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff
        .db     0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff
        .db     0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff
        .db     0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff
