        ;; gpx_hide_sprite.s
        ;;
        ;; ZX Spectrum save-under sprite hide path.

        .module gpx_hide_sprite
        .optsdcc -mz80 sdcccall(1)

        .globl  _gpx_hide_sprite
        .globl  __gpx_sprite_blit_raw

        .area   _CODE

        ;; ------------------------------------------------------------
        ;; void gpx_hide_sprite(gpx_t *gpx, sprite_t *sprite)
        ;;
        ;; Input:
        ;;   HL = gpx
        ;;   DE = sprite
_gpx_hide_sprite::
        ld      a,d
        or      e
        ret     z

        ex      de,hl

        ld      c,(hl)                ;; x low
        inc     hl
        ld      a,(hl)                ;; x high
        or      a
        ret     nz

        inc     hl
        ld      b,(hl)                ;; y low
        inc     hl
        ld      a,(hl)                ;; y high
        or      a
        ret     nz

        ld      a,b
        cp      #192
        ret     nc

        inc     hl                    ;; skip bitmap pointer
        inc     hl
        ld      e,(hl)                ;; background pointer
        inc     hl
        ld      d,(hl)
        ld      a,d
        or      e
        ret     z

        ex      de,hl
        ld      a,#1                  ;; standard bitmap copy mode
        call    __gpx_sprite_blit_raw
        ret
