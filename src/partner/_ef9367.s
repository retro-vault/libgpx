        ;; _ef9367.s
        ;;
        ;; EF9367 utility helpers for status polling, command execution,
        ;; coordinate setup, and delta-command encoding.
        ;;
        ;; GPL2 License (see: LICENSE)
        ;; Copyright (C) 2026 Tomaz Stih
        ;;
        ;; 2026-04-04   TS

        .module _ef9367
        .optsdcc -mz80 sdcccall(1)

        .globl  __ef9367_set_xy
        .globl  __ef9367_set_xy_fast
        .globl  __ef9367_max_y
        .globl  __ef9367_set_dxdy
        .globl  __ef9367_exec_cmd
        .globl  __ef9367_wait_ready
        .globl  __ef9367_wait_vbl
        .globl  __ef9367_set_blit_mode
        .globl  __ef9367_set_pen
        .globl  __ef9367_set_color
        .globl  __ef9367_set_line_style
        .globl  __ef9367_get_delta_cmd
        .globl  __ef9367_cache_bmode
        .globl  __ef9367_cache_color
        .globl  __ef9367_cache_pen
        .globl  __ef9367_cache_line_style
        .globl  __ef9367_gr_cmn
        .globl  __ef9367_set_gr_cmn
        .globl  __gdata

        .include "_ef9367-defs.inc"

        .equ    BM_XOR,                 0x01
        .equ    CO_BACK,                0x00
        .equ    CO_FORE,                0x01

        .area   _CODE

        ;; ------------------------------------------------------------
        ;; __ef9367_wait_ready
        ;; Wait until EF9367 READY status bit is high.
        ;;
        ;; Arguments:
        ;;   none
        ;;
        ;; Return:
        ;;   none
        ;;
        ;; Clobbers:
        ;;   AF
__ef9367_wait_ready:
        in      a,(EF9367_STS_NI)       ; read status register
        and     #EF9367_STS_NI_READY    ; mask READY status bit
        jr      z,__ef9367_wait_ready   ; loop while GDP is busy
        ret                             ; return when ready

        ;; ------------------------------------------------------------
        ;; __ef9367_wait_vbl
        ;; Wait until the vertical blank status bit is high.
        ;;
        ;; Arguments:
        ;;   none
        ;;
        ;; Return:
        ;;   none
        ;;
        ;; Clobbers:
        ;;   AF
__ef9367_wait_vbl:
        in      a,(EF9367_STS_NI)       ; read status register
        and     #EF9367_STS_NI_VBLANK   ; mask vertical blank bit
        jr      z,__ef9367_wait_vbl     ; wait until vblank starts
        ret                             ; return in vblank

        ;; ------------------------------------------------------------
        ;; __ef9367_set_blit_mode
        ;; Set PIO graphics blit mode (copy/xor).
        ;;
        ;; Arguments:
        ;;   A = bmode
        ;;
        ;; Return:
        ;;   none
        ;;
        ;; Clobbers:
        ;;   AF, BC
__ef9367_set_blit_mode:
        ld      c,a                     ; keep requested mode
        ld      a,(__ef9367_cache_bmode) ; cached mode
        cp      c                       ; same as requested?
        ret     z                       ; yes, nothing to do
        ld      a,c                     ; mode became dirty
        ld      (__ef9367_cache_bmode),a ; cache new mode
        ld      a,(__ef9367_gr_cmn)     ; shadow of the board control latch
        and     #(0xFF-PIO_GR_CMN_XOR_MODE) ; clear XOR mode bit
        dec     c                       ; BM_XOR(1) -> 0, BM_CPY(0) -> 0xFF
        jr      nz,.sbm_copy            ; not XOR: leave the bit clear
        or      #PIO_GR_CMN_XOR_MODE    ; set XOR bit
.sbm_copy:
        jp      __ef9367_set_gr_cmn     ; latch it, shadow it, sync first

        ;; ------------------------------------------------------------
        ;; __ef9367_set_gr_cmn
        ;; Write the GDP board control latch (PIO port A) and shadow it.
        ;;
        ;; The port is write-only as the board programs it, so the shadow is
        ;; the only readable copy. The EF9367 samples these lines while it
        ;; draws, so the caller must be past any in-flight command.
        ;;
        ;; Arguments:
        ;;   A = new latch value
        ;;
        ;; Clobbers:
        ;;   AF
__ef9367_set_gr_cmn:
        ld      (__ef9367_gr_cmn),a     ; keep the shadow in step
        push    af                      ; preserve value across the sync
        call    __ef9367_wait_ready     ; do not move the lines mid-command
        pop     af                      ; recover value
        out     (PIO_GR_A_DAT),a        ; drive the board control lines
        ret                             ; done

        ;; ------------------------------------------------------------
        ;; __ef9367_set_line_style
        ;; Set CR2 vector style bits (1:0).
        ;;
        ;; Arguments:
        ;;   A = style bits (0..3)
        ;;
        ;; Return:
        ;;   none
        ;;
        ;; Clobbers:
        ;;   AF, BC
__ef9367_set_line_style:
        and     #0x03                   ; keep only style bits
        ld      c,a                     ; requested style
        ld      a,(__ef9367_cache_line_style) ; cached style
        cp      c                       ; unchanged?
        ret     z                       ; yes, nothing to do
        ld      a,c                     ; new style
        ld      (__ef9367_cache_line_style),a ; cache style
        call    __ef9367_wait_ready     ; avoid changing CR2 mid-draw
        in      a,(EF9367_CR2)          ; current CR2
        and     #0xFC                   ; clear style bits
        or      c                       ; apply requested style
        out     (EF9367_CR2),a          ; write CR2 back
        ret                             ; done

        ;; ------------------------------------------------------------
        ;; __ef9367_set_pen
        ;; Set pen up/down state.
        ;;
        ;; Arguments:
        ;;   A = 0 -> pen up, non-zero -> pen down
        ;;
        ;; Return:
        ;;   none
        ;;
        ;; Clobbers:
        ;;   AF
__ef9367_set_pen:
        or      a                       ; pen up/down selector
        jr      z,.spen_norm_up         ; normalize to 0
        ld      a,#1                    ; normalize non-zero to 1
        jr      .spen_cache
.spen_norm_up:
        xor     a                       ; normalized pen-up value
.spen_cache:
        ld      c,a                     ; C = normalized pen state
        ld      a,(__ef9367_cache_pen)  ; cached pen state
        cp      c                       ; same state?
        ret     z                       ; yes, nothing to do
        ld      a,c                     ; state changed
        ld      (__ef9367_cache_pen),a  ; cache new state
        or      a                       ; choose command
        jr      z,.spen_up              ; zero -> pen up
        ld      a,#EF9367_CMD_PEN_DOWN  ; command for pen down
        call    __ef9367_exec_cmd       ; execute and wait
        ret                             ; done
.spen_up:
        ld      a,#EF9367_CMD_PEN_UP    ; command for pen up
        call    __ef9367_exec_cmd       ; execute and wait
        ret                             ; done

        ;; ------------------------------------------------------------
        ;; __ef9367_set_color
        ;; Set EF9367 drawing mode from logical 1bpp color.
        ;;
        ;; Arguments:
        ;;   A = color role (CO_BACK => erase, CO_FORE => draw)
        ;;
        ;; Return:
        ;;   none
        ;;
        ;; Clobbers:
        ;;   AF
__ef9367_set_color:
        ;; Under XOR the colour is not a choice. The ZX backend ignores the
        ;; colour argument entirely when BM_XOR is set, and the GDP's XOR
        ;; mode only toggles while the pen is selected -- an eraser stroke is
        ;; discarded outright. Forcing the pen here makes both backends do
        ;; the same thing: XOR always inverts. The cache below holds the
        ;; forced value, so a later change of blit mode re-issues correctly.
        ld      c,a                     ; keep requested color
        ld      a,(__ef9367_cache_bmode)
        cp      #BM_XOR
        jr      nz,.scolor_have
        ld      c,#CO_FORE              ; XOR: always the pen
.scolor_have:
        ld      a,c                     ; effective color
        ld      a,(__ef9367_cache_color) ; cached color
        cp      c                       ; same color?
        ret     z                       ; yes, nothing to do
        ld      a,c                     ; color changed
        ld      (__ef9367_cache_color),a ; cache new color
        bit     0,a                     ; CO_FORE uses bit0=1
        jr      z,.scolor_back          ; CO_BACK -> clear mode
        ld      a,#EF9367_CMD_DMOD_SET  ; pen draw mode
        call    __ef9367_exec_cmd       ; execute mode change
        ld      a,#1                    ; non-zero -> pen down
        call    __ef9367_set_pen        ; ensure pen is down
        ret                             ; done
.scolor_back:
        ld      a,#EF9367_CMD_DMOD_CLR  ; eraser mode
        call    __ef9367_exec_cmd       ; execute mode change
        ld      a,#1                    ; non-zero -> pen down
        call    __ef9367_set_pen        ; ensure pen is down
        ret                             ; done

        ;; ------------------------------------------------------------
        ;; __ef9367_exec_cmd
        ;; Issue command in A, and return without waiting for it to finish.
        ;;
        ;; The wait is on the way in, not on the way out: the datasheet's
        ;; rule (p. 6-58) is "do not write into the CMD register if execution
        ;; of the previous command is not completed", and the same page says
        ;; not to touch a register the running command uses as a parameter.
        ;; Fencing on entry satisfies both while leaving the GDP drawing
        ;; behind the CPU's back -- the caller's next primitive's setup runs
        ;; while the previous vector is still being plotted. Every routine
        ;; that touches an EF9367 register fences the same way, so there is
        ;; exactly one rule to keep: sync before you write, never after.
        ;;
        ;; Arguments:
        ;;   A = command byte
        ;;
        ;; Return:
        ;;   none
        ;;
        ;; Clobbers:
        ;;   AF
__ef9367_exec_cmd:
        push    af                      ; command survives the fence
.exc_wait:
        in      a,(EF9367_STS_NI)       ; previous command finished?
        and     #EF9367_STS_NI_READY    ; mask READY
        jr      z,.exc_wait             ; spin while the GDP is busy
        pop     af                      ; recover command
        out     (#EF9367_CMD),a         ; issue it and leave it running
        ret                             ; done

        ;; ------------------------------------------------------------
        ;; __ef9367_set_dxdy
        ;; Program delta registers.
        ;;
        ;; Notes:
        ;;   Fences on entry: a vector in flight reads DELTAX/DELTAY.
        ;;
        ;; Arguments:
        ;;   B = dy, C = dx
        ;;
        ;; Return:
        ;;   none
        ;;
        ;; Clobbers:
        ;;   AF
__ef9367_set_dxdy:
.sdd_wait:
        in      a,(EF9367_STS_NI)       ; previous command finished?
        and     #EF9367_STS_NI_READY    ; mask READY
        jr      z,.sdd_wait             ; the running vector reads these
        ld      a,b                     ; dy to A
        out     (#EF9367_DY),a          ; program delta-y register
        ld      a,c                     ; dx to A
        out     (#EF9367_DX),a          ; program delta-x register
        ret                             ; done

        ;; ------------------------------------------------------------
        ;; __ef9367_set_xy
        ;; Program cursor position; Y is transformed for reverse axis.
        ;;
        ;; Arguments:
        ;;   HL = x, DE = y
        ;;
        ;; Return:
        ;;   none
        ;;
        ;; Clobbers:
        ;;   AF, HL
__ef9367_set_xy:
        push    hl                      ; preserve X input
        call    __ef9367_set_xy_fast    ; DE survives, HL does not
        pop     hl                      ; restore input HL
        ret                             ; done

        ;; ------------------------------------------------------------
        ;; __ef9367_set_xy_fast
        ;; As __ef9367_set_xy, but only DE is preserved. Hot callers that
        ;; keep the cursor in DE use this and save the caller-side shuffle.
        ;;
        ;; Arguments:
        ;;   HL = x, DE = y
        ;;
        ;; Return:
        ;;   DE = y (unchanged)
        ;;
        ;; Clobbers:
        ;;   AF, HL
__ef9367_set_xy_fast:
        ;; Fence first: the running command uses X and Y as parameters, so
        ;; they must not move under it (datasheet p. 6-58).
.sxy_wait:
        in      a,(EF9367_STS_NI)       ; previous command finished?
        and     #EF9367_STS_NI_READY    ; mask READY
        jr      z,.sxy_wait             ; spin while the GDP is busy

        ld      a,l                     ; x low byte
        out     (#EF9367_XPOS_LO),a     ; write X low register
        ld      a,h                     ; x high byte
        out     (#EF9367_XPOS_HI),a     ; write X high register

        ld      hl,(__ef9367_max_y)     ; height-1, computed once at create
        or      a                       ; clear carry
        sbc     hl,de                   ; HL = max_y - y (reverse axis)
        ld      a,l                     ; y low byte
        out     (#EF9367_YPOS_LO),a     ; write Y low register
        ld      a,h                     ; y high byte
        out     (#EF9367_YPOS_HI),a     ; write Y high register
        ret                             ; done

        ;; ------------------------------------------------------------
        ;; __ef9367_get_delta_cmd
        ;; Build EF9367 delta command from signed 16-bit dx/dy.
        ;;
        ;; Arguments:
        ;;   HL = dx, DE = dy
        ;;
        ;; Return:
        ;;   A = command byte
        ;;
        ;; Clobbers:
        ;;   AF, BC
__ef9367_get_delta_cmd:
        ld      a,h                     ; inspect dx sign bit
        and     #0b10000000             ; isolate sign bit
        rlca                            ; move to EF9367 sign position
        rlca                            ; bit1 = dx sign
        ld      b,a                     ; keep dx sign bits in B

        ld      a,d                     ; inspect dy sign bit
        and     #0b10000000             ; isolate sign bit
        rlca                            ; rotate toward command bit
        rlca                            ; rotate toward command bit
        rlca                            ; bit2 = dy sign
        ld      c,a                     ; keep dy sign bits in C

        ld      a,h                     ; test dx == 0
        or      l                       ; combine high/low
        jr      z,.gdc_ignore_dx        ; special command for dx=0

        ld      a,d                     ; test dy == 0
        or      e                       ; combine high/low
        jr      z,.gdc_ignore_dy        ; special command for dy=0

        ld      a,#0b00010001           ; base delta draw command
        or      b                       ; apply dx sign
        or      c                       ; apply dy sign
        xor     #0b00000100             ; invert dy sign (reverse axis)
        ret                             ; all done

.gdc_ignore_dx:
        ld      a,c                     ; dy sign bits to A
        rrca                            ; mirror sign into dx slot
        or      c                       ; keep dy sign set as well
        xor     #0b00000100             ; invert dy sign (reverse axis)
        or      #0b00010000             ; set ignore-axis bit
        ret                             ; return command

.gdc_ignore_dy:
        ld      a,b                     ; dx sign bits to A
        rlca                            ; mirror sign into dy slot
        or      b                       ; keep dx sign set as well
        or      #0b00010000             ; set ignore-axis bit
        ret                             ; return command

        .area   _DATA

        ;; Cached EF9367 state to avoid redundant writes.
        ;; 0xFF means "unknown / force next update".
__ef9367_cache_bmode::
        .db     0xFF
__ef9367_cache_color::
        .db     0xFF
__ef9367_cache_pen::
        .db     0xFF
__ef9367_cache_line_style::
        .db     0xFF

        ;; Shadow of the GDP board control latch on PIO port A. The port
        ;; reads back only its own output latch, so this is the library's
        ;; single source of truth for page, XOR mode and format bits.
__ef9367_gr_cmn::
        .db     0x00

        ;; height-1 for the reverse-Y transform, so the per-pixel path does
        ;; not reload gdata.height and decrement it on every plot.
__ef9367_max_y::
        .dw     0x00FF
