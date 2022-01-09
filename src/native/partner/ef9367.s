		;; ef9367.s
        ;; 
        ;; a library of primitives for the thompson ef9367 card (GDP)
        ;; 
        ;; TODO: 
        ;;  - cache drawing modes and pen up/down status to 
        ;;    avoid multiple writes to registers 
		;;
        ;; MIT License (see: LICENSE)
        ;; copyright (c) 2021 tomaz stih
        ;;
		;; 04.04.2021    tstih
		.module ef9367

		.globl	__ef9367_init
        .globl 	__ef9367_cls
        .globl  __ef9367_set_blit_mode
        .globl  __ef9367_put_pixel
        .globl  __ef9367_move_right
        .globl  __ef9367_stride
        .globl  __ef9367_tiny
        .globl  __ef9367_hline
        .globl  __ef9367_vline
        .globl  __ef9367_draw_line
	    
		.include "ef9367.inc"


        ;; cached data
        .area   _DATA
blit_mode:
        .db     1                       ; default mode is 1 (BL_COPY)
pen_down:
        .db     1                       ; default is pen down
yrev:
        .dw     1                       ; y reverse axis size

        
        .area	_CODE
        ;; wait for the GDP to finish previous operation
        ;; don't touch interrupts!
        ;; affects: a
wait_for_gdp:
        ;; make sure GDP is free
        in      a,(#EF9367_STS_NI)      ; read the status register
        and     #EF9367_STS_READY       ; get ready flag, it's the same bit
        jr      z,wait_for_gdp
        ret


        ;; extern uint16_t test(uint8_t move, uint16_t tiny)
        .globl  _test
_test::
        pop     bc                      ; get return address
        pop     hl                      ; l=move, h=low (tiny)
        pop     de                      ; e=high(tiny)
        ;; restore stack
        push    de
        push    hl
        push    bc

        ;; store ix
        push    ix

        ;; shuffle parametersd
        ld      a,l                     ; move to a
        ld      l,h                     ; l=low(tiny)
        ld      h,e                     ; h=high(tiny)
        push    hl
        pop     ix                      ; set ix
        call    decode_dxdy             ; decode command
        call    xy_inside_rect          ; set clip filter
        ;; restore ix
        pop     ix
        ret

        ;; space for debug trace, 32 bytes
_dtrace::
        .dw     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

        .macro  WTRACE value,offset
        push    af
        ld      a,#value
        WTRACEA offset
        pop     af
        .endm

        .macro  WTRACEA offset
        push    hl
        push    de
        ld      hl,#_dtrace
        ld      d,#0
        ld      e,#offset
        add     hl,de
        ld      (hl),a
        pop     de
        pop     hl
        .endm

        .macro  ITRACE offset
        push    hl
        push    de
        push    af
        ld      hl,#_dtrace
        ld      d,#0
        ld      e,#offset
        add     hl,de
        ld      a,(hl)
        inc     a
        ld      (hl),a
        pop     af
        pop     de
        pop     hl
        .endm

        .macro  RTRACE offset
        push    hl
        push    de
        ld      hl,#_dtrace
        ld      d,#0
        ld      e,#offset
        add     hl,de
        ld      a,(hl)
        pop     de
        pop     hl
        .endm

		;; given tiny_clip_t pointer, it checks if both
        ;; points are inside clip rectangle
		;; input:   ix ... tiny_clip_t
        ;;          +0 ... x0
        ;;          +1 ... y0
        ;;          +2 ... x1
        ;;          +3 ... y1
        ;;          +9 ... clipstat 
        ;;         +10 ... clipx0
        ;;         +11 ... clipy0
        ;;         +12 ... clipx1
        ;;         +13 ... clipy1
		;; output:  populated tiny_clip_t, ix offsets:
        ;;          +9 bit 0 is pt0, bit 1 is pt1
        ;;             1 means inside, 0 outside
        ;; affects:  -
xy_inside_rect:
        push    af                      ; store a and flags
        xor     a                       ; assume both outside
        ld      9(ix),a                 ; clear
        ;; check pt0
        ld      a,(ix)                  ; x0
        cp      10(ix)                  ; compare to clipx0
        jr      c,xyr_pt0_outside       ; it is outside
        cp      12(ix)                  ; compare to clipx1
        jr      z,xyr_pt0_right_eq      ; equal is still in...
        jr      nc,xyr_pt0_outside      ; it is outside
xyr_pt0_right_eq:
        ld      a,1(ix)                 ; y0
        cp      11(ix)                  ; compare to clipy0
        jr      c,xyr_pt0_outside       ; it is outside
        cp      13(ix)                  ; compare to clipy1
        jr      z,xyr_pt0_bottom_eq     ; equal is still in...
        jr      nc,xyr_pt0_outside      ; it is outside
xyr_pt0_bottom_eq:
        ;; it must be inside
        ld      a,#1                    ; success!
        ld      9(ix),a                 ; store pt0 result        
        jr      xyr_next_pt
xyr_pt0_outside:	
        xor     a                       ; store 0
        ld      9(ix),a                 ; as result for pt0
xyr_next_pt:
         ;; check pt1
        ld      a,2(ix)                 ; x1
        cp      10(ix)                  ; compare to clipx0
        jr      c,xyr_done              ; it is outside
        cp      12(ix)                  ; compare to clipx1
        jr      z,xyr_pt1_right_eq
        jr      nc,xyr_done             ; it is outside
xyr_pt1_right_eq:
        ld      a,3(ix)                 ; y1
        cp      11(ix)                  ; compare to clipy0
        jr      c,xyr_done              ; it is outside
        cp      13(ix)                  ; compare to clipy1
        jr      z,xyr_pt1_bottom_eq     ; equal is still in...
        jr      nc,xyr_done             ; it is outside
xyr_pt1_bottom_eq:
        ;; it's inside, set bit 1, keep bit 0
        ld      a,9(ix)
        or      #0b00000010
        ld      9(ix),a
xyr_done:
        pop     af                      ; restore a and flags
        ret


        ;; given ef9367 short command, it decodes
        ;; x2, z2, dx, dy, len, sign(dx), and sign(dy) ... 
        ;; notes:   
        ;;  short command must be in format 1xxxxxx1. 
        ;;  bits: 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0
        ;;        1 |  dx   |  dy   |sy |sx | 1
        ;; input:   ix ... pointer to tiny_clip_t
        ;;          +0 ... x0
        ;;          +1 ... y0
        ;;           a ... command
        ;; output:  populated tiny_clip_t, ix offsets:
        ;;          +2 ... x1
        ;;          +3 ... y1
        ;;          +4 ... offset (len-1)
        ;;          +5 ... dx
        ;;          +6 ... dy
        ;;          +7 ... sign(dx) i.e. -1,0,1
        ;;          +8 ... sign(dy) i.e. -1,0,1
        ;; affects: -
decode_dxdy:
        push    af                      ; store original move!
        rra                             ; move bit sx...
        rra                             ; ...to carry
        push    af                      ; store sx (in carry flag)
        rra                             ; move sy to carry
        push    af                      ; store sy (in carry flag)
        push    af                      ; we'll need it twice...
        ;; dy is now in first two bits
        and     #0b00000011             ; cut other bits...
        ld      4(ix),a                 ; assume offset=first len
        jr      z,dxy_zerody            ; dy==0?
        pop     af                      ; get sx (stored in carry) 
        jr      nc,dxy_posdy            ; dy==positive?
        ;; dy is negative...
        ld      a,4(ix)                 ; get offset back
        neg                             ; negate it!
        ld      6(ix),a                 ; store it to dy
        ld      a,#-1               
        ld      8(ix),a                 ; set sign
        jr      dxy_dx                  ; next is dx
dxy_zerody:
        pop     af                      ; clear (remainder!)
        xor     a
        ld      6(ix),a                 ; set dy and...
        ld      8(ix),a                 ; ...sign dy
        jr      dxy_dx
dxy_posdy:
        ;; dy is positive.
        ld      a,4(ix)                 ; get a
        ld      6(ix),a                 ; store to dy
        ld      a,#1                    ; sign=1
        ld      8(ix),a                 ; to sign(dy)
dxy_dx:
        pop     af                      ; get a back
        rra                             ; move dx to...
        rra                             ; ...bits 0,1
        and     #0b00000011             ; cut off the rest (again)
        ;; a is now len of dx
        cp      4(ix)                   ; compare to stored length
        jr      c,dxy_lenok             ; no need to change len
        ld      4(ix),a                 ; new len is larger
dxy_lenok:
        ld      5(ix),a                 ; store dx
        or      a                       ; clear carry
        jr      z,dxy_zerodx            ; check zero
        pop     af                      ; get sign of dx
        jr      nc,dxy_posdx            ; not negative?
        ;; dx is negative
        ld      a,5(ix)                 ; get 
        neg                             ; negate
        ld      5(ix),a                 ; store back
        ld      a,#-1                   ; set sign
        ld      7(ix),a
        jr      dxy_dxok
dxy_zerodx:
        pop     af                      ; clear stack
        xor     a
        ld      5(ix),a
        ld      7(ix),a
        jr      dxy_dxok
dxy_posdx:
        ld      a,#1
        ld      7(ix),a                 ; set sign
dxy_dxok:
        ;; finally, calculate x2 and y2
        ld      a,(ix)                  ; get x
        add     5(ix)                   ; a=x+dx
        ld      2(ix),a                 ; store to x2
        ld      a,1(ix)                 ; get y
        add     6(ix)                   ; a=y+dy
        ld      3(ix),a                 ; store to y2
        pop     af                      ; restore original move
        ret
        


        ;; executes ef9367 command (wait for status first!)
        ;; input:	a=command
ef9367_cmd:
        push    af
        call    wait_for_gdp            ; wait gdp
        pop     af
        out     (#EF9367_CMD), a        ; exec. command
        ret



        ;; move the cursor to x,y
        ;; notes:   y is transformed bottom to top!
        ;; inputs:  hl=x, de=y
        ;; affect:  af
ef9367_xy::
        ;; store hl and de regs
        push    de
        push    hl
        ;; reverse y coordinate
        push    hl                      ; store x
        ld      hl,(yrev)               ; hl=max y
        or      a                       ; clear carry
        sbc     hl,de                   ; hl=maxy-y
        pop     de                      ; de=x
        ex      de,hl                   ; switch
        ;; wait for gdp
        call    wait_for_gdp
        ld a,l
        out (#EF9367_XPOS_LO),a
        ld a,h
        out (#EF9367_XPOS_HI),a
        ld a,e
        out (#EF9367_YPOS_LO),a
        ld a,d
        out (#EF9367_YPOS_HI),a
        ;; restore de and hl
        pop     hl
        pop     de
        ret


        ;; set deltas to dx, dy
        ;; inputs:  b=dy, c=dx
        ;; affect:  a, bc
ef9367_dxdy::
        call    wait_for_gdp
        ld      a,b
        out     (#EF9367_DY),a
        ld      a,C
        out     (#EF9367_DX),a
        ret


        ;; -------------------
		;; void _ef9367_init()
        ;; -------------------
        ;; initializes the ef9367, sets the 1024x512 graphics mode
        ;; no waiting for gdp bcs no command should be executing!
        ;; affect:  a, bc, flags
__ef9367_init::
        ld      a,#0b00000011           ; pen down, default pen
        out     (#EF9367_CR1),a         ; control reg 1 to default
        xor     a                       ; a=0
        out     (#EF9367_CR2),a         ; control reg 2 to default
        out     (#EF9367_CH_SIZE),a     ; no scaling!
        ;; this sets default (MAX) resolution
        ;; and default page to 0
        ld      a,#PIO_GR_CMN_1024x512  
		out     (#PIO_GR_CMN),a
        ;; cache resolution as yrev(erse)
        ld      hl, #EF9367_HIRES_HEIGHT
        ld      (yrev),hl
        ret



        ;; ------------------
		;; void _ef9367_cls()
        ;; ------------------
		;; clear graphic screen
        ;; affect:  af
__ef9367_cls::
		ld a,#EF9367_CMD_CLS
		call ef9367_cmd
        ret



        ;; set blit mode, use cached mode if necessary
        ;; input:   b = blit mode, one of BL_ codes!
        ;; affects: af, hl, bc, byte@sdm_cache
__ef9367_set_blit_mode:
        ;; are we already in this mode?
        ld      a,(blit_mode)           ; get cached value
        cp      b                       ; compare to current mode
        ret     z                       ; all done!
        ;; write to cache and into a
        ld      a,b                     ; store new mode
        ld      (blit_mode),a           ; to cache
        ;; if none then pen up!
        and     #EF9367_BM_NONE         ; none?
        jr      z, blm_pen_down         ; not none, check xor
        ;; if we are here: PEN UP!
        ld      a,(pen_down)            ; get cached pen status
        or      a                       ; set zero flag
        ret     z                       ; pen is already up!
        ;; set cached pen down to false
        xor     a
        ld      (pen_down),a
        ;; and call pen up
        ld      a,#EF9367_CMD_PEN_UP    ; pen up command
        call    ef9367_cmd              ; execute command.
        ret
        ;; whatever it is, it will require pen down
        ;; if not already down
blm_pen_down:
        ld      a,(pen_down)            ; get cached value
        or      a                       ; compare
        jr      nz,blm_pen_already_down
        ld      a,#1                    ; cached value to 1
        ld      (pen_down),a
        ld      a,#EF9367_CMD_PEN_DOWN  ; pen up command
        call    ef9367_cmd              ; execute command.
blm_pen_already_down:
        ;; first get current common register to a
        call    wait_for_gdp            ; wait for gdp
        in      a,(#PIO_GR_CMN)         ; get current reg. to a
        ld      c,a                     ; store to c
        ;; now toggle the xor flag. 
        ld      a,b                     ; blit mode back to a
        and     #EF9367_BM_XOR          ; is it xor?
        jr      z,blm_copy              ; default = copy!
        ;; it is XOR
        ld      a,c                     ; get back a
        or      #PIO_GR_CMN_XOR_MODE    ; set xor bit
        jr      blm_write               ; write xor value
        ;; it is COPY
blm_copy:
        ld      a,c                     ; get back a
        and     #~PIO_GR_CMN_XOR_MODE   ; clr xor bit
        ;; finally, write back to register.
blm_write:
        push    af
        call    wait_for_gdp            ; wait
        pop     af
        out     (#PIO_GR_CMN),a         ; write it back
        ret


        ;; ------------------------
		;; void _ef9367_put_pixel()
        ;; ------------------------
        ;; draw single pixel 
        ;; affect:  af
__ef9367_put_pixel::
        ld      a,#0x80
        call    ef9367_cmd
		ret


        ;; -------------------------
		;; void _ef9367_move_right()
        ;; -------------------------
        ;; move x to the right
__ef9367_move_right::
        call    wait_for_gdp
        ld      a,#0b00000010           ; pen up
        out     (#EF9367_CR1),a
        ld      a,#0b10100000           ; move right
        call    ef9367_cmd
        call    wait_for_gdp
        ld      a,#0b00000011           ; pen down (again!)
        out     (#EF9367_CR1),a
        ret


        ;; ---------------------
		;; void __ef9367_hline()
        ;; ---------------------
        ;; draw horizontal len from current x,y
        ;; inputs:
        ;;  hl=len
__ef9367_hline::
        ld      de,#EF9367_MAX_DELTA    ; de=max delta len.
hline_loop:
        ;; do we have 256 pixels left?
        ld      a,h                     ; test h for 0
        or      a               
        jr      nz,hline_more           ; we have more...
        ;; draw it
        call    wait_for_gdp
        ;; at this point l is line len
        ld      a,l
        out     (#EF9367_DX),a
        ;; and draw!
        call    wait_for_gdp
        ld      a,#0b00010000           ; ignore dy
        call    ef9367_cmd
        ret
hline_more:
        or      a                       ; clear carry
        sbc     hl,de                   ; reduce for 256
        ld      a,#EF9367_MAX_DELTA     ; dx
        call    wait_for_gdp
        out     (#EF9367_DX),a
        ;; and draw!
        call    wait_for_gdp
        ld      a,#0b00010000           ; ignore dy
        call    ef9367_cmd
        ;; loop
        jr      hline_loop
        ret



        ;; ---------------------
		;; void __ef9367_vline()
        ;; ---------------------
        ;; draw vertical len from current x,y
        ;; inputs:
        ;;  hl=len
__ef9367_vline::
        ld      de,#EF9367_MAX_DELTA    ; de=max delta len.
vline_loop:
        ;; do we have 256 pixels left?
        ld      a,h                     ; test h for 0
        or      a               
        jr      nz,vline_more           ; we have more...
        ;; draw it
        call    wait_for_gdp
        ;; at this point l is line len
        ld      a,l
        out     (#EF9367_DY),a
        ;; and draw!
        call    wait_for_gdp
        ld      a,#0b00010100           ; ignore dy
        call    ef9367_cmd
        ret
vline_more:
        or      a                       ; clear carry
        sbc     hl,de                   ; reduce for 256
        ld      a,#EF9367_MAX_DELTA     ; dx
        call    wait_for_gdp
        out     (#EF9367_DY),a
        ;; and draw!
        call    wait_for_gdp
        ld      a,#0b00010100           ; ignore dy
        call    ef9367_cmd
        ;; loop
        jr      vline_loop
        ret    



        ;; -------------------
		;; void _ef9367_tiny()
        ;; -------------------
        ;; draw fast tiny at (preset) x,y
        ;; inputs: 
        ;;  hl = moves
        ;;  e = number of moves
        ;;  bc = pointer to tiny_clip_s
        ;; globals:
        ;;  b is command counter
        ;;  c is used to signal active clipping
        ;; affect:  af, bc, de, hl
__ef9367_tiny::
        push    ix                      ; store index
        ;; first store clipping rectangle flag into d
        ld      d,#0                    ; assume no clipping!
        ld      a,b
        or      c
        jr      z,tny_clip_flag
        ;; if we are here, we have clip.
        ;; move it to ix
        push    bc
        pop     ix                      ; ix=tiny clip
        inc     d                       ; d=1 (we have clip!)
tny_clip_flag:
        ld      c,d                     ; clip flag to c
        ld      a,e                     ; moves to a
        or      a                       ; zero moves?
        ret     z
        ld      b,a                     ; b=move counter
tny_loop:
        ld      e,(hl)                  ; move to e
        ld      a,c                     ; clip bit to a
        or      a                       ; test it
        jr      nz,tny_clipping
        ld      a,e                     ; move to a
        push    af                      ; store it
        call    tny_handle_pen  
tny_draw_move:
        pop     af                      ; move back to a
        inc     hl                      ; next move
        ;; make a move!
        or      #0b10000001             ; set both bits to 1
        xor     #0b00000100             ; negate y sign (rev.axis)
        call    ef9367_cmd              ; and draw!
        ;; and, finally, move!
        djnz    tny_loop                ; and loop
        ;; restore index before exiting.
        pop     ix
        ret
        ;; if we're here, then we clip!
        ;; command is inside e a this point.
tny_clipping:
        ld      a,e                     ; move to a
        call    decode_dxdy             ; initial decode
        ;; first calculate clip points
        call    xy_inside_rect
        ;; now decide clip strategy
        ;; 1. if both ends are outside, ignore move
        ld      a,9(ix)                 ; a=clipstat 
        or      a
        jr      z,tny_clip_move_done    ; both ends outside clip area
        ;; 2. if both ends are inside, use standard move
        cp      #3                      ; both in
        jr      z,tny_clip_none
        cp      #2
        jr      z,tny_fosi              ; first out second in
        jr      tny_fiso                ; must be first in second out
tny_clip_none:
        ;; both are inside...
        ld      a,e                     ; move to a
        push    af
        call    tny_handle_pen          ; set color
        pop     af
        ;; make move
        or      #0b10000001             ; set both bits to 1
        xor     #0b00000100             ; negate y sign (rev.axis)
        call    ef9367_cmd              ; and draw!
        jr      tny_clip_move_done      ; and we're done

        ;; 3. if first in second out, draw until end of area
tny_fiso:
        ld      a,e                     ; original move to a
        call    tny_handle_pen          ; set pen
tny_fiso_loop1:
        call    tny_nextpix             ; calculate next pixel
        call    ef9367_cmd              ; draw it
        call    xy_inside_rect          ; calculate next clip
        or      a                       ; test a
        jr      nz,tny_fiso_loop1
        ;; now we are out!
tny_fiso_loop2:
        ld      a,4(ix)
        or      a
        jr      z,tny_clip_move_done
        call    tny_nextpix
        jr      tny_fiso_loop2
        jr      tny_clip_move_done

        ;; 4. if first out, second in, goto xy and draw the rest
tny_fosi:
        ;; first is out so move p0 to next pixel
        call    tny_nextpix
        call    xy_inside_rect          ; check clipping (again)
        cp      #3                      ; both are now in?
        jr      nz, tny_fosi            ; if not - loop.
        ;; move to position, both pixels are in
        call    tny_movep0
        ;; set pen...
        ld      a,e
        call    tny_handle_pen
        ;; draw single pixel
        ld      a,#0b10000001
        call    ef9367_cmd
        ;; the end?
tny_fosi_loop:
        ld      a,4(ix)
        or      a
        jr      z,tny_clip_move_done
        call    tny_nextpix
        call    ef9367_cmd
        jr      tny_fosi_loop
        ;; next move!
tny_clip_move_done:
        call    tny_pt1_2_pt0           ; to end point...
        inc     hl                      ; next move
        ;; execute "long djnz"
        dec     b        
        jp      nz,tny_loop
        ;; restore index before exiting
        pop     ix
        ret

        ;; move cursor to p0 (relative)
        ;; input:   ix ... tiny_clip_t pointer
        ;;          +0 ... relative x
        ;;          +1 ... relative y
        ;;         hl' ... absolute x
        ;;         de' ... absolute y 
tny_movep0:
        ;; now move to initial position, which is 
        ;; at x + dx, and y + dy. initial dx and dy
        ;; are bytes 0 and 1 of moves.
        exx                             ; alt set on
        ;; store regs
        push    af
        push    de
        push    hl
        ld      a,(ix)                  ; move p0 (dx) to a
        push    de                      ; store y
        ld      d,#0                    ; de=dx
        ld      e,a                     ; -"- 
        add     hl,de                   ; x = x + dx
        pop     de                      ; de = y
        ld      a,1(ix)                 ; dy to a
        push    hl                      ; store x
        ex      de,hl                   ; hl=y
        ld      d,#0
        ld      e,a                     ; de=dy
        add     hl,de                   ; hl=y+dy
        ex      de,hl                   ; de=y
        pop     hl                      ; hl=x
        call    ef9367_xy
        pop     hl
        pop     de
        pop     af
        exx                             ; alt set off
        ret

        ;; calculate next pixel
        ;; from pt0 and sx and sy.
        ;; input:   ix ... tiny_clip_t pointer
        ;; output:  +0 ... new x
        ;;          +1 ... new y
        ;;          +4 ... new len
        ;;           a ... command to draw this (if required)
tny_nextpix:
        ;; first dx
        ld      a,(ix)                  ; x to a
        add     7(ix)                   ; add sign x i.e. 1 pixel move
        ld      (ix),a                  ; to x
        ;; now dy
        ld      a,1(ix)                 ; y to a
        add     8(ix)                   ; add sign y
        ld      1(ix),a                 ; to y
        ;; reduce length
        ld      a,4(ix)                 ; current offset to a
        dec     a
        ld      4(ix),a                 ; store back pixel counter
        ;; and finally, generate command.
        ld      d,#0b10000001           ; create base command 
        ld      a,7(ix)                 ; sign x
        and     #0b10000000             ; is it negative?
        jr      z,tny_np_posdx
        ;; it's negative
        ld      a,d                     ; get d
        or      #2                      ; set sx bit
        ld      d,a                     ; back to d
        ld      a,7(ix)
        neg                             ; if negative - make positive
        jr      tny_np_shift_dx
tny_np_posdx:
        ld      a,7(ix)                 ; just a, no need for sign.
tny_np_shift_dx:
        ;; dx is in a (bits 0-1), move to bits 5-6
        rlca
        rlca
        rlca
        rlca
        rlca
        or      d                       ; or current command
        ld      d,a                     ; back to d
        ;; now handle y direction
        ;; remember: y is reverse axis!!!
        ld      a,8(ix)                 ; sign y
        and     #0b10000000             ; is negative?
        jr      z,tny_np_posdy        ; it's positive...
        ld      a,8(ix)                 ; sign back
        neg                             ; make positive
        jr      tny_np_shift_dy       ; and shift into command
tny_np_posdy:
        ld      a,d                     ; get command
        or      #4                      ; y is reverse axis, set -dy
        ld      d,a                     ; back to command
        ld      a,8(ix)                 ; get sign y
tny_np_shift_dy:
        ;; dy is in a (bits 0-1), move to bits 3-4
        rlca
        rlca
        rlca
        or      d                       ; add to current command
        ;; a now has the complete command
        ret

        ;; moves point 1 to point 0
        ;; inputs:  ix ... tiny_clip_t
tny_pt1_2_pt0:
        ;; move pt1 to pt0
        ld      a,2(ix)
        ld      (ix),a
        ld      a,3(ix)
        ld      1(ix),a
        ret
        ;; handle pen and color
        ;; inputs: a is the tiny command
tny_handle_pen:
        ld      d,#0                    ; assume pen up
        ;; now check pen...
        rlca                            ; get color to first 2 bits
        and     #0b00000011             ; get color
        jr      z,tny_set_pen           ; CO_NONE=raise the pen
        inc     d                       ; pen down to d
tny_set_pen:
        ;; compare d to (pen_down) cached value
        ld      a,(pen_down)
        cp      d
        jr      z,tny_set_color         ; if the same no change
        ;; if we are here we need to change the pen status
        ;; a has the inverse value!
        or      a                       ; cached pen down?
        jr      nz,tny_pen_up           ; pen up
        ;; if we are here, pen down!
        call    wait_for_gdp
        ld      a,#0b00000011           ; pen down
        out     (#EF9367_CR1),a
        and     #1                      ; a=1!
        ld      (pen_down),a            ; write to cache
        jr      tny_set_color 
tny_pen_up:
        ;; if we are here, pen up!
        call    wait_for_gdp
        ld      a,#0b00000010           ; pen up
        out     (#EF9367_CR1),a
        xor     a
        ld      (pen_down),a            ; and set cached value
        ret                             ; to tny_draw_move
        ;; pen is down/up as it should be
        ;; now set the eraser or ink
tny_set_color:
        pop     de                      ; return address
        pop     af                      ; get command 
        push    af                      ; and store back
        push    de
        rlca                            ; color to first two bits
        and     #0b00000010             ; mask?
        jr      nz,tny_eraser
        ;; if we are here it's pen
        ld      a,#EF9367_CMD_DMOD_SET
        call    ef9367_cmd
        ret
tny_eraser:
        ld      a,#EF9367_CMD_DMOD_CLR
        call    ef9367_cmd
        ret



TNY_TRACE:
        ;; TRACE.
        push    af
        ITRACE  9
        ;; points
        ld      a,(ix)
        WTRACEA 0
        ld      a,1(ix)
        WTRACEA 1
        ld      a,2(ix)
        WTRACEA 2
        ld      a,3(ix)
        WTRACEA 3
        ;; rect
        ld      a,10(ix)
        WTRACEA 4
        ld      a,11(ix)
        WTRACEA 5
        ld      a,12(ix)
        WTRACEA 6
        ld      a,13(ix)
        WTRACEA 7
        ;; status
        ld      a,9(ix)
        WTRACEA 8
        pop     af
        ret


        ;; ---------------------
		;; void _ef9367_stride()
        ;; ---------------------
        ;; draw fast stride at (preset) x,y
        ;; inputs: 
        ;;  hl = data
        ;;  e=start bit
        ;;  d=end bit
        ;; affect:  af, de, hl
__ef9367_stride::
        ;; calculate difference in pixels
        ld      a,d
        sub     e                       ; a=end-start
        ld      c,a                     ; store to c
        ;; start is in bits, how many bytes to skip?
        xor     a                       ; a=0
        srl     e                       ; e=e/2
        rla                             ; into a
        srl     e                       ; e=e/4
        rla                             ; into a
        srl     e                       ; e=e/8
        rla                             
        ;; e=bytes to skip, a=remainder
        ld      d,#0                    ; de=bytes to skip
        add     hl,de                   ; we are at right byte!
        ;; a=current bit (from the left), c=total bits, hl=address
        ld      d,(hl)                  ; first byte to default
        ;; do we need initial shift?
        or      a                       ; rotate is 0 bits?
        jr      z,strd_start            ; we are ready
        ;; let's do initial shift
        ld      b,a                     ; counter to a
strd_shift:
        sla     d                       ; shift data
        djnz    strd_shift              ; and loop
strd_start:
        ;; at this point - 
        ;;  a is current shift 
        ;;  d is shifted data 
        ;;  hl=address
        ;;  c total number of bits
        ld      b,c                     ; b will be our counter
strd_loop:
        ;; get the bit into carry
        push    af
        sla     d   
        jr      nc,strd_skip_draw       ; no bit?
        ;; draw it
        call    __ef9367_put_pixel   
strd_skip_draw:
        call    __ef9367_move_right
        pop     af
        inc     a                       ; next bit
        cp      #8                      ; across byte boundary?
        jr      nz,strd_get_nxt         ; nope...
        ;; we are across byte boundary
        xor     a                       ; bit is 0 from the left
        inc     hl                      ; next byte
        ld      d,(hl)                  ; into d
strd_get_nxt:
        ;; and next bit
        djnz    strd_loop
        ;; we're done
        ret


        ;; ----------------------
		;; void _ef9367_draw_line(
        ;;     unsigned int  x0, 
        ;;     unsigned int  y0, 
        ;;     unsigned int  x1,
        ;;     unsigned int  y1);  
        ;; ----------------------
		;; draws line fast
        ;; affect: 
__ef9367_draw_line::
        ;; store ix to stack, we'll use it to access args.
        push    ix
        ld      ix,#4                   ; first arg.
        add     ix,sp
        ;; y0 to de
        ld      e,2(ix)                 ; de=y0
        ld      d,3(ix)
        ;; goto hl=x,de=y
        ld      l,(ix)
        ld      h,1(ix)
        push    de                      ; gotoxy changes it
        call    ef9367_xy
        pop     de
        ;; find delta signs and mex line len
        ;; a will hold the deltas -
        ;; bit 2: negative dy (reverse axis!)
        ;; bit 1: negative dx
        ;; the rest: ef command
        ld      a,#0b00010001           ; command
        ld      l,6(ix)                 ; hl=y1
        ld      h,7(ix)
        push    hl                      ; store y1.
        or      a                       ; clear carry flag
        sbc     hl,de                   ; hl=y1-y0-c (C=0)
        ;; note: partner has reverse y axis
        jr      c, dli_negat_dy         ; y1<y0, no change to delta sign
        pop     de                      ; clean the stack (remove y1)
        ;; set flag (remember, reverse y axis!)
        or      #4                      ; set flag (bit 2 of a)
        jr      dli_dy_done             ; we're done 
dli_negat_dy:
        pop     hl                      ; hl=y1 (again)
        ex      de,hl                   ; reverese equation
        or      a                       ; clear carry...
        sbc     hl,de                   ; and make result positive
        ;; at this point hl is abs(dy)
dli_dy_done:
        ex      de,hl                   ; de=abs(y1-y0)
        ;; start dx calculation
        ld      c,(ix)                  ; bc=x0
        ld      b,1(ix)
        ld      l,4(ix)                 ; hl=x1
        ld      h,5(ix)
        pop     ix                      ; restore ix forever to cln. stack
        push    de                      ; store abs(y1-y0) to stack
        push    hl                      ; store the x1 
        or      a                       ; clear carry flag
        sbc     hl,bc                   ; hl=x1-x0
        jr      nc,dli_posit_dx         ; x1>=x0, sign 0 is ok    
        or      #2                      ; set bit 1 of delta to -, C=0
        pop     de                      ; de=x1       
        push    bc                      ; bc to hl
        pop     hl                      ; hl=x0
        sbc     hl,de                   ; hl=abs(x0-x1)
        jr      dli_dx_done    
dli_posit_dx:
        pop     de                      ; clean the stack (remove x1)
dli_dx_done:
        ;; hl = abs(x1-x0) and abs(y1-y0) is already on stack
        pop     de                      ; de=abs(y1-y0)
        ;; but push back for later
        push    de
        push    hl                      ; both distances to stack
        ;; now find longer to find out how many lines 
        ;; hl=dx, de=dy
        or      a                       ; clear carry
        sbc     hl,de
        jr      c,dli_dy_longer
        pop     hl                      ; hl is the longer one
        push    hl                      ; put it back
        jr      dli_draw_lines
dli_dy_longer:
        ex      de,hl                   ; move longer one to hl
dli_draw_lines:
        ;; store longer one to stack
        push    hl
        ;; start the recursion. there are four parameters
        ;; on stack (in the pop order): longest coordinate, 
        ;; abs(dx), abs(dy), and return
dli_recursion:
        pop     hl                      ; get longest coordinate
        push    hl                      ; and store to stack for consistency
        ld      de,#EF9367_MAX_DELTA    ; max line we can draw
        or      a                       ; clear carry flag
        sbc     hl,de                   ; commpare
        jr      c, dli_draw_delta       ; end of recursion
        ;; we can't draw this
        ;; find mid point and divide 
        ;; the line to two lines        ;
        exx                             ; we'll need more registers
        pop     de                      ; get longest coordinate into de
        push    de
        pop     hl                      ; AND into hl
        srl     d                       ; de=long. coord/2
        rr      e
        or      a                       ; clear carry
        sbc     hl,de                   ; hl=long. coord-de (/2 for odd numbers!)
        exx
        ;; do the same for dx with std. register sets
        pop     de                      ; de=dx
        push    de
        pop     hl                      ; AND into hl
        srl     d                       ; de=dx/2
        rr      e
        or      a                       ; clear carry
        sbc     hl,de                   ; hl=dx-de (/2 for odd numbers!)
        ;; and, finally, for dy use bc and bc' as storage!
        pop     bc                      ; bc=dy
        push    bc                      ; store back
        push    hl                      ; store hl...
        exx 
        pop     bc                      ; ...into alt bc
        exx
        pop     hl                      ; hl=(also) dy
        srl     b                       ; bc=dy/2
        rr      c
        or      a                       ; clear carry
        sbc     hl,bc                   ; hl=dy-dy/2
        ;; we have it all!
        ;; only return address left on staqck at this point, leave it!
        ;; nicely put halved args back to stack in reverse order, longer first!
        push    hl                      ; dy2
        exx
        push    bc                      ; dx2
        push    hl                      ; longer coord. 2
        exx
        ;; now the shorter line
        ld      hl,#dli_recursion       ; restart the recursion upon return
        push    hl
        push    bc                      ; dy1
        push    de                      ; dx1
        exx
        push    de                      ; shorter longest coord.
        exx
        jr      dli_recursion
dli_draw_delta:
        pop     hl                      ; longest coord. ... discharge it
        pop     hl                      ; hl=dx
        pop     de                      ; de=dy
        ld      c,l                     ; b=dx
        ld      b,e                     ; c=dy 
        ;; superfast line drawing (delta method)
        push    af                      ; store command
        call    ef9367_dxdy             ; set dx, dy
        pop     af
        ;; command is in a
        call    ef9367_cmd
        ret