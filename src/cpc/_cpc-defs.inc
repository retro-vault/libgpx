        ;; _cpc-defs.inc
        ;;
        ;; Amstrad CPC hardware definitions, and the two constants that
        ;; make one source tree assemble into either display mode.
        ;;
        ;; Assemble with -DCPC_MODE1 for the 320x200 library, or with
        ;; nothing for the default 640x200 one. Everything mode dependent
        ;; is derived here so no routine has to test the mode at run time:
        ;; the CPC has no spare cycles for that, and the two libraries are
        ;; built and shipped separately anyway.

        ;; --- framebuffer ----------------------------------------------------
        .equ    CPC_VRAM,               0xC000  ; screen base
        .equ    CPC_VRAM_SIZE,          0x4000  ; sixteen kilobytes
        .equ    CPC_ROW_BYTES,          80      ; bytes per scanline, both modes
        .equ    CPC_BANK_STEP,          0x800   ; distance between scanline banks
        .equ    CPC_HEIGHT,             200

        ;; --- Gate Array -----------------------------------------------------
        .equ    GA_PORT_HI,             0x7F    ; port 0x7Fxx
        .equ    GA_PEN,                 0x00    ; 0x00 | pen        select pen
        .equ    GA_BORDER,              0x10    ; pen 16 is the border
        .equ    GA_INK,                 0x40    ; 0x40 | hw colour  set colour
        .equ    GA_RMR,                 0x80    ; 0x80 | mode | rom disables
        .equ    GA_ROM_LO_OFF,          0x04
        .equ    GA_ROM_HI_OFF,          0x08

        ;; --- hardware colours we use ----------------------------------------
        .equ    CPC_BLACK,              0x14
        .equ    CPC_WHITE,              0x0B

        ;; --- CRTC -----------------------------------------------------------
        .equ    CRTC_SELECT_HI,         0xBC    ; port 0xBCxx, register index
        .equ    CRTC_DATA_HI,           0xBD    ; port 0xBDxx, register value
        .equ    CRTC_REGS,              14

        ;; --- display modes -------------------------------------------------
        ;; One library serves both modes: gpx_create() programs the hardware
        ;; and fills in the variables below, and every mode-dependent path
        ;; reads them. The values are chosen so the difference is a mask and
        ;; a shift rather than two separate code bases.
        ;;
        ;; Mode 1 packs four pixels per byte across two bit planes: pixel p
        ;; takes plane 1 from bit 7-p and plane 2 from bit 3-p. Drawing in
        ;; pen 1 therefore uses only the high nibble, which leaves the pixel
        ;; mask the same top-bit-first shape as mode 2 -- just four pixels
        ;; wide -- so one mask table serves both.
        .equ    GPXM_CPC_640X200,       0
        .equ    GPXM_CPC_320X200,       1

        .equ    CPC_W_640,              640
        .equ    CPC_W_320,              320
        .equ    CPC_SOLID_640,          0xFF    ; eight pixels of a byte
        .equ    CPC_SOLID_320,          0xF0    ; four pixels, high nibble
        .equ    CPC_PIXMASK_640,        7
        .equ    CPC_PIXMASK_320,        3
