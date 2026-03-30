        ;; _gpx_font_12x16_tiny.s
        ;;
        ;; Decoded font blob (single-label layout).
        .module gpx_font_12x16_tiny

        .globl _gpx_font_12x16_tiny

        .area _CODE
_gpx_font_12x16_tiny::
        ;; font header
        .db 4                   ; font flags (bit0 proportional, bit1 offsets_be, bit2 vector)
        .db 32                  ; first ascii
        .db 127                 ; last ascii
        .db 0                   ; empty_width
        .db 12                  ; max_glyph_width
        .db 16                  ; glyph_height
        .db 0                   ; advance
        .db 0                   ; descent

        ;; glpyh offsets
        .dw 0x00C8, 0x00CC, 0x00D7, 0x00E0, 0x00F9, 0x0117, 0x012C, 0x0148
        .dw 0x0150, 0x0160, 0x016B, 0x0186, 0x0195, 0x019F, 0x01A8, 0x01B1
        .dw 0x01C0, 0x01DA, 0x01EE, 0x0207, 0x021F, 0x0235, 0x024C, 0x0263
        .dw 0x0272, 0x028C, 0x02A6, 0x02B0, 0x02BE, 0x02CF, 0x02DB, 0x02E9
        .dw 0x02FF, 0x031E, 0x0334, 0x034D, 0x035E, 0x036C, 0x037D, 0x038C
        .dw 0x03A1, 0x03B8, 0x03CB, 0x03E0, 0x03F1, 0x03FC, 0x0414, 0x042B
        .dw 0x0444, 0x0456, 0x046F, 0x0485, 0x049B, 0x04AB, 0x04BD, 0x04CF
        .dw 0x04E3, 0x04F7, 0x0503, 0x0516, 0x0526, 0x052E, 0x053D, 0x054A
        .dw 0x0555, 0x055D, 0x0570, 0x0582, 0x0593, 0x05AA, 0x05C0, 0x05D1
        .dw 0x05ED, 0x05FE, 0x060E, 0x0620, 0x0633, 0x0643, 0x065A, 0x066B
        .dw 0x0681, 0x0697, 0x06B0, 0x06BF, 0x06D7, 0x06EA, 0x06FC, 0x070C
        .dw 0x071E, 0x072E, 0x0744, 0x0751, 0x0762, 0x076C, 0x077B, 0x0785

        ;; ascii 32: ' '
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 0                   ; # moves
        ;; ascii 33: '!'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 7                   ; # moves
        .db 112                 ; move dx=3, dy=2, color=none (move only!)
        .db 96                  ; move dx=3, dy=0, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 24                  ; move dx=0, dy=3, color=none (move only!)
        .db 8                   ; move dx=0, dy=1, color=none (move only!)
        .db 128                 ; move dx=0, dy=0, color=fore (set)
        ;; ascii 34: '"'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 5                   ; # moves
        .db 64                  ; move dx=2, dy=0, color=none (move only!)
        .db 144                 ; move dx=0, dy=2, color=fore (set)
        .db 116                 ; move dx=3, dy=-2, color=none (move only!)
        .db 32                  ; move dx=1, dy=0, color=none (move only!)
        .db 144                 ; move dx=0, dy=2, color=fore (set)
        ;; ascii 35: '#'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 21                  ; # moves
        .db 80                  ; move dx=2, dy=2, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 74                  ; move dx=-2, dy=1, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 226                 ; move dx=-3, dy=0, color=fore (set)
        .db 226                 ; move dx=-3, dy=0, color=fore (set)
        .db 92                  ; move dx=2, dy=-3, color=none (move only!)
        .db 206                 ; move dx=-2, dy=-1, color=fore (set)
        .db 80                  ; move dx=2, dy=2, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 144                 ; move dx=0, dy=2, color=fore (set)
        .db 124                 ; move dx=3, dy=-3, color=none (move only!)
        .db 32                  ; move dx=1, dy=0, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 62                  ; move dx=-1, dy=-3, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 94                  ; move dx=-2, dy=-3, color=none (move only!)
        .db 20                  ; move dx=0, dy=-2, color=none (move only!)
        .db 148                 ; move dx=0, dy=-2, color=fore (set)
        ;; ascii 36: '$'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 26                  ; # moves
        .db 112                 ; move dx=3, dy=2, color=none (move only!)
        .db 32                  ; move dx=1, dy=0, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 106                 ; move dx=-3, dy=1, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 44                  ; move dx=1, dy=-1, color=none (move only!)
        .db 156                 ; move dx=0, dy=-3, color=fore (set)
        .db 206                 ; move dx=-2, dy=-1, color=fore (set)
        .db 226                 ; move dx=-3, dy=0, color=fore (set)
        .db 194                 ; move dx=-2, dy=0, color=fore (set)
        .db 182                 ; move dx=-1, dy=-2, color=fore (set)
        .db 52                  ; move dx=1, dy=-2, color=none (move only!)
        .db 192                 ; move dx=2, dy=0, color=fore (set)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 200                 ; move dx=2, dy=1, color=fore (set)
        .db 122                 ; move dx=-3, dy=3, color=none (move only!)
        .db 58                  ; move dx=-1, dy=3, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 110                 ; move dx=-3, dy=-1, color=none (move only!)
        .db 174                 ; move dx=-1, dy=-1, color=fore (set)
        .db 28                  ; move dx=0, dy=-3, color=none (move only!)
        .db 28                  ; move dx=0, dy=-3, color=none (move only!)
        .db 140                 ; move dx=0, dy=-1, color=fore (set)
        ;; ascii 37: '%'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 17                  ; # moves
        .db 120                 ; move dx=3, dy=3, color=none (move only!)
        .db 96                  ; move dx=3, dy=0, color=none (move only!)
        .db 96                  ; move dx=3, dy=0, color=none (move only!)
        .db 250                 ; move dx=-3, dy=3, color=fore (set)
        .db 250                 ; move dx=-3, dy=3, color=fore (set)
        .db 250                 ; move dx=-3, dy=3, color=fore (set)
        .db 108                 ; move dx=3, dy=-1, color=none (move only!)
        .db 96                  ; move dx=3, dy=0, color=none (move only!)
        .db 192                 ; move dx=2, dy=0, color=fore (set)
        .db 202                 ; move dx=-2, dy=1, color=fore (set)
        .db 192                 ; move dx=2, dy=0, color=fore (set)
        .db 126                 ; move dx=-3, dy=-3, color=none (move only!)
        .db 126                 ; move dx=-3, dy=-3, color=none (move only!)
        .db 94                  ; move dx=-2, dy=-3, color=none (move only!)
        .db 192                 ; move dx=2, dy=0, color=fore (set)
        .db 202                 ; move dx=-2, dy=1, color=fore (set)
        .db 192                 ; move dx=2, dy=0, color=fore (set)
        ;; ascii 38: '&'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 24                  ; # moves
        .db 88                  ; move dx=2, dy=3, color=none (move only!)
        .db 8                   ; move dx=0, dy=1, color=none (move only!)
        .db 248                 ; move dx=3, dy=3, color=fore (set)
        .db 240                 ; move dx=3, dy=2, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 226                 ; move dx=-3, dy=0, color=fore (set)
        .db 110                 ; move dx=-3, dy=-1, color=none (move only!)
        .db 156                 ; move dx=0, dy=-3, color=fore (set)
        .db 252                 ; move dx=3, dy=-3, color=fore (set)
        .db 180                 ; move dx=1, dy=-2, color=fore (set)
        .db 206                 ; move dx=-2, dy=-1, color=fore (set)
        .db 120                 ; move dx=3, dy=3, color=none (move only!)
        .db 112                 ; move dx=3, dy=2, color=none (move only!)
        .db 202                 ; move dx=-2, dy=1, color=fore (set)
        .db 126                 ; move dx=-3, dy=-3, color=none (move only!)
        .db 94                  ; move dx=-2, dy=-3, color=none (move only!)
        .db 170                 ; move dx=-1, dy=1, color=fore (set)
        .db 80                  ; move dx=2, dy=2, color=none (move only!)
        .db 144                 ; move dx=0, dy=2, color=fore (set)
        .db 58                  ; move dx=-1, dy=3, color=none (move only!)
        .db 16                  ; move dx=0, dy=2, color=none (move only!)
        .db 160                 ; move dx=1, dy=0, color=fore (set)
        .db 96                  ; move dx=3, dy=0, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        ;; ascii 39: '''
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 4                   ; # moves
        .db 96                  ; move dx=3, dy=0, color=none (move only!)
        .db 96                  ; move dx=3, dy=0, color=none (move only!)
        .db 178                 ; move dx=-1, dy=2, color=fore (set)
        .db 162                 ; move dx=-1, dy=0, color=fore (set)
        ;; ascii 40: '('
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 12                  ; # moves
        .db 112                 ; move dx=3, dy=2, color=none (move only!)
        .db 96                  ; move dx=3, dy=0, color=none (move only!)
        .db 32                  ; move dx=1, dy=0, color=none (move only!)
        .db 242                 ; move dx=-3, dy=2, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 240                 ; move dx=3, dy=2, color=fore (set)
        .db 160                 ; move dx=1, dy=0, color=fore (set)
        .db 126                 ; move dx=-3, dy=-3, color=none (move only!)
        .db 28                  ; move dx=0, dy=-3, color=none (move only!)
        .db 28                  ; move dx=0, dy=-3, color=none (move only!)
        .db 236                 ; move dx=3, dy=-1, color=fore (set)
        ;; ascii 41: ')'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 7                   ; # moves
        .db 80                  ; move dx=2, dy=2, color=none (move only!)
        .db 232                 ; move dx=3, dy=1, color=fore (set)
        .db 40                  ; move dx=1, dy=1, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 242                 ; move dx=-3, dy=2, color=fore (set)
        .db 162                 ; move dx=-1, dy=0, color=fore (set)
        ;; ascii 42: '*'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 23                  ; # moves
        .db 88                  ; move dx=2, dy=3, color=none (move only!)
        .db 8                   ; move dx=0, dy=1, color=none (move only!)
        .db 232                 ; move dx=3, dy=1, color=fore (set)
        .db 64                  ; move dx=2, dy=0, color=none (move only!)
        .db 236                 ; move dx=3, dy=-1, color=fore (set)
        .db 122                 ; move dx=-3, dy=3, color=none (move only!)
        .db 226                 ; move dx=-3, dy=0, color=fore (set)
        .db 72                  ; move dx=2, dy=1, color=none (move only!)
        .db 242                 ; move dx=-3, dy=2, color=fore (set)
        .db 116                 ; move dx=3, dy=-2, color=none (move only!)
        .db 240                 ; move dx=3, dy=2, color=fore (set)
        .db 94                  ; move dx=-2, dy=-3, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 98                  ; move dx=-3, dy=0, color=none (move only!)
        .db 98                  ; move dx=-3, dy=0, color=none (move only!)
        .db 194                 ; move dx=-2, dy=0, color=fore (set)
        .db 60                  ; move dx=1, dy=-3, color=none (move only!)
        .db 240                 ; move dx=3, dy=2, color=fore (set)
        .db 90                  ; move dx=-2, dy=3, color=none (move only!)
        .db 202                 ; move dx=-2, dy=1, color=fore (set)
        .db 108                 ; move dx=3, dy=-1, color=none (move only!)
        .db 64                  ; move dx=2, dy=0, color=none (move only!)
        .db 232                 ; move dx=3, dy=1, color=fore (set)
        ;; ascii 43: '+'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 11                  ; # moves
        .db 120                 ; move dx=3, dy=3, color=none (move only!)
        .db 112                 ; move dx=3, dy=2, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 46                  ; move dx=-1, dy=-1, color=none (move only!)
        .db 226                 ; move dx=-3, dy=0, color=fore (set)
        .db 96                  ; move dx=3, dy=0, color=none (move only!)
        .db 64                  ; move dx=2, dy=0, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 110                 ; move dx=-3, dy=-1, color=none (move only!)
        .db 34                  ; move dx=-1, dy=0, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        ;; ascii 44: ','
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 6                   ; # moves
        .db 120                 ; move dx=3, dy=3, color=none (move only!)
        .db 56                  ; move dx=1, dy=3, color=none (move only!)
        .db 24                  ; move dx=0, dy=3, color=none (move only!)
        .db 16                  ; move dx=0, dy=2, color=none (move only!)
        .db 178                 ; move dx=-1, dy=2, color=fore (set)
        .db 162                 ; move dx=-1, dy=0, color=fore (set)
        ;; ascii 45: '-'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 5                   ; # moves
        .db 88                  ; move dx=2, dy=3, color=none (move only!)
        .db 24                  ; move dx=0, dy=3, color=none (move only!)
        .db 8                   ; move dx=0, dy=1, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        ;; ascii 46: '.'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 5                   ; # moves
        .db 120                 ; move dx=3, dy=3, color=none (move only!)
        .db 56                  ; move dx=1, dy=3, color=none (move only!)
        .db 24                  ; move dx=0, dy=3, color=none (move only!)
        .db 24                  ; move dx=0, dy=3, color=none (move only!)
        .db 128                 ; move dx=0, dy=0, color=fore (set)
        ;; ascii 47: '/'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 11                  ; # moves
        .db 120                 ; move dx=3, dy=3, color=none (move only!)
        .db 104                 ; move dx=3, dy=1, color=none (move only!)
        .db 32                  ; move dx=1, dy=0, color=none (move only!)
        .db 218                 ; move dx=-2, dy=3, color=fore (set)
        .db 186                 ; move dx=-1, dy=3, color=fore (set)
        .db 210                 ; move dx=-2, dy=2, color=fore (set)
        .db 136                 ; move dx=0, dy=1, color=fore (set)
        .db 124                 ; move dx=3, dy=-3, color=none (move only!)
        .db 92                  ; move dx=2, dy=-3, color=none (move only!)
        .db 28                  ; move dx=0, dy=-3, color=none (move only!)
        .db 180                 ; move dx=1, dy=-2, color=fore (set)
        ;; ascii 48: '0'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 22                  ; # moves
        .db 112                 ; move dx=3, dy=2, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 72                  ; move dx=2, dy=1, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 94                  ; move dx=-2, dy=-3, color=none (move only!)
        .db 250                 ; move dx=-3, dy=3, color=fore (set)
        .db 62                  ; move dx=-1, dy=-3, color=none (move only!)
        .db 156                 ; move dx=0, dy=-3, color=fore (set)
        .db 24                  ; move dx=0, dy=3, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 56                  ; move dx=1, dy=3, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 204                 ; move dx=2, dy=-1, color=fore (set)
        .db 156                 ; move dx=0, dy=-3, color=fore (set)
        .db 98                  ; move dx=-3, dy=0, color=none (move only!)
        .db 98                  ; move dx=-3, dy=0, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 92                  ; move dx=2, dy=-3, color=none (move only!)
        .db 252                 ; move dx=3, dy=-3, color=fore (set)
        .db 126                 ; move dx=-3, dy=-3, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        ;; ascii 49: '1'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 16                  ; # moves
        .db 112                 ; move dx=3, dy=2, color=none (move only!)
        .db 96                  ; move dx=3, dy=0, color=none (move only!)
        .db 242                 ; move dx=-3, dy=2, color=fore (set)
        .db 108                 ; move dx=3, dy=-1, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 226                 ; move dx=-3, dy=0, color=fore (set)
        .db 64                  ; move dx=2, dy=0, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 98                  ; move dx=-3, dy=0, color=none (move only!)
        .db 226                 ; move dx=-3, dy=0, color=fore (set)
        .db 92                  ; move dx=2, dy=-3, color=none (move only!)
        .db 28                  ; move dx=0, dy=-3, color=none (move only!)
        .db 28                  ; move dx=0, dy=-3, color=none (move only!)
        .db 202                 ; move dx=-2, dy=1, color=fore (set)
        ;; ascii 50: '2'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 21                  ; # moves
        .db 112                 ; move dx=3, dy=2, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 72                  ; move dx=2, dy=1, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 114                 ; move dx=-3, dy=2, color=none (move only!)
        .db 242                 ; move dx=-3, dy=2, color=fore (set)
        .db 16                  ; move dx=0, dy=2, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 28                  ; move dx=0, dy=-3, color=none (move only!)
        .db 20                  ; move dx=0, dy=-2, color=none (move only!)
        .db 202                 ; move dx=-2, dy=1, color=fore (set)
        .db 126                 ; move dx=-3, dy=-3, color=none (move only!)
        .db 54                  ; move dx=-1, dy=-2, color=none (move only!)
        .db 136                 ; move dx=0, dy=1, color=fore (set)
        .db 84                  ; move dx=2, dy=-2, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 122                 ; move dx=-3, dy=3, color=none (move only!)
        .db 90                  ; move dx=-2, dy=3, color=none (move only!)
        .db 16                  ; move dx=0, dy=2, color=none (move only!)
        .db 136                 ; move dx=0, dy=1, color=fore (set)
        ;; ascii 51: '3'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 20                  ; # moves
        .db 112                 ; move dx=3, dy=2, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 72                  ; move dx=2, dy=1, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 42                  ; move dx=-1, dy=1, color=none (move only!)
        .db 226                 ; move dx=-3, dy=0, color=fore (set)
        .db 104                 ; move dx=3, dy=1, color=none (move only!)
        .db 32                  ; move dx=1, dy=0, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 74                  ; move dx=-2, dy=1, color=none (move only!)
        .db 226                 ; move dx=-3, dy=0, color=fore (set)
        .db 174                 ; move dx=-1, dy=-1, color=fore (set)
        .db 72                  ; move dx=2, dy=1, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 126                 ; move dx=-3, dy=-3, color=none (move only!)
        .db 94                  ; move dx=-2, dy=-3, color=none (move only!)
        .db 28                  ; move dx=0, dy=-3, color=none (move only!)
        .db 172                 ; move dx=1, dy=-1, color=fore (set)
        .db 32                  ; move dx=1, dy=0, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        ;; ascii 52: '4'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 18                  ; # moves
        .db 112                 ; move dx=3, dy=2, color=none (move only!)
        .db 96                  ; move dx=3, dy=0, color=none (move only!)
        .db 32                  ; move dx=1, dy=0, color=none (move only!)
        .db 250                 ; move dx=-3, dy=3, color=fore (set)
        .db 82                  ; move dx=-2, dy=2, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 156                 ; move dx=0, dy=-3, color=fore (set)
        .db 156                 ; move dx=0, dy=-3, color=fore (set)
        .db 148                 ; move dx=0, dy=-2, color=fore (set)
        .db 24                  ; move dx=0, dy=3, color=none (move only!)
        .db 24                  ; move dx=0, dy=3, color=none (move only!)
        .db 8                   ; move dx=0, dy=1, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 126                 ; move dx=-3, dy=-3, color=none (move only!)
        .db 94                  ; move dx=-2, dy=-3, color=none (move only!)
        .db 252                 ; move dx=3, dy=-3, color=fore (set)
        ;; ascii 53: '5'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 19                  ; # moves
        .db 80                  ; move dx=2, dy=2, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 106                 ; move dx=-3, dy=1, color=none (move only!)
        .db 98                  ; move dx=-3, dy=0, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 104                 ; move dx=3, dy=1, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 82                  ; move dx=-2, dy=2, color=none (move only!)
        .db 226                 ; move dx=-3, dy=0, color=fore (set)
        .db 96                  ; move dx=3, dy=0, color=none (move only!)
        .db 204                 ; move dx=2, dy=-1, color=fore (set)
        .db 126                 ; move dx=-3, dy=-3, color=none (move only!)
        .db 54                  ; move dx=-1, dy=-2, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 122                 ; move dx=-3, dy=3, color=none (move only!)
        .db 82                  ; move dx=-2, dy=2, color=none (move only!)
        .db 128                 ; move dx=0, dy=0, color=fore (set)
        ;; ascii 54: '6'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 19                  ; # moves
        .db 112                 ; move dx=3, dy=2, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 106                 ; move dx=-3, dy=1, color=none (move only!)
        .db 34                  ; move dx=-1, dy=0, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 106                 ; move dx=-3, dy=1, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 48                  ; move dx=1, dy=2, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 84                  ; move dx=2, dy=-2, color=none (move only!)
        .db 156                 ; move dx=0, dy=-3, color=fore (set)
        .db 206                 ; move dx=-2, dy=-1, color=fore (set)
        .db 88                  ; move dx=2, dy=3, color=none (move only!)
        .db 8                   ; move dx=0, dy=1, color=none (move only!)
        .db 178                 ; move dx=-1, dy=2, color=fore (set)
        .db 126                 ; move dx=-3, dy=-3, color=none (move only!)
        .db 78                  ; move dx=-2, dy=-1, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        ;; ascii 55: '7'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 11                  ; # moves
        .db 80                  ; move dx=2, dy=2, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 8                   ; move dx=0, dy=1, color=none (move only!)
        .db 186                 ; move dx=-1, dy=3, color=fore (set)
        .db 218                 ; move dx=-2, dy=3, color=fore (set)
        .db 186                 ; move dx=-1, dy=3, color=fore (set)
        .db 94                  ; move dx=-2, dy=-3, color=none (move only!)
        .db 28                  ; move dx=0, dy=-3, color=none (move only!)
        .db 28                  ; move dx=0, dy=-3, color=none (move only!)
        .db 140                 ; move dx=0, dy=-1, color=fore (set)
        ;; ascii 56: '8'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 22                  ; # moves
        .db 112                 ; move dx=3, dy=2, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 72                  ; move dx=2, dy=1, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 74                  ; move dx=-2, dy=1, color=none (move only!)
        .db 226                 ; move dx=-3, dy=0, color=fore (set)
        .db 46                  ; move dx=-1, dy=-1, color=none (move only!)
        .db 156                 ; move dx=0, dy=-3, color=fore (set)
        .db 24                  ; move dx=0, dy=3, color=none (move only!)
        .db 16                  ; move dx=0, dy=2, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 40                  ; move dx=1, dy=1, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 76                  ; move dx=2, dy=-1, color=none (move only!)
        .db 156                 ; move dx=0, dy=-3, color=fore (set)
        .db 206                 ; move dx=-2, dy=-1, color=fore (set)
        .db 88                  ; move dx=2, dy=3, color=none (move only!)
        .db 178                 ; move dx=-1, dy=2, color=fore (set)
        .db 60                  ; move dx=1, dy=-3, color=none (move only!)
        .db 28                  ; move dx=0, dy=-3, color=none (move only!)
        .db 28                  ; move dx=0, dy=-3, color=none (move only!)
        .db 206                 ; move dx=-2, dy=-1, color=fore (set)
        ;; ascii 57: '9'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 22                  ; # moves
        .db 112                 ; move dx=3, dy=2, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 72                  ; move dx=2, dy=1, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 78                  ; move dx=-2, dy=-1, color=none (move only!)
        .db 226                 ; move dx=-3, dy=0, color=fore (set)
        .db 54                  ; move dx=-1, dy=-2, color=none (move only!)
        .db 156                 ; move dx=0, dy=-3, color=fore (set)
        .db 120                 ; move dx=3, dy=3, color=none (move only!)
        .db 120                 ; move dx=3, dy=3, color=none (move only!)
        .db 8                   ; move dx=0, dy=1, color=none (move only!)
        .db 242                 ; move dx=-3, dy=2, color=fore (set)
        .db 226                 ; move dx=-3, dy=0, color=fore (set)
        .db 28                  ; move dx=0, dy=-3, color=none (move only!)
        .db 28                  ; move dx=0, dy=-3, color=none (move only!)
        .db 136                 ; move dx=0, dy=1, color=fore (set)
        .db 72                  ; move dx=2, dy=1, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 126                 ; move dx=-3, dy=-3, color=none (move only!)
        .db 28                  ; move dx=0, dy=-3, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        ;; ascii 58: ':'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 6                   ; # moves
        .db 120                 ; move dx=3, dy=3, color=none (move only!)
        .db 48                  ; move dx=1, dy=2, color=none (move only!)
        .db 128                 ; move dx=0, dy=0, color=fore (set)
        .db 24                  ; move dx=0, dy=3, color=none (move only!)
        .db 24                  ; move dx=0, dy=3, color=none (move only!)
        .db 128                 ; move dx=0, dy=0, color=fore (set)
        ;; ascii 59: ';'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 10                  ; # moves
        .db 120                 ; move dx=3, dy=3, color=none (move only!)
        .db 56                  ; move dx=1, dy=3, color=none (move only!)
        .db 24                  ; move dx=0, dy=3, color=none (move only!)
        .db 16                  ; move dx=0, dy=2, color=none (move only!)
        .db 178                 ; move dx=-1, dy=2, color=fore (set)
        .db 162                 ; move dx=-1, dy=0, color=fore (set)
        .db 92                  ; move dx=2, dy=-3, color=none (move only!)
        .db 28                  ; move dx=0, dy=-3, color=none (move only!)
        .db 20                  ; move dx=0, dy=-2, color=none (move only!)
        .db 128                 ; move dx=0, dy=0, color=fore (set)
        ;; ascii 60: '<'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 13                  ; # moves
        .db 120                 ; move dx=3, dy=3, color=none (move only!)
        .db 96                  ; move dx=3, dy=0, color=none (move only!)
        .db 64                  ; move dx=2, dy=0, color=none (move only!)
        .db 242                 ; move dx=-3, dy=2, color=fore (set)
        .db 234                 ; move dx=-3, dy=1, color=fore (set)
        .db 74                  ; move dx=-2, dy=1, color=none (move only!)
        .db 232                 ; move dx=3, dy=1, color=fore (set)
        .db 240                 ; move dx=3, dy=2, color=fore (set)
        .db 232                 ; move dx=3, dy=1, color=fore (set)
        .db 62                  ; move dx=-1, dy=-3, color=none (move only!)
        .db 28                  ; move dx=0, dy=-3, color=none (move only!)
        .db 20                  ; move dx=0, dy=-2, color=none (move only!)
        .db 160                 ; move dx=1, dy=0, color=fore (set)
        ;; ascii 61: '='
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 8                   ; # moves
        .db 88                  ; move dx=2, dy=3, color=none (move only!)
        .db 16                  ; move dx=0, dy=2, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 122                 ; move dx=-3, dy=3, color=none (move only!)
        .db 106                 ; move dx=-3, dy=1, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        ;; ascii 62: '>'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 10                  ; # moves
        .db 24                  ; move dx=0, dy=3, color=none (move only!)
        .db 232                 ; move dx=3, dy=1, color=fore (set)
        .db 240                 ; move dx=3, dy=2, color=fore (set)
        .db 232                 ; move dx=3, dy=1, color=fore (set)
        .db 106                 ; move dx=-3, dy=1, color=none (move only!)
        .db 242                 ; move dx=-3, dy=2, color=fore (set)
        .db 234                 ; move dx=-3, dy=1, color=fore (set)
        .db 124                 ; move dx=3, dy=-3, color=none (move only!)
        .db 96                  ; move dx=3, dy=0, color=none (move only!)
        .db 204                 ; move dx=2, dy=-1, color=fore (set)
        ;; ascii 63: '?'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 18                  ; # moves
        .db 112                 ; move dx=3, dy=2, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 72                  ; move dx=2, dy=1, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 202                 ; move dx=-2, dy=1, color=fore (set)
        .db 34                  ; move dx=-1, dy=0, color=none (move only!)
        .db 170                 ; move dx=-1, dy=1, color=fore (set)
        .db 136                 ; move dx=0, dy=1, color=fore (set)
        .db 94                  ; move dx=-2, dy=-3, color=none (move only!)
        .db 28                  ; move dx=0, dy=-3, color=none (move only!)
        .db 136                 ; move dx=0, dy=1, color=fore (set)
        .db 84                  ; move dx=2, dy=-2, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 122                 ; move dx=-3, dy=3, color=none (move only!)
        .db 24                  ; move dx=0, dy=3, color=none (move only!)
        .db 24                  ; move dx=0, dy=3, color=none (move only!)
        .db 8                   ; move dx=0, dy=1, color=none (move only!)
        .db 128                 ; move dx=0, dy=0, color=fore (set)
        ;; ascii 64: '@'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 27                  ; # moves
        .db 112                 ; move dx=3, dy=2, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 72                  ; move dx=2, dy=1, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 106                 ; move dx=-3, dy=1, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 114                 ; move dx=-3, dy=2, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 126                 ; move dx=-3, dy=-3, color=none (move only!)
        .db 126                 ; move dx=-3, dy=-3, color=none (move only!)
        .db 156                 ; move dx=0, dy=-3, color=fore (set)
        .db 80                  ; move dx=2, dy=2, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 78                  ; move dx=-2, dy=-1, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 176                 ; move dx=1, dy=2, color=fore (set)
        .db 160                 ; move dx=1, dy=0, color=fore (set)
        .db 60                  ; move dx=1, dy=-3, color=none (move only!)
        .db 28                  ; move dx=0, dy=-3, color=none (move only!)
        .db 20                  ; move dx=0, dy=-2, color=none (move only!)
        .db 192                 ; move dx=2, dy=0, color=fore (set)
        .db 118                 ; move dx=-3, dy=-2, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 122                 ; move dx=-3, dy=3, color=none (move only!)
        .db 8                   ; move dx=0, dy=1, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        ;; ascii 65: 'A'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 18                  ; # moves
        .db 112                 ; move dx=3, dy=2, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 72                  ; move dx=2, dy=1, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 126                 ; move dx=-3, dy=-3, color=none (move only!)
        .db 126                 ; move dx=-3, dy=-3, color=none (move only!)
        .db 156                 ; move dx=0, dy=-3, color=fore (set)
        .db 24                  ; move dx=0, dy=3, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 60                  ; move dx=1, dy=-3, color=none (move only!)
        .db 20                  ; move dx=0, dy=-2, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 204                 ; move dx=2, dy=-1, color=fore (set)
        .db 28                  ; move dx=0, dy=-3, color=none (move only!)
        .db 206                 ; move dx=-2, dy=-1, color=fore (set)
        ;; ascii 66: 'B'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 21                  ; # moves
        .db 80                  ; move dx=2, dy=2, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 106                 ; move dx=-3, dy=1, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 106                 ; move dx=-3, dy=1, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 16                  ; move dx=0, dy=2, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 116                 ; move dx=3, dy=-2, color=none (move only!)
        .db 156                 ; move dx=0, dy=-3, color=fore (set)
        .db 206                 ; move dx=-2, dy=-1, color=fore (set)
        .db 92                  ; move dx=2, dy=-3, color=none (move only!)
        .db 206                 ; move dx=-2, dy=-1, color=fore (set)
        .db 72                  ; move dx=2, dy=1, color=none (move only!)
        .db 144                 ; move dx=0, dy=2, color=fore (set)
        .db 24                  ; move dx=0, dy=3, color=none (move only!)
        .db 24                  ; move dx=0, dy=3, color=none (move only!)
        .db 202                 ; move dx=-2, dy=1, color=fore (set)
        .db 98                  ; move dx=-3, dy=0, color=none (move only!)
        .db 182                 ; move dx=-1, dy=-2, color=fore (set)
        ;; ascii 67: 'C'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 13                  ; # moves
        .db 112                 ; move dx=3, dy=2, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 200                 ; move dx=2, dy=1, color=fore (set)
        .db 98                  ; move dx=-3, dy=0, color=none (move only!)
        .db 98                  ; move dx=-3, dy=0, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 56                  ; move dx=1, dy=3, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 204                 ; move dx=2, dy=-1, color=fore (set)
        .db 126                 ; move dx=-3, dy=-3, color=none (move only!)
        .db 98                  ; move dx=-3, dy=0, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        ;; ascii 68: 'D'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 10                  ; # moves
        .db 80                  ; move dx=2, dy=2, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 240                 ; move dx=3, dy=2, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 242                 ; move dx=-3, dy=2, color=fore (set)
        .db 226                 ; move dx=-3, dy=0, color=fore (set)
        .db 156                 ; move dx=0, dy=-3, color=fore (set)
        .db 156                 ; move dx=0, dy=-3, color=fore (set)
        .db 156                 ; move dx=0, dy=-3, color=fore (set)
        ;; ascii 69: 'E'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 13                  ; # moves
        .db 80                  ; move dx=2, dy=2, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 106                 ; move dx=-3, dy=1, color=none (move only!)
        .db 98                  ; move dx=-3, dy=0, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 126                 ; move dx=-3, dy=-3, color=none (move only!)
        .db 86                  ; move dx=-2, dy=-2, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        ;; ascii 70: 'F'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 11                  ; # moves
        .db 80                  ; move dx=2, dy=2, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 106                 ; move dx=-3, dy=1, color=none (move only!)
        .db 98                  ; move dx=-3, dy=0, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 60                  ; move dx=1, dy=-3, color=none (move only!)
        .db 20                  ; move dx=0, dy=-2, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        ;; ascii 71: 'G'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 17                  ; # moves
        .db 112                 ; move dx=3, dy=2, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 200                 ; move dx=2, dy=1, color=fore (set)
        .db 98                  ; move dx=-3, dy=0, color=none (move only!)
        .db 98                  ; move dx=-3, dy=0, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 56                  ; move dx=1, dy=3, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 84                  ; move dx=2, dy=-2, color=none (move only!)
        .db 156                 ; move dx=0, dy=-3, color=fore (set)
        .db 194                 ; move dx=-2, dy=0, color=fore (set)
        .db 88                  ; move dx=2, dy=3, color=none (move only!)
        .db 178                 ; move dx=-1, dy=2, color=fore (set)
        .db 126                 ; move dx=-3, dy=-3, color=none (move only!)
        .db 78                  ; move dx=-2, dy=-1, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        ;; ascii 72: 'H'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 19                  ; # moves
        .db 80                  ; move dx=2, dy=2, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 124                 ; move dx=3, dy=-3, color=none (move only!)
        .db 124                 ; move dx=3, dy=-3, color=none (move only!)
        .db 156                 ; move dx=0, dy=-3, color=fore (set)
        .db 24                  ; move dx=0, dy=3, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 126                 ; move dx=-3, dy=-3, color=none (move only!)
        .db 78                  ; move dx=-2, dy=-1, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 204                 ; move dx=2, dy=-1, color=fore (set)
        .db 24                  ; move dx=0, dy=3, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 126                 ; move dx=-3, dy=-3, color=none (move only!)
        .db 98                  ; move dx=-3, dy=0, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        ;; ascii 73: 'I'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 15                  ; # moves
        .db 112                 ; move dx=3, dy=2, color=none (move only!)
        .db 32                  ; move dx=1, dy=0, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 42                  ; move dx=-1, dy=1, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 194                 ; move dx=-2, dy=0, color=fore (set)
        .db 32                  ; move dx=1, dy=0, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 126                 ; move dx=-3, dy=-3, color=none (move only!)
        .db 28                  ; move dx=0, dy=-3, color=none (move only!)
        .db 28                  ; move dx=0, dy=-3, color=none (move only!)
        .db 12                  ; move dx=0, dy=-1, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        ;; ascii 74: 'J'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 17                  ; # moves
        .db 112                 ; move dx=3, dy=2, color=none (move only!)
        .db 96                  ; move dx=3, dy=0, color=none (move only!)
        .db 64                  ; move dx=2, dy=0, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 74                  ; move dx=-2, dy=1, color=none (move only!)
        .db 226                 ; move dx=-3, dy=0, color=fore (set)
        .db 182                 ; move dx=-1, dy=-2, color=fore (set)
        .db 124                 ; move dx=3, dy=-3, color=none (move only!)
        .db 60                  ; move dx=1, dy=-3, color=none (move only!)
        .db 20                  ; move dx=0, dy=-2, color=none (move only!)
        .db 160                 ; move dx=1, dy=0, color=fore (set)
        .db 56                  ; move dx=1, dy=3, color=none (move only!)
        .db 24                  ; move dx=0, dy=3, color=none (move only!)
        .db 16                  ; move dx=0, dy=2, color=none (move only!)
        .db 178                 ; move dx=-1, dy=2, color=fore (set)
        ;; ascii 75: 'K'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 13                  ; # moves
        .db 80                  ; move dx=2, dy=2, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 252                 ; move dx=3, dy=-3, color=fore (set)
        .db 252                 ; move dx=3, dy=-3, color=fore (set)
        .db 122                 ; move dx=-3, dy=3, color=none (move only!)
        .db 58                  ; move dx=-1, dy=3, color=none (move only!)
        .db 248                 ; move dx=3, dy=3, color=fore (set)
        .db 118                 ; move dx=-3, dy=-2, color=none (move only!)
        .db 66                  ; move dx=-2, dy=0, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 124                 ; move dx=3, dy=-3, color=none (move only!)
        .db 248                 ; move dx=3, dy=3, color=fore (set)
        ;; ascii 76: 'L'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 7                   ; # moves
        .db 80                  ; move dx=2, dy=2, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 8                   ; move dx=0, dy=1, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        ;; ascii 77: 'M'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 20                  ; # moves
        .db 16                  ; move dx=0, dy=2, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 124                 ; move dx=3, dy=-3, color=none (move only!)
        .db 92                  ; move dx=2, dy=-3, color=none (move only!)
        .db 252                 ; move dx=3, dy=-3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 126                 ; move dx=-3, dy=-3, color=none (move only!)
        .db 54                  ; move dx=-1, dy=-2, color=none (move only!)
        .db 254                 ; move dx=-3, dy=-3, color=fore (set)
        .db 58                  ; move dx=-1, dy=3, color=none (move only!)
        .db 24                  ; move dx=0, dy=3, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 124                 ; move dx=3, dy=-3, color=none (move only!)
        .db 96                  ; move dx=3, dy=0, color=none (move only!)
        .db 64                  ; move dx=2, dy=0, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        ;; ascii 78: 'N'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 19                  ; # moves
        .db 80                  ; move dx=2, dy=2, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 92                  ; move dx=2, dy=-3, color=none (move only!)
        .db 28                  ; move dx=0, dy=-3, color=none (move only!)
        .db 248                 ; move dx=3, dy=3, color=fore (set)
        .db 60                  ; move dx=1, dy=-3, color=none (move only!)
        .db 156                 ; move dx=0, dy=-3, color=fore (set)
        .db 24                  ; move dx=0, dy=3, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 136                 ; move dx=0, dy=1, color=fore (set)
        .db 126                 ; move dx=-3, dy=-3, color=none (move only!)
        .db 28                  ; move dx=0, dy=-3, color=none (move only!)
        .db 254                 ; move dx=-3, dy=-3, color=fore (set)
        .db 24                  ; move dx=0, dy=3, color=none (move only!)
        .db 24                  ; move dx=0, dy=3, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        ;; ascii 79: 'O'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 21                  ; # moves
        .db 112                 ; move dx=3, dy=2, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 72                  ; move dx=2, dy=1, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 90                  ; move dx=-2, dy=3, color=none (move only!)
        .db 226                 ; move dx=-3, dy=0, color=fore (set)
        .db 62                  ; move dx=-1, dy=-3, color=none (move only!)
        .db 156                 ; move dx=0, dy=-3, color=fore (set)
        .db 156                 ; move dx=0, dy=-3, color=fore (set)
        .db 120                 ; move dx=3, dy=3, color=none (move only!)
        .db 120                 ; move dx=3, dy=3, color=none (move only!)
        .db 8                   ; move dx=0, dy=1, color=none (move only!)
        .db 178                 ; move dx=-1, dy=2, color=fore (set)
        .db 126                 ; move dx=-3, dy=-3, color=none (move only!)
        .db 78                  ; move dx=-2, dy=-1, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 92                  ; move dx=2, dy=-3, color=none (move only!)
        .db 28                  ; move dx=0, dy=-3, color=none (move only!)
        .db 28                  ; move dx=0, dy=-3, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        ;; ascii 80: 'P'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 14                  ; # moves
        .db 80                  ; move dx=2, dy=2, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 106                 ; move dx=-3, dy=1, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 124                 ; move dx=3, dy=-3, color=none (move only!)
        .db 124                 ; move dx=3, dy=-3, color=none (move only!)
        .db 156                 ; move dx=0, dy=-3, color=fore (set)
        .db 206                 ; move dx=-2, dy=-1, color=fore (set)
        .db 122                 ; move dx=-3, dy=3, color=none (move only!)
        .db 16                  ; move dx=0, dy=2, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 204                 ; move dx=2, dy=-1, color=fore (set)
        ;; ascii 81: 'Q'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 21                  ; # moves
        .db 112                 ; move dx=3, dy=2, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 72                  ; move dx=2, dy=1, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 16                  ; move dx=0, dy=2, color=none (move only!)
        .db 242                 ; move dx=-3, dy=2, color=fore (set)
        .db 246                 ; move dx=-3, dy=-2, color=fore (set)
        .db 156                 ; move dx=0, dy=-3, color=fore (set)
        .db 156                 ; move dx=0, dy=-3, color=fore (set)
        .db 148                 ; move dx=0, dy=-2, color=fore (set)
        .db 120                 ; move dx=3, dy=3, color=none (move only!)
        .db 24                  ; move dx=0, dy=3, color=none (move only!)
        .db 24                  ; move dx=0, dy=3, color=none (move only!)
        .db 208                 ; move dx=2, dy=2, color=fore (set)
        .db 160                 ; move dx=1, dy=0, color=fore (set)
        .db 28                  ; move dx=0, dy=-3, color=none (move only!)
        .db 156                 ; move dx=0, dy=-3, color=fore (set)
        .db 126                 ; move dx=-3, dy=-3, color=none (move only!)
        .db 62                  ; move dx=-1, dy=-3, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        ;; ascii 82: 'R'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 18                  ; # moves
        .db 80                  ; move dx=2, dy=2, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 106                 ; move dx=-3, dy=1, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 124                 ; move dx=3, dy=-3, color=none (move only!)
        .db 248                 ; move dx=3, dy=3, color=fore (set)
        .db 28                  ; move dx=0, dy=-3, color=none (move only!)
        .db 28                  ; move dx=0, dy=-3, color=none (move only!)
        .db 156                 ; move dx=0, dy=-3, color=fore (set)
        .db 206                 ; move dx=-2, dy=-1, color=fore (set)
        .db 122                 ; move dx=-3, dy=3, color=none (move only!)
        .db 16                  ; move dx=0, dy=2, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 204                 ; move dx=2, dy=-1, color=fore (set)
        .db 106                 ; move dx=-3, dy=1, color=none (move only!)
        .db 170                 ; move dx=-1, dy=1, color=fore (set)
        ;; ascii 83: 'S'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 18                  ; # moves
        .db 112                 ; move dx=3, dy=2, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 200                 ; move dx=2, dy=1, color=fore (set)
        .db 98                  ; move dx=-3, dy=0, color=none (move only!)
        .db 98                  ; move dx=-3, dy=0, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 40                  ; move dx=1, dy=1, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 72                  ; move dx=2, dy=1, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 74                  ; move dx=-2, dy=1, color=none (move only!)
        .db 226                 ; move dx=-3, dy=0, color=fore (set)
        .db 174                 ; move dx=-1, dy=-1, color=fore (set)
        .db 72                  ; move dx=2, dy=1, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 126                 ; move dx=-3, dy=-3, color=none (move only!)
        .db 20                  ; move dx=0, dy=-2, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        ;; ascii 84: 'T'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 12                  ; # moves
        .db 80                  ; move dx=2, dy=2, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 74                  ; move dx=-2, dy=1, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 60                  ; move dx=1, dy=-3, color=none (move only!)
        .db 28                  ; move dx=0, dy=-3, color=none (move only!)
        .db 28                  ; move dx=0, dy=-3, color=none (move only!)
        .db 12                  ; move dx=0, dy=-1, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        ;; ascii 85: 'U'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 14                  ; # moves
        .db 80                  ; move dx=2, dy=2, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 40                  ; move dx=1, dy=1, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 92                  ; move dx=2, dy=-3, color=none (move only!)
        .db 156                 ; move dx=0, dy=-3, color=fore (set)
        .db 156                 ; move dx=0, dy=-3, color=fore (set)
        .db 140                 ; move dx=0, dy=-1, color=fore (set)
        .db 24                  ; move dx=0, dy=3, color=none (move only!)
        .db 24                  ; move dx=0, dy=3, color=none (move only!)
        .db 16                  ; move dx=0, dy=2, color=none (move only!)
        .db 178                 ; move dx=-1, dy=2, color=fore (set)
        ;; ascii 86: 'V'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 14                  ; # moves
        .db 24                  ; move dx=0, dy=3, color=none (move only!)
        .db 184                 ; move dx=1, dy=3, color=fore (set)
        .db 216                 ; move dx=2, dy=3, color=fore (set)
        .db 184                 ; move dx=1, dy=3, color=fore (set)
        .db 60                  ; move dx=1, dy=-3, color=none (move only!)
        .db 220                 ; move dx=2, dy=-3, color=fore (set)
        .db 188                 ; move dx=1, dy=-3, color=fore (set)
        .db 140                 ; move dx=0, dy=-1, color=fore (set)
        .db 90                  ; move dx=-2, dy=3, color=none (move only!)
        .db 16                  ; move dx=0, dy=2, color=none (move only!)
        .db 186                 ; move dx=-1, dy=3, color=fore (set)
        .db 126                 ; move dx=-3, dy=-3, color=none (move only!)
        .db 94                  ; move dx=-2, dy=-3, color=none (move only!)
        .db 148                 ; move dx=0, dy=-2, color=fore (set)
        ;; ascii 87: 'W'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 16                  ; # moves
        .db 16                  ; move dx=0, dy=2, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 116                 ; move dx=3, dy=-2, color=none (move only!)
        .db 250                 ; move dx=-3, dy=3, color=fore (set)
        .db 124                 ; move dx=3, dy=-3, color=none (move only!)
        .db 44                  ; move dx=1, dy=-1, color=none (move only!)
        .db 248                 ; move dx=3, dy=3, color=fore (set)
        .db 60                  ; move dx=1, dy=-3, color=none (move only!)
        .db 156                 ; move dx=0, dy=-3, color=fore (set)
        .db 156                 ; move dx=0, dy=-3, color=fore (set)
        .db 24                  ; move dx=0, dy=3, color=none (move only!)
        .db 24                  ; move dx=0, dy=3, color=none (move only!)
        .db 8                   ; move dx=0, dy=1, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        ;; ascii 88: 'X'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 16                  ; # moves
        .db 16                  ; move dx=0, dy=2, color=none (move only!)
        .db 248                 ; move dx=3, dy=3, color=fore (set)
        .db 64                  ; move dx=2, dy=0, color=none (move only!)
        .db 252                 ; move dx=3, dy=-3, color=fore (set)
        .db 122                 ; move dx=-3, dy=3, color=none (move only!)
        .db 58                  ; move dx=-1, dy=3, color=none (move only!)
        .db 250                 ; move dx=-3, dy=3, color=fore (set)
        .db 124                 ; move dx=3, dy=-3, color=none (move only!)
        .db 248                 ; move dx=3, dy=3, color=fore (set)
        .db 126                 ; move dx=-3, dy=-3, color=none (move only!)
        .db 148                 ; move dx=0, dy=-2, color=fore (set)
        .db 58                  ; move dx=-1, dy=3, color=none (move only!)
        .db 250                 ; move dx=-3, dy=3, color=fore (set)
        .db 124                 ; move dx=3, dy=-3, color=none (move only!)
        .db 64                  ; move dx=2, dy=0, color=none (move only!)
        .db 248                 ; move dx=3, dy=3, color=fore (set)
        ;; ascii 89: 'Y'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 8                   ; # moves
        .db 16                  ; move dx=0, dy=2, color=none (move only!)
        .db 248                 ; move dx=3, dy=3, color=fore (set)
        .db 64                  ; move dx=2, dy=0, color=none (move only!)
        .db 252                 ; move dx=3, dy=-3, color=fore (set)
        .db 122                 ; move dx=-3, dy=3, color=none (move only!)
        .db 42                  ; move dx=-1, dy=1, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        ;; ascii 90: 'Z'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 15                  ; # moves
        .db 80                  ; move dx=2, dy=2, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 16                  ; move dx=0, dy=2, color=none (move only!)
        .db 250                 ; move dx=-3, dy=3, color=fore (set)
        .db 250                 ; move dx=-3, dy=3, color=fore (set)
        .db 16                  ; move dx=0, dy=2, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 118                 ; move dx=-3, dy=-2, color=none (move only!)
        .db 98                  ; move dx=-3, dy=0, color=none (move only!)
        .db 136                 ; move dx=0, dy=1, color=fore (set)
        .db 124                 ; move dx=3, dy=-3, color=none (move only!)
        .db 92                  ; move dx=2, dy=-3, color=none (move only!)
        .db 180                 ; move dx=1, dy=-2, color=fore (set)
        ;; ascii 91: '['
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 12                  ; # moves
        .db 112                 ; move dx=3, dy=2, color=none (move only!)
        .db 32                  ; move dx=1, dy=0, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 8                   ; move dx=0, dy=1, color=none (move only!)
        .db 192                 ; move dx=2, dy=0, color=fore (set)
        .db 94                  ; move dx=-2, dy=-3, color=none (move only!)
        .db 28                  ; move dx=0, dy=-3, color=none (move only!)
        .db 28                  ; move dx=0, dy=-3, color=none (move only!)
        .db 12                  ; move dx=0, dy=-1, color=none (move only!)
        .db 192                 ; move dx=2, dy=0, color=fore (set)
        ;; ascii 92: '\'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 4                   ; # moves
        .db 88                  ; move dx=2, dy=3, color=none (move only!)
        .db 248                 ; move dx=3, dy=3, color=fore (set)
        .db 248                 ; move dx=3, dy=3, color=fore (set)
        .db 248                 ; move dx=3, dy=3, color=fore (set)
        ;; ascii 93: ']'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 11                  ; # moves
        .db 112                 ; move dx=3, dy=2, color=none (move only!)
        .db 32                  ; move dx=1, dy=0, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 202                 ; move dx=-2, dy=1, color=fore (set)
        .db 192                 ; move dx=2, dy=0, color=fore (set)
        .db 28                  ; move dx=0, dy=-3, color=none (move only!)
        .db 28                  ; move dx=0, dy=-3, color=none (move only!)
        .db 28                  ; move dx=0, dy=-3, color=none (move only!)
        .db 206                 ; move dx=-2, dy=-1, color=fore (set)
        ;; ascii 94: '^'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 9                   ; # moves
        .db 104                 ; move dx=3, dy=1, color=none (move only!)
        .db 32                  ; move dx=1, dy=0, color=none (move only!)
        .db 232                 ; move dx=3, dy=1, color=fore (set)
        .db 110                 ; move dx=-3, dy=-1, color=none (move only!)
        .db 242                 ; move dx=-3, dy=2, color=fore (set)
        .db 162                 ; move dx=-1, dy=0, color=fore (set)
        .db 108                 ; move dx=3, dy=-1, color=none (move only!)
        .db 96                  ; move dx=3, dy=0, color=none (move only!)
        .db 232                 ; move dx=3, dy=1, color=fore (set)
        ;; ascii 95: '_'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 7                   ; # moves
        .db 88                  ; move dx=2, dy=3, color=none (move only!)
        .db 24                  ; move dx=0, dy=3, color=none (move only!)
        .db 24                  ; move dx=0, dy=3, color=none (move only!)
        .db 24                  ; move dx=0, dy=3, color=none (move only!)
        .db 16                  ; move dx=0, dy=2, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        ;; ascii 96: '`'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 4                   ; # moves
        .db 96                  ; move dx=3, dy=0, color=none (move only!)
        .db 32                  ; move dx=1, dy=0, color=none (move only!)
        .db 176                 ; move dx=1, dy=2, color=fore (set)
        .db 160                 ; move dx=1, dy=0, color=fore (set)
        ;; ascii 97: 'a'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 15                  ; # moves
        .db 120                 ; move dx=3, dy=3, color=none (move only!)
        .db 48                  ; move dx=1, dy=2, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 40                  ; move dx=1, dy=1, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 226                 ; move dx=-3, dy=0, color=fore (set)
        .db 194                 ; move dx=-2, dy=0, color=fore (set)
        .db 182                 ; move dx=-1, dy=-2, color=fore (set)
        .db 52                  ; move dx=1, dy=-2, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 204                 ; move dx=2, dy=-1, color=fore (set)
        .db 106                 ; move dx=-3, dy=1, color=none (move only!)
        .db 66                  ; move dx=-2, dy=0, color=none (move only!)
        .db 170                 ; move dx=-1, dy=1, color=fore (set)
        ;; ascii 98: 'b'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 14                  ; # moves
        .db 80                  ; move dx=2, dy=2, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 106                 ; move dx=-3, dy=1, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 124                 ; move dx=3, dy=-3, color=none (move only!)
        .db 156                 ; move dx=0, dy=-3, color=fore (set)
        .db 206                 ; move dx=-2, dy=-1, color=fore (set)
        .db 88                  ; move dx=2, dy=3, color=none (move only!)
        .db 16                  ; move dx=0, dy=2, color=none (move only!)
        .db 178                 ; move dx=-1, dy=2, color=fore (set)
        .db 226                 ; move dx=-3, dy=0, color=fore (set)
        ;; ascii 99: 'c'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 13                  ; # moves
        .db 120                 ; move dx=3, dy=3, color=none (move only!)
        .db 16                  ; move dx=0, dy=2, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 200                 ; move dx=2, dy=1, color=fore (set)
        .db 98                  ; move dx=-3, dy=0, color=none (move only!)
        .db 98                  ; move dx=-3, dy=0, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 56                  ; move dx=1, dy=3, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 204                 ; move dx=2, dy=-1, color=fore (set)
        .db 126                 ; move dx=-3, dy=-3, color=none (move only!)
        .db 98                  ; move dx=-3, dy=0, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        ;; ascii 100: 'd'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 19                  ; # moves
        .db 112                 ; move dx=3, dy=2, color=none (move only!)
        .db 96                  ; move dx=3, dy=0, color=none (move only!)
        .db 64                  ; move dx=2, dy=0, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 226                 ; move dx=-3, dy=0, color=fore (set)
        .db 106                 ; move dx=-3, dy=1, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 56                  ; move dx=1, dy=3, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 92                  ; move dx=2, dy=-3, color=none (move only!)
        .db 156                 ; move dx=0, dy=-3, color=fore (set)
        .db 24                  ; move dx=0, dy=3, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 226                 ; move dx=-3, dy=0, color=fore (set)
        .db 126                 ; move dx=-3, dy=-3, color=none (move only!)
        .db 144                 ; move dx=0, dy=2, color=fore (set)
        .db 60                  ; move dx=1, dy=-3, color=none (move only!)
        .db 28                  ; move dx=0, dy=-3, color=none (move only!)
        .db 160                 ; move dx=1, dy=0, color=fore (set)
        ;; ascii 101: 'e'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 18                  ; # moves
        .db 120                 ; move dx=3, dy=3, color=none (move only!)
        .db 16                  ; move dx=0, dy=2, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 72                  ; move dx=2, dy=1, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 226                 ; move dx=-3, dy=0, color=fore (set)
        .db 226                 ; move dx=-3, dy=0, color=fore (set)
        .db 156                 ; move dx=0, dy=-3, color=fore (set)
        .db 56                  ; move dx=1, dy=3, color=none (move only!)
        .db 24                  ; move dx=0, dy=3, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 204                 ; move dx=2, dy=-1, color=fore (set)
        .db 126                 ; move dx=-3, dy=-3, color=none (move only!)
        .db 98                  ; move dx=-3, dy=0, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 92                  ; move dx=2, dy=-3, color=none (move only!)
        .db 28                  ; move dx=0, dy=-3, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        ;; ascii 102: 'f'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 13                  ; # moves
        .db 112                 ; move dx=3, dy=2, color=none (move only!)
        .db 64                  ; move dx=2, dy=0, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 122                 ; move dx=-3, dy=3, color=none (move only!)
        .db 226                 ; move dx=-3, dy=0, color=fore (set)
        .db 72                  ; move dx=2, dy=1, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 28                  ; move dx=0, dy=-3, color=none (move only!)
        .db 28                  ; move dx=0, dy=-3, color=none (move only!)
        .db 156                 ; move dx=0, dy=-3, color=fore (set)
        .db 50                  ; move dx=-1, dy=2, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        ;; ascii 103: 'g'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 24                  ; # moves
        .db 120                 ; move dx=3, dy=3, color=none (move only!)
        .db 16                  ; move dx=0, dy=2, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 64                  ; move dx=2, dy=0, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 86                  ; move dx=-2, dy=-2, color=none (move only!)
        .db 226                 ; move dx=-3, dy=0, color=fore (set)
        .db 62                  ; move dx=-1, dy=-3, color=none (move only!)
        .db 156                 ; move dx=0, dy=-3, color=fore (set)
        .db 24                  ; move dx=0, dy=3, color=none (move only!)
        .db 24                  ; move dx=0, dy=3, color=none (move only!)
        .db 24                  ; move dx=0, dy=3, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 192                 ; move dx=2, dy=0, color=fore (set)
        .db 126                 ; move dx=-3, dy=-3, color=none (move only!)
        .db 94                  ; move dx=-2, dy=-3, color=none (move only!)
        .db 144                 ; move dx=0, dy=2, color=fore (set)
        .db 72                  ; move dx=2, dy=1, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 60                  ; move dx=1, dy=-3, color=none (move only!)
        .db 28                  ; move dx=0, dy=-3, color=none (move only!)
        .db 206                 ; move dx=-2, dy=-1, color=fore (set)
        ;; ascii 104: 'h'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 13                  ; # moves
        .db 80                  ; move dx=2, dy=2, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 106                 ; move dx=-3, dy=1, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 124                 ; move dx=3, dy=-3, color=none (move only!)
        .db 124                 ; move dx=3, dy=-3, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 28                  ; move dx=0, dy=-3, color=none (move only!)
        .db 28                  ; move dx=0, dy=-3, color=none (move only!)
        .db 206                 ; move dx=-2, dy=-1, color=fore (set)
        ;; ascii 105: 'i'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 12                  ; # moves
        .db 120                 ; move dx=3, dy=3, color=none (move only!)
        .db 112                 ; move dx=3, dy=2, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 74                  ; move dx=-2, dy=1, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 160                 ; move dx=1, dy=0, color=fore (set)
        .db 94                  ; move dx=-2, dy=-3, color=none (move only!)
        .db 28                  ; move dx=0, dy=-3, color=none (move only!)
        .db 206                 ; move dx=-2, dy=-1, color=fore (set)
        .db 92                  ; move dx=2, dy=-3, color=none (move only!)
        .db 128                 ; move dx=0, dy=0, color=fore (set)
        ;; ascii 106: 'j'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 14                  ; # moves
        .db 120                 ; move dx=3, dy=3, color=none (move only!)
        .db 112                 ; move dx=3, dy=2, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 202                 ; move dx=-2, dy=1, color=fore (set)
        .db 78                  ; move dx=-2, dy=-1, color=none (move only!)
        .db 168                 ; move dx=1, dy=1, color=fore (set)
        .db 124                 ; move dx=3, dy=-3, color=none (move only!)
        .db 28                  ; move dx=0, dy=-3, color=none (move only!)
        .db 28                  ; move dx=0, dy=-3, color=none (move only!)
        .db 28                  ; move dx=0, dy=-3, color=none (move only!)
        .db 12                  ; move dx=0, dy=-1, color=none (move only!)
        .db 128                 ; move dx=0, dy=0, color=fore (set)
        ;; ascii 107: 'k'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 15                  ; # moves
        .db 80                  ; move dx=2, dy=2, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 244                 ; move dx=3, dy=-2, color=fore (set)
        .db 236                 ; move dx=3, dy=-1, color=fore (set)
        .db 122                 ; move dx=-3, dy=3, color=none (move only!)
        .db 66                  ; move dx=-2, dy=0, color=none (move only!)
        .db 240                 ; move dx=3, dy=2, color=fore (set)
        .db 200                 ; move dx=2, dy=1, color=fore (set)
        .db 118                 ; move dx=-3, dy=-2, color=none (move only!)
        .db 98                  ; move dx=-3, dy=0, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 116                 ; move dx=3, dy=-2, color=none (move only!)
        .db 64                  ; move dx=2, dy=0, color=none (move only!)
        .db 208                 ; move dx=2, dy=2, color=fore (set)
        ;; ascii 108: 'l'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 12                  ; # moves
        .db 112                 ; move dx=3, dy=2, color=none (move only!)
        .db 96                  ; move dx=3, dy=0, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 74                  ; move dx=-2, dy=1, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 160                 ; move dx=1, dy=0, color=fore (set)
        .db 94                  ; move dx=-2, dy=-3, color=none (move only!)
        .db 28                  ; move dx=0, dy=-3, color=none (move only!)
        .db 28                  ; move dx=0, dy=-3, color=none (move only!)
        .db 206                 ; move dx=-2, dy=-1, color=fore (set)
        ;; ascii 109: 'm'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 19                  ; # moves
        .db 24                  ; move dx=0, dy=3, color=none (move only!)
        .db 16                  ; move dx=0, dy=2, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 74                  ; move dx=-2, dy=1, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 126                 ; move dx=-3, dy=-3, color=none (move only!)
        .db 62                  ; move dx=-1, dy=-3, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 124                 ; move dx=3, dy=-3, color=none (move only!)
        .db 124                 ; move dx=3, dy=-3, color=none (move only!)
        .db 64                  ; move dx=2, dy=0, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 28                  ; move dx=0, dy=-3, color=none (move only!)
        .db 28                  ; move dx=0, dy=-3, color=none (move only!)
        .db 206                 ; move dx=-2, dy=-1, color=fore (set)
        ;; ascii 110: 'n'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 13                  ; # moves
        .db 88                  ; move dx=2, dy=3, color=none (move only!)
        .db 16                  ; move dx=0, dy=2, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 106                 ; move dx=-3, dy=1, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 124                 ; move dx=3, dy=-3, color=none (move only!)
        .db 124                 ; move dx=3, dy=-3, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 28                  ; move dx=0, dy=-3, color=none (move only!)
        .db 28                  ; move dx=0, dy=-3, color=none (move only!)
        .db 206                 ; move dx=-2, dy=-1, color=fore (set)
        ;; ascii 111: 'o'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 18                  ; # moves
        .db 120                 ; move dx=3, dy=3, color=none (move only!)
        .db 16                  ; move dx=0, dy=2, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 72                  ; move dx=2, dy=1, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 90                  ; move dx=-2, dy=3, color=none (move only!)
        .db 226                 ; move dx=-3, dy=0, color=fore (set)
        .db 62                  ; move dx=-1, dy=-3, color=none (move only!)
        .db 156                 ; move dx=0, dy=-3, color=fore (set)
        .db 120                 ; move dx=3, dy=3, color=none (move only!)
        .db 104                 ; move dx=3, dy=1, color=none (move only!)
        .db 178                 ; move dx=-1, dy=2, color=fore (set)
        .db 126                 ; move dx=-3, dy=-3, color=none (move only!)
        .db 78                  ; move dx=-2, dy=-1, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 92                  ; move dx=2, dy=-3, color=none (move only!)
        .db 28                  ; move dx=0, dy=-3, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        ;; ascii 112: 'p'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 18                  ; # moves
        .db 88                  ; move dx=2, dy=3, color=none (move only!)
        .db 16                  ; move dx=0, dy=2, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 106                 ; move dx=-3, dy=1, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 124                 ; move dx=3, dy=-3, color=none (move only!)
        .db 156                 ; move dx=0, dy=-3, color=fore (set)
        .db 206                 ; move dx=-2, dy=-1, color=fore (set)
        .db 88                  ; move dx=2, dy=3, color=none (move only!)
        .db 16                  ; move dx=0, dy=2, color=none (move only!)
        .db 178                 ; move dx=-1, dy=2, color=fore (set)
        .db 98                  ; move dx=-3, dy=0, color=none (move only!)
        .db 66                  ; move dx=-2, dy=0, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 60                  ; move dx=1, dy=-3, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        ;; ascii 113: 'q'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 21                  ; # moves
        .db 120                 ; move dx=3, dy=3, color=none (move only!)
        .db 16                  ; move dx=0, dy=2, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 64                  ; move dx=2, dy=0, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 86                  ; move dx=-2, dy=-2, color=none (move only!)
        .db 226                 ; move dx=-3, dy=0, color=fore (set)
        .db 62                  ; move dx=-1, dy=-3, color=none (move only!)
        .db 156                 ; move dx=0, dy=-3, color=fore (set)
        .db 16                  ; move dx=0, dy=2, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 72                  ; move dx=2, dy=1, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 32                  ; move dx=1, dy=0, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 28                  ; move dx=0, dy=-3, color=none (move only!)
        .db 28                  ; move dx=0, dy=-3, color=none (move only!)
        .db 28                  ; move dx=0, dy=-3, color=none (move only!)
        .db 206                 ; move dx=-2, dy=-1, color=fore (set)
        ;; ascii 114: 'r'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 11                  ; # moves
        .db 88                  ; move dx=2, dy=3, color=none (move only!)
        .db 16                  ; move dx=0, dy=2, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 124                 ; move dx=3, dy=-3, color=none (move only!)
        .db 28                  ; move dx=0, dy=-3, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 98                  ; move dx=-3, dy=0, color=none (move only!)
        .db 202                 ; move dx=-2, dy=1, color=fore (set)
        .db 58                  ; move dx=-1, dy=3, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        ;; ascii 115: 's'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 20                  ; # moves
        .db 120                 ; move dx=3, dy=3, color=none (move only!)
        .db 16                  ; move dx=0, dy=2, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 122                 ; move dx=-3, dy=3, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 200                 ; move dx=2, dy=1, color=fore (set)
        .db 90                  ; move dx=-2, dy=3, color=none (move only!)
        .db 226                 ; move dx=-3, dy=0, color=fore (set)
        .db 116                 ; move dx=3, dy=-2, color=none (move only!)
        .db 64                  ; move dx=2, dy=0, color=none (move only!)
        .db 178                 ; move dx=-1, dy=2, color=fore (set)
        .db 126                 ; move dx=-3, dy=-3, color=none (move only!)
        .db 94                  ; move dx=-2, dy=-3, color=none (move only!)
        .db 136                 ; move dx=0, dy=1, color=fore (set)
        .db 116                 ; move dx=3, dy=-2, color=none (move only!)
        .db 32                  ; move dx=1, dy=0, color=none (move only!)
        .db 200                 ; move dx=2, dy=1, color=fore (set)
        .db 122                 ; move dx=-3, dy=3, color=none (move only!)
        .db 114                 ; move dx=-3, dy=2, color=none (move only!)
        .db 128                 ; move dx=0, dy=0, color=fore (set)
        ;; ascii 116: 't'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 15                  ; # moves
        .db 112                 ; move dx=3, dy=2, color=none (move only!)
        .db 32                  ; move dx=1, dy=0, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 106                 ; move dx=-3, dy=1, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 56                  ; move dx=1, dy=3, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 98                  ; move dx=-3, dy=0, color=none (move only!)
        .db 182                 ; move dx=-1, dy=-2, color=fore (set)
        .db 28                  ; move dx=0, dy=-3, color=none (move only!)
        .db 28                  ; move dx=0, dy=-3, color=none (move only!)
        .db 202                 ; move dx=-2, dy=1, color=fore (set)
        .db 96                  ; move dx=3, dy=0, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        ;; ascii 117: 'u'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 14                  ; # moves
        .db 88                  ; move dx=2, dy=3, color=none (move only!)
        .db 16                  ; move dx=0, dy=2, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 40                  ; move dx=1, dy=1, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 92                  ; move dx=2, dy=-3, color=none (move only!)
        .db 156                 ; move dx=0, dy=-3, color=fore (set)
        .db 24                  ; move dx=0, dy=3, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 226                 ; move dx=-3, dy=0, color=fore (set)
        .db 124                 ; move dx=3, dy=-3, color=none (move only!)
        .db 28                  ; move dx=0, dy=-3, color=none (move only!)
        .db 140                 ; move dx=0, dy=-1, color=fore (set)
        ;; ascii 118: 'v'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 12                  ; # moves
        .db 24                  ; move dx=0, dy=3, color=none (move only!)
        .db 16                  ; move dx=0, dy=2, color=none (move only!)
        .db 184                 ; move dx=1, dy=3, color=fore (set)
        .db 216                 ; move dx=2, dy=3, color=fore (set)
        .db 116                 ; move dx=3, dy=-2, color=none (move only!)
        .db 220                 ; move dx=2, dy=-3, color=fore (set)
        .db 90                  ; move dx=-2, dy=3, color=none (move only!)
        .db 8                   ; move dx=0, dy=1, color=none (move only!)
        .db 210                 ; move dx=-2, dy=2, color=fore (set)
        .db 124                 ; move dx=3, dy=-3, color=none (move only!)
        .db 60                  ; move dx=1, dy=-3, color=none (move only!)
        .db 140                 ; move dx=0, dy=-1, color=fore (set)
        ;; ascii 119: 'w'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 14                  ; # moves
        .db 24                  ; move dx=0, dy=3, color=none (move only!)
        .db 16                  ; move dx=0, dy=2, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 40                  ; move dx=1, dy=1, color=none (move only!)
        .db 192                 ; move dx=2, dy=0, color=fore (set)
        .db 44                  ; move dx=1, dy=-1, color=none (move only!)
        .db 156                 ; move dx=0, dy=-3, color=fore (set)
        .db 124                 ; move dx=3, dy=-3, color=none (move only!)
        .db 32                  ; move dx=1, dy=0, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 202                 ; move dx=-2, dy=1, color=fore (set)
        .db 162                 ; move dx=-1, dy=0, color=fore (set)
        ;; ascii 120: 'x'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 12                  ; # moves
        .db 24                  ; move dx=0, dy=3, color=none (move only!)
        .db 16                  ; move dx=0, dy=2, color=none (move only!)
        .db 248                 ; move dx=3, dy=3, color=fore (set)
        .db 108                 ; move dx=3, dy=-1, color=none (move only!)
        .db 242                 ; move dx=-3, dy=2, color=fore (set)
        .db 250                 ; move dx=-3, dy=3, color=fore (set)
        .db 124                 ; move dx=3, dy=-3, color=none (move only!)
        .db 64                  ; move dx=2, dy=0, color=none (move only!)
        .db 248                 ; move dx=3, dy=3, color=fore (set)
        .db 62                  ; move dx=-1, dy=-3, color=none (move only!)
        .db 28                  ; move dx=0, dy=-3, color=none (move only!)
        .db 172                 ; move dx=1, dy=-1, color=fore (set)
        ;; ascii 121: 'y'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 18                  ; # moves
        .db 88                  ; move dx=2, dy=3, color=none (move only!)
        .db 16                  ; move dx=0, dy=2, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 40                  ; move dx=1, dy=1, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 92                  ; move dx=2, dy=-3, color=none (move only!)
        .db 156                 ; move dx=0, dy=-3, color=fore (set)
        .db 24                  ; move dx=0, dy=3, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 58                  ; move dx=-1, dy=3, color=none (move only!)
        .db 226                 ; move dx=-3, dy=0, color=fore (set)
        .db 92                  ; move dx=2, dy=-3, color=none (move only!)
        .db 200                 ; move dx=2, dy=1, color=fore (set)
        .db 136                 ; move dx=0, dy=1, color=fore (set)
        .db 28                  ; move dx=0, dy=-3, color=none (move only!)
        .db 28                  ; move dx=0, dy=-3, color=none (move only!)
        .db 156                 ; move dx=0, dy=-3, color=fore (set)
        ;; ascii 122: 'z'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 9                   ; # moves
        .db 88                  ; move dx=2, dy=3, color=none (move only!)
        .db 16                  ; move dx=0, dy=2, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 8                   ; move dx=0, dy=1, color=none (move only!)
        .db 250                 ; move dx=-3, dy=3, color=fore (set)
        .db 250                 ; move dx=-3, dy=3, color=fore (set)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        ;; ascii 123: '{'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 13                  ; # moves
        .db 112                 ; move dx=3, dy=2, color=none (move only!)
        .db 64                  ; move dx=2, dy=0, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 106                 ; move dx=-3, dy=1, color=none (move only!)
        .db 34                  ; move dx=-1, dy=0, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 16                  ; move dx=0, dy=2, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 40                  ; move dx=1, dy=1, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 126                 ; move dx=-3, dy=-3, color=none (move only!)
        .db 62                  ; move dx=-1, dy=-3, color=none (move only!)
        .db 202                 ; move dx=-2, dy=1, color=fore (set)
        ;; ascii 124: '|'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 6                   ; # moves
        .db 112                 ; move dx=3, dy=2, color=none (move only!)
        .db 96                  ; move dx=3, dy=0, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 136                 ; move dx=0, dy=1, color=fore (set)
        ;; ascii 125: '}'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 11                  ; # moves
        .db 80                  ; move dx=2, dy=2, color=none (move only!)
        .db 224                 ; move dx=3, dy=0, color=fore (set)
        .db 40                  ; move dx=1, dy=1, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 16                  ; move dx=0, dy=2, color=none (move only!)
        .db 152                 ; move dx=0, dy=3, color=fore (set)
        .db 42                  ; move dx=-1, dy=1, color=none (move only!)
        .db 226                 ; move dx=-3, dy=0, color=fore (set)
        .db 124                 ; move dx=3, dy=-3, color=none (move only!)
        .db 84                  ; move dx=2, dy=-2, color=none (move only!)
        .db 160                 ; move dx=1, dy=0, color=fore (set)
        ;; ascii 126: '~'
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 6                   ; # moves
        .db 104                 ; move dx=3, dy=1, color=none (move only!)
        .db 232                 ; move dx=3, dy=1, color=fore (set)
        .db 204                 ; move dx=2, dy=-1, color=fore (set)
        .db 98                  ; move dx=-3, dy=0, color=none (move only!)
        .db 194                 ; move dx=-2, dy=0, color=fore (set)
        .db 170                 ; move dx=-1, dy=1, color=fore (set)
        ;; ascii 127: <non standard>
        .db 32                  ; class(bits 5-7)
        .db 11                  ; width
        .db 15                  ; height
        .db 0                   ; # moves
