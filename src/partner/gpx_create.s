        ;; gpx_create.s
        ;;
        ;; Partner GPX lifecycle and shared context pointer.
        ;;
        ;; GPL2 License (see: LICENSE)
        ;; Copyright (C) 2026 Tomaz Stih
        ;;
        ;; 2026-04-04   TS

        .module gpx_create
        .optsdcc -mz80 sdcccall(1)

        .globl  _gpx_create
        .globl  __gpx_ctx
        .globl  __gdata
        .globl  __ef9367_wait_ready
        .globl  __ef9367_exec_cmd
        .globl  __ef9367_set_gr_cmn
        .globl  __ef9367_gr_cmn
        .globl  __ef9367_max_y
        .globl  __ef9367_set_blit_mode
        .globl  __ef9367_set_color
        .globl  __ef9367_cache_bmode
        .globl  __ef9367_cache_color
        .globl  __ef9367_cache_pen
        .globl  __ef9367_cache_line_style

        .include "_ef9367-defs.inc"

        .equ    GPXM_DEFAULT,           0x00
        .equ    CO_FORE,                0x01
        .equ    BM_CPY,                 0x00
        .equ    GPX_TEXT_BG_OPAQUE,     0x00

        .equ    SCRWIDTH,               0x0400 ; 1024
        .equ    SCRHEIGHT_LO,           0x0100 ; 256
        .equ    SCRHEIGHT_HI,           0x0200 ; 512
        .equ    SCRPAGES,               0x02 ; Partner has two pages

        .area   _CODE

        ;; ------------------------------------------------------------
        ;; gpx_t *gpx_create(gmode mode)
        ;; Arguments:
        ;;   A = mode (0 => 1024x256, 1 => 1024x512)
        ;;       any other value falls back to mode 0
        ;;
        ;; Return:
        ;;   DE = gpx_t*
        ;;
        ;; Clobbers:
        ;;   AF, BC, DE, HL
_gpx_create::
        ld      c,a                     ; keep requested mode

        ;; Baseline EF9367 setup.
        ld      a,#(EF9367_CR1_PEN_DOWN|EF9367_CR1_DMOD_TST)
        out     (EF9367_CR1),a
        xor     a
        out     (EF9367_CR2),a
        ld      a,#0b00100001
        out     (EF9367_CH_SIZE),a

        ;; Put GDP board PIO port A into mode 0 so its latch actually drives
        ;; the board. Out of PIO reset the port is in input mode and every
        ;; write to 0x30 is latched but never presented, so page selects, XOR
        ;; write mode and the format bits all silently do nothing. The boot
        ;; ROM programs this at 0x0170; repeating it here costs eight bytes
        ;; and makes the library work on a bare machine too. Both writes are
        ;; idempotent, so running after the ROM is harmless.
        ld      a,#PIO_CW_INT_DISABLE   ; int control word, EI clear
        out     (PIO_GR_A_CMD),a
        ld      a,#PIO_CW_MODE_OUTPUT   ; mode word: mode 0, all bits output
        out     (PIO_GR_A_CMD),a

        ;; Program Partner resolution bits in the board control latch. The
        ;; shadow starts at 0, matching the latch the two writes above leave.
        ld      a,#PIO_GR_CMN_1024x256  ; lores has both format bits clear
        ld      b,a
        ld      a,c
        cp      #1
        ld      a,b
        jr      nz,.gcr_set_res
        ld      a,#PIO_GR_CMN_1024x512
.gcr_set_res:
        call    __ef9367_set_gr_cmn

        ;; Fill shared gpx_t descriptor.
        ld      hl,#SCRWIDTH
        ld      (__gdata+0),hl
        ld      a,#SCRPAGES
        ld      (__gdata+4),a
        ld      a,#GPX_TEXT_BG_OPAQUE
        ld      (__gdata+5),a

        ld      a,c
        cp      #1
        jr      z,.gcr_hires_ctx

        ;; 1024x256 context
        ld      hl,#SCRHEIGHT_LO
        jr      .gcr_store_height

.gcr_hires_ctx:
        ;; 1024x512 context
        ld      hl,#SCRHEIGHT_HI

.gcr_store_height:
        ld      (__gdata+2),hl
        dec     hl                      ; max_y, hoisted out of every plot
        ld      (__ef9367_max_y),hl

.gcr_defaults:
        ;; Invalidate helper caches after direct register writes above.
        ld      a,#0xFF
        ld      (__ef9367_cache_bmode),a
        ld      (__ef9367_cache_color),a
        ld      (__ef9367_cache_pen),a
        xor     a
        ld      (__ef9367_cache_line_style),a ; CR2 already programmed to solid

        ;; Default drawing state: copy mode, foreground pen.
        ld      a,#BM_CPY
        call    __ef9367_set_blit_mode
        ld      a,#CO_FORE
        call    __ef9367_set_color

        ;; Clear graphics screen.
        ld      a,#EF9367_CMD_CLS
        call    __ef9367_exec_cmd

        ;; Update active context pointer and return it.
        ld      de,#__gdata
        ld      (__gpx_ctx),de
        ret

        .area   _DATA

        ;; Active context pointer used by width/height accessors.
__gpx_ctx::
        .dw     __gdata

        ;; Shared static Partner display descriptor (gpx_t).
__gdata::
        .dw     SCRWIDTH
        .dw     SCRHEIGHT_LO
        .db     SCRPAGES
        .db     GPX_TEXT_BG_OPAQUE
