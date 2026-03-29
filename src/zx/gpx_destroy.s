        ;; gpx_destroy.s
        ;;
        ;; ZX Spectrum GPX destroy routine.

        .module gpx_destroy
        .optsdcc -mz80 sdcccall(1)

        .globl  _gpx_destroy
        .globl  __gpx_ctx

        .area   _CODE

        ;; void gpx_destroy(gpx_t *gpx)
        ;;   HL = gpx (ignored for ZX static backend)
_gpx_destroy::
        ret
