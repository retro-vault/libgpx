        ;; stride.s
        ;; 
        ;; Draw stride.
		;;
        ;; MIT License (see: LICENSE)
        ;; Copyright (C) 2021 Tomaz Stih
        ;;
		;; 13.08.2021   tstih
        .module stride

        .globl  __stridexy

        .area   _CODE

        ;; -------------------
        ;; void _stridexy(
        ;;      coord x, 
        ;;      coord y, 
        ;;      void *data, 
        ;;      uint8_t start, 
        ;;      uint8_t end)
        ;; -------------------
        ;; draw stride (scan line) at x,y, left to right,
        ;; starting with bit start and ending with bit end
        ;; affects: just about everything
__stridexy::
        ret