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
        .globl  __gpx_ffshr
        .globl  __rect_cmp16s_lt
        .globl  __vid_rowaddr
        .globl  __vid_nextrow

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
        .equ    L_SRCROW,           50
        .equ    L_SRCROW_OR,        52
        .equ    L_SRCPTR,           54
        .equ    L_SRCPTR_OR,        56
        .equ    L_DSTPTR,           58
        .equ    L_ROWCNT,           60
        .equ    L_YCUR,             62
        .equ    L_INSIDE,           65
        .equ    L_FORE,             66
        .equ    L_ROT,              67
        .equ    L_REMAINDER,        68
        .equ    L_REMAINDER_OR,     70
        .equ    L_IS_MASKED,        72
        .equ    L_DRAWMODE,         73
        ;; 2-byte source window state (replaces the old rotate+remainder carry):
        ;;   SUB      = (8 - rshift) & 7   sub-byte left shift for the window
        ;;   SRCREMAIN= source bytes left to read this row (else default)
        ;;   REMAINDER/REMAINDER_OR are reused as prevA/prevO (previous src byte)
        .equ    L_SUB,              74
        .equ    L_SRCREMAIN,        75
        .equ    L_SIZE,             76

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
        ;; Drain y and bitmap-ptr args into the alternate set and park the
        ;; return address back on the stack; clip stays as the only stack
        ;; arg (read at 6(ix) below, discarded by the exit). DE = x and
        ;; BC = mode tags stay live in the main set throughout.
        exx
        pop     bc                     ;; BC' = return address
        pop     hl                     ;; HL' = y
        pop     de                     ;; DE' = bitmap ptr
        push    bc                     ;; return address back (clip below it)
        exx
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
        ;;   0 = public gpx_draw_bmp semantics, plain source: out = old | src
        ;;   4 = public gpx_draw_bmp semantics, masked source: the AND plane
        ;;       is the only case where the compositor reads it at all
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

        ;; Save clip pointer (the one remaining stack arg).
        ld      e,6(ix)
        ld      d,7(ix)
        ST16DE  L_CLIP

        ;; y and bitmap pointer were drained into the alternate set.
        exx
        ld      L_Y(iy),l
        ld      L_YHI(iy),h
        ST16DE  L_BPTR
        push    de
        exx
        pop     hl                     ;; HL = bitmap ptr (main set)

        ;; Null bitmap -> return.
        ld      a,h
        or      l
        jp      z,gb_exit
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
        jr      gb_sig_need_and

 gb_sig_masked:
        ld      a,#1
        ld      L_IS_MASKED(iy),a

 gb_sig_need_and:
        ;; Public semantics on a masked source is the one case that reads the
        ;; AND plane; fold it into the mode so the byte loop tests once.
        ld      a,L_DRAWMODE(iy)
        or      a
        jr      nz,gb_sig_parse
        ld      a,L_IS_MASKED(iy)
        or      a
        jr      z,gb_sig_parse
        ld      a,#4
        ld      L_DRAWMODE(iy),a

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
        or      L_CLIP+1(iy)
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
        pop     hl                     ;; does not disturb the compare's carry
        jr      nc,gb_clip_y0_load
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
        pop     hl                     ;; does not disturb the compare's carry
        jr      nc,gb_clip_x1_load
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
        pop     hl                     ;; does not disturb the compare's carry
        jr      nc,gb_clip_y1_load
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
        jr      nc,gb_clip_ready
        ld      l,c
        ld      h,b
        ST16HL  L_CLIP_Y1

 gb_clip_ready:
        ;; Empty effective clip -> nothing visible.
        LD16HL  L_CLIP_X1
        LD16DE  L_CLIP_X0
        call    __rect_cmp16s_lt
        jp      c,gb_exit

        LD16HL  L_CLIP_Y1
        LD16DE  L_CLIP_Y0
        call    __rect_cmp16s_lt
        jp      c,gb_exit

        ;; Reject if draw rect does not intersect clip rect.
        LD16HL  L_XEND
        LD16DE  L_CLIP_X0
        call    __rect_cmp16s_lt       ;; draw_x1 < clip_x0 ?
        jp      c,gb_exit

        LD16HL  L_CLIP_X1
        LD16DE  L_X
        call    __rect_cmp16s_lt       ;; clip_x1 < draw_x0 ?
        jp      c,gb_exit

        LD16HL  L_YEND
        LD16DE  L_CLIP_Y0
        call    __rect_cmp16s_lt       ;; draw_y1 < clip_y0 ?
        jp      c,gb_exit

        LD16HL  L_CLIP_Y1
        LD16DE  L_Y
        call    __rect_cmp16s_lt       ;; clip_y1 < draw_y0 ?
        jp      c,gb_exit

        ;; vis rect = draw rect clamped to effective clip, via shared
        ;; gb_max16 / gb_min16 (HL=result; cmp preserves HL/DE).
        ;; visx0 = max(draw_x0, clip_x0)
        LD16HL  L_X
        LD16DE  L_CLIP_X0
        call    gb_max16
        ST16HL  L_VISX0

        ;; visy0 = max(draw_y0, clip_y0)
        LD16HL  L_Y
        LD16DE  L_CLIP_Y0
        call    gb_max16
        ST16HL  L_VISY0

        ;; visx1 = min(draw_x1, clip_x1)
        LD16HL  L_XEND
        LD16DE  L_CLIP_X1
        call    gb_min16
        ST16HL  L_VISX1

        ;; visy1 = min(draw_y1, clip_y1)
        LD16HL  L_YEND
        LD16DE  L_CLIP_Y1
        call    gb_min16
        ST16HL  L_VISY1

 gb_skips:
        ;; Source skip is the clipped-away left/top part.
        ld      a,L_VISX0(iy)          ;; srcx = visx0 - x
        sub     L_X(iy)
        ld      L_SRCX(iy),a

        ld      a,L_VISY0(iy)          ;; srcy = visy0 - y
        sub     L_Y(iy)
        ld      L_SRCY(iy),a

        ;; visw = visx1 - visx0 + 1
        ld      a,L_VISX1(iy)
        sub     L_VISX0(iy)
        inc     a
        ld      L_VISW(iy),a
        or      a
        jp      z,gb_exit

        ;; vish = visy1 - visy0 + 1
        ld      a,L_VISY1(iy)
        sub     L_VISY0(iy)
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
        sub     L_SRCBIT(iy)
        and     #0x07
        ld      L_RSHIFT(iy),a

        ;; sub = (8 - rshift) & 7  (left shift used by the 2-byte src window)
        neg
        and     #0x07
        ld      L_SUB(iy),a

        ;; lmask = ~(0xff >> dbit)   (dbit=0 -> ~0xff = 0, same formula)
        ld      a,L_DBIT(iy)
        call    __gpx_ffshr
        cpl
        ld      L_LMASK(iy),a

        ;; rmask = 0xff >> ((dbit + visw) & 7), with 0 -> 0
        ld      a,L_VISW(iy)
        add     a,L_DBIT(iy)
        and     #0x07
        jr      z,gb_rmask_zero
        call    __gpx_ffshr
 gb_rmask_zero:
        ld      L_RMASK(iy),a

 gb_rmask_done:
        ;; srcspan = (srcbit + visw + 7) >> 3 ; dstspan = (dbit + visw + 7) >> 3
        ld      a,L_SRCBIT(iy)
        call    gb_span
        ld      L_SRCSPAN(iy),a
        ld      a,L_DBIT(iy)
        call    gb_span
        ld      L_DSTSPAN(iy),a

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
        ld      a,L_ROWSTRIDE_AND(iy)
        add     a,L_SRCROW(iy)
        ld      L_SRCROW(iy),a
        jr      nc,gb_skip_or
        inc     L_SRCROW+1(iy)
 gb_skip_or:
        ld      a,L_ROWSTRIDE_OR(iy)
        add     a,L_SRCROW_OR(iy)
        ld      L_SRCROW_OR(iy),a
        jr      nc,gb_skip_next
        inc     L_SRCROW_OR+1(iy)
 gb_skip_next:

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
        ld      a,L_VISH(iy)
        or      a
        jp      z,gb_exit
        ld      L_ROWCNT(iy),a         ;; counts down

        ;; The destination row address is derived once here and then stepped:
        ;; consecutive display rows are one __vid_nextrow apart, which is far
        ;; cheaper than rebuilding the interleaved address from y every row.
        ;; The row base low byte is a multiple of 0x20 and xbyte is 0..31, so
        ;; the add cannot carry.
        ld      b,L_VISY0(iy)
        call    __vid_rowaddr
        ld      a,L_XBYTE(iy)
        add     a,l
        ld      l,a                    ;; HL now rides through the row loop

 gb_row_loop:
        ;; Source row pointers live in the alternate bank: HL'=AND, DE'=OR.
        ;; (IY is not swapped by exx, so IY-relative loads still work here.)
        ;; HL' is only a pointer when the AND plane is live; otherwise the
        ;; byte loop uses it as a shift window, so there is nothing to load.
        ld      a,L_DRAWMODE(iy)
        cp      #4
        jr      nz,gb_row_or_only
        exx
        LD16HL  L_SRCROW
        LD16DE  L_SRCROW_OR
        exx
        jr      gb_row_ptrs_done
 gb_row_or_only:
        exx
        LD16DE  L_SRCROW_OR
        exx
 gb_row_ptrs_done:

        ;; per-row: reset the source counter, prime the window prev bytes
        ld      a,L_SRCSPAN(iy)
        ld      L_SRCREMAIN(iy),a

        ;; hb0 = (dbit > srcbit) ? -1 : 0
        ld      a,L_SRCBIT(iy)
        cp      L_DBIT(iy)             ;; C if srcbit < dbit => dbit>srcbit => hb0=-1
        jr      c,gb_prime_default

        ;; hb0 = 0: prev = first source byte (consume one from each live plane)
        ld      a,L_DRAWMODE(iy)
        cp      #4
        jr      nz,gb_prime_or_only
        exx
        ld      a,(hl)                 ;; AND plane (HL')
        inc     hl
        ld      L_REMAINDER(iy),a      ;; prevA  (IY works inside exx)
        exx
 gb_prime_or_only:
        exx
        ld      a,(de)                 ;; OR plane (DE')
        inc     de
        ld      c,a                    ;; C' = prevO for the fast path
        ld      L_REMAINDER_OR(iy),a   ;; prevO for the masked path
        exx
        ld      a,L_SRCREMAIN(iy)
        dec     a
        ld      L_SRCREMAIN(iy),a
        jr      gb_dst_init

 gb_prime_default:
        ;; hb0 = -1: prevA = 0xFF (transparent AND), prevO = 0x00
        ld      a,#0xff
        ld      L_REMAINDER(iy),a
        xor     a
        ld      L_REMAINDER_OR(iy),a
        exx
        ld      c,a                    ;; C' = prevO for the fast path
        exx

 gb_dst_init:

        ;; The left and right edge masks only ever apply to the first and
        ;; last byte of the span, so the run is walked in three phases and
        ;; the middle bytes carry no edge handling at all. The destination
        ;; byte stays addressed by HL and is read through (hl) at 7 T-states.
        ld      a,L_DSTSPAN(iy)
        dec     a
        jr      z,gb_span_single

        ;; --- first byte ---
        ld      a,L_LMASK(iy)
        cpl
        ld      L_INSIDE(iy),a
        call    gb_byte

        ;; --- middle bytes, entirely inside the visible span ---
        ld      a,L_DSTSPAN(iy)
        sub     #2
        jr      z,gb_span_last
        ld      b,a
        ld      a,#0xff
        ld      L_INSIDE(iy),a
 gb_mid_loop:
        push    bc
        call    gb_byte
        pop     bc
        djnz    gb_mid_loop

 gb_span_last:
        ld      a,L_RMASK(iy)
        cpl
        ld      L_INSIDE(iy),a
        call    gb_byte
        jp      gb_next_row

 gb_span_single:
        ld      a,L_LMASK(iy)
        or      L_RMASK(iy)
        cpl
        ld      L_INSIDE(iy),a
        call    gb_byte
        jp      gb_next_row

        ;; ------------------------------------------------------------
        ;; gb_byte: compose one destination byte at (HL) and advance HL.
        ;; All state is in the caller's stack frame via IY, so this stays
        ;; re-entrant. Clobbers A, BC, DE and the alternate bank.
        ;;
        ;; The AND plane is live only for a masked bitmap drawn with the
        ;; default public semantics. Every other draw leaves HL' free, so the
        ;; two-byte source window can shift there with add hl,hl and the
        ;; previous source byte can stay in C' instead of the workspace.
        ;; ------------------------------------------------------------
 gb_byte:
        ld      a,L_DRAWMODE(iy)
        cp      #4
        jp      z,gb_byte_masked

        ld      a,L_SRCREMAIN(iy)
        or      a
        jr      z,gb_fast_pad
        dec     a
        ld      L_SRCREMAIN(iy),a
        exx
        ld      a,(de)                 ;; curO from the OR pointer in DE'
        inc     de
        jr      gb_fast_have
 gb_fast_pad:
        exx
        xor     a                      ;; past the source span: zero fill
 gb_fast_have:
        ld      h,c                    ;; H = prevO
        ld      l,a                    ;; L = curO
        ld      c,a                    ;; C' = prevO for the next byte
        ld      b,L_SUB(iy)            ;; IY is not swapped by exx
        inc     b
        dec     b
        jr      z,gb_fast_done
 gb_fast_lp:
        add     hl,hl                  ;; 11T a step, against 16T in D:E
        djnz    gb_fast_lp
 gb_fast_done:
        ld      a,h
        exx
        ld      e,a                    ;; E = ORBITS, straight into the compose
        jr      gb_have_src

 gb_byte_masked:
        ;; Masked source, public semantics: both planes are live, so HL' and
        ;; DE' are both taken and the window stages through D:E as before.
        ld      a,L_SRCREMAIN(iy)
        or      a
        jr      z,gb_cur_default

        exx
        ld      a,(hl)                 ;; curA from alt HL' (AND ptr)
        inc     hl
        exx
        ld      c,a                    ;; curA
        ld      a,L_REMAINDER(iy)      ;; prevA
        ld      d,a
        ld      e,c
        ld      a,L_SUB(iy)
        or      a
        jr      z,gbw1_done
        ld      b,a
 gbw1_lp:
        sla     e
        rl      d
        djnz    gbw1_lp
 gbw1_done:
        ld      a,d
        ld      L_FORE(iy),a
        ld      a,c
        ld      L_REMAINDER(iy),a      ;; prevA = curA

        exx
        ld      a,(de)                 ;; curO from alt DE' (OR ptr)
        inc     de
        exx
        ld      c,a                    ;; curO
        ld      a,L_REMAINDER_OR(iy)   ;; prevO
        ld      d,a
        ld      e,c
        ld      a,L_SUB(iy)
        or      a
        jr      z,gbw2_done
        ld      b,a
 gbw2_lp:
        sla     e
        rl      d
        djnz    gbw2_lp
 gbw2_done:
        ld      a,c
        ld      L_REMAINDER_OR(iy),a   ;; prevO = curO
        ld      e,d                    ;; E = ORBITS
        ld      a,L_SRCREMAIN(iy)
        dec     a
        ld      L_SRCREMAIN(iy),a
        jr      gb_have_src

 gb_cur_default:
        ;; Cold path: trailing transparent bytes past the source span.
        ld      c,#0xff                ;; curA default (transparent)
        ld      a,L_REMAINDER(iy)
        call    gb_win
        ld      L_FORE(iy),a
        ld      a,c
        ld      L_REMAINDER(iy),a
        ld      c,#0x00                ;; curO default
        ld      a,L_REMAINDER_OR(iy)
        call    gb_win
        ld      e,a                    ;; E = ORBITS
        ld      a,c
        ld      L_REMAINDER_OR(iy),a

 gb_have_src:
        ld      a,L_DRAWMODE(iy)
        or      a
        jr      nz,gb_mode_compose

        ;; Plain source, public semantics: draw = old | src. There is no AND
        ;; plane to consult, so the compositor never reads one.
        ld      a,e
        or      (hl)
        jr      gb_store_out

 gb_mode_compose:
        cp      #4
        jr      z,gb_mode_masked
        cp      #3
        jr      z,gb_mode_xor
        cp      #2
        jr      z,gb_mode_back

        ;; FORE copy: write source bits directly.
        ld      a,e
        jr      gb_store_out

 gb_mode_masked:
        ;; Masked source, public semantics: draw = (old & AND) | OR.
        ld      a,L_FORE(iy)
        and     (hl)
        or      e
        jr      gb_store_out

 gb_mode_back:
        ;; BACK copy: write inverted source bits directly.
        ld      a,e
        cpl
        jr      gb_store_out

 gb_mode_xor:
        ;; XOR: flip OR bits only. old ^ ((old ^ (old ^ src)) & inside)
        ;; collapses to old ^ (src & inside), so this path skips the merge.
        ld      a,e
        and     L_INSIDE(iy)
        xor     (hl)
        jr      gb_store_byte

 gb_store_out:
        ;; A = draw; out = old ^ ((old ^ draw) & inside)
        xor     (hl)
        and     L_INSIDE(iy)
        xor     (hl)
 gb_store_byte:
        ld      (hl),a                 ;; HL = DSTPTR
        inc     hl                     ;; advance DSTPTR (kept in HL)
        ret

 gb_next_row:
        ld      a,L_ROWCNT(iy)
        dec     a
        ld      L_ROWCNT(iy),a
        jr      z,gb_exit

        ;; Advance the source rows. A row stride is stride or 2*stride, at
        ;; most 32, so this is an 8-bit add with a carry into the high byte
        ;; rather than a full 16-bit add through DE.
        ld      a,L_ROWSTRIDE_AND(iy)
        add     a,L_SRCROW(iy)
        ld      L_SRCROW(iy),a
        jr      nc,gb_nr_or
        inc     L_SRCROW+1(iy)
 gb_nr_or:
        ld      a,L_ROWSTRIDE_OR(iy)
        add     a,L_SRCROW_OR(iy)
        ld      L_SRCROW_OR(iy),a
        jr      nc,gb_nr_dst
        inc     L_SRCROW_OR+1(iy)
 gb_nr_dst:
        ;; The byte phases left HL one past the end of the span, so rewind by
        ;; the span width and step a row: no workspace round-trip either way.
        ld      a,l
        sub     L_DSTSPAN(iy)
        ld      l,a
        jr      nc,gb_nr_step
        dec     h
 gb_nr_step:
        call    __vid_nextrow
        jp      gb_row_loop

 gb_exit:
        ;; y and b were popped at entry; drop the remaining clip word.
        ld      sp,ix
        pop     iy
        pop     ix
        pop     de                     ;; return address
        pop     hl                     ;; discard clip
        push    de
        ret

        ;; Row address (y in B -> HL) is shared with _video.s (__vid_rowaddr).

        ;; gb_max16 / gb_min16: HL = signed max/min(HL, DE).
        ;; __rect_cmp16s_lt preserves HL/DE (writes only A); A=1 when HL<DE.
 gb_max16:
        call    __rect_cmp16s_lt
        ret     nc                      ;; HL >= DE -> HL is the max
        ex      de,hl
        ret
 gb_min16:
        call    __rect_cmp16s_lt
        ret     c                     ;; HL < DE -> HL is the min
        ex      de,hl
        ret

        ;; gb_win: A=prev, C=cur -> A = high byte of (prev:cur) << SUB.
        ;; Uses D,E,B; leaves HL (DSTPTR) and C (cur) intact. Used by the cold
        ;; trailing-transparent path; the hot SRCREMAIN path inlines this body.
 gb_win:
        ld      d,a
        ld      e,c
        ld      a,L_SUB(iy)
        or      a
        jr      z,gb_win_done
        ld      b,a
 gb_win_lp:
        sla     e
        rl      d
        djnz    gb_win_lp
 gb_win_done:
        ld      a,d
        ret

        ;; __gpx_ffshr: A = 0xff >> A (A = 0..7; 0 -> 0xff). Clobbers B.
__gpx_ffshr::
        or      a
        jr      z,gb_ffshr_ff
        ld      b,a
        ld      a,#0xff
 gb_ffshr_lp:
        srl     a
        djnz    gb_ffshr_lp
        ret
 gb_ffshr_ff:
        ld      a,#0xff
        ret

        ;; gb_span: A = bit (0..7) -> A = (bit + L_VISW + 7) >> 3
 gb_span:
        ld      h,#0
        ld      l,a
        ld      a,L_VISW(iy)
        add     a,l
        ld      l,a
        jr      nc,gb_span_add7
        inc     h
 gb_span_add7:
        ld      a,l
        add     a,#7
        ld      l,a
        jr      nc,gb_span_div
        inc     h
 gb_span_div:
        srl     h
        rr      l
        srl     h
        rr      l
        srl     h
        rr      l
        ld      a,l
        ret

 gb_ff_pad:
        .db     0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff
        .db     0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff
        .db     0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff
        .db     0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff
