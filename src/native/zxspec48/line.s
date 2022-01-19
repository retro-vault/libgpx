        ;; line.s
        ;; 
        ;; line drawing primitives
		;;
        ;; MIT License (see: LICENSE)
        ;; Copyright (C) 2021 Tomaz Stih
        ;;
		;; 2021-09-27   tstih
        .module line

        .globl  __hline
        .globl  __vline
        .globl  __line

        .area   _CODE

        ;; ----------------------------------------
        ;; void _hline(coord x0, coord x1, coord y)
        ;; ----------------------------------------
        ;; fast horizontal line drawing
__hline::
        ret

        ;; ----------------------------------------
        ;; void _vline(coord x, coord y0, coord y1)
        ;; ----------------------------------------
        ;; fast horizontal line drawing
__vline::
        ret