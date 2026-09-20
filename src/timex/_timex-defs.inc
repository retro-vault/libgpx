        ;; _timex-defs.inc
        ;;
        ;; Timex/Sinclair 512x192 high-resolution display definitions.
        ;;
        ;; The display is made from two Spectrum-format bitmap files. Logical
        ;; eight-pixel columns alternate between the primary file at 0x4000
        ;; and the secondary file at 0x6000; both use the Spectrum's familiar
        ;; non-linear scanline order.

        .equ    TIMEX_VRAM0,            0x4000
        .equ    TIMEX_VRAM1,            0x6000
        .equ    TIMEX_BITMAP_SIZE,      0x1800
        .equ    TIMEX_FILE_DELTA,       0x2000
        .equ    TIMEX_WIDTH,            512
        .equ    TIMEX_HEIGHT,           192
        .equ    TIMEX_LOGICAL_ROW_BYTES, 64
        .equ    TIMEX_FILE_ROW_BYTES,   32

        ;; SCLD display enhancement control, port 0xff. Bits 2..0 = 110 select
        ;; the 64-column / 512-pixel mode; colour bits 5..3 = 000 select black
        ;; ink on white paper.
        .equ    TIMEX_VIDEO_PORT,       0xFF
        .equ    TIMEX_HIRES_BW,         0x06

        .equ    TIMEX_SOLID,            0xFF
        .equ    TIMEX_PIXMASK,          7
