#!/usr/bin/env python3
"""Pixel-oracle checks for CPC UI drawing hot paths."""
import random
from itertools import product
from pathlib import Path
from optimization_regressions import Cpc, check, cpc_offset, invoke, pixel, word, write

ROOT = Path(__file__).resolve().parents[2]


def main():
    rng = random.Random(6128)
    for mode, ppb in ((0, 8), (1, 4)):
        width = ppb * 80
        image = ROOT / 'build/cpc-tests' / f'cpc_prims-{width}x200.bin'
        with Cpc() as machine:
            machine.reset(clear_memory=True)
            machine.load_binary(image, 0x8000)
            context = invoke(machine, image, '_gpx_create', af=mode << 8)['de']
            for trial in range(96):
                x = rng.choice((-1, 0, 1, 255, 256, width-1, width))
                y0, y1 = rng.choice(((-10, 199), (0, 0), (7, 32), (199, 200), (80, 1)))
                color, op = trial % 2, trial // 2 % 2
                clip = (1, 3, width-2, 190) if trial % 3 else (0, 0, width-1, 199)
                expected = bytearray(rng.randbytes(16384))
                write(machine, 0xc000, expected)
                write(machine, 0x2100, b''.join(map(word, clip)))
                invoke(machine, image, '_gpx_draw_line',
                       word(y0)+word(x)+word(y1)+bytes((color, op, 255))+word(0x2100),
                       hl=context, de=x & 65535)
                if clip[0] <= x <= clip[2]:
                    for y in range(max(clip[1], min(y0, y1)), min(clip[3], max(y0, y1))+1):
                        pixel(expected, ppb, x, y, lambda old: not old if op else bool(color))
                check(machine, expected, (mode, 'vertical', trial))
            for trial in range(96):
                x = 13 + trial % 8
                length = trial % 24 + 1 if trial < 72 else width-35
                color = trial % 2
                pattern = bytes((rng.randrange(256), rng.randrange(256)))
                rect = (x, 7, x+length-1, 10)
                clip = (x+trial%3, 8, x+length-1, 10)
                expected = bytearray(rng.randbytes(16384))
                write(machine, 0xc000, expected)
                write(machine, 0x2000, pattern)
                write(machine, 0x2100, b''.join(map(word, rect)))
                write(machine, 0x2120, b''.join(map(word, clip)))
                invoke(machine, image, '_gpx_fill_rectangle',
                       bytes((color, 0))+word(0x2000)+b'\x02'+word(0x2120),
                       hl=context, de=0x2100)
                for y in range(8, 11):
                    for px in range(clip[0], clip[2]+1):
                        value = bool(pattern[(y-7)%2] & (128 >> ((px-x)%8)))
                        pixel(expected, ppb, px, y, lambda old: value if color else not value)
                check(machine, expected, (mode, 'opaque span', trial))
            font = invoke(machine, image, '_gpx_get_system_font')['de']
            write(machine, 0x2000, b'Clipped proportional text!\0')
            for trial in range(36):
                x, y = ((4, 7), (-9, -2), (width-40, 195))[trial % 3]
                clip = ((0, 0, width-1, 199), (35, 8, 70, 11),
                        (0, 100, 4, 110), (width-8, 0, width-1, 199))[trial//3 % 4]
                color, op = trial % 2, trial//12 % 2
                before = rng.randbytes(16384)
                args = word(y)+word(0x2000)+word(font)+bytes((color, op))
                write(machine, 0xc000, before)
                invoke(machine, image, '_gpx_draw_text', args+word(0), hl=context, de=x & 65535)
                full = machine.screen()
                write(machine, 0xc000, before)
                write(machine, 0x2100, b''.join(map(word, clip)))
                invoke(machine, image, '_gpx_draw_text', args+word(0x2100), hl=context, de=x & 65535)
                expected = bytearray(before)
                for py in range(clip[1], clip[3]+1):
                    for px in range(clip[0], clip[2]+1):
                        value = bool(full[cpc_offset(px//ppb, py)] & (128 >> (px%ppb)))
                        pixel(expected, ppb, px, py, lambda old: value)
                check(machine, expected, (mode, 'clipped text', trial))
            # Independent masked-font oracle: preserve outside the halo,
            # draw explicit paper in the inverse ink, and let OR beat AND.
            # Exercise the text entry, both background policies and XOR.
            and_rows=(0x87,0x03,0x43,0x03,0x7b,0x03,0x03,0x03)
            or_rows=(0,0x30,0x48,0x48,0x78,0x48,0x48,0)
            glyph=bytes((0x10,6,8))+word(16)+bytes(v for pair in zip(and_rows,or_rows) for v in pair)
            font=bytes((1,65,65,0,6,8,0,0))+word(10)+glyph
            write(machine,0x2200,font)
            write(machine,0x2000,b'A\0')
            for trial,(color,op,background,x,clipped) in enumerate(product(
                    (0,1),(0,1),(0,1),(3,7,253,width-4),(False,True))):
                y=7
                clip=(x+1,y+1,x+4,y+6) if clipped else (0,0,width-1,199)
                expected=bytearray(rng.randbytes(16384))
                write(machine,0xc000,expected)
                write(machine,0x2100,b''.join(map(word,clip)))
                invoke(machine,image,'_gpx_set_text_background',bytes((background,)),hl=context)
                invoke(machine,image,'_gpx_draw_text',
                       word(y)+word(0x2000)+word(0x2200)+bytes((color,op))+word(0x2100),hl=context,de=x)
                for row in range(8):
                    for col in range(6):
                        px,py=x+col,y+row
                        if not (0<=px<width and clip[0]<=px<=clip[2] and clip[1]<=py<=clip[3]):continue
                        ink=bool(or_rows[row]&(0x80>>col))
                        keep=bool(and_rows[row]&(0x80>>col))
                        value=(lambda old,s=ink:old!=s) if op else (
                            lambda old,s=ink,k=keep,c=color:bool(c) if s else old if k else not c)
                        pixel(expected,ppb,px,py,value)
                check(machine,expected,(mode,'masked text',trial,color,op,background))
            print(f'{width}x200: 96 vertical, 96 opaque span, 36 text clip, 64 masked font cases passed')


if __name__ == '__main__':
    main()
