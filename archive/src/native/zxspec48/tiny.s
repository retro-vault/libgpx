        ;; tiny.s
        ;; 
        ;; Draw tiny.
		;;
        ;; MIT License (see: LICENSE)
        ;; Copyright (C) 2021 Tomaz Stih
        ;;
		;; 13.08.2021   tstih
        .module tiny

        .globl  __tinyxy

        .area   _CODE

        ;; -------------------
        ;; extern void _tinyxy(
        ;;    coord x, 
        ;;    coord y, 
        ;;    uint8_t *moves,
        ;;    uint8_t num,
        ;;    tiny_clip_t *clip);
        ;; -------------------
        ;; draw tiny moves at x,y, 
        ;; affects: just about everything
__tinyxy::
        ret