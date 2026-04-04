        ;; gpx_bmp.s
        ;;
        ;; Hand-optimized ZX bitmap blitter.
        ;;
        ;; Fast path supports:
        ;; - BMP_ENC_1BPP
        ;; - BMP_ENC_1BPP_MASK (AND/OR composition)
        ;;
        ;; It precomputes visible width/height (screen + optional clip)
        ;; and then blits row/byte spans without per-pixel clip checks.

        .module gpx_bmp
        .optsdcc -mz80 sdcccall(1)

        .globl  _gpx_draw_bmp
        .globl  _gpx_draw_bmp_clip
        .globl  __gpx_bmp_color
        .globl  __gpx_bmp_mode

        .equ    SCRHEIGHT, 192
        .equ    BMP_SIG_ENC_MASK, 0xF0
        .equ    BMP_SIG_1BPP, 0x00
        .equ    BMP_SIG_1BPP_MASK, 0x10

        .area   _CODE

        ;; void gpx_draw_bmp(
        ;;   gpx_t *gpx,        HL (ignored)
        ;;   coord x,           DE
        ;;   coord y,           SP+2
        ;;   bmp_t *b,          SP+4
        ;;   const rect_t *clip SP+6
        ;; )
_gpx_draw_bmp::
        ;; Public bitmap API uses fixed CO_FORE/BM_CPY semantics.
        ld      a,#0x01
        ld      (__gpx_bmp_color),a
        xor     a
        ld      (__gpx_bmp_mode),a

        ;; Preserve incoming register args in case we need fallback later.
        ld      (gb_gpx),hl
        ld      a,e
        ld      (gb_x),a
        ld      a,d
        ld      (gb_xhi),a

        ;; Fast path requires x in 0..255.
        ld      a,d
        or      a
        jp      nz,gb_fallback

        ;; Save clip pointer (may be NULL).
        ld      hl,#6
        add     hl,sp
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ld      (gb_clip),de

        ;; Load y and bmp pointer.
        ld      hl,#2
        add     hl,sp
        ld      a,(hl)
        ld      (gb_y),a
        inc     hl
        ld      a,(hl)
        or      a
        jp      nz,gb_fallback

        inc     hl
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ld      (gb_bptr),de

        ;; Null bitmap -> return.
        ld      a,d
        or      e
        jp      z,gb_exit

        ;; y in 0..191 for fast path. (Negative/high handled by clip fallback.)
        ld      a,(gb_y)
        cp      #SCRHEIGHT
        jp      nc,gb_fallback

        ;; Validate encoding + parse metadata.
        ex      de,hl                  ;; HL = b
        ld      a,(hl)
        and     #BMP_SIG_ENC_MASK
        cp      #BMP_SIG_1BPP
        jr      z,gb_sig_unmasked_full
        cp      #BMP_SIG_1BPP_MASK
        jr      z,gb_sig_masked_full
        jp      gb_exit

gb_sig_unmasked_full:
        xor     a
        ld      (gb_is_masked),a
        jr      gb_sig_parse_full

gb_sig_masked_full:
        ld      a,#1
        ld      (gb_is_masked),a

gb_sig_parse_full:
        ;; stride is packed in signature low nibble as (stride-1).
        ld      a,(hl)
        and     #0x0F
        inc     a
        ld      (gb_bstride),a
        xor     a
        ld      (gb_bstride+1),a

        inc     hl
        ld      a,(hl)
        ld      (gb_bw),a
        xor     a
        ld      (gb_bw_hi),a
        inc     hl
        ld      a,(hl)
        ld      (gb_bh),a
        xor     a
        ld      (gb_bh_hi),a

gb_sig_ok_done:
        ;; w/h must be non-zero.
        ld      a,(gb_bw_hi)
        or      a
        jr      nz,gb_bw_nonzero
        ld      a,(gb_bw)
        or      a
        jp      z,gb_exit
gb_bw_nonzero:
        ld      a,(gb_bh_hi)
        or      a
        jr      nz,gb_bh_nonzero
        ld      a,(gb_bh)
        or      a
        jp      z,gb_exit
gb_bh_nonzero:

        ;; Default visibility limits: full screen.
        ld      a,#255
        ld      (gb_right_limit),a
        ld      a,#(SCRHEIGHT-1)
        ld      (gb_bottom_limit),a

        ;; Optional fast clip: only when clip is byte-range and does not
        ;; trim on left/top (no source offset required).
        ld      a,(gb_clip+1)
        ld      b,a
        ld      a,(gb_clip)
        or      b
        jr      z,gb_limits_ready

        ld      hl,(gb_clip)

        ;; x0 high:
        ;; - negative => no left trim needed
        ;; - zero     => enforce x >= x0
        ;; - positive => left trim needed (fallback)
        ld      c,(hl)                 ;; x0 lo
        inc     hl
        ld      a,(hl)                 ;; x0 hi
        bit     7,a
        jr      nz,gb_clip_y0
        or      a
        jp      nz,gb_fallback
        ld      a,(gb_x)
        cp      c
        jp      c,gb_fallback

gb_clip_y0:
        ;; y0 high:
        ;; - negative => no top trim needed
        ;; - zero     => enforce y >= y0
        ;; - positive => top trim needed (fallback)
        inc     hl
        ld      c,(hl)                 ;; y0 lo
        inc     hl
        ld      a,(hl)                 ;; y0 hi
        bit     7,a
        jr      nz,gb_clip_x1
        or      a
        jp      nz,gb_fallback
        ld      a,(gb_y)
        cp      c
        jp      c,gb_fallback

gb_clip_x1:
        ;; x1 high:
        ;; - negative => nothing visible for x>=0
        ;; - zero     => right limit = x1
        ;; - positive => right limit stays 255 (no restriction)
        inc     hl
        ld      a,(hl)                 ;; x1 lo
        ld      c,a
        inc     hl
        ld      a,(hl)                 ;; x1 hi
        bit     7,a
        jp      nz,gb_exit
        or      a
        jr      nz,gb_clip_y1
        ld      a,c
        ld      (gb_right_limit),a

        ;; If start x is right of clip right edge -> nothing visible.
        ld      a,(gb_right_limit)
        ld      c,a
        ld      a,(gb_x)
        cp      c
        jr      c,gb_clip_y1
        jr      z,gb_clip_y1
        jp      gb_exit

gb_clip_y1:
        ;; y1 high:
        ;; - negative => nothing visible for y>=0
        ;; - zero     => bottom limit = min(y1,191)
        ;; - positive => bottom limit stays 191 (no restriction)
        inc     hl
        ld      a,(hl)                 ;; y1 lo
        ld      c,a
        inc     hl
        ld      a,(hl)                 ;; y1 hi
        bit     7,a
        jp      nz,gb_exit
        or      a
        jr      nz,gb_clip_y1_chk
        ld      a,c
        cp      #(SCRHEIGHT-1)
        jr      c,gb_clip_y1_set
        ld      a,#(SCRHEIGHT-1)
gb_clip_y1_set:
        ld      (gb_bottom_limit),a

gb_clip_y1_chk:
        ;; If start y is below clip bottom edge -> nothing visible.
        ld      a,(gb_bottom_limit)
        ld      c,a
        ld      a,(gb_y)
        cp      c
        jr      c,gb_limits_ready
        jr      z,gb_limits_ready
        jp      gb_exit

gb_limits_ready:

        ;; visw = min(bitmap width, right_limit - x + 1)
        ld      a,(gb_bw_hi)
        or      a
        jr      z,gb_w_from_low
        ld      a,#255
        jr      gb_w_have

gb_w_from_low:
        ld      a,(gb_bw)

gb_w_have:
        ld      b,a

        ;; x == 0 means the remaining visible span is 256 pixels.
        ;; The 8-bit `right_limit - x + 1` path below would wrap to 0,
        ;; so keep the bitmap width unchanged in that case.
        ld      a,(gb_x)
        or      a
        jr      z,gb_w_clipped

        ld      a,(gb_right_limit)
        ld      c,a
        ld      a,(gb_x)
        ld      d,a
        ld      a,c
        sub     d
        inc     a
        cp      b
        jr      nc,gb_w_clipped
        ld      b,a

gb_w_clipped:
        ld      a,b
        ld      (gb_visw),a
        or      a
        jp      z,gb_exit

        ;; vish = min(bitmap height, bottom_limit - y + 1)
        ld      a,(gb_bh_hi)
        or      a
        jr      z,gb_h_from_low
        ld      a,#SCRHEIGHT
        jr      gb_h_have

gb_h_from_low:
        ld      a,(gb_bh)

gb_h_have:
        ld      e,a

        ld      a,(gb_bottom_limit)
        ld      c,a
        ld      a,(gb_y)
        ld      b,a
        ld      a,c
        sub     b
        inc     a
        cp      e
        jr      nc,gb_h_clipped
        ld      e,a

gb_h_clipped:
        ld      a,e
        ld      (gb_vish),a
        or      a
        jp      z,gb_exit

        ;; xbyte = x >> 3, rshift = x & 7
        ld      a,(gb_x)
        and     #0x07
        ld      (gb_rshift),a
        ld      a,(gb_x)
        srl     a
        srl     a
        srl     a
        ld      (gb_xbyte),a

        ;; lmask = ~(0xff >> rshift)
        ld      a,(gb_rshift)
        or      a
        jr      z,gb_lmask_zero
        ld      b,a
        ld      a,#0xff
gb_lmask_loop:
        srl     a
        djnz    gb_lmask_loop
        cpl
        ld      (gb_lmask),a
        jr      gb_lmask_done

gb_lmask_zero:
        xor     a
        ld      (gb_lmask),a

gb_lmask_done:
        ;; rmask = 0xff >> ((x + visw) & 7), with 0 -> 0
        ld      a,(gb_x)
        ld      b,a
        ld      a,(gb_visw)
        add     a,b
        and     #0x07
        jr      z,gb_rmask_zero
        ld      b,a
        ld      a,#0xff
gb_rmask_loop:
        srl     a
        djnz    gb_rmask_loop
        ld      (gb_rmask),a
        jr      gb_rmask_done

gb_rmask_zero:
        xor     a
        ld      (gb_rmask),a

gb_rmask_done:
        ;; srcspan = (visw + 7) >> 3
        xor     a
        ld      h,a
        ld      a,(gb_visw)
        ld      l,a
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
        ld      (gb_srcspan),a

        ;; dstspan = (rshift + visw + 7) >> 3
        xor     a
        ld      h,a
        ld      a,(gb_rshift)
        ld      l,a
        ld      a,(gb_visw)
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
        ld      (gb_dstspan),a
        dec     a
        ld      (gb_dstlast),a

        ;; source row pointers + independent row strides:
        ;; - AND row (mask plane, or synthetic 0xFF for unmasked)
        ;; - OR row  (bitmap plane)
        ld      hl,(gb_bptr)
        ld      de,#5
        add     hl,de

        ;; unmasked: AND=0xFF stream (step 0), OR=bitmap row (step stride)
        ;; masked:   AND=mask row (step stride*2), OR=mask+stride (step stride*2)
        ld      a,(gb_is_masked)
        or      a
        jr      z,gb_rows_unmasked

        ;; masked rows
        ld      (gb_srcrow),hl

        ld      de,(gb_bstride)
        add     hl,de
        ld      (gb_srcrow_or),hl

        ld      hl,(gb_bstride)
        add     hl,hl
        ld      (gb_rowstride_and),hl
        ld      (gb_rowstride_or),hl
        jr      gb_rows_ready

gb_rows_unmasked:
        ld      (gb_srcrow_or),hl
        ld      hl,#gb_ff_pad
        ld      (gb_srcrow),hl
        xor     a
        ld      l,a
        ld      h,a
        ld      (gb_rowstride_and),hl
        ld      hl,(gb_bstride)
        ld      (gb_rowstride_or),hl

gb_rows_ready:
        xor     a
        ld      (gb_rowcnt),a
        ld      a,(gb_y)
        ld      (gb_ycur),a

gb_row_loop:
        ;; done when rowcnt == vish
        ld      a,(gb_rowcnt)
        ld      b,a
        ld      a,(gb_vish)
        cp      b
        jp      z,gb_exit

        ;; row destination base + xbyte
        ld      a,(gb_ycur)
        ld      b,a
        call    gb_rowaddr
        ld      a,(gb_xbyte)
        add     a,l
        ld      l,a
        ld      (gb_dstptr),hl

        ld      hl,(gb_srcrow)
        ld      (gb_srcptr),hl
        ld      hl,(gb_srcrow_or)
        ld      (gb_srcptr_or),hl

        xor     a
        ld      (gb_remainder),a
        ld      (gb_remainder_or),a
        ld      (gb_bytecnt),a

        jp      gb_col_loop_compose


gb_col_loop_compose:
        ld      a,(gb_bytecnt)
        ld      c,a
        ld      a,(gb_dstspan)
        cp      c
        jp      z,gb_next_row

        ;; old destination byte
        ld      hl,(gb_dstptr)
        ld      a,(hl)
        ld      (gb_old),a

        ;; keep mask for outside bits (left/right edges)
        xor     a
        ld      (gb_keep),a

        ld      a,c
        or      a
        jr      nz,gb_um_not_first
        ld      a,(gb_lmask)
        ld      (gb_keep),a

gb_um_not_first:
        ld      a,(gb_dstlast)
        cp      c
        jr      nz,gb_um_keep_ready
        ld      a,(gb_keep)
        ld      b,a
        ld      a,(gb_rmask)
        or      b
        ld      (gb_keep),a

gb_um_keep_ready:
        ld      a,(gb_keep)
        cpl
        ld      (gb_inside),a

        ;; read source bytes if c < srcspan
        ld      a,(gb_srcspan)
        cp      c
        jr      z,gb_cm_no_src
        jr      c,gb_cm_no_src

        ;; AND source byte (masked row or synthetic 0xFF row for unmasked)
        ld      hl,(gb_srcptr)
        ld      a,(hl)
        inc     hl
        ld      (gb_srcptr),hl
        ld      (gb_rot),a

        ;; rotate right by rshift
        ld      a,(gb_rshift)
        or      a
        jr      z,gb_cm_and_rot_done
        ld      b,a
        ld      a,(gb_rot)
gb_cm_and_rot_loop:
        rrca
        djnz    gb_cm_and_rot_loop
        ld      (gb_rot),a

gb_cm_and_rot_done:
        ld      a,(gb_lmask)
        cpl
        ld      b,a
        ld      a,(gb_rot)
        and     b
        ld      b,a
        ld      a,(gb_remainder)
        or      b
        ld      (gb_fore),a

        ;; next AND remainder = rot & lmask
        ld      a,(gb_rot)
        ld      b,a
        ld      a,(gb_lmask)
        and     b
        ld      (gb_remainder),a

        ;; OR source byte
        ld      hl,(gb_srcptr_or)
        ld      a,(hl)
        inc     hl
        ld      (gb_srcptr_or),hl
        ld      (gb_rot),a

        ;; rotate right by rshift
        ld      a,(gb_rshift)
        or      a
        jr      z,gb_cm_or_rot_done
        ld      b,a
        ld      a,(gb_rot)
gb_cm_or_rot_loop:
        rrca
        djnz    gb_cm_or_rot_loop
        ld      (gb_rot),a

gb_cm_or_rot_done:
        ld      a,(gb_lmask)
        cpl
        ld      b,a
        ld      a,(gb_rot)
        and     b
        ld      b,a
        ld      a,(gb_remainder_or)
        or      b
        ld      (gb_orbits),a

        ;; next OR remainder = rot & lmask
        ld      a,(gb_rot)
        ld      b,a
        ld      a,(gb_lmask)
        and     b
        ld      (gb_remainder_or),a
        jr      gb_cm_have_src

gb_cm_no_src:
        ;; flush pending carry bits from both planes
        ld      a,(gb_remainder)
        ld      (gb_fore),a
        xor     a
        ld      (gb_remainder),a

        ld      a,(gb_remainder_or)
        ld      (gb_orbits),a
        xor     a
        ld      (gb_remainder_or),a

gb_cm_have_src:
        ;; and_inside = and_aligned & inside
        ld      a,(gb_fore)
        ld      b,a
        ld      a,(gb_inside)
        and     b
        ld      (gb_fore),a

        ;; draw = (old & and_inside) | (or_aligned & inside)
        ld      a,(gb_old)
        ld      b,a
        ld      a,(gb_fore)
        and     b
        ld      (gb_draw),a

        ld      a,(gb_orbits)
        ld      b,a
        ld      a,(gb_inside)
        and     b
        ld      b,a

        ld      a,(gb_draw)
        or      b
        ld      (gb_draw),a

        ;; out = (old & keep) | draw
        ld      a,(gb_old)
        ld      b,a
        ld      a,(gb_keep)
        and     b
        ld      b,a
        ld      a,(gb_draw)
        or      b
        ld      hl,(gb_dstptr)
        ld      (hl),a

        ;; advance destination pointer + counter
        ld      hl,(gb_dstptr)
        inc     hl
        ld      (gb_dstptr),hl

        ld      a,(gb_bytecnt)
        inc     a
        ld      (gb_bytecnt),a
        jp      gb_col_loop_compose


gb_next_row:
        ;; AND srcrow += and_rowstride
        ld      hl,(gb_srcrow)
        ld      de,(gb_rowstride_and)
        add     hl,de
        ld      (gb_srcrow),hl

        ;; OR srcrow += or_rowstride
        ld      hl,(gb_srcrow_or)
        ld      de,(gb_rowstride_or)
        add     hl,de
        ld      (gb_srcrow_or),hl

        ;; ycur++, rowcnt++
        ld      a,(gb_ycur)
        inc     a
        ld      (gb_ycur),a

        ld      a,(gb_rowcnt)
        inc     a
        ld      (gb_rowcnt),a
        jp      gb_row_loop


gb_fallback:
        ld      hl,(gb_gpx)
        ld      a,(gb_x)
        ld      e,a
        ld      a,(gb_xhi)
        ld      d,a
        jp      _gpx_draw_bmp_clip

gb_exit:
        ;; callee cleanup: y(2), b(2), clip(2)
        pop     hl
        pop     af
        pop     af
        pop     af
        jp      (hl)


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


        .area   _DATA
gb_gpx:
        .ds     2
gb_x:
        .ds     1
gb_xhi:
        .ds     1
gb_y:
        .ds     1
gb_clip:
        .ds     2
gb_bptr:
        .ds     2
gb_bw:
        .ds     1
gb_bw_hi:
        .ds     1
gb_bh:
        .ds     1
gb_bh_hi:
        .ds     1
gb_bstride:
        .ds     2
gb_rowstride_and:
        .ds     2
gb_rowstride_or:
        .ds     2
gb_right_limit:
        .ds     1
gb_bottom_limit:
        .ds     1
gb_visw:
        .ds     1
gb_vish:
        .ds     1
gb_xbyte:
        .ds     1
gb_rshift:
        .ds     1
gb_lmask:
        .ds     1
gb_rmask:
        .ds     1
gb_srcspan:
        .ds     1
gb_dstspan:
        .ds     1
gb_dstlast:
        .ds     1
gb_srcrow:
        .ds     2
gb_srcrow_or:
        .ds     2
gb_srcptr:
        .ds     2
gb_srcptr_or:
        .ds     2
gb_dstptr:
        .ds     2
gb_rowcnt:
        .ds     1
gb_bytecnt:
        .ds     1
gb_ycur:
        .ds     1
gb_old:
        .ds     1
gb_keep:
        .ds     1
gb_inside:
        .ds     1
gb_fore:
        .ds     1
gb_rot:
        .ds     1
gb_remainder:
        .ds     1
gb_draw:
        .ds     1
gb_remainder_or:
        .ds     1
gb_orbits:
        .ds     1
gb_is_masked:
        .ds     1
gb_ff_pad:
        .db     0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff
        .db     0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff
        .db     0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff
        .db     0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff
