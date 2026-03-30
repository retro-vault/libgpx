        ;; __gpx_cohen_sutherland.s
        ;;
        ;; Full Cohen-Sutherland clipping using bisection intersections.

        .module __gpx_cohen_sutherland
        .optsdcc -mz80 sdcccall(1)

        .globl  __gpx_cohen_sutherland
        .globl  __cs_compute_code
        .globl  __cs_rect_cmp16s_lt
        .globl  __gpx_cs_intersection_bisect

        .area   _CODE

        .equ    CS_LEFT,             0x01
        .equ    CS_RIGHT,            0x02
        .equ    CS_TOP,              0x04
        .equ    CS_BOTTOM,           0x08

        ;; ------------------------------------------------------------
        ;; uint8_t gpx_cohen_sutherland(gpx_line_state_t *s, const rect_t *r)
        ;;   HL = s
        ;;   DE = r
        ;; returns:
        ;;   A = 1 accepted (and clipped), A = 0 rejected
        ;; ------------------------------------------------------------
__gpx_cohen_sutherland::
        push    ix
        ld      ix,#0
        add     ix,sp

        ;; locals: 18 bytes
        ;; -18  loop_guard
        ;; -1   oc0
        ;; -2   oc1
        ;; -3   oc
        ;; -5..-4 yi
        ;; -7..-6 xi
        ;; -9..-8 pyo ptr
        ;; -11..-10 pxo ptr
        ;; -15..-14 r ptr
        ;; -17..-16 s ptr
        ld      c,l                    ;; save s ptr
        ld      b,h
        ld      hl,#-18
        add     hl,sp
        ld      sp,hl

        ld      -18(ix),#24            ;; hard stop: guarantee termination
        ld      -17(ix),c
        ld      -16(ix),b
        ld      -15(ix),e
        ld      -14(ix),d

.cs_loop:
        ld      a,-18(ix)
        or      a
        jp      z,.cs_reject
        dec     a
        ld      -18(ix),a

        ;; IY = r
        ld      l,-15(ix)
        ld      h,-14(ix)
        push    hl
        pop     iy

        ;; oc0 = outcode(s->x0, s->y0, r)
        ld      l,-17(ix)
        ld      h,-16(ix)              ;; HL = s
        ld      e,(hl)                 ;; x0 lo
        inc     hl
        ld      d,(hl)                 ;; x0 hi
        push    de
        inc     hl
        ld      e,(hl)                 ;; y0 lo
        inc     hl
        ld      d,(hl)                 ;; y0 hi
        pop     hl                     ;; HL = x0
        call    __cs_compute_code
        ld      -1(ix),a

        ;; oc1 = outcode(s->x1, s->y1, r)
        ld      l,-17(ix)
        ld      h,-16(ix)              ;; HL = s
        ld      de,#4
        add     hl,de                  ;; HL = &x1
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        push    de
        inc     hl
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        pop     hl                     ;; HL = x1, DE = y1
        call    __cs_compute_code
        ld      -2(ix),a

        ;; accept if (oc0 | oc1) == 0
        ld      a,-1(ix)
        or      -2(ix)
        jp      z,.cs_accept

        ;; reject if (oc0 & oc1) != 0
        ld      a,-1(ix)
        and     -2(ix)
        jp      nz,.cs_reject

        ;; choose outside endpoint and inside endpoint
        ld      a,-1(ix)
        or      a
        jr      z,.cs_out_ep1

        ;; outside endpoint = 0
        ld      a,-1(ix)
        ld      -3(ix),a               ;; oc = oc0

        ld      l,-17(ix)
        ld      h,-16(ix)              ;; HL = s
        ld      -11(ix),l              ;; pxo = &x0
        ld      -10(ix),h

        inc     hl
        inc     hl                     ;; &y0
        ld      -9(ix),l               ;; pyo = &y0
        ld      -8(ix),h

        inc     hl
        inc     hl                     ;; &x1
        ld      a,(hl)
        ld      -7(ix),a               ;; xi = x1
        inc     hl
        ld      a,(hl)
        ld      -6(ix),a

        inc     hl                     ;; &y1
        ld      a,(hl)
        ld      -5(ix),a               ;; yi = y1
        inc     hl
        ld      a,(hl)
        ld      -4(ix),a

        jr      .cs_pick_side

.cs_out_ep1:
        ;; outside endpoint = 1
        ld      a,-2(ix)
        ld      -3(ix),a               ;; oc = oc1

        ld      l,-17(ix)
        ld      h,-16(ix)              ;; HL = s

        ld      a,(hl)
        ld      -7(ix),a               ;; xi = x0
        inc     hl
        ld      a,(hl)
        ld      -6(ix),a

        inc     hl
        ld      a,(hl)
        ld      -5(ix),a               ;; yi = y0
        inc     hl
        ld      a,(hl)
        ld      -4(ix),a

        inc     hl                     ;; &x1
        ld      -11(ix),l              ;; pxo = &x1
        ld      -10(ix),h

        inc     hl
        inc     hl                     ;; &y1
        ld      -9(ix),l               ;; pyo = &y1
        ld      -8(ix),h

.cs_pick_side:
        ld      a,-3(ix)
        bit     2,a
        jr      nz,.cs_top
        bit     3,a
        jr      nz,.cs_bottom
        bit     1,a
        jr      nz,.cs_right
        jp      .cs_left

.cs_top:
        ;; ao=&y_out bo=&x_out ai=y_in bi=x_in edge=r->y0 outside_gt=0
        ld      a,#0
        push    af
        inc     sp

        ld      l,-15(ix)
        ld      h,-14(ix)              ;; r
        inc     hl
        inc     hl                     ;; &y0
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        push    de                     ;; edge

        ld      l,-7(ix)
        ld      h,-6(ix)
        push    hl                     ;; bi = xi

        ld      l,-5(ix)
        ld      h,-4(ix)
        push    hl                     ;; ai = yi

        ld      l,-9(ix)
        ld      h,-8(ix)               ;; ao = pyo
        ld      e,-11(ix)
        ld      d,-10(ix)              ;; bo = pxo
        call    __gpx_cs_intersection_bisect
        jp      .cs_loop

.cs_bottom:
        ;; ao=&y_out bo=&x_out ai=y_in bi=x_in edge=r->y1 outside_gt=1
        ld      a,#1
        push    af
        inc     sp

        ld      l,-15(ix)
        ld      h,-14(ix)              ;; r
        ld      de,#6
        add     hl,de                  ;; &y1
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        push    de                     ;; edge

        ld      l,-7(ix)
        ld      h,-6(ix)
        push    hl                     ;; bi = xi

        ld      l,-5(ix)
        ld      h,-4(ix)
        push    hl                     ;; ai = yi

        ld      l,-9(ix)
        ld      h,-8(ix)               ;; ao = pyo
        ld      e,-11(ix)
        ld      d,-10(ix)              ;; bo = pxo
        call    __gpx_cs_intersection_bisect
        jp      .cs_loop

.cs_right:
        ;; ao=&x_out bo=&y_out ai=x_in bi=y_in edge=r->x1 outside_gt=1
        ld      a,#1
        push    af
        inc     sp

        ld      l,-15(ix)
        ld      h,-14(ix)              ;; r
        ld      de,#4
        add     hl,de                  ;; &x1
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        push    de                     ;; edge

        ld      l,-5(ix)
        ld      h,-4(ix)
        push    hl                     ;; bi = yi

        ld      l,-7(ix)
        ld      h,-6(ix)
        push    hl                     ;; ai = xi

        ld      l,-11(ix)
        ld      h,-10(ix)              ;; ao = pxo
        ld      e,-9(ix)
        ld      d,-8(ix)               ;; bo = pyo
        call    __gpx_cs_intersection_bisect
        jp      .cs_loop

.cs_left:
        ;; ao=&x_out bo=&y_out ai=x_in bi=y_in edge=r->x0 outside_gt=0
        ld      a,#0
        push    af
        inc     sp

        ld      l,-15(ix)
        ld      h,-14(ix)              ;; r
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        push    de                     ;; edge

        ld      l,-5(ix)
        ld      h,-4(ix)
        push    hl                     ;; bi = yi

        ld      l,-7(ix)
        ld      h,-6(ix)
        push    hl                     ;; ai = xi

        ld      l,-11(ix)
        ld      h,-10(ix)              ;; ao = pxo
        ld      e,-9(ix)
        ld      d,-8(ix)               ;; bo = pyo
        call    __gpx_cs_intersection_bisect
        jp      .cs_loop

.cs_accept:
        ld      a,#1
        jr      .cs_ret

.cs_reject:
        xor     a

.cs_ret:
        ld      sp,ix
        pop     ix
        ret

        ;; ------------------------------------------------------------
        ;; uint8_t __cs_compute_code(coord x, coord y, const rect_t *r)
        ;;   HL = x
        ;;   DE = y
        ;;   IY = r
        ;; returns:
        ;;   A = outcode
        ;; ------------------------------------------------------------
__cs_compute_code:
        push    de                    ;; save y
        ld      c,#0                  ;; code accumulator

        ;; if (x < r->x0) code |= LEFT;
        ld      e,0(iy)
        ld      d,1(iy)
        call    __cs_rect_cmp16s_lt
        jr      z,.cc_x_right
        set     0,c
        jr      .cc_y_enter

.cc_x_right:
        ;; else if (x > r->x1) code |= RIGHT;  (x1 < x)
        ex      de,hl                 ;; DE = x
        ld      l,4(iy)
        ld      h,5(iy)
        call    __cs_rect_cmp16s_lt
        jr      z,.cc_y_enter
        set     1,c

.cc_y_enter:
        pop     hl                    ;; HL = y

        ;; if (y < r->y0) code |= TOP;
        ld      e,2(iy)
        ld      d,3(iy)
        call    __cs_rect_cmp16s_lt
        jr      z,.cc_y_bottom
        set     2,c
        jr      .cc_done

.cc_y_bottom:
        ;; else if (y > r->y1) code |= BOTTOM; (y1 < y)
        ex      de,hl                 ;; DE = y
        ld      l,6(iy)
        ld      h,7(iy)
        call    __cs_rect_cmp16s_lt
        jr      z,.cc_done
        set     3,c

.cc_done:
        ld      a,c
        ret

        ;; ------------------------------------------------------------
        ;; uint8_t __cs_rect_cmp16s_lt(coord a, coord b)
        ;;   HL = a
        ;;   DE = b
        ;; returns:
        ;;   A = 1 if (a < b), else 0
        ;; ------------------------------------------------------------
__cs_rect_cmp16s_lt:
        ;; Keep compare helper non-destructive for HL/DE.
        ld      a,h
        xor     d
        jp      p,.cs_cmp_same_sign

        ;; different signs: negative is smaller
        bit     7,h
        jr      z,.cs_cmp_false
        ld      a,#1
        ret

.cs_cmp_same_sign:
        ld      a,h
        cp      d
        jr      c,.cs_cmp_true
        jr      nz,.cs_cmp_false
        ld      a,l
        cp      e
        jr      c,.cs_cmp_true

.cs_cmp_false:
        xor     a
        ret

.cs_cmp_true:
        ld      a,#1
        ret
