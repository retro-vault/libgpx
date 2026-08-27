        ;; gpx_destroy.s
        ;;
        ;; Partner GPX destroy routine.
        ;;
        ;; GPL2 License (see: LICENSE)
        ;; Copyright (C) 2026 Tomaz Stih
        ;;
        ;; 2026-03-30   TS

        .module gpx_destroy
        .optsdcc -mz80 sdcccall(1)

        .globl  _gpx_destroy

        .area   _CODE

        ;; ------------------------------------------------------------
        ;; void gpx_destroy(gpx_t *gpx)
        ;; Arguments:
        ;;   HL = gpx (ignored for static Partner backend)
        ;;
        ;; Return:
        ;;   none
        ;;
        ;; Clobbers:
        ;;   none
_gpx_destroy::
        ret
