        ;; gpx_bmp_clip.s
        ;;
        ;; Compact clipped bitmap renderer.
        ;; Generic fallback path used by gpx_bmp fast dispatcher.

        .module gpx_bmp_clip
        .optsdcc -mz80 sdcccall(1)

        .globl  _gpx_draw_bmp_clip
        .globl  _gpx_draw_pixel

        .equ    BMP_SIG_ENC_MASK,         0xF0
        .equ    BMP_SIG_1BPP,             0x00
        .equ    BMP_SIG_1BPP_MASK,        0x10
        .equ    BMP_SIG_1BPP_COMPACT,     0x20
        .equ    BMP_SIG_1BPP_MASK_COMPACT,0x30

        .area   _CODE

        ;; void gpx_draw_bmp_clip(gpx_t *gpx, coord x, coord y, bmp_t *b, const rect_t *clip)
        ;; HL = gpx
        ;; DE = x
        ;; stack: y, b, clip
_gpx_draw_bmp_clip::
        push    ix
        ld      ix,#0
        add     ix,sp

        ;; locals (33 bytes)
        ;; -1..-2   gpx
        ;; -3..-4   x0
        ;; -5..-6   y0
        ;; -7..-8   bmp ptr
        ;; -9..-10  clip ptr
        ;; -11..-12 w
        ;; -13..-14 h
        ;; -15..-16 stride (or row step when masked)
        ;; -17..-18 data ptr / row step temp
        ;; -19      (unused/reserved)
        ;; -20..-21 ycur
        ;; -22..-23 row remain
        ;; -24..-25 row ptr
        ;; -26..-27 xcur
        ;; -28..-29 col remain
        ;; -30      bit mask
        ;; -31..-32 src byte ptr
        ;; -33      src byte cache
        ld      hl,#-33
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
        cp      #BMP_SIG_1BPP_COMPACT
        jp      z,.gbc_compact_unmasked
        cp      #BMP_SIG_1BPP_MASK_COMPACT
        jp      z,.gbc_compact_masked
        jp      .gbc_done

.gbc_full_unmasked:
        inc     hl
        ld      a,(hl)
        ld      -11(ix),a              ;; w lo
        inc     hl
        ld      a,(hl)
        ld      -12(ix),a              ;; w hi

        inc     hl
        ld      a,(hl)
        ld      -13(ix),a              ;; h lo
        inc     hl
        ld      a,(hl)
        ld      -14(ix),a              ;; h hi

        inc     hl
        ld      a,(hl)
        ld      -15(ix),a              ;; stride lo
        inc     hl
        ld      a,(hl)
        ld      -16(ix),a              ;; stride hi

        inc     hl                     ;; size lo
        inc     hl                     ;; size hi
        inc     hl                     ;; bitmap
        ld      -17(ix),l              ;; data lo
        ld      -18(ix),h              ;; data hi
        jp      .gbc_dims_ok

.gbc_full_masked:
        inc     hl
        ld      a,(hl)
        ld      -11(ix),a              ;; w lo
        inc     hl
        ld      a,(hl)
        ld      -12(ix),a              ;; w hi

        inc     hl
        ld      a,(hl)
        ld      -13(ix),a              ;; h lo
        inc     hl
        ld      a,(hl)
        ld      -14(ix),a              ;; h hi

        inc     hl
        ld      a,(hl)
        ld      -15(ix),a              ;; stride lo
        inc     hl
        ld      a,(hl)
        ld      -16(ix),a              ;; stride hi

        inc     hl                     ;; size lo
        inc     hl                     ;; size hi
        inc     hl                     ;; bitmap starts with mask plane

        ;; for masked payload, use bmp plane at +stride
        ld      e,-15(ix)
        ld      d,-16(ix)
        add     hl,de
        ld      -17(ix),l
        ld      -18(ix),h

        ;; row step becomes stride*2
        ld      a,-15(ix)
        add     a,-15(ix)
        ld      -15(ix),a
        ld      a,-16(ix)
        adc     a,-16(ix)
        ld      -16(ix),a
        jp      .gbc_dims_ok

.gbc_compact_unmasked:
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

        inc     hl
        ld      a,(hl)
        ld      -15(ix),a              ;; stride lo
        xor     a
        ld      -16(ix),a              ;; stride hi

        inc     hl                     ;; size lo
        inc     hl                     ;; size hi
        inc     hl                     ;; bitmap
        ld      -17(ix),l
        ld      -18(ix),h
        jp      .gbc_dims_ok

.gbc_compact_masked:
        inc     hl
        ld      a,(hl)
        ld      -11(ix),a              ;; w lo
        xor     a
        ld      -12(ix),a

        inc     hl
        ld      a,(hl)
        ld      -13(ix),a              ;; h lo
        xor     a
        ld      -14(ix),a

        inc     hl
        ld      a,(hl)
        ld      -15(ix),a              ;; stride lo
        xor     a
        ld      -16(ix),a

        inc     hl                     ;; size lo
        inc     hl                     ;; size hi
        inc     hl                     ;; mask plane

        ;; bmp plane at +stride
        ld      e,-15(ix)
        ld      d,#0x00
        add     hl,de
        ld      -17(ix),l
        ld      -18(ix),h

        ;; row step = stride*2
        ld      a,-15(ix)
        add     a,-15(ix)
        ld      -15(ix),a
        xor     a
        adc     a,a
        ld      -16(ix),a

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

        ld      a,-17(ix)
        ld      -24(ix),a              ;; row ptr lo
        ld      a,-18(ix)
        ld      -25(ix),a              ;; row ptr hi

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

        ;; src byte ptr = row ptr, mask = 0x80
        ld      a,-24(ix)
        ld      -31(ix),a
        ld      a,-25(ix)
        ld      -32(ix),a
        ld      a,#0x80
        ld      -30(ix),a

        ;; preload first source byte
        ld      l,-31(ix)
        ld      h,-32(ix)
        ld      a,(hl)
        ld      -33(ix),a

.gbc_col_loop:
        ld      a,-28(ix)
        or      -29(ix)
        jr      z,.gbc_row_done

        ld      a,-33(ix)
        and     -30(ix)
        jr      z,.gbc_skip_pixel

        ;; draw foreground pixel
        ld      l,-9(ix)
        ld      h,-10(ix)
        push    hl                     ;; clip

        ld      l,#0x01                ;; CO_FORE
        ld      h,#0x00                ;; BM_CPY
        push    hl

        ld      l,-20(ix)
        ld      h,-21(ix)
        push    hl                     ;; y

        ld      l,-1(ix)
        ld      h,-2(ix)
        ld      e,-26(ix)
        ld      d,-27(ix)
        call    _gpx_draw_pixel

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

        ;; next source byte
        ld      l,-31(ix)
        ld      h,-32(ix)
        inc     hl
        ld      -31(ix),l
        ld      -32(ix),h
        ld      a,(hl)
        ld      -33(ix),a
        ld      a,#0x80

.gbc_store_mask:
        ld      -30(ix),a
        jr      .gbc_col_loop

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

        ;; row_ptr += row_step
        ld      l,-24(ix)
        ld      h,-25(ix)
        ld      e,-15(ix)
        ld      d,-16(ix)
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
