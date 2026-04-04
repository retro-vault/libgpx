        ;; _gpx_bmp_clip.s
        ;;
        ;; Compact clipped bitmap renderer.
        ;; Generic fallback path used by gpx_bmp fast dispatcher.

        .module _gpx_bmp_clip
        .optsdcc -mz80 sdcccall(1)

        .globl  _gpx_draw_bmp_clip
        .globl  __vid_rowaddr
        .globl  __gpx_bmp_color
        .globl  __gpx_bmp_mode

        .equ    BMP_SIG_ENC_MASK,         0xF0
        .equ    BMP_SIG_1BPP,             0x00
        .equ    BMP_SIG_1BPP_MASK,        0x10

        .area   _CODE

        ;; void gpx_draw_bmp_clip(gpx_t *gpx, coord x, coord y, bmp_t *b, const rect_t *clip)
        ;; HL = gpx
        ;; DE = x
        ;; stack: y, b, clip
_gpx_draw_bmp_clip::
        push    ix
        ld      ix,#0
        add     ix,sp

        ;; locals (38 bytes)
        ;; -1..-2   gpx
        ;; -3..-4   x0
        ;; -5..-6   y0
        ;; -7..-8   bmp ptr
        ;; -9..-10  clip ptr
        ;; -11..-12 w
        ;; -13..-14 h
        ;; -15..-16 OR row step (stride, or stride*2 when masked)
        ;; -17..-18 OR row ptr
        ;; -19      reserved
        ;; -20..-21 ycur
        ;; -22..-23 row remain
        ;; -24..-25 AND row ptr
        ;; -26..-27 xcur
        ;; -28..-29 col remain
        ;; -30      bit mask
        ;; -31..-32 OR src byte ptr
        ;; -33      OR src byte cache
        ;; -34..-35 AND src byte ptr
        ;; -36      AND src byte cache
        ;; -37..-38 AND row step (0 for unmasked, stride*2 for masked)
        ld      hl,#-38
        add     hl,sp
        ld      sp,hl

        ;; save args
        ld      -1(ix),l               ;; gpx lo
        ld      -2(ix),h               ;; gpx hi

        ld      -3(ix),e               ;; x lo
        ld      -4(ix),d               ;; x hi

        ld      a,4(ix)                ;; y lo
        ld      -5(ix),a
        ld      a,5(ix)                ;; y hi
        ld      -6(ix),a

        ld      a,6(ix)                ;; bmp lo
        ld      -7(ix),a
        ld      a,7(ix)                ;; bmp hi
        ld      -8(ix),a

        ld      a,8(ix)                ;; clip lo
        ld      -9(ix),a
        ld      a,9(ix)                ;; clip hi
        ld      -10(ix),a

        ;; if (!bmp) return
        ld      a,-7(ix)
        or      -8(ix)
        jp      z,.gbc_done

        ;; parse signature
        ld      l,-7(ix)
        ld      h,-8(ix)
        ld      a,(hl)
        and     #BMP_SIG_ENC_MASK
        cp      #BMP_SIG_1BPP
        jr      z,.gbc_full_unmasked
        cp      #BMP_SIG_1BPP_MASK
        jr      z,.gbc_full_masked
        jp      .gbc_done

.gbc_full_unmasked:
        ;; compact header:
        ;; +0 signature (stride in low nibble as stride-1)
        ;; +1 width, +2 height, +3 size lo, +4 size hi, +5 bitmap
        ld      a,(hl)
        and     #0x0F
        inc     a
        ld      -15(ix),a              ;; stride lo
        xor     a
        ld      -16(ix),a              ;; stride hi
        ld      -37(ix),a              ;; AND row step lo = 0
        ld      -38(ix),a              ;; AND row step hi = 0

        inc     hl
        ld      a,(hl)
        ld      -11(ix),a              ;; w lo
        xor     a
        ld      -12(ix),a              ;; w hi

        inc     hl
        ld      a,(hl)
        ld      -13(ix),a              ;; h lo
        xor     a
        ld      -14(ix),a              ;; h hi

        inc     hl                     ;; size lo
        inc     hl                     ;; size hi
        inc     hl                     ;; bitmap
        ld      -17(ix),l              ;; OR row ptr lo
        ld      -18(ix),h              ;; OR row ptr hi

        ld      hl,#gbc_ff_pad         ;; AND row ptr = synthetic 0xFF stream
        ld      -24(ix),l
        ld      -25(ix),h
        jp      .gbc_dims_ok

.gbc_full_masked:
        ld      a,(hl)
        and     #0x0F
        inc     a
        ld      -37(ix),a              ;; mask stride lo (temp)
        xor     a
        ld      -38(ix),a              ;; mask stride hi (temp)

        inc     hl
        ld      a,(hl)
        ld      -11(ix),a              ;; w lo
        xor     a
        ld      -12(ix),a              ;; w hi

        inc     hl
        ld      a,(hl)
        ld      -13(ix),a              ;; h lo
        xor     a
        ld      -14(ix),a              ;; h hi

        inc     hl                     ;; size lo
        inc     hl                     ;; size hi
        inc     hl                     ;; bitmap starts with mask plane

        ;; AND row ptr starts at mask plane
        ld      -24(ix),l
        ld      -25(ix),h

        ;; OR row ptr = AND row ptr + mask_stride
        ld      e,-37(ix)
        ld      d,-38(ix)
        add     hl,de
        ld      -17(ix),l
        ld      -18(ix),h

        ;; row step = mask_stride * 2 (for OR rows)
        ld      a,-37(ix)
        add     a,-37(ix)
        ld      -15(ix),a
        ld      a,-38(ix)
        adc     a,-38(ix)
        ld      -16(ix),a

        ;; AND rows advance with the same step
        ld      a,-15(ix)
        ld      -37(ix),a
        ld      a,-16(ix)
        ld      -38(ix),a
        jp      .gbc_dims_ok

.gbc_dims_ok:
        ;; reject empty width/height
        ld      a,-11(ix)
        or      -12(ix)
        jp      z,.gbc_done
        ld      a,-13(ix)
        or      -14(ix)
        jp      z,.gbc_done

        ;; init row loop
        ld      a,-5(ix)
        ld      -20(ix),a              ;; ycur lo
        ld      a,-6(ix)
        ld      -21(ix),a              ;; ycur hi

        ld      a,-13(ix)
        ld      -22(ix),a              ;; rows lo
        ld      a,-14(ix)
        ld      -23(ix),a              ;; rows hi

.gbc_row_loop:
        ld      a,-22(ix)
        or      -23(ix)
        jp      z,.gbc_done

        ;; xcur = x0
        ld      a,-3(ix)
        ld      -26(ix),a
        ld      a,-4(ix)
        ld      -27(ix),a

        ;; col remain = w
        ld      a,-11(ix)
        ld      -28(ix),a
        ld      a,-12(ix)
        ld      -29(ix),a

        ;; OR src byte ptr = OR row ptr, mask = 0x80
        ld      a,-17(ix)
        ld      -31(ix),a
        ld      a,-18(ix)
        ld      -32(ix),a
        ld      a,#0x80
        ld      -30(ix),a

        ;; AND src byte ptr = AND row ptr
        ld      a,-24(ix)
        ld      -34(ix),a
        ld      a,-25(ix)
        ld      -35(ix),a

        ;; preload OR cache
        ld      l,-31(ix)
        ld      h,-32(ix)
        ld      a,(hl)
        ld      -33(ix),a

        ;; preload AND cache
        ld      l,-34(ix)
        ld      h,-35(ix)
        ld      a,(hl)
        ld      -36(ix),a

.gbc_col_loop:
        ld      a,-28(ix)
        or      -29(ix)
        jp      z,.gbc_row_done

        ;; OR bit for current pixel
        ld      a,-33(ix)
        and     -30(ix)
        ld      b,a

        ;; Public gpx_draw_bmp uses CO_FORE/BM_CPY.
        ;; Mode-aware path (used by gpx_draw_bmp_mode_internal) draws from OR bits.
        ld      a,(__gpx_bmp_mode)
        or      a
        jr      nz,.gbc_mode_color_path
        ld      a,(__gpx_bmp_color)
        cp      #0x01
        jr      nz,.gbc_mode_color_path

        ;; default compositor:
        ;; if (AND) draw OR ? FORE : skip
        ;; else     draw OR ? FORE : BACK
        ld      a,-36(ix)
        and     -30(ix)
        jr      z,.gbc_masked_clear_or_set
        ld      a,b
        or      a
        jp      z,.gbc_skip_pixel
        ld      a,#0x01
        jr      .gbc_draw_color

.gbc_masked_clear_or_set:
        ld      a,b
        or      a
        ld      a,#0x00
        jr      z,.gbc_draw_color
        ld      a,#0x01
        jr      .gbc_draw_color

.gbc_mode_color_path:
        ;; non-default mode/color:
        ;; draw only where OR bit is set.
        ld      a,b
        or      a
        jp      z,.gbc_skip_pixel
        ld      a,(__gpx_bmp_color)

.gbc_draw_color:
        ;; draw pixel inline, honoring screen bounds + clip
        ld      e,a

        ;; x must be 0..255
        ld      a,-27(ix)              ;; x hi
        or      a
        jp      m,.gbc_skip_pixel
        jp      nz,.gbc_skip_pixel

        ;; y must be 0..191
        ld      a,-21(ix)              ;; y hi
        or      a
        jp      m,.gbc_skip_pixel
        jp      nz,.gbc_skip_pixel
        ld      a,-20(ix)              ;; y lo
        cp      #192
        jp      nc,.gbc_skip_pixel

        ;; optional clip
        ld      a,-9(ix)
        or      -10(ix)
        jr      z,.gbc_plot

        ;; if (x < clip->x0) reject
        ld      l,-9(ix)
        ld      h,-10(ix)
        ld      c,(hl)                 ;; x0 lo
        inc     hl
        ld      a,(hl)                 ;; x0 hi
        bit     7,a
        jr      nz,.gbc_clip_y0
        or      a
        jp      nz,.gbc_skip_pixel
        ld      a,-26(ix)              ;; x lo
        cp      c
        jp      c,.gbc_skip_pixel

.gbc_clip_y0:
        ;; if (y < clip->y0) reject
        inc     hl
        ld      c,(hl)                 ;; y0 lo
        inc     hl
        ld      a,(hl)                 ;; y0 hi
        bit     7,a
        jr      nz,.gbc_clip_x1
        or      a
        jp      nz,.gbc_skip_pixel
        ld      a,-20(ix)              ;; y lo
        cp      c
        jp      c,.gbc_skip_pixel

.gbc_clip_x1:
        ;; if (x > clip->x1) reject
        inc     hl
        ld      c,(hl)                 ;; x1 lo
        inc     hl
        ld      a,(hl)                 ;; x1 hi
        bit     7,a
        jp      nz,.gbc_skip_pixel
        or      a
        jr      nz,.gbc_clip_y1
        ld      a,c
        cp      -26(ix)                ;; x1 < x ?
        jp      c,.gbc_skip_pixel

.gbc_clip_y1:
        ;; if (y > clip->y1) reject
        inc     hl
        ld      c,(hl)                 ;; y1 lo
        inc     hl
        ld      a,(hl)                 ;; y1 hi
        bit     7,a
        jp      nz,.gbc_skip_pixel
        or      a
        jr      nz,.gbc_plot
        ld      a,c
        cp      -20(ix)                ;; y1 < y ?
        jp      c,.gbc_skip_pixel

.gbc_plot:
        ;; HL = row base for y
        ld      b,-20(ix)              ;; y lo
        call    __vid_rowaddr

        ;; HL += x>>3
        ld      a,-26(ix)              ;; x lo
        srl     a
        srl     a
        srl     a
        add     a,l
        ld      l,a

        ;; C = 0x80 >> (x & 7)
        ld      a,-26(ix)
        and     #0x07
        ld      d,a
        ld      a,#0x80
        jr      z,.gbc_mask_ready
.gbc_mask_loop:
        srl     a
        dec     d
        jr      nz,.gbc_mask_loop
.gbc_mask_ready:
        ld      c,a

        ;; apply mode/color
        ld      a,(__gpx_bmp_mode)
        bit     0,a
        jr      nz,.gbc_xor_pixel

        ;; BM_CPY color in E bit0 => set/clear
        ld      a,e
        bit     0,a
        jr      nz,.gbc_set_pixel

        ;; clear
        ld      a,c
        cpl
        and     (hl)
        ld      (hl),a
        jr      .gbc_skip_pixel

.gbc_set_pixel:
        ld      a,c
        or      (hl)
        ld      (hl),a
        jr      .gbc_skip_pixel

.gbc_xor_pixel:
        ld      a,c
        xor     (hl)
        ld      (hl),a

.gbc_skip_pixel:
        ;; xcur++
        ld      l,-26(ix)
        ld      h,-27(ix)
        inc     hl
        ld      -26(ix),l
        ld      -27(ix),h

        ;; col--
        ld      l,-28(ix)
        ld      h,-29(ix)
        dec     hl
        ld      -28(ix),l
        ld      -29(ix),h

        ;; advance bit mask and source byte pointer
        ld      a,-30(ix)
        srl     a
        jr      nz,.gbc_store_mask

        ;; next OR source byte
        ld      l,-31(ix)
        ld      h,-32(ix)
        inc     hl
        ld      -31(ix),l
        ld      -32(ix),h
        ld      a,(hl)
        ld      -33(ix),a

        ;; next AND source byte
        ld      l,-34(ix)
        ld      h,-35(ix)
        inc     hl
        ld      -34(ix),l
        ld      -35(ix),h
        ld      a,(hl)
        ld      -36(ix),a

        ld      a,#0x80

.gbc_store_mask:
        ld      -30(ix),a
        jp      .gbc_col_loop

.gbc_row_done:
        ;; ycur++
        ld      l,-20(ix)
        ld      h,-21(ix)
        inc     hl
        ld      -20(ix),l
        ld      -21(ix),h

        ;; rows--
        ld      l,-22(ix)
        ld      h,-23(ix)
        dec     hl
        ld      -22(ix),l
        ld      -23(ix),h

        ;; OR row ptr += OR row_step
        ld      l,-17(ix)
        ld      h,-18(ix)
        ld      e,-15(ix)
        ld      d,-16(ix)
        add     hl,de
        ld      -17(ix),l
        ld      -18(ix),h

        ;; AND row ptr += AND row_step
        ld      l,-24(ix)
        ld      h,-25(ix)
        ld      e,-37(ix)
        ld      d,-38(ix)
        add     hl,de
        ld      -24(ix),l
        ld      -25(ix),h

        jp      .gbc_row_loop

.gbc_done:
        ld      sp,ix
        pop     ix

        ;; callee cleanup: y(2), bmp(2), clip(2)
        pop     de
        ld      hl,#6
        add     hl,sp
        ld      sp,hl
        push    de
        ret

        .area   _DATA
gbc_ff_pad:
        .db     0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff
        .db     0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff
        .db     0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff
        .db     0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff
__gpx_bmp_color::
        .db     0x01
__gpx_bmp_mode::
        .db     0x00
