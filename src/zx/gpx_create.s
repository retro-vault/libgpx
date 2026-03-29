        ;; gpx_create.s
        ;;
        ;; ZX Spectrum GPX lifecycle and shared context pointer.

        .module gpx_create
        .optsdcc -mz80 sdcccall(1)

        .globl  _gpx_create
        .globl  _gpx_clrscr
        .globl  __gpx_ctx

        .equ    GPXM_DEFAULT, 0x00

        .equ    SCRWIDTH,  0x0100       ;; 256
        .equ    SCRHEIGHT, 0x00c0       ;; 192
        .equ    SCRSTRIDE, 0x0020       ;; 32 bytes / row
        .equ    SCRSIZE,   0x1800       ;; 6144 bytes

        .area   _CODE

        ;; gpx_t *gpx_create(gmode mode)
        ;;   A  = mode
        ;;   DE = gpx_t* (or 0 on failure)
_gpx_create::
        call    _gpx_clrscr
        ld      de,#__gpx_data
        ld      (__gpx_ctx),de
        ret

        .area   _DATA

        ;; Internal active context pointer used by gpx_width/gpx_height.
__gpx_ctx::
        .dw     __gpx_data

        ;; Static ZX Spectrum display descriptor (gpx_t).
__gpx_data::
        .dw     SCRWIDTH
        .dw     SCRHEIGHT
        .dw     SCRSTRIDE
        .dw     SCRSIZE
