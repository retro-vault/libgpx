        .module gpx_create_next_l2
        .optsdcc -mz80 sdcccall(1)
        .include "_zxnext-l2-defs.inc"
        .globl _gpx_create
        .globl _gpx_clrscr
        .globl __gpx_ctx
        .area _CODE
_gpx_create::
        ;; NextReg 0x12: active Layer 2 bank, 0x13: shadow bank.
        ld bc,#NXT_REG_SEL
        ld a,#0x12
        out (c),a
        ld bc,#NXT_REG_DATA
        ld a,#NXT_L2_BASE
        out (c),a
        ld bc,#NXT_REG_SEL
        ld a,#0x13
        out (c),a
        ld bc,#NXT_REG_DATA
        ld a,#(NXT_L2_BASE+5)
        out (c),a
        ;; NextReg 0x70: 640x256x4 Layer 2 mode.
        ld bc,#NXT_REG_SEL
        ld a,#0x70
        out (c),a
        ld bc,#NXT_REG_DATA
        ld a,#NXT_MODE_640
        out (c),a
        ;; Layer 2 first-palette entries used by the monochrome API:
        ;; index 0 black and index 15 white (RRRGGGBB).
        ld bc,#NXT_REG_SEL
        ld a,#0x43
        out (c),a
        ld bc,#NXT_REG_DATA
        ld a,#0x10
        out (c),a
        ld bc,#NXT_REG_SEL
        ld a,#0x40
        out (c),a
        ld bc,#NXT_REG_DATA
        xor a
        out (c),a
        ld bc,#NXT_REG_SEL
        ld a,#0x41
        out (c),a
        ld bc,#NXT_REG_DATA
        xor a
        out (c),a
        ld bc,#NXT_REG_SEL
        ld a,#0x40
        out (c),a
        ld bc,#NXT_REG_DATA
        ld a,#15
        out (c),a
        ld bc,#NXT_REG_SEL
        ld a,#0x41
        out (c),a
        ld bc,#NXT_REG_DATA
        ld a,#0xff
        out (c),a
        ;; Make Layer 2 the visible monochrome canvas while the API is active.
        ld bc,#NXT_REG_SEL
        ld a,#0x68
        out (c),a
        ld bc,#NXT_REG_DATA
        ld a,#0x80
        out (c),a
        ld bc,#NXT_REG_SEL
        ld a,#0x15
        out (c),a
        ld bc,#NXT_REG_DATA
        xor a
        out (c),a
        call _gpx_clrscr
        xor a
        ld (__gpx_data+5),a
        ld de,#__gpx_data
        ld (__gpx_ctx),de
        ret
        .area _DATA
__gpx_ctx:: .dw __gpx_data
__gpx_data::
        .dw NXT_WIDTH
        .dw NXT_HEIGHT
        .db NXT_PAGES
        .db 0
