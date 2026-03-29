        ;; gpx-cls.s
        ;; 
        ;; clear screen function
		;;
        ;; MIT License (see: LICENSE)
        ;; Copyright (C) 2021 Tomaz Stih
        ;;
		;; 2021-06-16   tstih
        .module gpxcls

        .globl  _gpx_cls

        .area   _CODE

        .equ    VMEMBEG, 0x4000         ; video ram
        .equ    VMEMSZE, 0x1800         ; raster size
        .equ    ATTRSZE, 0x02ff         ; attr size

        .equ    BDRPORT, 0xfe           ; border port

        ;; -----------------------
		;; void _gpx_cls(gpx_t *g)
        ;; -----------------------
        ;; clears the screen using current background
        ;; (paper) and foreground (ink) color 
        ;; input:   a=background color
        ;;          b=foreground color
        ;; affects: af, hl, de, bc
_gpx_cls::
        pop     de                      ; return address
        pop     hl                      ; g
        ;; restore stack
        push    hl
        push    de
        ;; get correct address
        ld      de,#23                  ; offset
        add     hl,de                   ; add to hl
        ;; get fore color
        ld      b,(hl)
        inc     hl
        inc     hl
        ;; get back color
        ld      a,(hl)
        out     (#BDRPORT),a            ; set border
        ;; prepare attr
        rlca                            ; bits 3-5
        rlca
        rlca
        and     #0xf8
        or      b                       ; ink color to bits 0-2
        ;; first vmem
        ld      hl,#VMEMBEG             ; vmem
        ld      bc,#VMEMSZE             ; size
        ld      (hl),l                  ; l=0
        ld      d,h
        ld      e,#1
        ldir         
        ;; now attr
        ld      (hl),a                  ; attr
        ld      bc,#ATTRSZE             ; size of attr
        ldir
        ret