        ;; gpx_set_page.s
        ;;
        ;; ZX Spectrum page selection API.
        ;; Current backend keeps this as a no-op.

        .module gpx_set_page
        .optsdcc -mz80 sdcccall(1)

        .globl  _gpx_set_page

        .area   _CODE

        ;; void gpx_set_page(uint8_t op, uint8_t page)
        ;;   A = op
        ;;   L = page
_gpx_set_page::
        ret
