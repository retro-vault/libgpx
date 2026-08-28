        ;; gpx_fill_polygon.s
        ;;
        ;; Scanline polygon fill, even-odd rule.
        ;;
        ;; Portable: each span is a horizontal gpx_draw_line, so the
        ;; backend's own run renderer does the work -- a byte-span writer on
        ;; the ZX and the CPC, the EF9367's vector generator on the Partner
        ;; -- and one copy of the code serves every machine.
        ;;
        ;; One walker per non-horizontal edge steps the same Bresenham
        ;; gpx_draw_line uses, so a span ends exactly where the outline of
        ;; the same polygon is drawn. An edge the polygon traverses upwards
        ;; has to be walked downwards here, and this rasterizer is not
        ;; symmetric under reversal, so a flipped edge takes the opposite
        ;; rounding bias -- (dx-1)/2 rather than dx/2 -- which reproduces
        ;; the reversed walk exactly.
        ;;
        ;; Crossings use the half-open rule y0 <= y < y1, so a shared vertex
        ;; counts once; on the polygon's own bottom row the rule closes, so
        ;; the bottom edge is filled the way gpx_fill_rectangle fills its
        ;; bottom row. Spans on a row are then clamped to be disjoint,
        ;; because two of them can meet on a shared vertex pixel and BM_XOR
        ;; would cancel it.
        ;;
        ;; The fill pattern is anchored to the polygon's bounding box: row n
        ;; takes fpatt[n % fpatt_len] counting from the top of the box, and
        ;; the byte is reversed and rotated so its MSB falls on the box's
        ;; left edge -- the same conversion the circle fill does.
        ;;
        ;; GPL2 License (see: LICENSE)
        ;; Copyright (C) 2026 Tomaz Stih
        ;;
        ;; 2026-08-28   TS

        .module gpx_fill_polygon
        .optsdcc -mz80 sdcccall(1)

        .globl  _gpx_fill_polygon
        .globl  _gpx_draw_line

        ;; Raising MAXPTS costs ERECSZ bytes of stack per point plus four
        ;; for its crossing slot. Keep it in step with GPX_MAX_POLY_PTS.
        .equ    MAXPTS, 12
        .equ    ERECSZ, 13
        .equ    EDGEBYTES, MAXPTS * ERECSZ
        .equ    CROSSBYTES, MAXPTS * 4
        .equ    SCALARS, 48
        .equ    FRAME, SCALARS + EDGEBYTES + CROSSBYTES

        ;; edge record fields
        .equ    E_Y1, 0
        .equ    E_DX, 2
        .equ    E_DY, 4
        .equ    E_ERR, 6
        .equ    E_CX, 8
        .equ    E_CY, 10
        .equ    E_SX, 12

        .area   _CODE

        ;; ------------------------------------------------------------
        ;; _gpx_fill_polygon
        ;; Fill the closed path through n points with a repeating pattern.
        ;; Fewer than three points, more than MAXPTS of them, or an empty
        ;; pattern draws nothing.
        ;;
        ;; Signature:
        ;;   void gpx_fill_polygon(gpx_t *gpx, point_t *pts, uint8_t n,
        ;;                         color c, bmode m,
        ;;                         uint8_t *fpatt, uint8_t fpatt_len,
        ;;                         const rect_t *clip)
        ;;
        ;; Arguments:
        ;;   HL = gpx, DE = pts
        ;;   stack: n(1), c(1), m(1), fpatt(2), fpatt_len(1), clip(2)
        ;;
        ;; Clobbers:
        ;;   AF, BC, DE, HL, IX, IY, and the alternate set
        ;;
        ;; References:
        ;;   _gpx_draw_line
_gpx_fill_polygon::
        push    ix
        ld      ix,#0
        add     ix,sp

        ;; locals. The scalars stay inside IX's one-byte reach; the two
        ;; tables below them are walked with cursors instead.
        ;; -1..-2   gpx
        ;; -3..-4   pts
        ;; -5       nedges
        ;; -6       nints, the crossings on this row
        ;; -7..-8   ymin
        ;; -9..-10  ymax
        ;; -11..-12 xmin
        ;; -13..-14 y, the current scanline
        ;; -15      patt_idx
        ;; -16      set on the polygon's bottom row
        ;; -17..-18 &pts[i]
        ;; -19..-20 &pts[j]
        ;; -21..-22 span x0
        ;; -23..-24 span x1
        ;; -25..-26 end of the span before it
        ;; -27..-28 run lo on this row
        ;; -29..-30 run hi on this row
        ;; -31..-32 edge table base
        ;; -33..-34 crossing table base
        ;; -35..-36 &pts[0], for the wrap
        ;; -37..-38 next free edge record
        ;; -39      counter
        ;; -40      this row's pattern byte
        ;; -41..-42 pi.x
        ;; -43..-44 pi.y
        ;; -45..-46 pj.x
        ;; -47..-48 pj.y
        ld      b,h
        ld      c,l                     ; gpx, out of the way of the frame
        ld      hl,#-FRAME
        add     hl,sp
        ld      sp,hl
        ld      -1(ix),c
        ld      -2(ix),b
        ld      -3(ix),e
        ld      -4(ix),d
        ld      -35(ix),e
        ld      -36(ix),d

        ;; table bases
        push    ix
        pop     hl
        ld      de,#-SCALARS-EDGEBYTES
        add     hl,de
        ld      -31(ix),l
        ld      -32(ix),h
        ld      -37(ix),l
        ld      -38(ix),h
        ld      de,#-CROSSBYTES
        add     hl,de
        ld      -33(ix),l
        ld      -34(ix),h

        ;; a polygon needs three points and the table has room for MAXPTS
        ld      a,4(ix)
        cp      #3
        jp      c,.fp_done
        cp      #MAXPTS+1
        jp      nc,.fp_done
        ;; an empty pattern draws nothing
        ld      a,9(ix)
        or      a
        jp      z,.fp_done

        ;; ---- edge table and bounding box ----
        xor     a
        ld      -5(ix),a                ; nedges = 0
        ld      -39(ix),a               ; i = 0
        ld      a,-3(ix)
        ld      -17(ix),a
        ld      a,-4(ix)
        ld      -18(ix),a               ; &pts[0]
        ld      l,-3(ix)
        ld      h,-4(ix)
        ld      de,#4
        add     hl,de
        ld      -19(ix),l
        ld      -20(ix),h               ; &pts[1]

        ;; the box starts at pts[0]
        ld      l,-3(ix)
        ld      h,-4(ix)
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ld      -11(ix),e
        ld      -12(ix),d               ; xmin
        inc     hl
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ld      -7(ix),e
        ld      -8(ix),d                ; ymin
        ld      -9(ix),e
        ld      -10(ix),d               ; ymax

.fp_build:
        call    .load_edge_points
        call    .bbox_pi
        call    .edge_add

        ;; i++, step &pts[i], wrap &pts[j] back to pts[0] on the last edge
        ld      hl,#4
        ld      e,-17(ix)
        ld      d,-18(ix)
        add     hl,de
        ld      -17(ix),l
        ld      -18(ix),h
        ld      a,-39(ix)
        inc     a
        ld      -39(ix),a
        cp      4(ix)
        jr      nc,.fp_built
        inc     a
        cp      4(ix)
        jr      c,.fp_next_j
        ld      a,-35(ix)
        ld      -19(ix),a
        ld      a,-36(ix)
        ld      -20(ix),a
        jp      .fp_build
.fp_next_j:
        ld      hl,#4
        ld      e,-19(ix)
        ld      d,-20(ix)
        add     hl,de
        ld      -19(ix),l
        ld      -20(ix),h
        jp      .fp_build

.fp_built:
        ld      a,-5(ix)
        or      a
        jp      z,.fp_done              ; every edge was horizontal

        ;; ---- scanlines, ymin down to ymax ----
        ld      a,-7(ix)
        ld      -13(ix),a
        ld      a,-8(ix)
        ld      -14(ix),a               ; y = ymin
        xor     a
        ld      -15(ix),a               ; patt_idx = 0

.fp_row:
        xor     a
        ld      -16(ix),a
        ld      l,-13(ix)
        ld      h,-14(ix)
        ld      e,-9(ix)
        ld      d,-10(ix)
        or      a
        sbc     hl,de                   ; y - ymax
        jp      m,.fp_row_go            ; y < ymax
        ld      a,h
        or      l
        jp      nz,.fp_done             ; y > ymax: finished
        inc     a
        ld      -16(ix),a               ; y == ymax: the closing row
.fp_row_go:
        call    .row_crossings
        call    .row_sort
        call    .row_spans

        ;; patt_idx = (patt_idx + 1) % fpatt_len
        ld      a,-15(ix)
        inc     a
        cp      9(ix)
        jr      c,.fp_row_patt
        xor     a
.fp_row_patt:
        ld      -15(ix),a

        ld      l,-13(ix)
        ld      h,-14(ix)
        inc     hl
        ld      -13(ix),l
        ld      -14(ix),h
        jp      .fp_row

.fp_done:
        ld      sp,ix
        pop     ix

        ;; callee cleanup: n(1), c(1), m(1), fpatt(2), fpatt_len(1),
        ;; clip(2) = 8
        pop     de
        ld      hl,#8
        add     hl,sp
        ld      sp,hl
        push    de
        ret

        ;; .load_edge_points
        ;; copy pts[i] and pts[j] into the pi/pj locals
        ;; clobbers: AF, DE, HL
.load_edge_points:
        ld      l,-17(ix)
        ld      h,-18(ix)
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ld      -41(ix),e
        ld      -42(ix),d
        inc     hl
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ld      -43(ix),e
        ld      -44(ix),d
        ld      l,-19(ix)
        ld      h,-20(ix)
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ld      -45(ix),e
        ld      -46(ix),d
        inc     hl
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ld      -47(ix),e
        ld      -48(ix),d
        ret

        ;; .bbox_pi
        ;; widen the bounding box to include pi
        ;; clobbers: AF, DE, HL
.bbox_pi:
        ld      e,-41(ix)
        ld      d,-42(ix)               ; pi.x
        ld      l,-11(ix)
        ld      h,-12(ix)
        or      a
        sbc     hl,de                   ; xmin - x
        jr      z,.bb_y
        jp      m,.bb_y
        ld      -11(ix),e
        ld      -12(ix),d
.bb_y:
        ld      e,-43(ix)
        ld      d,-44(ix)               ; pi.y
        ld      l,-7(ix)
        ld      h,-8(ix)
        or      a
        sbc     hl,de
        jr      z,.bb_ymax
        jp      m,.bb_ymax
        ld      -7(ix),e
        ld      -8(ix),d
.bb_ymax:
        ld      l,-9(ix)
        ld      h,-10(ix)
        or      a
        sbc     hl,de
        jp      p,.bb_done
        ld      -9(ix),e
        ld      -10(ix),d
.bb_done:
        ret

        ;; .edge_add
        ;; append one edge record for pi -> pj, normalized top to bottom.
        ;; A horizontal edge takes no slot: it contributes no crossing, and
        ;; the two edges that meet it carry the row.
        ;; clobbers: AF, BC, DE, HL, IY
.edge_add:
        ;; horizontal?
        ld      e,-43(ix)
        ld      d,-44(ix)
        ld      l,-47(ix)
        ld      h,-48(ix)
        or      a
        sbc     hl,de
        ret     z                       ; pi.y == pj.y

        ;; flipped = pi.y > pj.y, which is the sign of (pj.y - pi.y)
        ld      c,#0                    ; C = flipped
        jp      p,.ea_ordered
        ld      c,#1
        ;; swap pi and pj
        ld      e,-41(ix)
        ld      d,-42(ix)
        ld      l,-45(ix)
        ld      h,-46(ix)
        ld      -41(ix),l
        ld      -42(ix),h
        ld      -45(ix),e
        ld      -46(ix),d
        ld      e,-43(ix)
        ld      d,-44(ix)
        ld      l,-47(ix)
        ld      h,-48(ix)
        ld      -43(ix),l
        ld      -44(ix),h
        ld      -47(ix),e
        ld      -48(ix),d
.ea_ordered:
        ;; IY = the record being written
        ld      l,-37(ix)
        ld      h,-38(ix)
        push    hl
        pop     iy

        ;; y1 = pj.y
        ld      a,-47(ix)
        ld      E_Y1(iy),a
        ld      a,-48(ix)
        ld      E_Y1+1(iy),a
        ;; cx = pi.x, cy = pi.y
        ld      a,-41(ix)
        ld      E_CX(iy),a
        ld      a,-42(ix)
        ld      E_CX+1(iy),a
        ld      a,-43(ix)
        ld      E_CY(iy),a
        ld      a,-44(ix)
        ld      E_CY+1(iy),a

        ;; dy = pj.y - pi.y, always positive here
        ld      l,-47(ix)
        ld      h,-48(ix)
        ld      e,-43(ix)
        ld      d,-44(ix)
        or      a
        sbc     hl,de
        ld      E_DY(iy),l
        ld      E_DY+1(iy),h

        ;; dx = |pj.x - pi.x|, sx = its sign
        ld      l,-45(ix)
        ld      h,-46(ix)
        ld      e,-41(ix)
        ld      d,-42(ix)
        or      a
        sbc     hl,de                   ; pj.x - pi.x
        ld      a,h
        or      l
        jr      z,.ea_vertical
        bit     7,h
        jr      nz,.ea_left
        ld      a,#1
        jr      .ea_have_sx
.ea_left:
        call    .neg_hl
        ld      a,#0xFF
        jr      .ea_have_sx
.ea_vertical:
        xor     a
.ea_have_sx:
        ld      E_SX(iy),a
        ld      E_DX(iy),l
        ld      E_DX+1(iy),h

        ;; err = dx > dy ? bias(dx) : -bias(dy), where a flipped edge takes
        ;; (v-1)/2 so its walk lands on the same pixels as the outline's
        ld      e,E_DY(iy)
        ld      d,E_DY+1(iy)
        or      a
        sbc     hl,de                   ; dx - dy
        jr      z,.ea_ymajor
        jp      m,.ea_ymajor
        ld      l,E_DX(iy)
        ld      h,E_DX+1(iy)
        call    .bias
        jr      .ea_store_err
.ea_ymajor:
        ld      l,E_DY(iy)
        ld      h,E_DY+1(iy)
        call    .bias
        call    .neg_hl
.ea_store_err:
        ld      E_ERR(iy),l
        ld      E_ERR+1(iy),h

        ;; nedges++, advance the record cursor
        ld      a,-5(ix)
        inc     a
        ld      -5(ix),a
        ld      hl,#ERECSZ
        ld      e,-37(ix)
        ld      d,-38(ix)
        add     hl,de
        ld      -37(ix),l
        ld      -38(ix),h
        ret

        ;; .bias
        ;; param: HL = magnitude, C = 1 when the edge was flipped
        ;; return: HL = (C ? magnitude - 1 : magnitude) >> 1
        ;; clobbers: AF, HL
.bias:
        ld      a,c
        or      a
        jr      z,.bi_shift
        dec     hl
.bi_shift:
        srl     h
        rr      l
        ret

        ;; .neg_hl
        ;; return: HL = -HL
        ;; clobbers: AF, HL
.neg_hl:
        xor     a
        sub     l
        ld      l,a
        sbc     a,a
        sub     h
        ld      h,a
        ret

        ;; .estep
        ;; one Bresenham step of the edge in IY, the same step
        ;; gpx_draw_line takes
        ;; clobbers: AF, BC, DE, HL
.estep:
        ld      l,E_ERR(iy)
        ld      h,E_ERR+1(iy)
        ld      c,l
        ld      b,h                     ; BC = e2, the error before this step
        ;; if (e2 > -dx), i.e. (e2 + dx) > 0
        ld      e,E_DX(iy)
        ld      d,E_DX+1(iy)
        add     hl,de
        ld      a,h
        or      l
        jr      z,.es_no_x
        bit     7,h
        jr      nz,.es_no_x
        ;; err = e2 - dy
        ld      l,c
        ld      h,b
        ld      e,E_DY(iy)
        ld      d,E_DY+1(iy)
        or      a
        sbc     hl,de
        ld      E_ERR(iy),l
        ld      E_ERR+1(iy),h
        ;; cx += sx
        ld      a,E_SX(iy)
        or      a
        jr      z,.es_no_x
        ld      l,E_CX(iy)
        ld      h,E_CX+1(iy)
        bit     7,a
        jr      nz,.es_x_left
        inc     hl
        jr      .es_x_store
.es_x_left:
        dec     hl
.es_x_store:
        ld      E_CX(iy),l
        ld      E_CX+1(iy),h
.es_no_x:
        ;; if (e2 < dy) { err += dx; cy++; }
        ld      l,c
        ld      h,b
        ld      e,E_DY(iy)
        ld      d,E_DY+1(iy)
        or      a
        sbc     hl,de
        ret     p                       ; e2 >= dy
        ld      l,E_ERR(iy)
        ld      h,E_ERR+1(iy)
        ld      e,E_DX(iy)
        ld      d,E_DX+1(iy)
        add     hl,de
        ld      E_ERR(iy),l
        ld      E_ERR+1(iy),h
        ld      l,E_CY(iy)
        ld      h,E_CY+1(iy)
        inc     hl
        ld      E_CY(iy),l
        ld      E_CY+1(iy),h
        ret

        ;; .row_crossings
        ;; collect this row's crossings into the crossing table
        ;; clobbers: AF, BC, DE, HL, IY
.row_crossings:
        xor     a
        ld      -6(ix),a                ; nints = 0
        ld      a,-5(ix)
        ld      -39(ix),a               ; edges left to look at
        ld      a,-31(ix)
        ld      -37(ix),a
        ld      a,-32(ix)
        ld      -38(ix),a               ; edge cursor
        ld      a,-33(ix)
        ld      -35(ix),a
        ld      a,-34(ix)
        ld      -36(ix),a               ; crossing cursor

.rc_loop:
        ld      a,-39(ix)
        or      a
        ret     z
        ld      l,-37(ix)
        ld      h,-38(ix)
        push    hl
        pop     iy

        ;; the edge has not been reached yet?
        ld      l,-13(ix)
        ld      h,-14(ix)
        ld      e,E_CY(iy)
        ld      d,E_CY+1(iy)
        or      a
        sbc     hl,de
        jp      m,.rc_next              ; y < cy

        ;; past its end?  half-open, except on the closing row
        ld      l,-13(ix)
        ld      h,-14(ix)
        ld      e,E_Y1(iy)
        ld      d,E_Y1+1(iy)
        or      a
        sbc     hl,de                   ; y - y1
        jp      m,.rc_active
        ld      a,-16(ix)
        or      a
        jp      z,.rc_next              ; y >= y1
        ld      a,h
        or      l
        jp      nz,.rc_next             ; y > y1 even on the closing row

.rc_active:
        ;; walk down to this row
.rc_walk:
        ld      l,E_CY(iy)
        ld      h,E_CY+1(iy)
        ld      e,-13(ix)
        ld      d,-14(ix)
        or      a
        sbc     hl,de
        jp      p,.rc_at_row            ; cy >= y
        call    .estep
        jr      .rc_walk

.rc_at_row:
        ;; the run starts and ends at cx until the walk says otherwise
        ld      a,E_CX(iy)
        ld      -27(ix),a
        ld      -29(ix),a
        ld      a,E_CX+1(iy)
        ld      -28(ix),a
        ld      -30(ix),a

.rc_run:
        ;; step, and stop as soon as the walk leaves this row
        ld      c,E_CY(iy)
        ld      b,E_CY+1(iy)
        push    bc
        call    .estep
        pop     bc
        ld      l,E_CY(iy)
        ld      h,E_CY+1(iy)
        or      a
        sbc     hl,bc
        jr      nz,.rc_store

        ;; still on this row: widen the run
        ld      e,E_CX(iy)
        ld      d,E_CX+1(iy)
        ld      l,-27(ix)
        ld      h,-28(ix)
        or      a
        sbc     hl,de
        jr      z,.rc_hi
        jp      m,.rc_hi
        ld      -27(ix),e
        ld      -28(ix),d               ; cx < lo
.rc_hi:
        ld      e,E_CX(iy)
        ld      d,E_CX+1(iy)
        ld      l,-29(ix)
        ld      h,-30(ix)
        or      a
        sbc     hl,de
        jp      p,.rc_run
        ld      -29(ix),e
        ld      -30(ix),d               ; cx > hi
        jr      .rc_run

.rc_store:
        ld      l,-35(ix)
        ld      h,-36(ix)
        ld      a,-27(ix)
        ld      (hl),a
        inc     hl
        ld      a,-28(ix)
        ld      (hl),a
        inc     hl
        ld      a,-29(ix)
        ld      (hl),a
        inc     hl
        ld      a,-30(ix)
        ld      (hl),a
        inc     hl
        ld      -35(ix),l
        ld      -36(ix),h
        ld      a,-6(ix)
        inc     a
        ld      -6(ix),a

.rc_next:
        ld      hl,#ERECSZ
        ld      e,-37(ix)
        ld      d,-38(ix)
        add     hl,de
        ld      -37(ix),l
        ld      -38(ix),h
        ld      a,-39(ix)
        dec     a
        ld      -39(ix),a
        jp      .rc_loop

        ;; .row_sort
        ;; selection sort of this row's crossings by their low x
        ;; clobbers: AF, BC, DE, HL
.row_sort:
        ld      a,-6(ix)
        cp      #2
        ret     c
        dec     a
        ld      -39(ix),a               ; outer passes = nints - 1
        ld      a,-33(ix)
        ld      -21(ix),a
        ld      a,-34(ix)
        ld      -22(ix),a               ; p = first record

.rs_outer:
        ld      a,-21(ix)
        ld      -25(ix),a
        ld      a,-22(ix)
        ld      -26(ix),a               ; min = p
        ld      l,-21(ix)
        ld      h,-22(ix)
        ld      de,#4
        add     hl,de
        ld      -23(ix),l
        ld      -24(ix),h               ; q = p + 1
        ld      a,-39(ix)
        ld      -40(ix),a               ; inner comparisons left

.rs_inner:
        ld      a,-40(ix)
        or      a
        jr      z,.rs_swap
        ;; q->lo < min->lo ?
        ld      l,-23(ix)
        ld      h,-24(ix)
        ld      e,(hl)
        inc     hl
        ld      d,(hl)                  ; DE = q->lo
        ld      l,-25(ix)
        ld      h,-26(ix)
        ld      c,(hl)
        inc     hl
        ld      b,(hl)                  ; BC = min->lo
        ld      l,c
        ld      h,b
        or      a
        sbc     hl,de                   ; min->lo - q->lo
        jr      z,.rs_inner_next
        jp      m,.rs_inner_next
        ld      a,-23(ix)
        ld      -25(ix),a
        ld      a,-24(ix)
        ld      -26(ix),a               ; new minimum
.rs_inner_next:
        ld      hl,#4
        ld      e,-23(ix)
        ld      d,-24(ix)
        add     hl,de
        ld      -23(ix),l
        ld      -24(ix),h
        ld      a,-40(ix)
        dec     a
        ld      -40(ix),a
        jr      .rs_inner

.rs_swap:
        ;; swap the four bytes at p and min, if they differ
        ld      a,-21(ix)
        cp      -25(ix)
        jr      nz,.rs_do_swap
        ld      a,-22(ix)
        cp      -26(ix)
        jr      z,.rs_outer_next
.rs_do_swap:
        ld      b,#4
        ld      l,-21(ix)
        ld      h,-22(ix)
        ld      e,-25(ix)
        ld      d,-26(ix)
.rs_swap_byte:
        ld      a,(de)
        ld      c,a
        ld      a,(hl)
        ld      (de),a
        ld      a,c
        ld      (hl),a
        inc     hl
        inc     de
        djnz    .rs_swap_byte

.rs_outer_next:
        ld      hl,#4
        ld      e,-21(ix)
        ld      d,-22(ix)
        add     hl,de
        ld      -21(ix),l
        ld      -22(ix),h
        ld      a,-39(ix)
        dec     a
        ld      -39(ix),a
        jp      nz,.rs_outer
        ret

        ;; .row_spans
        ;; draw this row's spans, pairing crossings even-odd
        ;; clobbers: AF, BC, DE, HL, IY
.row_spans:
        ld      a,-6(ix)
        cp      #2
        ret     c
        ld      a,-33(ix)
        ld      -21(ix),a
        ld      a,-34(ix)
        ld      -22(ix),a               ; cursor at the first crossing
        ;; Seed the previous end just left of the leftmost crossing. A
        ;; sentinel like 0x8000 would overflow the signed compares below.
        ld      l,-21(ix)
        ld      h,-22(ix)
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        dec     de
        ld      -25(ix),e
        ld      -26(ix),d
        ld      a,-6(ix)
        srl     a
        ld      -39(ix),a               ; pairs to draw

.rp_pair:
        ld      a,-39(ix)
        or      a
        ret     z

        ;; x0 = this crossing's low x
        ld      l,-21(ix)
        ld      h,-22(ix)
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ld      -23(ix),e
        ld      -24(ix),d
        ;; x1 = the next crossing's high x
        ld      l,-21(ix)
        ld      h,-22(ix)
        ld      bc,#6
        add     hl,bc
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ld      -27(ix),e
        ld      -28(ix),d

        ;; two spans can meet on a shared vertex pixel: leave it to the
        ;; first, so BM_XOR does not cancel it
        ld      l,-23(ix)
        ld      h,-24(ix)
        ld      e,-25(ix)
        ld      d,-26(ix)
        or      a
        sbc     hl,de                   ; x0 - prev_end
        jp      p,.rp_have_x0
        ld      l,-25(ix)
        ld      h,-26(ix)
        inc     hl
        ld      -23(ix),l
        ld      -24(ix),h
        jr      .rp_check
.rp_have_x0:
        ld      a,h
        or      l
        jr      nz,.rp_check
        ld      l,-25(ix)
        ld      h,-26(ix)
        inc     hl
        ld      -23(ix),l
        ld      -24(ix),h

.rp_check:
        ;; anything left of the span?
        ld      l,-23(ix)
        ld      h,-24(ix)
        ld      e,-27(ix)
        ld      d,-28(ix)
        or      a
        sbc     hl,de                   ; x0 - x1
        jr      z,.rp_draw
        jp      p,.rp_next              ; x0 > x1: nothing to draw
.rp_draw:
        ld      a,-27(ix)
        ld      -25(ix),a
        ld      a,-28(ix)
        ld      -26(ix),a               ; prev_end = x1
        call    .span_line

.rp_next:
        ld      hl,#8
        ld      e,-21(ix)
        ld      d,-22(ix)
        add     hl,de
        ld      -21(ix),l
        ld      -22(ix),h
        ld      a,-39(ix)
        dec     a
        ld      -39(ix),a
        jp      .rp_pair

        ;; .span_line
        ;; draw one span with this row's pattern byte, turned from the
        ;; fill's MSB-first-from-the-box convention into the LSB-first one
        ;; a line consumes
        ;; clobbers: AF, BC, DE, HL
.span_line:
        ld      e,-15(ix)
        ld      d,#0
        ld      l,7(ix)
        ld      h,8(ix)
        add     hl,de
        ld      a,(hl)                  ; fpatt[patt_idx]
        ld      b,#8
.sl_reverse:
        rlca
        rr      c
        djnz    .sl_reverse
        ld      a,c
        ld      -40(ix),a

        ;; rotate right by how far this span starts inside the box
        ld      l,-23(ix)
        ld      h,-24(ix)
        ld      e,-11(ix)
        ld      d,-12(ix)
        or      a
        sbc     hl,de                   ; x0 - xmin
        ld      a,l
        and     #0x07
        jr      z,.sl_draw
        ld      b,a
        ld      a,-40(ix)
.sl_rotate:
        rrca
        djnz    .sl_rotate
        ld      -40(ix),a

.sl_draw:
        ;; gpx_draw_line(gpx, x0, y, x1, y, c, m, patt, clip). The callee
        ;; does not keep IX and cleans its own arguments, so IX is saved
        ;; underneath them.
        push    ix
        ld      l,10(ix)
        ld      h,11(ix)
        push    hl                      ; clip
        ld      a,-40(ix)
        push    af
        inc     sp                      ; lpatt
        ld      l,5(ix)
        ld      h,6(ix)
        push    hl                      ; c, m
        ld      l,-13(ix)
        ld      h,-14(ix)
        push    hl                      ; y1
        ld      l,-27(ix)
        ld      h,-28(ix)
        push    hl                      ; x1
        ld      l,-13(ix)
        ld      h,-14(ix)
        push    hl                      ; y0
        ld      e,-23(ix)
        ld      d,-24(ix)               ; DE = x0
        ld      l,-1(ix)
        ld      h,-2(ix)                ; HL = gpx
        call    _gpx_draw_line
        pop     ix                      ; saved below the argument block
        ret
