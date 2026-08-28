        ;; gpx_draw_polygon.s
        ;;
        ;; Closed polygon outline.
        ;;
        ;; Portable: every edge is a gpx_draw_line, so clipping, blit modes
        ;; and the framebuffer layout stay the backend's business and one
        ;; copy of the code serves every machine. The rotated pattern each
        ;; line returns is carried into the next edge, the way
        ;; gpx_draw_rectangle carries it around a rectangle, so a dashed
        ;; outline stays continuous around the corners.
        ;;
        ;; GPL2 License (see: LICENSE)
        ;; Copyright (C) 2026 Tomaz Stih
        ;;
        ;; 2026-08-28   TS

        .module gpx_draw_polygon
        .optsdcc -mz80 sdcccall(1)

        .globl  _gpx_draw_polygon
        .globl  _gpx_draw_line

        .area   _CODE

        ;; ------------------------------------------------------------
        ;; _gpx_draw_polygon
        ;; Draw the closed path through n points. Fewer than two points
        ;; draws nothing.
        ;;
        ;; Signature:
        ;;   void gpx_draw_polygon(gpx_t *gpx, point_t *pts, uint8_t n,
        ;;                         color c, bmode m, uint8_t lpatt,
        ;;                         const rect_t *clip)
        ;;
        ;; Arguments:
        ;;   HL = gpx, DE = pts
        ;;   stack: n(1), c(1), m(1), lpatt(1), clip(2)
        ;;
        ;; Clobbers:
        ;;   AF, BC, DE, HL, IX, IY, and the alternate set
        ;;
        ;; References:
        ;;   _gpx_draw_line
_gpx_draw_polygon::
        push    ix
        ld      ix,#0
        add     ix,sp

        ;; locals (10 bytes)
        ;; -1..-2   gpx
        ;; -3..-4   pts
        ;; -5..-6   &pts[i]
        ;; -7..-8   &pts[j], j = (i + 1) % n
        ;; -9       i
        ;; -10      the pattern, rotated on by every edge drawn
        ld      b,h
        ld      c,l                     ; gpx, out of the way of the frame
        ld      hl,#-10
        add     hl,sp
        ld      sp,hl
        ld      -1(ix),c
        ld      -2(ix),b
        ld      -3(ix),e
        ld      -4(ix),d

        ;; a closed path needs two points
        ld      a,4(ix)
        cp      #2
        jp      c,.dp_done

        ;; i = 0, &pts[0], &pts[1]
        xor     a
        ld      -9(ix),a
        ld      -5(ix),e
        ld      -6(ix),d
        ld      hl,#4
        add     hl,de
        ld      -7(ix),l
        ld      -8(ix),h

        ld      a,7(ix)
        ld      -10(ix),a               ; starting pattern

.dp_edge:
        ;; gpx_draw_line(gpx, pts[i].x, pts[i].y, pts[j].x, pts[j].y,
        ;;               c, m, patt, clip). The callee does not keep IX and
        ;; cleans its own arguments, so IX is saved underneath them.
        push    ix
        ld      l,8(ix)
        ld      h,9(ix)
        push    hl                      ; clip
        ld      a,-10(ix)
        push    af
        inc     sp                      ; lpatt
        ld      l,5(ix)
        ld      h,6(ix)
        push    hl                      ; c, m

        ld      l,-7(ix)
        ld      h,-8(ix)                ; &pts[j]
        inc     hl
        inc     hl
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        push    de                      ; y1
        ld      l,-7(ix)
        ld      h,-8(ix)
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        push    de                      ; x1

        ld      l,-5(ix)
        ld      h,-6(ix)                ; &pts[i]
        inc     hl
        inc     hl
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        push    de                      ; y0

        ld      l,-5(ix)
        ld      h,-6(ix)
        ld      e,(hl)
        inc     hl
        ld      d,(hl)                  ; DE = x0
        ld      l,-1(ix)
        ld      h,-2(ix)                ; HL = gpx
        call    _gpx_draw_line
        pop     ix                      ; saved below the argument block
        ld      -10(ix),a               ; carry the phase into the next edge

        ;; i++, and step both cursors, wrapping j back to pts[0]
        ld      hl,#4
        ld      e,-5(ix)
        ld      d,-6(ix)
        add     hl,de
        ld      -5(ix),l
        ld      -6(ix),h

        ld      a,-9(ix)
        inc     a
        ld      -9(ix),a
        cp      4(ix)
        jr      nc,.dp_done             ; every edge drawn

        inc     a
        cp      4(ix)
        jr      c,.dp_next_j            ; j = i + 1 is still inside pts
        ;; j wrapped back to pts[0]
        ld      a,-3(ix)
        ld      -7(ix),a
        ld      a,-4(ix)
        ld      -8(ix),a
        jp      .dp_edge
.dp_next_j:
        ld      hl,#4
        ld      e,-7(ix)
        ld      d,-8(ix)
        add     hl,de
        ld      -7(ix),l
        ld      -8(ix),h
        jp      .dp_edge

.dp_done:
        ld      sp,ix
        pop     ix

        ;; callee cleanup: n(1), c(1), m(1), lpatt(1), clip(2) = 6
        pop     de
        ld      hl,#6
        add     hl,sp
        ld      sp,hl
        push    de
        ret
