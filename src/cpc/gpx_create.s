        ;; gpx_create.s
        ;;
        ;; Amstrad CPC graphics bring-up.
        ;;
        ;; The library programs the CRTC and the Gate Array itself, so a
        ;; libgpx program runs from a raw binary with both ROMs paged out
        ;; and never depends on the firmware having set the screen up.
        ;;
        ;; GPL2 License (see: LICENSE)
        ;; Copyright (C) 2026 Tomaz Stih
        ;;
        ;; 2026-08-26   TS

        .module gpx_create
        .optsdcc -mz80 sdcccall(1)

        .include "_cpc-defs.inc"

        .globl  _gpx_create
        .globl  _gpx_clrscr
        .globl  __gpx_ctx
        .globl  __gpx_data
        .globl  __cpc_mode1
        .globl  __cpc_solid
        .globl  __cpc_pixmask
        .globl  __cpc_width
        .globl  __rect_screen

        .equ    GPX_TEXT_BG_OPAQUE, 0x00
        .equ    SCRPAGES,  0x01         ; one framebuffer page

        .area   _CODE

        ;; ------------------------------------------------------------
        ;; _gpx_create
        ;; Bring up the graphics subsystem and hand back the drawing
        ;; context. The mode argument selects the display mode: one library
        ;; serves both, so everything mode dependent is settled here and
        ;; read from _gpx_mode.s afterwards.
        ;;
        ;; Signature:
        ;;   gpx_t *gpx_create(gmode mode)
        ;;
        ;; Arguments:
        ;;   A = GPXM_CPC_640X200 (also GPXM_DEFAULT) or GPXM_CPC_320X200
        ;;
        ;; Return:
        ;;   DE = gpx_t*, the static display descriptor
        ;;
        ;; Clobbers:
        ;;   AF, BC, DE, HL
        ;;
        ;; References:
        ;;   _gpx_clrscr
        ;;   __gpx_ctx
        ;;   __gpx_data
_gpx_create::
        ;; --- settle the mode before anything reads it ---
        and     #0x01                   ; anything else means the default
        ld      (__cpc_mode1),a
        or      a
        jr      nz,.gc_mode1

        ld      a,#CPC_SOLID_640
        ld      (__cpc_solid),a
        ld      a,#CPC_PIXMASK_640
        ld      (__cpc_pixmask),a
        ld      hl,#CPC_W_640
        ld      a,#(GA_RMR | 2 | GA_ROM_LO_OFF | GA_ROM_HI_OFF)
        jr      .gc_mode_set
.gc_mode1:
        ld      a,#CPC_SOLID_320
        ld      (__cpc_solid),a
        ld      a,#CPC_PIXMASK_320
        ld      (__cpc_pixmask),a
        ld      hl,#CPC_W_320
        ld      a,#(GA_RMR | 1 | GA_ROM_LO_OFF | GA_ROM_HI_OFF)
.gc_mode_set:
        ld      e,a                     ; Gate Array mode survives the CRTC loop
        ld      (__cpc_width),hl
        ld      (__gpx_data),hl         ; gpx_t.width
        dec     hl
        ld      (__rect_screen+4),hl    ; the screen rect's x1

        ;; --- CRTC: 40 columns, 25 rows of 8 lines, screen at 0xC000 ---
        ld      hl,#.gc_crtc
        ld      c,#0x00
.gc_crtc_loop:
        ld      b,#CRTC_SELECT_HI
        out     (c),c                   ; select register C
        ld      b,#CRTC_DATA_HI
        ld      a,(hl)
        out     (c),a                   ; write its value
        inc     hl
        inc     c
        ld      a,c
        cp      #CRTC_REGS
        jr      nz,.gc_crtc_loop

        ;; --- Gate Array: two pens, the border, then the mode ---
        ld      b,#GA_PORT_HI
        ld      a,#(GA_PEN | 0)
        out     (c),a
        ld      a,#(GA_INK | CPC_BLACK)
        out     (c),a                   ; pen 0 = paper
        ld      a,#(GA_PEN | 1)
        out     (c),a
        ld      a,#(GA_INK | CPC_WHITE)
        out     (c),a                   ; pen 1 = ink
        ld      a,#GA_BORDER
        out     (c),a
        ld      a,#(GA_INK | CPC_BLACK)
        out     (c),a                   ; border matches the paper

        ;; Selecting the mode also pages both ROMs out, which is what
        ;; puts RAM under 0x0000 and 0xC000 for a raw binary.
        ld      a,e
        out     (c),a

        call    _gpx_clrscr
        xor     a                       ; GPX_TEXT_BG_OPAQUE
        ld      (__gpx_data+5),a
        ld      de,#__gpx_data
        ld      (__gpx_ctx),de
        ret

        ;; The stock 40x25 screen. These are the values the firmware
        ;; itself programs, so the picture sits exactly where a normal
        ;; CPC picture sits.
.gc_crtc:
        .db     63                      ; R0  horizontal total
        .db     40                      ; R1  horizontal displayed
        .db     46                      ; R2  horizontal sync position
        .db     0x8E                    ; R3  sync widths
        .db     38                      ; R4  vertical total
        .db     0                       ; R5  vertical total adjust
        .db     25                      ; R6  vertical displayed
        .db     30                      ; R7  vertical sync position
        .db     0                       ; R8  interlace off
        .db     7                       ; R9  maximum raster
        .db     0                       ; R10 cursor start
        .db     0                       ; R11 cursor end
        .db     0x30                    ; R12 display start high -> 0xC000
        .db     0x00                    ; R13 display start low

        .area   _DATA

        ;; Internal active context pointer used by gpx_width/gpx_height.
__gpx_ctx::
        .dw     __gpx_data

        ;; Amstrad CPC display descriptor (gpx_t). The width is filled in
        ;; by gpx_create once the mode is known.
__gpx_data::
        .dw     CPC_W_640
        .dw     CPC_HEIGHT
        .db     SCRPAGES
        .db     GPX_TEXT_BG_OPAQUE
