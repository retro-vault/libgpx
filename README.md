![status.badge] ![language.badge] [![compiler.badge]][compiler.url] 

# libgpx

Welcome to **libgpx**, a multiplatform graphics library for 8bit micros. 

# Compiling libgpx

Run the `make` command with platform name as target in the root directory.

 > Supported platforms are `zxspec48` and `partner` and are 
 > case sensitive!

~~~
make PLATFORM=partner
~~~

After the compilation object and debug files are available in the `build` directory, and the `libgpx.lib` is copied to the `bin` directory. 

# Using libgpx

## Tiny coding convention

(...to be continued...)

## Dependencies

*libgpx* has been designed as an independent library. It incudes 
`stdbool.h`, and `stdint.h`, but uses its' own implementations.

## Initializing

To initialize the library, call `gpx_init()` function. This function returns a pointer to the `gpx_t` structure, which you pass to all other functions of the *libgpx*.

After you're done with using the library, you should call the `gpx_exit()`. On some platform this call just deletes the `gpx_t` structure. On others it switches from grapics back to text mode.

~~~cpp
#include <gpx.h>

void main() {
    gpt_t* g=gpx_init();
    /* your drawing code here */
    gpx_exit(g);
}
~~~

## Querying platform graphics capabilities

If you would like to know what the gpx library can do on your platform, you can call `gpx_cap().` This function will query platform graphics capabilities (resolution, no. of pages, black and white color, etc.). This function will return pointer to `gpx_cap_t`.

~~~cpp
#include <gpx.h>
#include <stdio.h>

void main() {
    /* enter gpx mode */
    gpx_t *g=gpx_init();

    /* query graphics capabilities */
    gpx_cap_t *cap=gpx_cap(g);
    printf("GRAPHICS PROPERTIES\n\n");
    printf("No. colors %d\nBack color %d\nFore color %d\n",
        cap->num_colors,
        cap->back_color,
        cap->fore_color);
    printf("Sup. pages %d\n", cap->num_pages);
    /* enum. pages */
    for(int p=0; p<cap->num_pages; p++)
        /* enum resolutions (for page) */
        for (int r=0; r<cap->pages[p].num_resolutions; r++)
            printf(" P%d Resol. %dx%d\n",
                p,
                cap->pages[p].resolutions[r].width,
                cap->pages[p].resolutions[r].height);
    
    /* leave gpx mode */
    gpx_exit(NULL);
}
~~~

And the result on ZX Spectrum 48K.

![ZX Spectrum 48K gpx_cap()](docs/img/zxspec48-gpx_cap.png)

## Page switching

If the platform supports multiple pages use `gpx_get_page()` to 
get current page and `gpx_set_page()` to switch to desired page. 

 > It is possible to set current **display page** and current
 > **write page**. The display page is the currently shown page,
 > and the write page is the target page for all drawing. 

You can use a combination of bitmask flags `PG_WRITE` and `PG_DISPLAY` 
to set the page.

~~~cpp
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

#include "partner.h"

#include <gpx.h>

int main() {

    /* enter gpx mode */
    gpx_t *g=gpx_init();
    if (g==NULL) {
        printf("Can't enter graphics mode.\n");
        return 1;
    }

    /* clear screen */
    gpx_cls(g);

    /* animation using page switching. */
    gpx_set_page(g,1,PG_WRITE);
    rect_t pg1rect={100,100,200,200};
    gpx_fill_rect(g,&pg1rect);
    
    rect_t pg0rect={300,300,400,400};
    gpx_set_page(g,0,PG_WRITE);
    gpx_fill_rect(g,&pg0rect);


    /* switch pages 100 times */
    for(int i=0;i<100;i++)
        gpx_set_page(g,i%2,PG_DISPLAY);

    /* leave gpx mode */
    gpx_exit(NULL);

    return 0;
}
~~~

## Colors

The library at present only supports monochrome graphics, but its interface is prepared for color displays. You can set the color by calling `gpx_set_color()`, passing the `color` and color flags. Flags are used because on some systems you can set background and foreground color (for example: paper and ink on ZX Spectrum).

You can obtain black and white colors and number of supported colors by calling the `gpx_query_cap()`.

## Rectangles

Rectangle type `rect_t` has four coordinates: `x0`,`y0`,`x1` and `y1`. Operations that consume rectangles always include border. Hence, a rectangle with same coordinates is a line or a pixel. Following core rectangle arithmetic functions are provided with the library.

~~~cpp
/* does rectangle contains point? */
extern bool gpx_rect_contains(rect_t *r, coord x, coord y);

/* do rectangles overlap? */
extern bool gpx_rect_overlap(rect_t *a, rect_t *b);

/* intersection of rectangles */
extern rect_t* gpx_rect_intersect(rect_t *a, rect_t *b, rect_t *intersect);

/* normalize rect coordinates i.e. ie from left top to right bottom */
extern void gpx_rect_norm(rect_t *r);
~~~

## Clipping

You can set a rectangular clipping region for all drawing. The clipping region is of type `rect_t` and is set by calling `gpx_set_clip_area()`. Passing `NULL` sets entire screen as the clipping region (=no clipping).

 > After the call to `gpx_init`, the defautl clipping area is entire screen.

~~~cpp
/* set clip. rectangle to 0, 0, 99, 99*/
rect_t ul_area={0, 0, 99, 99};
gpx_set_clip_area(g,&ul_area);
/* after this call all drawing operations outside the clip 
   rectangle will be invisible */
~~~

## Blit mode

Operations such as drawing lines, use blit mode. At present three blit 
modes are supported: `BLT_NONE`, `BLT_XOR` and `BLT_COPY`. You can set the blit mode using function `gpx_set_blit()` and read it by `gpx_get_blit()`.

> Mode `BM_NONE` is a dummy mode and disables all drawing operations.

~~~cpp
/* set XOR drawing mode for all drawing operations. */
gpx_set_blit(g,BLT_XOR);
~~~

## Styles

### Line styles

Call `gpx_set_line_style()` to pass a 1 byte line pattern. Line styles are applied to all draw fuinctions: lines, rectangles, circles, and polygons. But not to glyphs. 

You can use predefined line patterns or custom line patterns. If you use a predefined pattern the drawing
might get hardware accelerated. 

The predefined (well known) line style constants:
 * LS_SOLID    11111111
 * LS_DOTTED   10101010
 * LS_DASHED   11001100

~~~cpp
uint8_t shft_dashed_style=0x33;     /* 00110011 */
gpx_set_line_style(g,shft_dashed_style);
~~~

### Fill brushes

Call the `gpx_set_fill_brush()` to pass a min. 1 to max 8 byte fill pattern. Fill pattern will be applied to all fill functions: rectangles, circles and polygons. But not to glyphs.

 > Fills are implemented by scan line drawing. Each line is assigned one byte from the fill pattern as its'
 > line style. If all bytes in fill are well known line styles, then fill might be accelerated.

~~~cpp
/* fill circle with cross pattern */
uint8_t cross[8] = {
    0x81, 0x42, 0x24, 0x18, /* internals: each byte is line style */
    0x18, 0x24, 0x42, 0x81
};
gpx_set_fill_brush(g,8,cross);
gpx_fill_circle(g,550,300,100);
~~~

## Resolution

You can obtain resolution indexes by calling `gpx_get_cap()` and iterating through the `gpx_page_t[] pages` member. Each page has a `gpx_resolution_t[] resolutions` member, which contains resolutions.

By convention the resolutions are ordered from lowest to highest.

 > On some platforem `libgpx` emulates lower resolutions (for example - 
 > gpx emulates 512x256 on Iskra Delta Partner). 

Resolution is also set per page, so make sure you set it for all pages you are using.

~~~cpp
#include <gpx.h>

void main() {
    /* enter gpx mode */
    gpx_t *g=gpx_init();
    /* set screen resolution */
    gpx_set_resolution(g,0);
    /* exit gpx mode */
    gpx_exit(g);
}
~~~

## Clearing the screen

Use `gpx_cls()` to clear screen. Clear screen will respect 
current back color, and fore color. 

 > This function will, due to some hardware limitations, ignore current page settings 
 > and always clear the display page.

~~~cpp
#include <gpx.h>

void main() {
    /* enter gpx mode */
    gpx_t *g=gpx_init();
    /* clear screen */
    gpx_cls();
    /* exit gpx mode */
    gpx_exit(g);
}
~~~

## Drawing!

All drawing functions start with `gpx_draw_` and all fill functions start with `gpx_fill_`. They only accept coordinate arguments, because all other aspects of drawing (color, blit mode, clipping) is set by a separate function and stored in the `gpx_t` structure.

Following functions are available.
 * `gpx_draw_line()` ... draws a line
 * `gpx_draw_circle()` ... draws a circle 
 * `gpx_draw_rect()` ... draws a rectangle
 * `gpx_fill_rect()` ... draws a filled rectangle

 > All functions are optimized. For example - when drawing a line,
 > horizontal line is detected and drawn using super- speeed function.

~~~cpp
#include <gpx.h>

void main() {

    /* enter graphics */
    gpx_t *g=gpx_init();

    /* clear screen */
    gpx_cls(g);

    /* query graphics capabilities
       NOTE: this is only possible because initial page
             and initial resolution are both 0. */
    gpx_cap_t *cap=gpx_cap(g);
    coord centerx = cap->pages[0].resolutions[0].width/2;
    coord centery = cap->pages[0].resolutions[0].height/2;

    printf("Center is at %d,%d\n",centerx, centery);

    /* draw line */
    for (coord x=centerx-20; x<centerx+20;x++)
        gpx_draw_pixel(g,x,centery);

    /* draw circle */
    gpx_draw_circle(g,centerx,centery,20);

    /* leave graphics */
    gpx_exit(NULL);
}
~~~

And the result on ZX Spectrum 48K.

![ZX Spectrum 48K drawing](docs/img/zxspec48-gpx_draw1.png)

## Glyphs

The glyph is a basic building block of bitmapped graphics. Several classes 
of glyph are supported, each having a minimal header, just enough to draw 
the glyph. Each glyph type has its own optimal drawing function. 

### Glyph classes

Each glyph has a 4 byte glyph header. First three bits of the first byte tell the glyph class.

Following glyph classes are supported.

| Name      | Class | Description                                |
|-----------|-------|--------------------------------------------|
| Raster    |  000  | Encoded as standard 1bpp raster            |
| Tiny      |  001  | Encoded as Partners' relative movements    |
| Lines     |  010  | Encoded as lines (scanlines or outline)    |
| RLE bit   |  011  | Encoded as bit RLE graphics                |
| RLE byte  |  100  | Encoded as byte RLE graphics               |

The rest of the 4 byte structure depends on glyph class.

![glyph_t structure](docs/img/glyph_t.png)

### Glyph format limits

The `*glyph_t` structure immposes some reasonable limits for a glyph. 
All glyhps except the *RLE* are limited to 256x256. *RLE* has
two extra bits for width and height, limiting its size to
1024x1024. *RLE* also does not need size information, because the number
of rows equals to height, and each individual row has information about 
its size. *Tiny* glyph can have max. 256 moves, and *line* glyph can 
have max. of 4096 lines.

 > For obvious reasons, glyph type *Tiny*, which contains direct 
 > commands for *Iskra Delta Partner GDP* is not supported on other
 > platforms.

### LINES format

The lines format uses two subsequent bytes of data as relative x,y
coordinates of point from -127 to 127. A value of -128 is the escape sequence and is followed by a command.

Here's an example.

`12, 15, 30, 40, 20, 20, -128, 0, 17, 13, 20, 28`

first stroke is

`line from 12, 15 to 30, 40`
`line from 30, 40 to 20, 20`

escape sequence `-128` followed by command `0` means "line break" i.e.end of stroke. Next stroke is

`line from 17,13 to 20,20`

Following are available commands

| Code (bin)     | Command                       |
|:--------------:|-------------------------------|
|  0000 00 0 0   | End of current stroke.        |
|  0000 xx 0 0   | Reserved                      |
|  0000 00 1 0   | End of stroke, no color       | 
|  0000 01 1 0   | End of stroke, set fore color | 
|  0000 10 1 0   | End of stroke, set back color |
|  0000 11 1 0   | Reserved                      |
|  0000 00 1 1   | Set color to transparent      |
|  0000 01 1 1   | Set fore color                |
|  0000 10 1 1   | Set back color                |
|  0000 11 1 1   | Reserved                      |

 > Bit 0 tells if the stroke continues (=1) or ends (=0). Bit 1 tells if pen changes. Bits 3 and 4 tell the new pen. Top nibble is reserved for more commands.

### RLE format

RLE is an encoding for glyphs, optimized for fast drawing. You might've 
read about RLE "compression", which is based on wriing bytes that releat
with a byte value and a counter. 

In *libgpx* we talk about encoding, because the focus is not on compression,
but on faster drawing.

RLE format in libgpx can be aligned on a byyte or a bit boundary. 

#### Byte aligned RLE 

Byte aligned RLE rewrites repeating bytes with byte value and a counter. If the value does not repeat it is not compressed. For example value `ABCDE` would not change. But if the value repeats multiple times, then it is escaped by repeating it twice and the third byte is number of repetitions. For example the value `AAAAAAB` would be compressed into `AA6B`.

Byte aligned RLE is useful for raster optimization and can actually achieve compression.

#### Bit aligned RLE

Bit or pixel aligned RLE breaks down image to vector operations. 
Let's examine how this is done on following scan- line example, 
encoded as a pattern of bits: 1 for pixel set and 0 for background.

`10001111 11100111 11111111 11111111 11111111 01010101`

To encode this pattern we'll need recognize fast drawing line styles inside
this glyph. We can see that this line can be written as:

`1 000 1111111 00 111111111111111111111111111 01010101`

We recognize three line styles: `11111111`, `00000000` and `01010101`. So we can encode this this as follows:

11111111(1)
00000000(3)
11111111(7)
00000000(2)
11111111(27)
01010101(8)

The first number is the line style and second number is line length.

 > I'm putting "compression" in quotes because this is not really a compression, 
 > but a way to speed up drawing by using vectors. Instead of 48 pixels, we draw
 > 6 lines. On a vector display this leads to much better pefrormance. 

## Array of glyphs: the envelope approach

Glyphs can be combined into more complex bitmapped structures, such as 
fonts, animations, bitmaps, icons, or mouse mouse cursors. All of these 
structures are arrays (or envelopes) containing basic glyphs. By using 
the envelope approach one can create an animation or a font, made out 
of any glyph types.

 > The tradeoff of this approach is that each glyph array (such as
 > a font) is a bit larger, because collective properties, such as
 > font height are stored with each glyph. But it also results in 
 > smaller and faster code, required to manage graphics.

![Various envelopes](docs/img/envelopes.png)

### Glyph drawing functions

Here are four main glyph drawing functions.

 * `gpx_draw_glyph()` ... draws a glyph
 * `gpx_draw_mglyph()` ... draws a masked glyph
 * `gpx_read_glyph()` ... read a bitmap from screen

## Fonts

Fonts are implemented using the glyph group of drawing functions, because each letter is just a glyph, with some extra drawing hints. 

To use font you need to load it (unless already part of your C code). Each font starts with the `font_t` structure where you can find some basic font information such as average width, height, number of characters, etc.

You then simply call `gpx_draw_string()` to draw a sting. 

 > Don't forget that fonts also use the *blit mode*, and if it is not `BM_COPY`, background may not be deleted.

## Font header

The font header structure contains basic information about the font and a table of pointers to each
glyph. This way glyphs can have different sizes (i.e. in proportional fonts, the letter i takes much
less memory space than the letter w) and we avoid expensive calculations to find each glyph.

Because each glyph contains its width, it also makes it easy for us to measure strings by simply
iterating through all the glyphs in the string, and maxing the height and summing the width.

### Measuring text

Use `gpx_measure_string()` to measure string. 

(...to be continued...)

# Supported platforms

## Iskra Delta Partner

![Iskra Delta Partner](docs/img/partner.jpg) 

| Trait                     | Value     |
|---------------------------|----------:|
| Processor                 | Z80, 4Mhz |
| Graphics type             | Vector    |
| Native resolution         | 1024x512  |
| Colors                    | 2         |
| Page(s)                   | 2         |
| *libgpx* size in bytes    | N/A       |
| Implementation internals  | [Available](PARTNER.md) |

---

## ZX Spectrum 48K

![ZX Spectrum 48K](docs/img/zxspec48.jpg)

| Trait                     | Value     |
|---------------------------|----------:|
| Processor                 | Z80, 4Mhz |
| Graphics type             | Raster    |
| Native resolution         | 256x192   |
| Colors                    | 15        |
| Page(s)                   | 1         |
| *libgpx* size in bytes    | N/A       |
| Implementation internals  | [Available](ZXSPEC48.md) |

---

## Pixie Linux Vector Display Emulator

![Pixie](docs/img/zxspec48.jpg)

| Trait                     | Value     |
|---------------------------|----------:|
| Processor                 | Any Linux |
| Graphics type             | Vector    |
| Native resolution         | Custom    |
| Colors                    | 256       |
| Page(s)                   | Custom    |
| *libgpx* size in bytes    | N/A       |
| Implementation internals  | [Available](http://github.com/tstih/pixie) |

[language.badge]: https://img.shields.io/badge/languages-c11%2C%20z80%20assembly-blue.svg

[compiler.url]:   http://sdcc.sourceforge.net/
[compiler.badge]: https://img.shields.io/badge/compiler-sdcc-blue.svg

[status.badge]:  https://img.shields.io/badge/status-development-red.svg
