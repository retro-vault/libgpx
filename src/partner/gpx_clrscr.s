        ;; gpx_clrscr.s
        ;;
        ;; Partner clear-screen primitive.
        ;;
        ;; GPL2 License (see: LICENSE)
        ;; Copyright (C) 2026 Tomaz Stih
        ;;
        ;; 2026-03-30   TS

        .module gpx_clrscr
        .optsdcc -mz80 sdcccall(1)

        .globl  _gpx_clrscr
        .globl  __ef9367_exec_cmd

        .include "_ef9367-defs.inc"

        .area   _CODE

        ;; ------------------------------------------------------------
        ;; void gpx_clrscr(void)
        ;;
        ;; Clobbers:
        ;;   AF
_gpx_clrscr::
        ld      a,#EF9367_CMD_CLS
        call    __ef9367_exec_cmd
        ret
