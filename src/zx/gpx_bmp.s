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

        .equ    SCRHEIGHT, 192
        .equ    BMP_SIG_ENC_MASK, 0xF0
        .equ    BMP_SIG_1BPP, 0x00
        .equ    BMP_SIG_1BPP_MASK, 0x10
        .equ    BMP_SIG_1BPP_COMPACT, 0x20
        .equ    BMP_SIG_1BPP_MASK_COMPACT, 0x30

        .area   _CODE

        ;; void gpx_draw_bmp(
        ;;   gpx_t *gpx,        HL (ignored)
        ;;   coord x,           DE
        ;;   coord y,           SP+2
        ;;   bmp_t *b,          SP+4
        ;;   const rect_t *clip SP+6
        ;; )
_gpx_draw_bmp::
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

        ;; Fast path handles only clip==NULL; clipped draws use fallback.
        ld      hl,#6
        add     hl,sp
        ld      a,(hl)
        inc     hl
        or      (hl)
        jp      nz,gb_fallback

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
        cp      #BMP_SIG_1BPP_COMPACT
        jr      z,gb_sig_unmasked_compact
        cp      #BMP_SIG_1BPP_MASK
        jp      z,gb_fallback
        cp      #BMP_SIG_1BPP_MASK_COMPACT
        jp      z,gb_fallback
        jp      gb_exit

gb_sig_unmasked_full:
        xor     a
        ld      (gb_compact),a
        jr      gb_sig_ok

gb_sig_unmasked_compact:
        ld      a,#1
        ld      (gb_compact),a

gb_sig_ok:
        ld      a,(gb_compact)
        or      a
        jr      nz,gb_sig_ok_compact

        inc     hl
        ld      a,(hl)
        ld      (gb_bw),a
        inc     hl
        ld      a,(hl)
        ld      (gb_bw_hi),a
        inc     hl
        ld      a,(hl)
        ld      (gb_bh),a
        inc     hl
        ld      a,(hl)
        ld      (gb_bh_hi),a
        inc     hl
        ld      a,(hl)
        ld      (gb_bstride),a
        inc     hl
        ld      a,(hl)
        ld      (gb_bstride+1),a
        jr      gb_sig_ok_done

gb_sig_ok_compact:
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

        inc     hl
        ld      a,(hl)
        ld      (gb_bstride),a
        xor     a
        ld      (gb_bstride+1),a

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

        ;; row stride
        ld      hl,(gb_bstride)
        ld      (gb_rowstride),hl

        ;; source row starts at bmp->bitmap
        ld      hl,(gb_bptr)
        ld      a,(gb_compact)
        or      a
        jr      z,gb_srcrow_full
        ld      de,#6
        jr      gb_srcrow_set
gb_srcrow_full:
        ld      de,#9
gb_srcrow_set:
        add     hl,de
        ld      (gb_srcrow),hl

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

        xor     a
        ld      (gb_remainder),a
        ld      (gb_bytecnt),a

        jp      gb_col_loop_unmasked


gb_col_loop_unmasked:
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

        ;; read source byte if c < srcspan
        ld      a,(gb_srcspan)
        cp      c
        jr      z,gb_um_no_src
        jr      c,gb_um_no_src

        ld      hl,(gb_srcptr)
        ld      a,(hl)
        inc     hl
        ld      (gb_srcptr),hl
        ld      (gb_rot),a

        ;; rotate right by rshift
        ld      a,(gb_rshift)
        or      a
        jr      z,gb_um_rot_done
        ld      b,a
        ld      a,(gb_rot)
gb_um_rot_loop:
        rrca
        djnz    gb_um_rot_loop
        ld      (gb_rot),a

gb_um_rot_done:
        ld      a,(gb_lmask)
        cpl
        ld      b,a
        ld      a,(gb_rot)
        and     b
        ld      (gb_fore),a
        jr      gb_um_have_src

gb_um_no_src:
        xor     a
        ld      (gb_rot),a
        ld      (gb_fore),a

gb_um_have_src:
        ;; draw bits = current fore + previous remainder
        ld      a,(gb_fore)
        ld      b,a
        ld      a,(gb_remainder)
        or      b
        ld      b,a

        ;; keep only inside bits for this destination byte
        ld      a,(gb_inside)
        and     b
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

        ;; next remainder = rot & lmask
        ld      a,(gb_rot)
        ld      b,a
        ld      a,(gb_lmask)
        and     b
        ld      (gb_remainder),a

        ;; advance destination pointer + counter
        ld      hl,(gb_dstptr)
        inc     hl
        ld      (gb_dstptr),hl

        ld      a,(gb_bytecnt)
        inc     a
        ld      (gb_bytecnt),a
        jp      gb_col_loop_unmasked


gb_next_row:
        ;; srcrow += rowstride
        ld      hl,(gb_srcrow)
        ld      de,(gb_rowstride)
        add     hl,de
        ld      (gb_srcrow),hl

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
gb_rowstride:
        .ds     2
gb_compact:
        .ds     1
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
gb_srcptr:
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
