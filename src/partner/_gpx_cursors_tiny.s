        ;; _gpx_cursors_tiny.s
        ;;
        ;; Converted from masked AND/OR cursors to 3-state tiny payloads.
        ;;  state 0: background (pen up / move only)
        ;;  state 2: mask (pen down erase)
        ;;  state 1: foreground (pen down ink)
        ;;
        ;; FORMAT (tiny bmp_t + hotspot trailer):
        ;;   header (5 bytes):
        ;;     signature = type=10 (tiny), stride nibble=0
        ;;     width, height, size (size = move_count)
        ;;   payload: tiny move bytes (no origin bytes)
        ;;   trailer (2 bytes): hotspot_x, hotspot_y

        .module _gpx_cursors_tiny
        .optsdcc -mz80 sdcccall(1)

        .globl  _gpx_cur_classic_tiny
        .globl  _gpx_cur_std_tiny
        .globl  _gpx_cur_hourglass_tiny
        .globl  _gpx_cur_caret_tiny
        .globl  _gpx_cur_hand_tiny

        .area   _CODE

_gpx_cur_classic_tiny::
        .db     0x20                    ;; signature: tiny type=10, stride nibble=0
        .db     0x08                    ;; width
        .db     0x0A                    ;; height
        .dw     0x001A                  ;; payload size (moves only)
        .db     0x28                    ;; move 000: color=move dx=+1 dy=+1
        .db     0x98                    ;; move 001: color=fore dx=+0 dy=+3
        .db     0xE0                    ;; move 002: color=fore dx=+3 dy=+0
        .db     0xF2                    ;; move 003: color=fore dx=-3 dy=+2
        .db     0xE8                    ;; move 004: color=fore dx=+3 dy=+1
        .db     0xF6                    ;; move 005: color=fore dx=-3 dy=-2
        .db     0xBC                    ;; move 006: color=fore dx=+1 dy=-3
        .db     0xD8                    ;; move 007: color=fore dx=+2 dy=+3
        .db     0xA0                    ;; move 008: color=fore dx=+1 dy=+0
        .db     0x6E                    ;; move 009: color=move dx=-3 dy=-1
        .db     0xBA                    ;; move 010: color=fore dx=-1 dy=+3
        .db     0x14                    ;; move 011: color=move dx=+0 dy=-2
        .db     0xF8                    ;; move 012: color=fore dx=+3 dy=+3
        .db     0x5C                    ;; move 013: color=move dx=+2 dy=-3
        .db     0x7F                    ;; move 014: color=mask dx=-3 dy=-3
        .db     0x76                    ;; move 015: color=move dx=-3 dy=-2
        .db     0x19                    ;; move 016: color=mask dx=+0 dy=+3
        .db     0x19                    ;; move 017: color=mask dx=+0 dy=+3
        .db     0x11                    ;; move 018: color=mask dx=+0 dy=+2
        .db     0x4D                    ;; move 019: color=mask dx=+2 dy=-1
        .db     0x51                    ;; move 020: color=mask dx=+2 dy=+2
        .db     0x3C                    ;; move 021: color=move dx=+1 dy=-3
        .db     0x11                    ;; move 022: color=mask dx=+0 dy=+2
        .db     0x37                    ;; move 023: color=mask dx=-1 dy=-2
        .db     0x1C                    ;; move 024: color=move dx=+0 dy=-3
        .db     0x7F                    ;; move 025: color=mask dx=-3 dy=-3
        .db     0x01                    ;; hotspot_x
        .db     0x01                    ;; hotspot_y
        ;; 3-state rows: . = bg, m = mask, f = fore
        ;;   00: mm......
        ;;   01: mfm.....
        ;;   02: mffm....
        ;;   03: mfffm...
        ;;   04: mffffm..
        ;;   05: mfffffm.
        ;;   06: mfffmm..
        ;;   07: mfmffm..
        ;;   08: mm.mfm..
        ;;   09: ....m...
        ;; moves: 26
        ;; color pass order: 1 then 2

_gpx_cur_std_tiny::
        .db     0x20                    ;; signature: tiny type=10, stride nibble=0
        .db     0x08                    ;; width
        .db     0x0A                    ;; height
        .dw     0x001C                  ;; payload size (moves only)
        .db     0x98                    ;; move 000: color=fore dx=+0 dy=+3
        .db     0x98                    ;; move 001: color=fore dx=+0 dy=+3
        .db     0x08                    ;; move 002: color=move dx=+0 dy=+1
        .db     0xF0                    ;; move 003: color=fore dx=+3 dy=+2
        .db     0xCC                    ;; move 004: color=fore dx=+2 dy=-1
        .db     0x3C                    ;; move 005: color=move dx=+1 dy=-3
        .db     0xFE                    ;; move 006: color=fore dx=-3 dy=-3
        .db     0xD6                    ;; move 007: color=fore dx=-2 dy=-2
        .db     0x78                    ;; move 008: color=move dx=+3 dy=+3
        .db     0x18                    ;; move 009: color=move dx=+0 dy=+3
        .db     0xCC                    ;; move 010: color=fore dx=+2 dy=-1
        .db     0x4A                    ;; move 011: color=move dx=-2 dy=+1
        .db     0xA8                    ;; move 012: color=fore dx=+1 dy=+1
        .db     0x62                    ;; move 013: color=move dx=-3 dy=+0
        .db     0x80                    ;; move 014: color=fore dx=+0 dy=+0
        .db     0x3E                    ;; move 015: color=move dx=-1 dy=-3
        .db     0x1D                    ;; move 016: color=mask dx=+0 dy=-3
        .db     0x59                    ;; move 017: color=mask dx=+2 dy=+3
        .db     0x5B                    ;; move 018: color=mask dx=-2 dy=+3
        .db     0x3C                    ;; move 019: color=move dx=+1 dy=-3
        .db     0x59                    ;; move 020: color=mask dx=+2 dy=+3
        .db     0x6F                    ;; move 021: color=mask dx=-3 dy=-1
        .db     0x5C                    ;; move 022: color=move dx=+2 dy=-3
        .db     0x51                    ;; move 023: color=mask dx=+2 dy=+2
        .db     0x22                    ;; move 024: color=move dx=-1 dy=+0
        .db     0x63                    ;; move 025: color=mask dx=-3 dy=+0
        .db     0x58                    ;; move 026: color=move dx=+2 dy=+3
        .db     0x21                    ;; move 027: color=mask dx=+1 dy=+0
        .db     0x01                    ;; hotspot_x
        .db     0x01                    ;; hotspot_y
        ;; 3-state rows: . = bg, m = mask, f = fore
        ;;   00: ff......
        ;;   01: fmf.....
        ;;   02: fmmf....
        ;;   03: fmmmf...
        ;;   04: fmmmmf..
        ;;   05: fmmmmmf.
        ;;   06: fmmmff..
        ;;   07: fmfmmf..
        ;;   08: .ffmmf..
        ;;   09: ...ff...
        ;; moves: 28
        ;; color pass order: 1 then 2

_gpx_cur_hourglass_tiny::
        .db     0x20                    ;; signature: tiny type=10, stride nibble=0
        .db     0x08                    ;; width
        .db     0x0A                    ;; height
        .dw     0x001D                  ;; payload size (moves only)
        .db     0x48                    ;; move 000: color=move dx=+2 dy=+1
        .db     0x41                    ;; move 001: color=mask dx=+2 dy=+0
        .db     0x33                    ;; move 002: color=mask dx=-1 dy=+2
        .db     0x10                    ;; move 003: color=move dx=+0 dy=+2
        .db     0x33                    ;; move 004: color=mask dx=-1 dy=+2
        .db     0x0C                    ;; move 005: color=move dx=+0 dy=-1
        .db     0x41                    ;; move 006: color=mask dx=+2 dy=+0
        .db     0x09                    ;; move 007: color=mask dx=+0 dy=+1
        .db     0x5E                    ;; move 008: color=move dx=-2 dy=-3
        .db     0x1C                    ;; move 009: color=move dx=+0 dy=-3
        .db     0x09                    ;; move 010: color=mask dx=+0 dy=+1
        .db     0x56                    ;; move 011: color=move dx=-2 dy=-2
        .db     0xE0                    ;; move 012: color=fore dx=+3 dy=+0
        .db     0xE0                    ;; move 013: color=fore dx=+3 dy=+0
        .db     0xDA                    ;; move 014: color=fore dx=-2 dy=+3
        .db     0xFA                    ;; move 015: color=fore dx=-3 dy=+3
        .db     0x6C                    ;; move 016: color=move dx=+3 dy=-1
        .db     0xD8                    ;; move 017: color=fore dx=+2 dy=+3
        .db     0xE2                    ;; move 018: color=fore dx=-3 dy=+0
        .db     0xE2                    ;; move 019: color=fore dx=-3 dy=+0
        .db     0x5C                    ;; move 020: color=move dx=+2 dy=-3
        .db     0x14                    ;; move 021: color=move dx=+0 dy=-2
        .db     0xDE                    ;; move 022: color=fore dx=-2 dy=-3
        .db     0x70                    ;; move 023: color=move dx=+3 dy=+2
        .db     0x80                    ;; move 024: color=fore dx=+0 dy=+0
        .db     0x3A                    ;; move 025: color=move dx=-1 dy=+3
        .db     0xDA                    ;; move 026: color=fore dx=-2 dy=+3
        .db     0x6C                    ;; move 027: color=move dx=+3 dy=-1
        .db     0x80                    ;; move 028: color=fore dx=+0 dy=+0
        .db     0x03                    ;; hotspot_x
        .db     0x04                    ;; hotspot_y
        ;; 3-state rows: . = bg, m = mask, f = fore
        ;;   00: fffffff.
        ;;   01: .fmmmf..
        ;;   02: .fmfmf..
        ;;   03: ..fmf...
        ;;   04: ...f....
        ;;   05: ..fmf...
        ;;   06: .fmmmf..
        ;;   07: .fmfmf..
        ;;   08: fffffff.
        ;;   09: ........
        ;; moves: 29
        ;; color pass order: 2 then 1

_gpx_cur_caret_tiny::
        .db     0x20                    ;; signature: tiny type=10, stride nibble=0
        .db     0x08                    ;; width
        .db     0x0A                    ;; height
        .dw     0x0021                  ;; payload size (moves only)
        .db     0x50                    ;; move 000: color=move dx=+2 dy=+2
        .db     0x19                    ;; move 001: color=mask dx=+0 dy=+3
        .db     0x11                    ;; move 002: color=mask dx=+0 dy=+2
        .db     0x2B                    ;; move 003: color=mask dx=-1 dy=+1
        .db     0x34                    ;; move 004: color=move dx=+1 dy=-2
        .db     0x31                    ;; move 005: color=mask dx=+1 dy=+2
        .db     0x3E                    ;; move 006: color=move dx=-1 dy=-3
        .db     0x1C                    ;; move 007: color=move dx=+0 dy=-3
        .db     0x2F                    ;; move 008: color=mask dx=-1 dy=-1
        .db     0x40                    ;; move 009: color=move dx=+2 dy=+0
        .db     0x01                    ;; move 010: color=mask dx=+0 dy=+0
        .db     0x6E                    ;; move 011: color=move dx=-3 dy=-1
        .db     0xB8                    ;; move 012: color=fore dx=+1 dy=+3
        .db     0x98                    ;; move 013: color=fore dx=+0 dy=+3
        .db     0xBA                    ;; move 014: color=fore dx=-1 dy=+3
        .db     0x7C                    ;; move 015: color=move dx=+3 dy=-3
        .db     0x9C                    ;; move 016: color=fore dx=+0 dy=-3
        .db     0xBC                    ;; move 017: color=fore dx=+1 dy=-3
        .db     0xCA                    ;; move 018: color=fore dx=-2 dy=+1
        .db     0x38                    ;; move 019: color=move dx=+1 dy=+3
        .db     0x10                    ;; move 020: color=move dx=+0 dy=+2
        .db     0xB8                    ;; move 021: color=fore dx=+1 dy=+3
        .db     0xCE                    ;; move 022: color=fore dx=-2 dy=-1
        .db     0x4E                    ;; move 023: color=move dx=-2 dy=-1
        .db     0xB0                    ;; move 024: color=fore dx=+1 dy=+2
        .db     0x3E                    ;; move 025: color=move dx=-1 dy=-3
        .db     0x1C                    ;; move 026: color=move dx=+0 dy=-3
        .db     0x0C                    ;; move 027: color=move dx=+0 dy=-1
        .db     0xB4                    ;; move 028: color=fore dx=+1 dy=-2
        .db     0x60                    ;; move 029: color=move dx=+3 dy=+0
        .db     0x90                    ;; move 030: color=fore dx=+0 dy=+2
        .db     0x3A                    ;; move 031: color=move dx=-1 dy=+3
        .db     0xB0                    ;; move 032: color=fore dx=+1 dy=+2
        .db     0x01                    ;; hotspot_x
        .db     0x07                    ;; hotspot_y
        ;; 3-state rows: . = bg, m = mask, f = fore
        ;;   00: ff.ff...
        ;;   01: fmfmf...
        ;;   02: ffmff...
        ;;   03: .fmf....
        ;;   04: .fmf....
        ;;   05: .fmf....
        ;;   06: .fmf....
        ;;   07: ffmff...
        ;;   08: fmfmf...
        ;;   09: ff.ff...
        ;; moves: 33
        ;; color pass order: 2 then 1

_gpx_cur_hand_tiny::
        .db     0x20                    ;; signature: tiny type=10, stride nibble=0
        .db     0x08                    ;; width
        .db     0x0A                    ;; height
        .dw     0x0023                  ;; payload size (moves only)
        .db     0x40                    ;; move 000: color=move dx=+2 dy=+0
        .db     0xF8                    ;; move 001: color=fore dx=+3 dy=+3
        .db     0x4E                    ;; move 002: color=move dx=-2 dy=-1
        .db     0x98                    ;; move 003: color=fore dx=+0 dy=+3
        .db     0x5E                    ;; move 004: color=move dx=-2 dy=-3
        .db     0xBA                    ;; move 005: color=fore dx=-1 dy=+3
        .db     0x90                    ;; move 006: color=fore dx=+0 dy=+2
        .db     0x50                    ;; move 007: color=move dx=+2 dy=+2
        .db     0xE0                    ;; move 008: color=fore dx=+3 dy=+0
        .db     0x54                    ;; move 009: color=move dx=+2 dy=-2
        .db     0x9C                    ;; move 010: color=fore dx=+0 dy=-3
        .db     0xD6                    ;; move 011: color=fore dx=-2 dy=-2
        .db     0x98                    ;; move 012: color=fore dx=+0 dy=+3
        .db     0x7E                    ;; move 013: color=move dx=-3 dy=-3
        .db     0x2E                    ;; move 014: color=move dx=-1 dy=-1
        .db     0x98                    ;; move 015: color=fore dx=+0 dy=+3
        .db     0x32                    ;; move 016: color=move dx=-1 dy=+2
        .db     0xB0                    ;; move 017: color=fore dx=+1 dy=+2
        .db     0x68                    ;; move 018: color=move dx=+3 dy=+1
        .db     0xCC                    ;; move 019: color=fore dx=+2 dy=-1
        .db     0x5E                    ;; move 020: color=move dx=-2 dy=-3
        .db     0x73                    ;; move 021: color=mask dx=-3 dy=+2
        .db     0x3D                    ;; move 022: color=mask dx=+1 dy=-3
        .db     0x1D                    ;; move 023: color=mask dx=+0 dy=-3
        .db     0x50                    ;; move 024: color=move dx=+2 dy=+2
        .db     0x19                    ;; move 025: color=mask dx=+0 dy=+3
        .db     0x54                    ;; move 026: color=move dx=+2 dy=-2
        .db     0x3B                    ;; move 027: color=mask dx=-1 dy=+3
        .db     0x63                    ;; move 028: color=mask dx=-3 dy=+0
        .db     0x08                    ;; move 029: color=move dx=+0 dy=+1
        .db     0x61                    ;; move 030: color=mask dx=+3 dy=+0
        .db     0x3C                    ;; move 031: color=move dx=+1 dy=-3
        .db     0x11                    ;; move 032: color=mask dx=+0 dy=+2
        .db     0x6E                    ;; move 033: color=move dx=-3 dy=-1
        .db     0x4F                    ;; move 034: color=mask dx=-2 dy=-1
        .db     0x02                    ;; hotspot_x
        .db     0x00                    ;; hotspot_y
        ;; 3-state rows: . = bg, m = mask, f = fore
        ;;   00: ..f.....
        ;;   01: .fmf....
        ;;   02: .fmfff..
        ;;   03: .fmfmff.
        ;;   04: ffmfmfmf
        ;;   05: fmmfmfmf
        ;;   06: fmmmmmmf
        ;;   07: fmmmmmmf
        ;;   08: .fmmmmf.
        ;;   09: ..ffff..
        ;; moves: 35
        ;; color pass order: 1 then 2
