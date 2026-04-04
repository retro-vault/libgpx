        ;; _ef9367.s
        ;;
        ;; EF9367 utility helpers for status polling, command execution,
        ;; coordinate setup, and delta-command encoding.

        .module _ef9367
        .optsdcc -mz80 sdcccall(1)

        .globl  __ef9367_set_xy
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
        .globl  __gdata

        .include "_ef9367-defs.inc"

        .equ    BM_XOR,                 0x01
        .equ    CO_BACK,                0x00

        .area   _CODE

        ;; ------------------------------------------------------------
        ;; __ef9367_wait_ready
        ;; Wait until EF9367 READY status bit is high.
        ;;
        ;; Input:
        ;;   none
        ;;
        ;; Output:
        ;;   none
        ;;
        ;; Clobbers:
        ;;   AF
__ef9367_wait_ready:
        in      a,(EF9367_STS_NI)       ; read status register
        and     #EF9367_STS_NI_READY    ; mask READY status bit
        jr      z,__ef9367_wait_ready    ; loop while GDP is busy
        ret                             ; return when ready

        ;; ------------------------------------------------------------
        ;; __ef9367_wait_vbl
        ;; Wait until the vertical blank status bit is high.
        ;;
        ;; Input:
        ;;   none
        ;;
        ;; Output:
        ;;   none
        ;;
        ;; Clobbers:
        ;;   AF
__ef9367_wait_vbl:
        in      a,(EF9367_STS_NI)       ; read status register
        and     #EF9367_STS_NI_VBLANK   ; mask vertical blank bit
        jr      z,__ef9367_wait_vbl      ; wait until vblank starts
        ret                             ; return in vblank

        ;; ------------------------------------------------------------
        ;; __ef9367_set_blit_mode
        ;; Set PIO graphics blit mode (copy/xor).
        ;;
        ;; Input:
        ;;   A = bmode
        ;;
        ;; Output:
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
        call    __ef9367_wait_ready      ; avoid touching PIO mid-command
        in      a,(PIO_GR_CMN)          ; read current common register
        and     #0xFB                   ; clear XOR mode bit
        ld      b,a                     ; keep base register value
        ld      a,c                     ; restore mode
        cp      #BM_XOR                 ; xor mode?
        jr      nz,.sbm_copy            ; no, keep copy mode
        ld      a,b                     ; start from masked base value
        or      #PIO_GR_CMN_XOR_MODE    ; set XOR bit
        out     (PIO_GR_CMN),a          ; write updated register
        ret                             ; done
.sbm_copy:
        ld      a,b                     ; copy mode with xor bit cleared
        out     (PIO_GR_CMN),a          ; write updated register
        ret                             ; done

        ;; ------------------------------------------------------------
        ;; __ef9367_set_line_style
        ;; Set CR2 vector style bits (1:0).
        ;;
        ;; Input:
        ;;   A = style bits (0..3)
        ;;
        ;; Output:
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
        call    __ef9367_wait_ready      ; avoid changing CR2 mid-draw
        in      a,(EF9367_CR2)          ; current CR2
        and     #0xFC                   ; clear style bits
        or      c                       ; apply requested style
        out     (EF9367_CR2),a          ; write CR2 back
        ret                             ; done

        ;; ------------------------------------------------------------
        ;; __ef9367_set_pen
        ;; Set pen up/down state.
        ;;
        ;; Input:
        ;;   A = 0 -> pen up, non-zero -> pen down
        ;;
        ;; Output:
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
        call    __ef9367_exec_cmd        ; execute and wait
        ret                             ; done
.spen_up:
        ld      a,#EF9367_CMD_PEN_UP    ; command for pen up
        call    __ef9367_exec_cmd        ; execute and wait
        ret                             ; done

        ;; ------------------------------------------------------------
        ;; __ef9367_set_color
        ;; Set EF9367 drawing mode from logical 1bpp color.
        ;;
        ;; Input:
        ;;   A = color role (CO_BACK => erase, CO_FORE => draw)
        ;;
        ;; Output:
        ;;   none
        ;;
        ;; Clobbers:
        ;;   AF
__ef9367_set_color:
        ld      c,a                     ; keep requested color
        ld      a,(__ef9367_cache_color) ; cached color
        cp      c                       ; same color?
        ret     z                       ; yes, nothing to do
        ld      a,c                     ; color changed
        ld      (__ef9367_cache_color),a ; cache new color
        bit     0,a                     ; CO_FORE uses bit0=1
        jr      z,.scolor_back          ; CO_BACK -> clear mode
        ld      a,#EF9367_CMD_DMOD_SET  ; pen draw mode
        call    __ef9367_exec_cmd        ; execute mode change
        ld      a,#1                    ; non-zero -> pen down
        call    __ef9367_set_pen         ; ensure pen is down
        ret                             ; done
.scolor_back:
        ld      a,#EF9367_CMD_DMOD_CLR  ; eraser mode
        call    __ef9367_exec_cmd        ; execute mode change
        ld      a,#1                    ; non-zero -> pen down
        call    __ef9367_set_pen         ; ensure pen is down
        ret                             ; done

        ;; ------------------------------------------------------------
        ;; __ef9367_exec_cmd
        ;; Execute command in A and wait for completion.
        ;;
        ;; Input:
        ;;   A = command byte
        ;;
        ;; Output:
        ;;   none
        ;;
        ;; Clobbers:
        ;;   AF
__ef9367_exec_cmd:
        out     (#EF9367_CMD),a         ; execute EF9367 command
        call    __ef9367_wait_ready      ; wait for cmd to finish
        ret                             ; done

        ;; ------------------------------------------------------------
        ;; __ef9367_set_dxdy
        ;; Program delta registers.
        ;;
        ;; Notes:
        ;;   Caller handles synchronization with EF9367 readiness.
        ;;
        ;; Input:
        ;;   B = dy, C = dx
        ;;
        ;; Output:
        ;;   none
        ;;
        ;; Clobbers:
        ;;   AF
__ef9367_set_dxdy:
        ld      a,b                     ; dy to A
        out     (#EF9367_DY),a          ; program delta-y register
        ld      a,c                     ; dx to A
        out     (#EF9367_DX),a          ; program delta-x register
        ret                             ; done

        ;; ------------------------------------------------------------
        ;; __ef9367_set_xy
        ;; Program cursor position; Y is transformed for reverse axis.
        ;;
        ;; Input:
        ;;   HL = x, DE = y
        ;;
        ;; Output:
        ;;   none
        ;;
        ;; Clobbers:
        ;;   AF, HL
__ef9367_set_xy:
        push    de                      ; preserve Y input
        push    hl                      ; preserve X input

        push    hl                      ; keep original X on stack
        ld      hl,(__gdata+2)           ; load gdata.height
        dec     hl                      ; compute max_y
        or      a                       ; clear carry
        sbc     hl,de                   ; HL = max_y - y
        pop     de                      ; DE = original X
        ex      de,hl                   ; HL = X, DE = transformed Y

        ld      a,l                     ; x low byte
        out     (#EF9367_XPOS_LO),a     ; write X low register
        ld      a,h                     ; x high byte
        out     (#EF9367_XPOS_HI),a     ; write X high register
        ld      a,e                     ; y low byte
        out     (#EF9367_YPOS_LO),a     ; write Y low register
        ld      a,d                     ; y high byte
        out     (#EF9367_YPOS_HI),a     ; write Y high register

        pop     hl                      ; restore input HL
        pop     de                      ; restore input DE
        ret                             ; done

        ;; ------------------------------------------------------------
        ;; __ef9367_get_delta_cmd
        ;; Build EF9367 delta command from signed 16-bit dx/dy.
        ;;
        ;; Input:
        ;;   HL = dx, DE = dy
        ;;
        ;; Output:
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
