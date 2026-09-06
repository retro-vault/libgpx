        ;; gpx_bmp.s
        ;;
        ;; Unified Amstrad CPC bitmap blitter.
        ;;
        ;; Mode 2 packs eight pixels per byte. Mode 1 packs four pixels
        ;; in each high nibble, so each eight-pixel source window updates
        ;; two screen bytes. The compositor prepares replacement/toggle
        ;; masks once per group and applies them directly in either mode,
        ;; preserving the unused low-nibble plane in mode 1.
        ;;
        ;; All clipping is resolved up front in 16-bit space, then the
        ;; bitmap is drawn with byte-span composition directly into
        ;; display memory. No pixel fallback path remains here.
        ;;
        ;; Re-entrant/thread-safe: mutable state stays in registers and on the stack.
        ;;
        ;; GPL2 License (see: LICENSE)
        ;; Copyright (C) 2026 Tomaz Stih
        ;;
        ;; 2026-08-25   TS

        .module gpx_bmp
        .optsdcc -mz80 sdcccall(1)

        .include "_cpc-defs.inc"

        .globl  _gpx_draw_bmp
        .globl  _gpx_draw_bmp_clip
        .globl  __gpx_ffshr
        .globl  __rect_cmp16s_lt
        .globl  __vid_rowaddr
        .globl  __vid_nextrow
        .globl  __clip_seg
        .globl  __rect_screen
        .globl  __cpc_width
        .globl  __cpc_mode1

        .equ    SCRHEIGHT, CPC_HEIGHT
        .equ    BMP_SIG_ENC_MASK, 0xF0
        .equ    BMP_SIG_1BPP, 0x00
        .equ    BMP_SIG_1BPP_MASK, 0x10

        ;; Stack-local workspace. IX holds the selected compositor; IY
        ;; addresses the live clipping and source-window state.
        .equ    L_X,                   0
        .equ    L_XHI,                 1
        .equ    L_Y,                   2
        .equ    L_YHI,                 3
        .equ    L_CLIP,                4
        .equ    L_BPTR,                6
        .equ    L_BW,                  8
        .equ    L_BH,                  9
        .equ    L_BSTRIDE,             10
        .equ    L_ROWSTRIDE_OR,        11
        .equ    L_DSTSTEP,             12
        .equ    L_HB0,                 13
        .equ    L_INS_L,               14
        .equ    L_INS_R,               15
        .equ    L_INS_S,               16
        .equ    L_XEND,                17
        .equ    L_YEND,                19
        .equ    L_VISX0,               21
        .equ    L_VISX1,               23
        .equ    L_VISY0,               25
        .equ    L_VISY1,               27
        .equ    L_VISW,                29
        .equ    L_VISH,                30
        .equ    L_SRCX,                31
        .equ    L_SRCY,                32
        .equ    L_XBYTE,               33
        .equ    L_SRCBYTE,             34
        .equ    L_DBIT,                35
        .equ    L_SRCBIT,              36
        .equ    L_SRCSPAN,             37
        .equ    L_DSTSPAN,             38
        .equ    L_SRCROW_OR,           39
        .equ    L_IS_MASKED,           41
        .equ    L_DRAWMODE,            42
        .equ    L_SUB,                 43
        .equ    L_SRCREMAIN,           44
        .equ    L_SIZE,                45

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

        ;; ------------------------------------------------------------
        ;; _gpx_draw_bmp
        ;; Blit a bitmap with its top-left corner at (x, y). Public entry:
        ;; the payload's own colours are used and the mode is copy, so it
        ;; sets the internal mode tag and falls into the shared core.
        ;;
        ;; Signature:
        ;;   void gpx_draw_bmp(gpx_t *gpx, coord x, coord y, bmp_t *b,
        ;;                     const rect_t *clip)
        ;;
        ;; Arguments:
        ;;   HL = gpx, DE = x
        ;;   stack: y, b, clip
        ;;
        ;; Clobbers:
        ;;   AF, BC, DE, HL, IX, IY
        ;;
        ;; References:
        ;;   .gb_core
_gpx_draw_bmp::
        ;; Public API semantics:
        ;; - unmasked: draw 1 bits, skip 0 bits
        ;; - masked:   apply AND/OR pair
        ld      b,#0x80                 ; internal mode tag: keep legacy semantics

        ;; ------------------------------------------------------------
        ;; _gpx_draw_bmp_clip
        ;; As gpx_draw_bmp, but the caller chooses the colour and blit
        ;; mode. The text path uses this so the colour and mode given to
        ;; gpx_draw_text actually reach the glyphs.
        ;;
        ;; Arguments:
        ;;   B = bmode, C = color
        ;;   HL = gpx, DE = x
        ;;   stack: y, b, clip
        ;;
        ;; Clobbers:
        ;;   AF, BC, DE, HL, IX, IY
        ;;
        ;; References:
        ;;   .gb_core
_gpx_draw_bmp_clip::
.gb_core:
        ;; Drain y and bitmap-ptr args into the alternate set and park the
        ;; return address back on the stack; clip stays as the only stack
        ;; arg (read at 6(ix) below, discarded by the exit). DE = x and
        ;; BC = mode tags stay live in the main set throughout.
        exx
        pop     bc                      ; BC' = return address
        pop     hl                      ; HL' = y
        pop     de                      ; DE' = bitmap ptr
        push    bc                      ; return address back (clip below it)
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

        ;; Preserve the arguments before IX becomes the compositor address.
        ld      L_X(iy),e
        ld      L_XHI(iy),d
        ld      e,6(ix)
        ld      d,7(ix)
        ST16DE  L_CLIP

        ;; Select the byte compositor once. IX is otherwise unused after
        ;; reading the stack arguments; the saved caller IX remains on the
        ;; stack above the IY-relative workspace. Bit 7 of the incoming mode
        ;; marks public bitmap semantics and is resolved after the header.
        ld      L_DRAWMODE(iy),b
        ld      ix,#.gb_mode_plain
        bit     7,b
        jr      nz,.gb_mode_done
        bit     0,b
        jr      nz,.gb_mode_xor_sel
        bit     6,b
        jr      z,.gb_mode_opaque_select
        bit     0,c
        jr      nz,.gb_mode_done
        ld      ix,#.gb_mode_trans_back
        jr      .gb_mode_done

.gb_mode_opaque_select:
        ld      ix,#.gb_mode_fore
        bit     0,c
        jr      nz,.gb_mode_done
        ld      ix,#.gb_mode_back
        jr      .gb_mode_done

.gb_mode_xor_sel:
        ld      ix,#.gb_mode_xor

.gb_mode_done:
        ;; y and bitmap pointer were drained into the alternate set.
        exx
        ld      L_Y(iy),l
        ld      L_YHI(iy),h
        ST16DE  L_BPTR
        push    de
        exx
        pop     hl                      ; HL = bitmap ptr (main set)

        ;; Null bitmap -> return.
        ld      a,h
        or      l
        jp      z,.gb_exit
        ld      a,(hl)
        and     #0xe0
        jp      nz,.gb_exit
        bit     4,(hl)
        jr      nz,.gb_sig_masked

.gb_sig_unmasked:
        xor     a
        ld      L_IS_MASKED(iy),a
        jr      .gb_sig_need_and

.gb_sig_masked:
        ld      a,#1
        ld      L_IS_MASKED(iy),a

.gb_sig_need_and:
        ;; Only a masked public bitmap reads the AND plane. Every text
        ;; compositor consumes the OR plane, including custom masked fonts.
        ld      a,L_IS_MASKED(iy)
        or      a
        jr      z,.gb_sig_mode_ready
        ld      a,L_DRAWMODE(iy)
        and     #0x80
        jr      z,.gb_sig_mode_ready
        ld      ix,#.gb_mode_masked
.gb_sig_mode_ready:
        ld      L_DRAWMODE(iy),a        ; nonzero only when AND is live

.gb_sig_parse:
        ld      a,(hl)
        and     #0x0F
        inc     a
        ld      L_BSTRIDE(iy),a

        inc     hl
        ld      a,(hl)
        ld      L_BW(iy),a
        inc     hl
        ld      a,(hl)
        ld      L_BH(iy),a

        ld      a,L_BW(iy)
        or      a
        jp      z,.gb_exit
        ld      a,L_BH(iy)
        or      a
        jp      z,.gb_exit

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

        ;; The overwhelmingly common blit -- every glyph of a text run,
        ;; every sprite that is not straddling an edge -- has no clip rect
        ;; and lies wholly on screen. Recognising that costs four compares
        ;; and skips four generic 1-D clamps, which is most of what a glyph
        ;; used to spend here.
        ld      a,L_CLIP(iy)
        or      L_CLIP+1(iy)
        jr      nz,.gb_clip_general
        ld      a,L_XHI(iy)
        or      a
        jp      m,.gb_clip_general      ; x < 0
        ld      a,L_YHI(iy)
        or      a
        jr      nz,.gb_clip_general     ; y outside a byte
        ld      a,L_YEND+1(iy)
        or      a
        jr      nz,.gb_clip_general
        ld      a,L_YEND(iy)
        cp      #SCRHEIGHT
        jr      nc,.gb_clip_general     ; runs off the bottom
        ld      l,L_XEND(iy)
        ld      h,L_XEND+1(iy)
        ld      de,(__cpc_width)
        or      a
        sbc     hl,de
        jr      nc,.gb_clip_general     ; runs off the right

.gb_vis_all:
        ;; Wholly visible -- no clip rect and the whole bitmap on screen,
        ;; which is every glyph of a text run and every sprite not straddling
        ;; an edge. The visible rect *is* the draw rect, so everything
        ;; .gb_skips derives is already known: nothing is skipped off the left
        ;; or top, which makes srcx and srcy zero, leaves the source pointer
        ;; on its first byte, and makes the visible size the bitmap's own.
        ;; Only the destination bit and the edge masks still have to be
        ;; worked out, and those come straight from x instead of from a
        ;; clipped visx0. That skips two subtractions, a 16-bit width, a
        ;; height, and the source bit/byte split.
        xor     a
        ld      L_SRCX(iy),a
        ld      L_SRCY(iy),a
        ld      L_SRCBIT(iy),a
        ld      L_SRCBYTE(iy),a

        ld      a,L_Y(iy)               ; only the low byte is ever read back
        ld      L_VISY0(iy),a

        ld      a,L_BW(iy)              ; both were rejected as zero above
        ld      L_VISW(iy),a
        ld      a,L_BH(iy)
        ld      L_VISH(iy),a

        ld      a,L_X(iy)
        and     #0x07
        ld      L_DBIT(iy),a
        ld      c,a                     ; dbit rides in C, as .gb_skips leaves it
        neg
        and     #0x07
        ld      L_SUB(iy),a

        ld      l,L_X(iy)               ; group index = x >> 3
        ld      h,L_XHI(iy)
        srl     h
        rr      l
        srl     h
        rr      l
        srl     h
        rr      l
        ld      a,l
        ld      L_XBYTE(iy),a

        ld      e,#0                    ; srcbit rides in E, likewise
        jp      .gb_lrmask


        ;; Clamp the draw rect to the screen, then to the caller's clip.
        ;; x reaches 639 here, so the byte-domain shortcuts a 256-pixel-wide
        ;; machine can take do not apply; both axes go through the shared
        ;; 1-D clamp, which also rejects an inverted span. IY carries the
        ;; workspace, and __clip_seg wants it for the rect, so it is saved
        ;; around each call.
.gb_clip_general:
        ld      l,L_X(iy)
        ld      h,L_XHI(iy)
        ld      e,L_XEND(iy)
        ld      d,L_XEND+1(iy)
        push    iy
        ld      iy,#__rect_screen
        call    __clip_seg
        pop     iy
        jp      c,.gb_exit
        ld      L_VISX0(iy),l
        ld      L_VISX0+1(iy),h
        ld      L_VISX1(iy),e
        ld      L_VISX1+1(iy),d

        ld      l,L_Y(iy)
        ld      h,L_YHI(iy)
        ld      e,L_YEND(iy)
        ld      d,L_YEND+1(iy)
        push    iy
        ld      iy,#__rect_screen+2
        call    __clip_seg
        pop     iy
        jp      c,.gb_exit
        ld      L_VISY0(iy),l
        ld      L_VISY0+1(iy),h
        ld      L_VISY1(iy),e
        ld      L_VISY1+1(iy),d

        ;; optional caller clip on top
        ld      a,L_CLIP(iy)
        or      L_CLIP+1(iy)
        jr      z,.gb_clip_test

        ld      l,L_VISX0(iy)
        ld      h,L_VISX0+1(iy)
        ld      e,L_VISX1(iy)
        ld      d,L_VISX1+1(iy)
        push    iy
        ld      a,L_CLIP(iy)
        ld      c,a
        ld      a,L_CLIP+1(iy)
        ld      b,a
        push    bc
        pop     iy                      ; IY = &clip->x0
        call    __clip_seg
        pop     iy
        jp      c,.gb_exit
        ld      L_VISX0(iy),l
        ld      L_VISX0+1(iy),h
        ld      L_VISX1(iy),e
        ld      L_VISX1+1(iy),d

        ld      l,L_VISY0(iy)
        ld      h,L_VISY0+1(iy)
        ld      e,L_VISY1(iy)
        ld      d,L_VISY1+1(iy)
        push    iy
        ld      a,L_CLIP(iy)
        ld      c,a
        ld      a,L_CLIP+1(iy)
        ld      b,a
        inc     bc
        inc     bc
        push    bc
        pop     iy                      ; IY = &clip->y0
        call    __clip_seg
        pop     iy
        jp      c,.gb_exit
        ld      L_VISY0(iy),l
        ld      L_VISY0+1(iy),h
        ld      L_VISY1(iy),e
        ld      L_VISY1+1(iy),d

.gb_clip_test:

.gb_skips:
        ;; Source skip is the clipped-away left/top part.
        ld      a,L_VISX0(iy)           ; srcx = visx0 - x, under 256 wide
        sub     L_X(iy)
        ld      L_SRCX(iy),a

        ld      a,L_VISY0(iy)           ; srcy = visy0 - y
        sub     L_Y(iy)
        ld      L_SRCY(iy),a

        ;; visw = visx1 - visx0 + 1
        ld      l,L_VISX1(iy)           ; visw = visx1 - visx0 + 1
        ld      h,L_VISX1+1(iy)
        ld      e,L_VISX0(iy)
        ld      d,L_VISX0+1(iy)
        or      a
        sbc     hl,de
        inc     hl
        ld      a,l                     ; a bitmap is at most 255 wide
        ld      L_VISW(iy),a
        or      a
        jp      z,.gb_exit

        ;; vish = visy1 - visy0 + 1
        ld      a,L_VISY1(iy)           ; vish: y fits a byte on this machine
        sub     L_VISY0(iy)
        inc     a
        ld      L_VISH(iy),a
        or      a
        jp      z,.gb_exit

        ;; Destination group index and pixel-in-group. A "byte" here is an
        ;; eight-pixel group: one screen byte in mode 2, two in mode 1.
        ld      a,L_VISX0(iy)
        and     #0x07
        ld      L_DBIT(iy),a
        ld      c,a                     ; dbit rides in C through this block
        ld      l,L_VISX0(iy)
        ld      h,L_VISX0+1(iy)
        srl     h
        rr      l
        srl     h
        rr      l
        srl     h
        rr      l
        ld      a,l                     ; group index, 0..79
        ld      L_XBYTE(iy),a

        ;; Source x byte / bit.
        ld      a,L_SRCX(iy)
        ld      b,a
        and     #0x07
        ld      L_SRCBIT(iy),a
        ld      e,a                     ; srcbit rides in E
        ld      a,b
        rrca
        rrca
        rrca
        and     #0x1f
        ld      L_SRCBYTE(iy),a

        ;; rshift = (dbit - srcbit) & 7
        ld      a,c
        sub     e
        and     #0x07

        ;; sub = (8 - rshift) & 7, the source window's left shift.
        neg
        and     #0x07
        ld      L_SUB(iy),a

.gb_lrmask:
        ;; First-group coverage is 0xff >> dbit.
        ld      a,c
        call    __gpx_ffshr
        ld      L_INS_L(iy),a

        ;; Last-group coverage is the complement of the trailing mask.
        ld      a,L_VISW(iy)
        add     a,c
        and     #0x07
        jr      z,.gb_rmask_zero
        call    __gpx_ffshr
.gb_rmask_zero:
        cpl
        ld      L_INS_R(iy),a

.gb_rmask_done:
        ;; srcspan = (srcbit + visw + 7) >> 3 ; dstspan = (dbit + visw + 7) >> 3
        ld      a,e
        call    .gb_span
        ld      L_SRCSPAN(iy),a
        ld      a,c
        call    .gb_span
        ld      L_DSTSPAN(iy),a

        ;; Walk to the first visible source row in registers and retain
        ;; only its OR pointer. The AND plane is one stride before it.
        LD16HL  L_BPTR
        ld      de,#5
        add     hl,de
        ld      e,L_BSTRIDE(iy)
        ld      d,#0
        ld      a,L_IS_MASKED(iy)
        or      a
        jr      z,.gb_rows_stride
        add     hl,de                   ; OR follows the first AND stride
        sla     e                       ; masked rows contain both planes
.gb_rows_stride:
        ld      L_ROWSTRIDE_OR(iy),e
        ld      b,L_SRCY(iy)
        inc     b
        dec     b
        jr      z,.gb_rows_skip_x
.gb_rows_skip_loop:
        add     hl,de
        djnz    .gb_rows_skip_loop
.gb_rows_skip_x:
        ld      e,L_SRCBYTE(iy)
        add     hl,de
        ST16HL  L_SRCROW_OR

.gb_rows_ready:
        ;; A single group is covered by the intersection of both edges.
        ld      a,L_INS_L(iy)
        and     L_INS_R(iy)
        ld      L_INS_S(iy),a

        ;; The two-byte source window starts on the first source byte only
        ;; when the source bit is at or right of the destination bit. That
        ;; compares two values neither of which changes between rows.
        ld      a,L_SRCBIT(iy)
        cp      L_DBIT(iy)              ; C: srcbit < dbit, so window is short
        ld      a,#0                    ; ld leaves the flags alone
        jr      c,.gb_hb0_done
        inc     a
.gb_hb0_done:
        ld      L_HB0(iy),a

        ;; Destination bytes per row: one per pixel group, two in mode 1.
        ld      a,(__cpc_mode1)
        or      a
        ld      a,L_DSTSPAN(iy)
        jr      z,.gb_dststep_done
        add     a,a
.gb_dststep_done:
        ld      L_DSTSTEP(iy),a

        ;; The destination row address is derived once here and then stepped:
        ;; consecutive display rows are one __vid_nextrow apart, which is far
        ;; cheaper than rebuilding the interleaved address from y every row.
        ;; A CPC row base is 80 bytes into its bank, not 32-aligned, so the
        ;; add can carry. In mode 1 a group is two screen bytes wide.
        ld      b,L_VISY0(iy)
        call    __vid_rowaddr
        ld      a,(__cpc_mode1)
        or      a
        ld      a,L_XBYTE(iy)
        jr      z,.gb_dst_wide
        add     a,a                     ; mode 1: two screen bytes per group
.gb_dst_wide:
        add     a,l
        ld      l,a
        jr      nc,.gb_dst_ok
        inc     h
.gb_dst_ok:                             ; HL now rides through the row loop

.gb_row_loop:
        ;; Source pointers live in the alternate bank. Derive AND from OR
        ;; only when it is read, so the row loop advances just one pointer.
        exx
        LD16DE  L_SRCROW_OR
        ld      a,L_DRAWMODE(iy)
        or      a
        jr      z,.gb_row_ptrs_done
        ld      h,d
        ld      l,e
        ld      c,L_BSTRIDE(iy)
        ld      b,#0
        sbc     hl,bc                   ; OR test above cleared carry
.gb_row_ptrs_done:
        exx

        ;; per-row: reset the source counter, prime the window prev bytes
        ld      a,L_SRCSPAN(iy)
        ld      L_SRCREMAIN(iy),a

        ;; hb0 was decided once, before the first row.
        ld      a,L_HB0(iy)
        or      a
        jr      z,.gb_prime_default

        ;; Prime the live source planes in alternate BC. A masked window
        ;; keeps its previous AND in B' and previous OR in C'; the plain
        ;; window needs only C' for its previous OR byte.
        ld      a,L_DRAWMODE(iy)
        or      a
        jr      z,.gb_prime_or_only
        exx
        ld      b,(hl)
        inc     hl
        ld      a,(de)
        inc     de
        ld      c,a
        exx
        jr      .gb_prime_done
.gb_prime_or_only:
        exx
        ld      a,(de)
        inc     de
        ld      c,a
        exx
.gb_prime_done:
        dec     L_SRCREMAIN(iy)
        jr      .gb_dst_init

.gb_prime_default:
        ;; Transparent AND/OR defaults also give the plain window C'=0.
        exx
        ld      bc,#0xff00
        exx

.gb_dst_init:

        ;; The left and right edge masks only ever apply to the first and
        ;; last byte of the span, so the run is walked in three phases and
        ;; the middle bytes carry no edge handling at all. The destination
        ;; byte stays addressed by HL and is read through (hl) at 7 T-states.
        ld      a,L_DSTSPAN(iy)
        dec     a
        jr      z,.gb_span_single

        ;; --- first byte ---
        ld      c,L_INS_L(iy)
        call    .gb_byte

        ;; --- middle bytes, entirely inside the visible span ---
        ld      a,L_DSTSPAN(iy)
        sub     #2
        jr      z,.gb_span_last
        ld      b,a
        ld      c,#0xff
.gb_mid_loop:
        call    .gb_byte
        djnz    .gb_mid_loop

.gb_span_last:
        ld      c,L_INS_R(iy)
        call    .gb_byte
        jp      .gb_next_row

.gb_span_single:
        ld      c,L_INS_S(iy)
        call    .gb_byte
        jp      .gb_next_row

        ;; ------------------------------------------------------------
        ;; .gb_byte: compose one destination byte at (HL) and advance HL.
        ;; IY addresses the caller's workspace. BC retains the destination
        ;; count and coverage. Clobbers AF, DE and the alternate bank.
        ;;
        ;; The AND plane is live only for a masked bitmap drawn with the
        ;; default public semantics. Every other draw leaves HL' free, so the
        ;; two-byte source window can shift there with add hl,hl and the
        ;; previous source byte can stay in C' instead of the workspace.
        ;; ------------------------------------------------------------
.gb_byte:
        ld      a,L_DRAWMODE(iy)
        or      a
        jp      nz,.gb_byte_masked

        ld      a,L_SRCREMAIN(iy)
        or      a
        jr      z,.gb_fast_pad
        dec     a
        ld      L_SRCREMAIN(iy),a
        exx
        ld      a,(de)                  ; curO from the OR pointer in DE'
        inc     de
        jr      .gb_fast_have
.gb_fast_pad:
        exx
        xor     a                       ; past the source span: zero fill
.gb_fast_have:
        ld      h,c                     ; H = prevO
        ld      l,a                     ; L = curO
        ld      c,a                     ; C' = prevO for the next byte
        ld      b,L_SUB(iy)             ; IY is not swapped by exx
        inc     b
        dec     b
        jr      z,.gb_fast_done
.gb_fast_lp:
        add     hl,hl                   ; 11T a step, against 16T in D:E
        djnz    .gb_fast_lp
.gb_fast_done:
        ld      a,h
        exx
        ld      e,a                     ; E = ORBITS, straight into the compose
        jr      .gb_have_src

.gb_byte_masked:
        ;; Transfer both previous/current byte pairs through the stack,
        ;; retaining them in alternate BC between destination groups.
        push    bc                      ; destination count and coverage
        push    hl                      ; destination
        ld      a,L_SRCREMAIN(iy)
        or      a
        exx
        push    bc                      ; previous AND:OR
        jr      z,.gb_cur_default
        dec     L_SRCREMAIN(iy)
        ld      b,(hl)
        inc     hl
        ld      a,(de)
        inc     de
        ld      c,a
        jr      .gb_masked_windows
.gb_cur_default:
        ld      bc,#0xff00
.gb_masked_windows:
        push    bc                      ; current AND:OR
        exx
        pop     bc
        pop     de
        ld      h,e                     ; HL = previous/current OR
        ld      l,c
        ld      e,b                     ; DE = previous/current AND
        ld      b,L_SUB(iy)
        ld      a,b
        or      a
        jr      z,.gb_masked_shifted
.gb_masked_shift:
        sla     e
        rl      d
        add     hl,hl
        djnz    .gb_masked_shift
.gb_masked_shifted:
        ld      e,h                     ; OR bits, with AND bits already in D
        pop     hl
        pop     bc

.gb_have_src:
        jp      (ix)                    ; compositor selected once per bitmap

        ;; Represent every compositor as old XOR ((old AND D) XOR E).
        ;; D is the set of destination bits replaced; E supplies their new
        ;; values, or bits to toggle where D is zero. Neither preparation
        ;; nor clipping needs the old framebuffer byte.
.gb_mode_plain:
        ld      a,c
        and     e
        ld      d,a
        ld      e,a
        jr      .gb_store_byte

.gb_mode_fore:
        ld      a,c
        ld      d,a
        and     e
        ld      e,a
        jr      .gb_store_byte

.gb_mode_back:
        ld      a,e
        cpl
        ld      e,a
        jr      .gb_mode_fore

.gb_mode_masked:
        ld      a,d                     ; the source AND plane
        cpl
        or      e
        and     c
        ld      d,a
        ld      a,c
        and     e
        ld      e,a
        jr      .gb_store_byte

.gb_mode_trans_back:
        ld      a,c
        and     e
        ld      d,a
        ld      e,#0
        jr      .gb_store_byte

.gb_mode_xor:
        ld      a,c
        and     e
        ld      e,a
        ld      d,#0

.gb_store_byte:
        ld      a,(__cpc_mode1)
        or      a
        jr      z,.gb_store_wide
        ;; Apply the same eight-pixel operation directly to two packed
        ;; bytes. Only the high nibble changes; the second colour plane
        ;; survives without gathering and scattering an old virtual byte.
        ld      a,d
        and     (hl)
        xor     e
        and     #0xf0
        xor     (hl)
        ld      (hl),a
        inc     hl
        ld      a,(hl)
        rrca
        rrca
        rrca
        rrca
        and     d
        xor     e
        rlca
        rlca
        rlca
        rlca
        and     #0xf0
        xor     (hl)
        ld      (hl),a
        inc     hl
        ret
.gb_store_wide:
        ld      a,d
        and     (hl)
        xor     e
        xor     (hl)
        ld      (hl),a
        inc     hl
        ret

.gb_next_row:
        dec     L_VISH(iy)
        jr      z,.gb_exit

.gb_nr_or:
        ld      a,L_ROWSTRIDE_OR(iy)
        add     a,L_SRCROW_OR(iy)
        ld      L_SRCROW_OR(iy),a
        jr      nc,.gb_nr_dst
        inc     L_SRCROW_OR+1(iy)
.gb_nr_dst:
        ;; The byte phases left HL one past the end of the span, so rewind by
        ;; the span width and step a row: no workspace round-trip either way.
        ld      a,L_DSTSTEP(iy)         ; span width, doubled in mode 1
        ld      b,a
        ld      a,l
        sub     b
        ld      l,a
        jr      nc,.gb_nr_step
        dec     h
.gb_nr_step:
        call    __vid_nextrow
        jp      .gb_row_loop

.gb_exit:
        ;; y and b were popped at entry; drop the remaining clip word.
        ld      sp,iy
        ld      hl,#L_SIZE
        add     hl,sp
        ld      sp,hl
        pop     iy
        pop     ix
        pop     de                      ; return address
        pop     hl                      ; discard clip
        push    de
        ret

        ;; Row address (y in B -> HL) is shared with _video.s (__vid_rowaddr).

        ;; ------------------------------------------------------------
        ;; __gpx_ffshr
        ;; Right-edge mask for a byte span: 0xFF shifted right by A. A
        ;; table costs eight bytes and beats the shift loop it replaces at
        ;; every shift count.
        ;;
        ;; Arguments:
        ;;   A = shift count, 0..7
        ;;
        ;; Return:
        ;;   A = 0xFF >> count (a count of 0 gives 0xFF)
        ;;
        ;; Clobbers:
        ;;   AF, B
__gpx_ffshr::
        push    hl
        ld      hl,#.gb_ffshr_tab
        add     a,l
        ld      l,a
        jr      nc,.gb_ffshr_hi
        inc     h
.gb_ffshr_hi:
        ld      a,(hl)
        pop     hl
        ret

.gb_ffshr_tab:
        .db     0xff,0x7f,0x3f,0x1f,0x0f,0x07,0x03,0x01
        ;; .gb_span: A = bit (0..7) -> A = (bit + L_VISW + 7) >> 3
.gb_span:
        ;; bit+7 fits a byte; adding the width needs at most nine bits.
        ;; RRA consumes that ninth bit before the remaining two rotations.
        add     a,#7
        add     a,L_VISW(iy)
        rra
        rrca
        rrca
        and     #0x3f
        ret
