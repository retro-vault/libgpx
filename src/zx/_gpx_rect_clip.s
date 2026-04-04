        ;; _gpx_rect_clip.s
        ;;
        ;; Rectangle helper routines in Z80 assembly.

        .module _gpx_rect_clip
        .optsdcc -mz80 sdcccall(1)

        .globl  __gpx_clip_rect_effective
        .globl  __gpx_point_in_rect
        .globl  __gpx_line_needs_clip
        .globl  __rect_cmp16s_lt

        .area   _CODE

        ;; --------------------------------------------------------------
        ;; uint8_t gpx_clip_rect_effective(rect_t *out, const rect_t *clip)
        ;;   HL = out
        ;;   DE = clip (or 0)
        ;; --------------------------------------------------------------
__gpx_clip_rect_effective::
        ld      b,h
        ld      c,l                    ;; BC = out base

        ;; default out = [0,0]-[255,191]
        xor     a
        ld      (hl),a                 ;; x0 lo
        inc     hl
        ld      (hl),a                 ;; x0 hi
        inc     hl
        ld      (hl),a                 ;; y0 lo
        inc     hl
        ld      (hl),a                 ;; y0 hi
        inc     hl
        ld      a,#0xff
        ld      (hl),a                 ;; x1 lo
        inc     hl
        xor     a
        ld      (hl),a                 ;; x1 hi
        inc     hl
        ld      a,#0xbf
        ld      (hl),a                 ;; y1 lo
        inc     hl
        xor     a
        ld      (hl),a                 ;; y1 hi

        ;; no user clip -> just validate default/effective rectangle
        ld      a,d
        or      e
        jr      z,grc_check

        ;; x0 = max(0, clip->x0)
        ld      a,(de)
        ld      l,a                    ;; clip x0 lo
        inc     de
        ld      a,(de)
        ld      h,a                    ;; clip x0 hi
        inc     de
        bit     7,h
        jr      nz,grc_y0
        ld      a,h
        or      l
        jr      z,grc_y0
        push    de
        ld      d,h
        ld      e,l
        ld      h,b
        ld      l,c
        ld      (hl),e
        inc     hl
        ld      (hl),d
        pop     de

 grc_y0:
        ;; y0 = max(0, clip->y0)
        ld      a,(de)
        ld      l,a                    ;; clip y0 lo
        inc     de
        ld      a,(de)
        ld      h,a                    ;; clip y0 hi
        inc     de
        bit     7,h
        jr      nz,grc_x1
        ld      a,h
        or      l
        jr      z,grc_x1
        push    de
        ld      d,h
        ld      e,l
        ld      h,b
        ld      l,c
        inc     hl
        inc     hl
        ld      (hl),e
        inc     hl
        ld      (hl),d
        pop     de

 grc_x1:
        ;; x1 = min(255, clip->x1)
        ld      a,(de)
        ld      l,a                    ;; clip x1 lo
        inc     de
        ld      a,(de)
        ld      h,a                    ;; clip x1 hi
        inc     de
        bit     7,h
        jr      nz,grc_x1_set
        ld      a,h
        or      a
        jr      nz,grc_y1              ;; >=256 keeps default 255
        ld      a,l
        cp      #0xff
        jr      nc,grc_y1              ;; 255 keeps default
 grc_x1_set:
        push    de
        ld      d,h
        ld      e,l
        ld      h,b
        ld      l,c
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        ld      (hl),e
        inc     hl
        ld      (hl),d
        pop     de

 grc_y1:
        ;; y1 = min(191, clip->y1)
        ld      a,(de)
        ld      l,a                    ;; clip y1 lo
        inc     de
        ld      a,(de)
        ld      h,a                    ;; clip y1 hi
        bit     7,h
        jr      nz,grc_y1_set
        ld      a,h
        or      a
        jr      nz,grc_check           ;; >=256 keeps default 191
        ld      a,l
        cp      #0xbf
        jr      nc,grc_check           ;; 191 keeps default
 grc_y1_set:
        push    hl                     ;; save clipped y1 value
        ld      h,b
        ld      l,c
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        inc     hl                     ;; out->y1
        pop     de                     ;; DE = clipped y1
        ld      (hl),e
        inc     hl
        ld      (hl),d

 grc_check:
        ;; validate x0 <= x1 (signed)
        ld      h,b
        ld      l,c
        ld      e,(hl)                 ;; x0 lo
        inc     hl
        ld      d,(hl)                 ;; x0 hi
        inc     hl
        inc     hl
        inc     hl                     ;; skip y0
        ld      a,(hl)                 ;; x1 lo
        inc     hl
        ld      h,(hl)                 ;; x1 hi
        ld      l,a                    ;; HL = x1

        ;; if (x1 < x0) => invalid
        call    __rect_cmp16s_lt
        or      a
        jp      nz,grc_invalid

        ;; validate y0 <= y1 (signed)
        ld      h,b
        ld      l,c
        inc     hl
        inc     hl
        ld      e,(hl)                 ;; y0 lo
        inc     hl
        ld      d,(hl)                 ;; y0 hi
        inc     hl
        inc     hl                     ;; skip x1
        inc     hl
        ld      a,(hl)                 ;; y1 lo
        inc     hl
        ld      h,(hl)                 ;; y1 hi
        ld      l,a                    ;; HL = y1

        ;; if (y1 < y0) => invalid
        call    __rect_cmp16s_lt
        or      a
        jp      nz,grc_invalid

        ld      a,#1
        ret

 grc_invalid:
        xor     a
        ret


        ;; --------------------------------------------------------------
        ;; uint8_t gpx_point_in_rect(coord x, coord y, const rect_t *r)
        ;;   HL = x
        ;;   DE = y
        ;;   stack: r ptr (2 bytes)
        ;; callee cleans 2 bytes
        ;; --------------------------------------------------------------
__gpx_point_in_rect::
        push    ix
        ld      ix,#0
        add     ix,sp

        ;; Save x/y so we can freely reuse HL/DE/BC.
        push    hl                     ;; x at -2(ix), -1(ix)
        push    de                     ;; y at -4(ix), -3(ix)

        ;; x < r->x0 ?
        ld      l,4(ix)
        ld      h,5(ix)                ;; HL = rect*
        ld      e,(hl)
        inc     hl
        ld      d,(hl)                 ;; DE = x0

        ld      l,-2(ix)               ;; HL = x
        ld      h,-1(ix)
        call    __rect_cmp16s_lt
        or      a
        jp      nz,gpr_out

        ;; y < r->y0 ?
        ld      l,4(ix)
        ld      h,5(ix)                ;; HL = rect*
        inc     hl
        inc     hl                     ;; HL = &y0
        ld      e,(hl)
        inc     hl
        ld      d,(hl)                 ;; DE = y0

        ld      l,-4(ix)               ;; HL = y
        ld      h,-3(ix)
        call    __rect_cmp16s_lt
        or      a
        jp      nz,gpr_out

        ;; x > r->x1 ?  (x1 - x) < 0
        ld      l,4(ix)
        ld      h,5(ix)                ;; HL = rect*
        inc     hl
        inc     hl
        inc     hl
        inc     hl                     ;; HL = &x1
        ld      e,(hl)
        inc     hl
        ld      d,(hl)                 ;; DE = x1

        ld      l,-2(ix)               ;; HL = x
        ld      h,-1(ix)
        call    .gpx_sgt16_hl_de
        or      a
        jp      nz,gpr_out

        ;; y > r->y1 ?  (y1 - y) < 0
        ld      l,4(ix)
        ld      h,5(ix)                ;; HL = rect*
        ld      de,#0x0006
        add     hl,de                  ;; HL = &y1
        ld      e,(hl)
        inc     hl
        ld      d,(hl)                 ;; DE = y1

        ld      l,-4(ix)               ;; HL = y
        ld      h,-3(ix)
        call    .gpx_sgt16_hl_de
        or      a
        jp      nz,gpr_out

        ;; inside
        pop     de                     ;; drop saved y
        pop     de                     ;; drop saved x
        ld      a,#1
        jr      gpr_ret

 gpr_out:
        pop     de                     ;; drop saved y
        pop     de                     ;; drop saved x
        xor     a

 gpr_ret:
        pop     ix

        ;; callee cleanup: 2-byte r pointer
        pop     bc
        inc     sp
        inc     sp
        push    bc
        ret


        ;; --------------------------------------------------------------
        ;; uint8_t gpx_line_needs_clip(coord x0, coord y0,
        ;;                             coord x1, coord y1, const rect_t *r)
        ;;   HL = x0
        ;;   DE = y0
        ;;   stack: x1(2), y1(2), r(2)
        ;; callee cleans 6 bytes
        ;; --------------------------------------------------------------
__gpx_line_needs_clip::
        push    ix
        ld      ix,#0
        add     ix,sp

        ;; endpoint 0
        ld      c,8(ix)
        ld      b,9(ix)
        push    bc
        call    __gpx_point_in_rect
        or      a
        jr      z,glnc_need

        ;; endpoint 1
        ld      l,4(ix)
        ld      h,5(ix)
        ld      e,6(ix)
        ld      d,7(ix)
        ld      c,8(ix)
        ld      b,9(ix)
        push    bc
        call    __gpx_point_in_rect
        or      a
        jr      z,glnc_need

        xor     a
        jr      glnc_ret

 glnc_need:
        ld      a,#1

 glnc_ret:
        pop     ix

        ;; callee cleanup: x1(2) + y1(2) + r(2)
        pop     bc
        ld      hl,#6
        add     hl,sp
        ld      sp,hl
        push    bc
        ret

.gpx_sgt16_hl_de:
        ex      de,hl
        call    __rect_cmp16s_lt
        ex      de,hl
        ret
