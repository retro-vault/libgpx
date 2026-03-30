        ;; gpx_create.s
        ;;
        ;; Partner GPX lifecycle and shared context pointer.

        .module gpx_create
        .optsdcc -mz80 sdcccall(1)

        .globl  _gpx_create
        .globl  __gpx_ctx
        .globl  __gdata
        .globl  __ef9367_wait_ready
        .globl  __ef9367_exec_cmd
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

        .equ    SCRWIDTH,               0x0400   ;; 1024
        .equ    SCRHEIGHT_LO,           0x0100   ;; 256
        .equ    SCRHEIGHT_HI,           0x0200   ;; 512
        .equ    SCRSTRIDE,              0x0080   ;; 128 bytes / row
        .equ    SCRSIZE_LO_LOWORD,      0x8000   ;; 32768 = 0x00008000
        .equ    SCRSIZE_LO_HIWORD,      0x0000
        .equ    SCRSIZE_HI_LOWORD,      0x0000   ;; 65536 = 0x00010000
        .equ    SCRSIZE_HI_HIWORD,      0x0001

        .area   _CODE

        ;; ------------------------------------------------------------
        ;; gpx_t *gpx_create(gmode mode)
        ;; Input:
        ;;   A = mode (0 => 1024x256, 1 => 1024x512)
        ;;       any other value falls back to mode 0
        ;;
        ;; Output:
        ;;   DE = gpx_t*
        ;;
        ;; Clobbers:
        ;;   AF, BC, DE, HL
_gpx_create::
        ld      c,a                     ;; keep requested mode

        ;; Baseline EF9367 setup.
        ld      a,#(EF9367_CR1_PEN_DOWN|EF9367_CR1_DMOD_TST)
        out     (EF9367_CR1),a
        xor     a
        out     (EF9367_CR2),a
        ld      a,#0b00100001
        out     (EF9367_CH_SIZE),a

        ;; Program Partner resolution bits in PIO_GR_CMN.
        call    __ef9367_wait_ready
        in      a,(PIO_GR_CMN)
        and     #PIO_GR_CMD_RES_MSK     ;; clear resolution bits
        ld      b,a
        ld      a,c
        cp      #1
        jr      z,.gcr_hires_reg
        ld      a,b
        or      #PIO_GR_CMN_1024x256
        out     (PIO_GR_CMN),a
        jr      .gcr_ctx
.gcr_hires_reg:
        ld      a,b
        or      #PIO_GR_CMN_1024x512
        out     (PIO_GR_CMN),a

.gcr_ctx:
        ;; Fill shared gpx_t descriptor.
        ld      hl,#SCRWIDTH
        ld      (__gdata+0),hl
        ld      hl,#SCRSTRIDE
        ld      (__gdata+4),hl

        ld      a,c
        cp      #1
        jr      z,.gcr_hires_ctx

        ;; 1024x256 context
        ld      hl,#SCRHEIGHT_LO
        ld      (__gdata+2),hl
        ld      hl,#SCRSIZE_LO_LOWORD
        ld      (__gdata+6),hl
        ld      hl,#SCRSIZE_LO_HIWORD
        ld      (__gdata+8),hl
        jr      .gcr_defaults

.gcr_hires_ctx:
        ;; 1024x512 context
        ld      hl,#SCRHEIGHT_HI
        ld      (__gdata+2),hl
        ld      hl,#SCRSIZE_HI_LOWORD
        ld      (__gdata+6),hl
        ld      hl,#SCRSIZE_HI_HIWORD
        ld      (__gdata+8),hl

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
        .dw     SCRSTRIDE
        .dw     SCRSIZE_LO_LOWORD
        .dw     SCRSIZE_LO_HIWORD
