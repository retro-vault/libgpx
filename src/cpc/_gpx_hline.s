        ;; _gpx_hline.s
        ;;
        ;; Fast horizontal line helper:
        ;;  - assumes x0 <= x1 (sorted)
        ;;  - quick clip reject against the clip rectangle, or the screen when
        ;;    the caller passes no clip
        ;;  - clips x to those bounds
        ;;  - draws by bytes (start/stop masks + full middle bytes)
        ;;  - preserves pattern phase (skip + drawn span)
        ;;  - pattern 0-bits are left alone, matching gpx_draw_pixel and the
        ;;    Bresenham raster: CO_FORE sets pattern-1 pixels, CO_BACK clears
        ;;    them, BM_XOR toggles them and ignores the color.
        ;;
        ;; CPC x runs to 639, so x stays 16-bit only until it is split into a
        ;; byte index and a pixel index. The byte index is 0..79 in both
        ;; modes, so everything from the span descriptor inwards is 8-bit,
        ;; exactly as on a machine whose x fits a byte.
        ;;
        ;; The line pattern is one bit per pixel with a period of eight
        ;; pixels. In mode 2 eight pixels are one screen byte, so a single
        ;; aligned pattern byte serves the whole run. In mode 1 eight pixels
        ;; are two screen bytes, so the run alternates between the pattern's
        ;; high nibble and its low nibble, both lifted into the high nibble
        ;; where pen 1 lives.
        ;;
        ;; GPL2 License (see: LICENSE)
        ;; Copyright (C) 2026 Tomaz Stih
        ;;
        ;; 2026-08-26   TS

        .module _gpx_hline
        .optsdcc -mz80 sdcccall(1)

        .include "_cpc-defs.inc"

        .globl  __gpx_hline
        .globl  __gpx_span_row
        .globl  __gpx_span_setup
        .globl  __gpx_xbyte
        .globl  __rect_screen
        .globl  __ret_clean11
        .globl  __clip_seg
        .globl  __vid_rowaddr
        .globl  __cpc_mode1
        .globl  __cpc_solid
        .globl  __cpc_pixmask

        ;; Shortest solid run worth parking the stack for. The stack path
        ;; saves fourteen T-states a byte and costs about 180 to set up, so
        ;; it breaks even around thirteen bytes.
        .equ    SR_SP_MIN, 16

        .area   _CODE

        ;; ------------------------------------------------------------
        ;; __gpx_xbyte
        ;;
        ;; Split a screen x into its byte index within the row. The result
        ;; is 0..79 in both modes, which is what lets the span code stay
        ;; 8-bit even though x itself does not fit a byte.
        ;;
        ;; Arguments:
        ;;   HL = x, already clamped to 0..CPC_WIDTH-1
        ;;
        ;; Return:
        ;;   A = x >> CPC_PIX_SHIFT (0..79)
        ;;
        ;; Clobbers:
        ;;   AF, H
        ;; ------------------------------------------------------------
__gpx_xbyte::
        ld      a,l
        srl     h
        rra
        srl     h
        rra                             ; x >> 2: mode 1 stops here
        ld      l,a
        ld      a,(__cpc_mode1)
        or      a
        ld      a,l
        ret     nz
        rra                             ; OR above cleared carry: divide by two
        ret

        ;; ------------------------------------------------------------
        ;; __gpx_hline
        ;;
        ;; Clipped wrapper:
        ;;  - optional clip reject/clamp against clip rectangle
        ;;  - then enters shared draw core
        ;;
        ;; Signature is identical to gpx_draw_line():
        ;;   HL = gpx
        ;;   DE = x0
        ;;   stack: y0, x1, y1, c, m, lpatt, clip
        ;;
        ;; Return:
        ;;   A = updated lpatt, or unchanged lpatt on reject.
        ;;
        ;; Clobbers:
        ;;   AF, BC, DE, HL, IX, IY
        ;;
        ;; References:
        ;;   __gpx_span_setup
        ;;   __gpx_span_row
        ;;   __vid_rowaddr
__gpx_hline::
        push    ix
        ld      ix,#0
        add     ix,sp

        ;; locals (16 bytes):
        ;; -1..-2  x0
        ;; -3..-4  x1
        ;; -5      x0 original low
        ;; -6      patt_start
        ;; -7      patt_byte
        ;; -8      byte_lo
        ;; -16..-9 span descriptor, laid out for __gpx_span_row:
        ;;         -16 mask_first, -15 mask_last, -14 count,
        ;;         -13 sel_or,     -12 sel_xor,   -11 start parity,
        ;;         -10 odd sel_or, -9  odd sel_xor  (mode 1 only)
        ld      hl,#-16
        add     hl,sp
        ld      sp,hl

        ;; cache x0/x1
        ld      -2(ix),e                ; x0 lo
        ld      -1(ix),d                ; x0 hi
        ld      -5(ix),e                ; x0 original lo
        ld      a,6(ix)
        ld      -4(ix),a                ; x1 lo
        ld      a,7(ix)
        ld      -3(ix),a                ; x1 hi

        ;; The screen is an implicit clip, and it is applied first: a clip
        ;; rect may itself extend off-screen, and a byte-span path handed a
        ;; span the screen cannot hold would write past the framebuffer.
        ld      a,5(ix)                 ; y hi: nonzero => y < 0 or y > 255
        or      a
        jp      nz,.ghl_reject
        ld      a,4(ix)
        cp      #CPC_HEIGHT
        jp      nc,.ghl_reject

        ;; x0/x1 against the screen's x pair. The shared 1-D clip does the
        ;; clamp and the reject in one pass, and __rect_screen already
        ;; carries this machine's width.
        ld      iy,#__rect_screen
        ld      l,-2(ix)
        ld      h,-1(ix)                ; HL = x0
        ld      e,-4(ix)
        ld      d,-3(ix)                ; DE = x1
        call    __clip_seg
        jp      c,.ghl_reject
        ld      -2(ix),l
        ld      -1(ix),h
        ld      -4(ix),e
        ld      -3(ix),d

        ;; optional caller clip, on top of the screen bounds
        ld      a,13(ix)
        or      14(ix)
        jr      z,.ghl_draw_core

.ghl_clip_checks:
        ;; BC = clip pointer
        ld      c,13(ix)
        ld      b,14(ix)

        ;; y outside the clip's y-range? A point is a degenerate segment,
        ;; so the shared 1-D clip does the reject test (clamp is a no-op).
        ld      iy,#2
        add     iy,bc                   ; IY = &clip->y0 (y1 at IY+4)
        ld      l,4(ix)
        ld      h,5(ix)                 ; HL = y
        ld      e,l
        ld      d,h                     ; DE = y
        call    __clip_seg
        jp      c,.ghl_reject
        ;; __clip_seg preserves IY at &clip->y0. Move back to x0
        ;; without reloading the clip pointer and rebuilding IY.
        dec     iy
        dec     iy
        ld      l,-2(ix)
        ld      h,-1(ix)                ; HL = x0
        ld      e,-4(ix)
        ld      d,-3(ix)                ; DE = x1
        call    __clip_seg
        jp      c,.ghl_reject
        ld      -2(ix),l
        ld      -1(ix),h                ; x0 = clamped lo
        ld      -4(ix),e
        ld      -3(ix),d                ; x1 = clamped hi

.ghl_draw_core:
        ;; Clipping changes the start pattern and its pixel position by
        ;; equal amounts. Their rotations cancel, so the byte-grid pattern
        ;; depends only on the original x0 and original line pattern.
        ld      a,12(ix)
        cp      #0xFF
        jr      z,.ghl_pbyte_store      ; solid rows need no phase conversion
        ld      b,#8
.ghl_rev_loop:
        rrca
        rl      d                       ; eight shifts replace every old bit
        djnz    .ghl_rev_loop

        ld      a,-5(ix)
        and     #0x07
        ld      b,a
        ld      a,d
        jr      z,.ghl_pbyte_store
.ghl_pbyte_rot:
        rrca
        djnz    .ghl_pbyte_rot
.ghl_pbyte_store:
        ld      -7(ix),a

        ;; Span descriptor for __gpx_span_row: IY = &descriptor (ix - 16).
        push    ix
        pop     iy
        ld      de,#-16
        add     iy,de

        ld      l,-2(ix)
        ld      h,-1(ix)                ; HL = x0 (clamped to the screen)
        ld      e,-4(ix)
        ld      d,-3(ix)                ; DE = x1
        ld      b,10(ix)                ; color
        ld      c,11(ix)                ; mode
        call    __gpx_span_setup        ; A = byte_lo
        ld      -8(ix),a

        ;; HL = row base + byte_lo
        ld      b,4(ix)                 ; y low
        call    __vid_rowaddr
        ld      a,-8(ix)
        add     a,l
        ld      l,a
        jr      nc,.ghl_row_ptr_ok
        inc     h
.ghl_row_ptr_ok:
        ld      a,-7(ix)                ; byte-grid aligned pattern
        call    __gpx_span_row

.ghl_ret_pattern:
        ;; Skipped and drawn rotations combine into x1 - original x0.
        ld      a,-4(ix)
        sub     -5(ix)
        and     #0x07                   ; Z set when shift==0, A=shift
        ld      b,a                     ; B = rotate count
        ld      a,12(ix)                ; original lpatt
        jr      z,.ghl_return
.ghl_pret_rot:
        rrca
        djnz    .ghl_pret_rot
        jr      .ghl_return

.ghl_reject:
        ;; unchanged lpatt on reject
        ld      a,12(ix)

.ghl_return:
        ld      sp,ix
        pop     ix
        jp      __ret_clean11

        ;; ------------------------------------------------------------
        ;; __gpx_span_setup
        ;;
        ;; Fill the span descriptor __gpx_span_row consumes. Everything here
        ;; is constant down a filled rectangle, which is why it is a separate
        ;; step: gpx_fill_rectangle calls it once and then loops rows.
        ;;
        ;; Arguments:
        ;;   HL = x0, DE = x1, both clamped to 0..CPC_WIDTH-1 with x0 <= x1
        ;;   B  = color byte, C = mode byte
        ;;   IY = descriptor (+0 mask_first, +1 mask_last, +2 count,
        ;;                    +3 sel_or, +4 sel_xor, +5 start parity,
        ;;                    +6/+7 scratch used by the mode 1 run)
        ;;
        ;; Return:
        ;;   A = byte_lo (0..79)
        ;;
        ;; Clobbers:
        ;;   AF, BC, DE, HL
        ;; ------------------------------------------------------------
__gpx_span_setup::
        push    bc                      ; colour/mode, wanted at the end

        ;; mask_first = solid >> (x0 & pixmask). Pen 1 sits in the high
        ;; nibble in mode 1, so one shift covers "this pixel and every pixel
        ;; right of it in the byte" in both modes.
        ld      a,(__cpc_pixmask)
        and     l
        ld      b,a
        ld      a,(__cpc_solid)
        jr      z,.ss_first_done
.ss_first_lp:
        srl     a
        djnz    .ss_first_lp
.ss_first_done:
        ld      0(iy),a

        ;; mask_last = solid << (pixmask - (x1 & pixmask))
        ld      a,e
        cpl
        ld      b,a
        ld      a,(__cpc_pixmask)
        and     b
        ld      b,a
        ld      a,(__cpc_solid)
        jr      z,.ss_last_done
.ss_last_lp:
        add     a,a
        djnz    .ss_last_lp
.ss_last_done:
        ld      1(iy),a

        ;; byte_lo and byte_hi, both 0..79
        push    de                      ; x1
        call    __gpx_xbyte             ; A = byte_lo
        ld      c,a
        pop     hl                      ; HL = x1
        call    __gpx_xbyte             ; A = byte_hi
        sub     c
        inc     a
        ld      2(iy),a                 ; count, at least 1

        ;; Which half of the eight-pixel pattern the first byte lands on.
        ;; Only mode 1 reads it; in mode 2 a byte is a whole period.
        ld      a,c
        and     #0x01
        ld      5(iy),a

        ;; Plot selectors: set FF/00, clear FF/FF, xor 00/FF. Pattern 0-bits
        ;; never reach the destination in any of them.
        pop     de                      ; D = colour, E = mode
        ld      a,e
        bit     0,a
        ld      b,#0xff
        ld      h,#0x00
        jr      z,.ss_cpy
        ld      b,#0x00                 ; BM_XOR ignores the colour
        ld      h,#0xff
        jr      .ss_store
.ss_cpy:
        ld      a,d
        bit     0,a
        jr      nz,.ss_store            ; CO_FORE: set
        ld      h,#0xff                 ; CO_BACK: clear
.ss_store:
        ld      3(iy),b
        ld      4(iy),h
        ld      a,c                     ; A = byte_lo
        ret

        ;; ------------------------------------------------------------
        ;; __gpx_span_row
        ;;
        ;; Apply one byte-aligned pattern across a horizontal run of bytes.
        ;; Every value that is constant for the run lives in the descriptor,
        ;; so a caller filling many rows pays the setup once instead of once
        ;; per row.
        ;;
        ;;   HL = first destination byte of the run
        ;;   A  = pattern byte, already rotated onto the pixel grid
        ;;   IY = span descriptor, see __gpx_span_setup
        ;;
        ;; Each byte becomes  dest = (dest | (m & sel_or)) ^ (m & sel_xor)
        ;; with m = pattern & coverage: set FF/00, clear FF/FF, xor 00/FF.
        ;;
        ;; Clobbers:
        ;;   AF, BC, DE. HL, IX and IY are preserved, so a caller filling
        ;;   many rows keeps the row pointer in HL and simply steps it.
        ;; ------------------------------------------------------------
__gpx_span_row::
        push    hl
        call    .sr_run
        pop     hl
        ret

.sr_run:
        ;; The pattern arrives in A; park it in C, which is where the run
        ;; wants it in mode 2 and where the nibble split reads it in mode 1.
        ld      c,a
        ld      a,(__cpc_mode1)
        or      a
        jp      z,.sr_have_pattern      ; mode 2: one pattern for the whole run

        ;; Eight pattern pixels span two screen bytes in mode 1. Lift each
        ;; nibble into the high nibble, where pen 1 lives, and start on
        ;; whichever half the run actually begins on.
        ld      a,c
        and     #0xF0
        ld      d,a                     ; pattern for even bytes
        ld      a,c
        rlca
        rlca
        rlca
        rlca
        and     #0xF0
        ld      e,a                     ; pattern for odd bytes
        ld      a,5(iy)
        or      a
        jr      z,.sr_have_halves
        ld      a,d                     ; run starts on the odd half
        ld      d,e
        ld      e,a
.sr_have_halves:
        ld      a,d
        cp      e
        jp      nz,.sr_alt              ; halves differ: alternate
        ld      c,d                     ; halves agree: one pattern serves
.sr_have_pattern:

        ld      b,2(iy)                 ; B = byte count
        dec     b
        jp      z,.sr_single

        ld      a,0(iy)
        and     c
        call    .sr_apply

        dec     b
        jp      z,.sr_last

        ;; Middle bytes are fully covered, so the selectors fold into the
        ;; pattern once for the whole run instead of once per byte.
        ld      a,c
        and     3(iy)
        ld      d,a
        ld      a,c
        and     4(iy)
        ld      e,a

        ;; When the folded OR selector covers every pixel of the byte, the
        ;; result no longer depends on what was underneath: it is the same
        ;; constant all the way along. That is true of a solid set AND a
        ;; solid clear -- between them most of what a UI actually paints --
        ;; so both become a plain store instead of a read-modify-write.
        ld      a,(__cpc_solid)
        cp      d
        jr      nz,.sr_mid_rmw
        xor     e                       ; solid ^ sel_xor: set, or clear
        ld      d,a

        ;; A long solid run writes through the stack pointer: push puts two
        ;; bytes down in twelve T-states where store-and-increment costs
        ;; twelve for one. Same trick, and the same interrupt discipline, as
        ;; gpx_clrscr. Parking the stack costs about 180 T-states, so short
        ;; runs -- every small fill, and both edges of a big one -- keep the
        ;; plain unrolled loop instead.
        ld      a,b
        cp      #SR_SP_MIN
        jr      c,.sr_ms_small

        ld      e,d                     ; DE = the run's byte, twice over
        bit     0,b
        jr      z,.sr_ms_even
        inc     hl                      ; odd length: one byte the plain way
        ld      (hl),d
        dec     b
.sr_ms_even:
        ld      a,b                     ; HL = the run's last byte
        add     a,l
        ld      l,a
        jr      nc,.sr_ms_end
        inc     h
.sr_ms_end:
        srl     b                       ; B = pairs to push

        ld      a,i                     ; P/V now carries IFF2
        push    af
        di
        ld      (.sr_sp),sp
        inc     hl
        ld      sp,hl                   ; SP just past the run, pushes descend
        dec     hl

        ;; Four pushes per loop test. One push per djnz would spend more on
        ;; the counter than on the write and give back most of the gain.
        ld      a,b
        and     #0x03
        jr      z,.sr_ms_push4
.sr_ms_push1:
        push    de
        dec     b
        dec     a
        jr      nz,.sr_ms_push1
        ld      a,b
        or      a
        jr      z,.sr_ms_pushed
.sr_ms_push4:
        srl     b
        srl     b
.sr_ms_pushlp:
        push    de
        push    de
        push    de
        push    de
        djnz    .sr_ms_pushlp
.sr_ms_pushed:
        ld      sp,(.sr_sp)
        pop     af
        jp      po,.sr_ms_ei_done       ; interrupts were already off
        ei
.sr_ms_ei_done:
        jp      .sr_last

        ;; Four stores per loop test. B is at least one here.
        ;; C carries the pattern into the last byte, so the odd-count
        ;; counter lives in A.
.sr_ms_small:
        ld      a,b
        and     #0x03
        jr      z,.sr_ms_quads
.sr_ms_odd:
        inc     hl
        ld      (hl),d
        dec     b
        dec     a
        jr      nz,.sr_ms_odd
        ld      a,b
        or      a
        jp      z,.sr_last
.sr_ms_quads:
        srl     b
        srl     b
.sr_mid_store:
        inc     hl
        ld      (hl),d
        inc     hl
        ld      (hl),d
        inc     hl
        ld      (hl),d
        inc     hl
        ld      (hl),d
        djnz    .sr_mid_store
        jp      .sr_last

        ;; The general case still has to read, but the two selectors split
        ;; into three shapes and only one of them needs both operations.
.sr_mid_rmw:
        ld      a,e
        or      a
        jp      z,.sr_mid_or            ; sel_xor empty: OR only
        ld      a,d
        or      a
        jp      z,.sr_mid_xor           ; sel_or empty: XOR only
.sr_mid_loop:
        inc     hl
        ld      a,(hl)
        or      d
        xor     e
        ld      (hl),a
        djnz    .sr_mid_loop
        jp      .sr_last
        ;; Both of these ran one byte per djnz, which spent a third of the
        ;; loop on the counter. Unrolled four ways like the constant-store
        ;; run above, with the count's low two bits walked off first. The
        ;; spare selector is free to hold that remainder: this path was
        ;; chosen precisely because it is empty.
.sr_mid_or:
        ld      a,b
        and     #0x03
        ld      e,a                     ; sel_xor is empty here
        jr      z,.sr_mo_quads
.sr_mo_odd:
        inc     hl
        ld      a,(hl)
        or      d
        ld      (hl),a
        dec     b
        dec     e
        jr      nz,.sr_mo_odd
        ld      a,b
        or      a
        jp      z,.sr_last
.sr_mo_quads:
        srl     b
        srl     b
.sr_mo_loop:
        inc     hl
        ld      a,(hl)
        or      d
        ld      (hl),a
        inc     hl
        ld      a,(hl)
        or      d
        ld      (hl),a
        inc     hl
        ld      a,(hl)
        or      d
        ld      (hl),a
        inc     hl
        ld      a,(hl)
        or      d
        ld      (hl),a
        djnz    .sr_mo_loop
        jp      .sr_last

.sr_mid_xor:
        ld      a,b
        and     #0x03
        ld      d,a                     ; sel_or is empty here
        jr      z,.sr_mx_quads
.sr_mx_odd:
        inc     hl
        ld      a,(hl)
        xor     e
        ld      (hl),a
        dec     b
        dec     d
        jr      nz,.sr_mx_odd
        ld      a,b
        or      a
        jp      z,.sr_last
.sr_mx_quads:
        srl     b
        srl     b
.sr_mx_loop:
        inc     hl
        ld      a,(hl)
        xor     e
        ld      (hl),a
        inc     hl
        ld      a,(hl)
        xor     e
        ld      (hl),a
        inc     hl
        ld      a,(hl)
        xor     e
        ld      (hl),a
        inc     hl
        ld      a,(hl)
        xor     e
        ld      (hl),a
        djnz    .sr_mx_loop

.sr_last:
        inc     hl
        ld      a,1(iy)
        and     c
        jr      .sr_apply               ; tail: its ret goes to our caller

.sr_single:
        ld      a,0(iy)
        and     1(iy)
        and     c
        ;; fall through

.sr_apply:
        ;; A = m
        ld      e,a
        and     3(iy)
        or      (hl)
        ld      d,a
        ld      a,e
        and     4(iy)
        xor     d
        ld      (hl),a
        ret

        ;; ------------------------------------------------------------
        ;; The two halves of the pattern differ, so the run alternates
        ;; between them. Both halves are folded with the selectors once, up
        ;; front: the even pair lives in D/E and the odd pair in the
        ;; descriptor's scratch slots, and the run walks two bytes per test
        ;; so the indexed loads are paid per pair rather than per byte.
        ;;
        ;; Masking a folded value by the edge coverage gives the same answer
        ;; as masking the raw pattern first and folding after, so the first
        ;; and last bytes need no raw pattern either.
        ;; ------------------------------------------------------------
.sr_alt:
        ld      a,e
        and     3(iy)
        ld      c,a
        ld      a,e
        and     4(iy)
        ld      7(iy),a                 ; odd XOR
        ld      a,c
        ld      6(iy),a                 ; odd OR
        ld      a,d
        and     4(iy)
        ld      c,a
        ld      a,d
        and     3(iy)
        ld      d,a                     ; D = even OR
        ld      e,c                     ; E = even XOR

        ld      b,2(iy)
        dec     b
        jr      z,.sr_alt_single

        ;; first byte, even half, through mask_first
        ld      a,d
        and     0(iy)
        or      (hl)
        ld      c,a
        ld      a,e
        and     0(iy)
        xor     c
        ld      (hl),a

        dec     b
        jr      z,.sr_alt_last

.sr_alt_mid:
        ;; The odd half's OR selector rides in C for the whole run: it is
        ;; dead until .sr_alt_last reloads it, and reading it from the
        ;; descriptor cost twenty T-states a byte against four.
        ld      c,6(iy)
.sr_alt_mid_lp:
        inc     hl                      ; odd byte
        ld      a,(hl)
        or      c
        xor     7(iy)
        ld      (hl),a
        dec     b
        jr      z,.sr_alt_last
        inc     hl                      ; even byte
        ld      a,(hl)
        or      d
        xor     e
        ld      (hl),a
        djnz    .sr_alt_mid_lp

.sr_alt_last:
        ;; The final byte takes whichever half it lands on. Byte 0 is even,
        ;; so an odd count ends on the even half.
        inc     hl
        ld      a,2(iy)
        rrca
        jr      c,.sr_alt_last_even
        ld      a,6(iy)
        and     1(iy)
        or      (hl)
        ld      c,a
        ld      a,7(iy)
        and     1(iy)
        xor     c
        ld      (hl),a
        ret
.sr_alt_last_even:
        ld      a,d
        and     1(iy)
        or      (hl)
        ld      c,a
        ld      a,e
        and     1(iy)
        xor     c
        ld      (hl),a
        ret

.sr_alt_single:
        ;; one byte only: both edge masks apply, even half
        ld      a,0(iy)
        and     1(iy)
        ld      c,a
        ld      a,d
        and     c
        or      (hl)
        ld      b,a
        ld      a,e
        and     c
        xor     b
        ld      (hl),a
        ret

        .area   _DATA

        ;; The caller's stack, parked while SP walks a solid run. Only ever
        ;; live inside the di window above, so it needs no re-entrancy.
.sr_sp:
        .dw     0
