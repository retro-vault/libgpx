        ;; gpx_set_text_background.s
        ;;
        ;; Partner text background policy setter.
        ;;
        ;; GPL2 License (see: LICENSE)
        ;; Copyright (C) 2026 Tomaz Stih
        ;;
        ;; 2026-08-26   TS

        .module gpx_set_text_background
        .optsdcc -mz80 sdcccall(1)

        .globl  _gpx_set_text_background

        .area   _CODE

        ;; ------------------------------------------------------------
        ;; _gpx_set_text_background
        ;; Select opaque (0) or transparent (1) text cell rendering.
        ;;
        ;; Signature:
        ;;   void gpx_set_text_background(gpx_t *gpx, textbg background)
        ;;
        ;; Arguments:
        ;;   HL = gpx
        ;;   stack: background
        ;;
        ;; Clobbers:
        ;;   AF, B, DE, HL, IX
_gpx_set_text_background::
        pop     de                      ; return address
        pop     bc                      ; C = the one-byte argument
        dec     sp                      ; leave the following caller byte intact
        ld      a,h
        or      l
        jr      z,.gstb_done

        ld      a,c
        and     #0x01
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        inc     hl                      ; -> gpx->text_background
        ld      (hl),a

.gstb_done:
        push    de
        ret
