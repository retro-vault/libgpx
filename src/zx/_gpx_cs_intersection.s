        ;; _gpx_cs_intersection.s
        ;;
        ;; Generic bisection intersection helper for Cohen-Sutherland.
        ;;
        ;; Converges exactly like the C oracle:
        ;;   while (abs(a_in-a_out) > 1 || abs(b_in-b_out) > 1)
        ;;       bisect and keep outside/inside half.

        .module _gpx_cs_intersection
        .optsdcc -mz80 sdcccall(1)

        .globl  _gpx_cs_intersection_bisect
        .globl  __rect_cmp16s_lt

        .area   _CODE

        ;; ------------------------------------------------------------
        ;; void gpx_cs_intersection_bisect(coord *ao, coord *bo,
        ;;                                 coord ai, coord bi,
        ;;                                 coord edge, uint8_t outside_gt)
        ;;   HL = ao pointer
        ;;   DE = bo pointer
        ;;   stack: ai(2), bi(2), edge(2), outside_gt(1)
        ;;
        ;; outside_gt:
        ;;   0 -> outside when a < edge
        ;;   1 -> outside when a > edge
        ;;
        ;; Writes clipped inside point to (*ao, *bo).
        ;; callee cleans 7 bytes.
        ;; ------------------------------------------------------------
_gpx_cs_intersection_bisect::
        push    ix
        ld      ix,#0
        add     ix,sp

        ;; locals: 22 bytes
        ;; -22     loop guard
        ;; -1      outside_gt
        ;; -3..-2  edge
        ;; -5..-4  ao ptr
        ;; -7..-6  bo ptr
        ;; -9..-8  a_out
        ;; -11..-10 b_out
        ;; -13..-12 a_in
        ;; -15..-14 b_in
        ;; -17..-16 a_mid
        ;; -19..-18 b_mid
        ;; -21..-20 diff temp
        ld      c,l
        ld      b,h
        ld      hl,#-22
        add     hl,sp
        ld      sp,hl

        ld      -22(ix),#32

        ;; save pointers and args
        ld      -5(ix),c
        ld      -4(ix),b
        ld      -7(ix),e
        ld      -6(ix),d

        ld      a,4(ix)
        ld      -13(ix),a
        ld      a,5(ix)
        ld      -12(ix),a

        ld      a,6(ix)
        ld      -15(ix),a
        ld      a,7(ix)
        ld      -14(ix),a

        ld      a,8(ix)
        ld      -3(ix),a
        ld      a,9(ix)
        ld      -2(ix),a

        ld      a,10(ix)
        ld      -1(ix),a

        ;; a_out = *ao
        ld      l,-5(ix)
        ld      h,-4(ix)
        ld      a,(hl)
        ld      -9(ix),a
        inc     hl
        ld      a,(hl)
        ld      -8(ix),a

        ;; b_out = *bo
        ld      l,-7(ix)
        ld      h,-6(ix)
        ld      a,(hl)
        ld      -11(ix),a
        inc     hl
        ld      a,(hl)
        ld      -10(ix),a

.csi_loop:
        ld      a,-22(ix)
        or      a
        jp      z,.csi_done
        dec     a
        ld      -22(ix),a

        ;; if (abs(a_in-a_out) > 1) keep iterating
        ld      l,-13(ix)
        ld      h,-12(ix)              ;; HL = a_in
        ld      e,-9(ix)
        ld      d,-8(ix)               ;; DE = a_out
        or      a
        sbc     hl,de                  ;; HL = diff
        ld      -21(ix),l
        ld      -20(ix),h

        ;; diff < -1 ?
        ld      de,#0xFFFF
        call    __rect_cmp16s_lt
        jr      nz,.csi_need_iter

        ;; 1 < diff ?
        ld      l,#0x01
        ld      h,#0x00
        ld      e,-21(ix)
        ld      d,-20(ix)
        call    __rect_cmp16s_lt
        jr      nz,.csi_need_iter

        ;; if (abs(b_in-b_out) > 1) keep iterating
        ld      l,-15(ix)
        ld      h,-14(ix)              ;; HL = b_in
        ld      e,-11(ix)
        ld      d,-10(ix)              ;; DE = b_out
        or      a
        sbc     hl,de                  ;; HL = diff
        ld      -21(ix),l
        ld      -20(ix),h

        ;; diff < -1 ?
        ld      de,#0xFFFF
        call    __rect_cmp16s_lt
        jr      nz,.csi_need_iter

        ;; 1 < diff ?
        ld      l,#0x01
        ld      h,#0x00
        ld      e,-21(ix)
        ld      d,-20(ix)
        call    __rect_cmp16s_lt
        jr      nz,.csi_need_iter

        ;; converged
        jp      .csi_done

.csi_need_iter:
        ;; a_mid = a_out + ((a_in - a_out) >> 1)
        ld      l,-13(ix)
        ld      h,-12(ix)              ;; HL = a_in
        ld      e,-9(ix)
        ld      d,-8(ix)               ;; DE = a_out
        or      a
        sbc     hl,de                  ;; HL = (a_in-a_out)
        sra     h
        rr      l
        add     hl,de                  ;; HL = a_mid
        ld      -17(ix),l
        ld      -16(ix),h

        ;; b_mid = b_out + ((b_in - b_out) >> 1)
        ld      l,-15(ix)
        ld      h,-14(ix)              ;; HL = b_in
        ld      e,-11(ix)
        ld      d,-10(ix)              ;; DE = b_out
        or      a
        sbc     hl,de                  ;; HL = (b_in-b_out)
        sra     h
        rr      l
        add     hl,de                  ;; HL = b_mid
        ld      -19(ix),l
        ld      -18(ix),h

        ;; side_out(a_mid)?
        ld      a,-1(ix)
        or      a
        jr      z,.csi_cmp_lt

        ;; outside_gt: outside when edge < a_mid
        ld      l,-3(ix)
        ld      h,-2(ix)               ;; HL = edge
        ld      e,-17(ix)
        ld      d,-16(ix)              ;; DE = a_mid
        call    __rect_cmp16s_lt
        jr      nz,.csi_outside
        jr      .csi_inside

.csi_cmp_lt:
        ;; outside_lt: outside when a_mid < edge
        ld      l,-17(ix)
        ld      h,-16(ix)              ;; HL = a_mid
        ld      e,-3(ix)
        ld      d,-2(ix)               ;; DE = edge
        call    __rect_cmp16s_lt
        jr      nz,.csi_outside

.csi_inside:
        ;; keep inside half: in = mid
        ld      a,-17(ix)
        ld      -13(ix),a
        ld      a,-16(ix)
        ld      -12(ix),a

        ld      a,-19(ix)
        ld      -15(ix),a
        ld      a,-18(ix)
        ld      -14(ix),a
        jp      .csi_loop

.csi_outside:
        ;; keep outside half: out = mid
        ld      a,-17(ix)
        ld      -9(ix),a
        ld      a,-16(ix)
        ld      -8(ix),a

        ld      a,-19(ix)
        ld      -11(ix),a
        ld      a,-18(ix)
        ld      -10(ix),a
        jp      .csi_loop

.csi_done:
        ;; write in-point back to (*ao, *bo)
        ld      l,-5(ix)
        ld      h,-4(ix)
        ld      a,-13(ix)
        ld      (hl),a
        inc     hl
        ld      a,-12(ix)
        ld      (hl),a

        ld      l,-7(ix)
        ld      h,-6(ix)
        ld      a,-15(ix)
        ld      (hl),a
        inc     hl
        ld      a,-14(ix)
        ld      (hl),a

        ld      sp,ix
        pop     ix

        ;; callee cleanup: ai(2)+bi(2)+edge(2)+outside_gt(1)
        pop     de
        ld      hl,#7
        add     hl,sp
        ld      sp,hl
        push    de
        ret
