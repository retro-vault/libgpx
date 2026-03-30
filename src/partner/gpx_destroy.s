        ;; gpx_destroy.s
        ;;
        ;; Partner GPX destroy routine.

        .module gpx_destroy
        .optsdcc -mz80 sdcccall(1)

        .globl  _gpx_destroy

        .area   _CODE

        ;; ------------------------------------------------------------
        ;; void gpx_destroy(gpx_t *gpx)
        ;; Input:
        ;;   HL = gpx (ignored for static Partner backend)
        ;;
        ;; Output:
        ;;   none
        ;;
        ;; Clobbers:
        ;;   none
_gpx_destroy::
        ret
