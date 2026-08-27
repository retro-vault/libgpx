        ;; gpx_clrscr.s
        ;;
        ;; Amstrad CPC screen clear.
        ;;
        ;; GPL2 License (see: LICENSE)
        ;; Copyright (C) 2026 Tomaz Stih
        ;;
        ;; 2026-08-26   TS

        .module gpx_clrscr
        .optsdcc -mz80 sdcccall(1)

        .include "_cpc-defs.inc"

        .globl  _gpx_clrscr

        .area   _CODE

        ;; ------------------------------------------------------------
        ;; _gpx_clrscr
        ;; Clear the whole 16 KiB framebuffer to paper. Every byte of it is
        ;; display memory in both modes, so there is no attribute area to
        ;; follow and no border write: gpx_create already matched the border
        ;; to the paper pen.
        ;;
        ;; The clear runs on the stack pointer. CPC memory timing rounds
        ;; every instruction up to a multiple of four T-states, which makes
        ;; a store-and-increment pair cost twelve for one byte while `push`
        ;; costs twelve for two: writing through SP is exactly twice as fast
        ;; here, and this is the largest single write the library ever does.
        ;; The price is that interrupts must be off while SP points at the
        ;; screen, so the caller's interrupt state is saved and restored
        ;; around it rather than assumed.
        ;;
        ;; Signature:
        ;;   void gpx_clrscr(void)
        ;;
        ;; Clobbers:
        ;;   AF, BC, DE, HL
_gpx_clrscr::
        ld      a,i                     ; P/V now carries IFF2
        push    af
        di
        ld      (.cls_sp),sp
        ld      sp,#(CPC_VRAM + CPC_VRAM_SIZE)

        ;; 16 KiB is 512 blocks of thirty-two bytes, which does not fit a
        ;; single 8-bit counter: two passes of djnz's full 256 do. The block
        ;; is wide enough that the loop test costs well under a T-state a
        ;; byte.
        ld      hl,#0x0000
        ld      d,h
        ld      e,l
        ld      c,#(CPC_VRAM_SIZE / 32 / 256)
.cls_outer:
        ld      b,#0                    ; djnz: 0 means 256
.cls_block:
        push    hl
        push    de
        push    hl
        push    de
        push    hl
        push    de
        push    hl
        push    de
        push    hl
        push    de
        push    hl
        push    de
        push    hl
        push    de
        push    hl
        push    de
        djnz    .cls_block
        dec     c
        jr      nz,.cls_outer

        ld      sp,(.cls_sp)
        pop     af
        ret     po                      ; interrupts were already off
        ei
        ret

        .area   _DATA

        ;; The caller's stack, parked while SP walks the screen.
.cls_sp:
        .dw     0
