# libgpx

Welcome to **libgpx**, a multiplatform graphics library for 8bit micros. 

# Compiling libgpx

# Supported platforms

ZX Spectrum, Iskra Delta Partner.

# Using libgpx

## Tiny coding convention

(...to be continued...)

## Initializing

To initialize the library, call `gpx_init()` function. This function returns a pointer to the `gpx_t` structure, which you pass to all other functions of the *libgpx*.

After you're done with using the library, you should call the `gpx_exit()`. On some platform this call just deletes the `gpx_t` structure. On others it switches from grapics back to text mode.

~~~cpp
#include <gpx.h>

void main() {
    gpt_x* g=gpx_init();
    /* your drawing code here */
    gpx_exit(g);
}
~~~

## Querying platform graphics capabilities

If you would like to know what the gpx library can do on your platform, you can call `gpx_query_cap().` This function will query platform graphics capabilities (resolution, no. of pages, black and white color, etc.). This function will return pointer to `gpx_cap_t`.

## Page switching

If the platform supports multiple pages you can call `gpx_get_page()` and `gpx_set_page()` to switch pages. Both calls also contain `flags` member which tell whether you'd just like to redirect graphical writes to page (but not switch) or switch to a page.

Once you set the page, all operations will go to that page.

## Colors

The library at present only supports monochrome graphics, but its interface is prepared for color displays. You can set the color by calling `gpx_set_color()`, passing the `color_t` and color flags. Flags are used because on some systems you can set background and foreground color (for example: paper and ink on ZX Spectrum).

You can obtain black and white colors and number of supported colors by calling the `gpx_query_cap()`.

## Clipping

You can set a rectangular clipping region for all drawing. The clipping region is of type `rect_t` and is set by calling `gpx_set_clip()`. Passing `NULL` sets entire screen as the clipping region (=no clipping).

## Blit mode

Operations such as drawing lines, use blit mode. At present two blit modes are supported: `BM_XOR` and `BP_COPY`. You can set the blit mode using function `gpx_set_blit()` and read it by `gpx_get_blit()`.

## Patterns

### Line pattern

Call `set_line_pattern()` to pass a 1 byte line pattern. You can use predefined line patterns or custom line patterns. If you use a predefined pattern it might get hardware accelerated. 

The predefined patterns are:
 * LP_SOLID    11111111
 * LP_DOTTED   10101010
 * LP_DASHED   11001100

### Fill pattern

Call the `set_fill_pattern()` to pass a min. 1 to max 8 byte fill pattern.

## Resolution

You can obtain resolution indexes by calling `gpx_get_cap()` and iterating through the `gpx_page_t[] pages` member. Each page has a `gpx_resolution_t[] resolutions` member, which contains resolutions.

By convention the resolutions are ordered from lowest to highest.

 > On some platforem `libgpx` emulates lower resolutions (for example - 
 > gpx emulates 512x256 on Iskra Delta Partner). 

Resolution is also set per page, so make sure you set it for all pages you are using.

## Drawing!

All drawing functions start with `gpx_draw_` and all fill functions start with `gpx_fill_`. They only accept coordinate arguments, because all other aspects of drawing (color, blit mode, clipping) is set by a separate function and stored in the `gpx_t` structure.

Following functions are available.
 * `gpx_draw_line()` ... draws a line
 * `gpx_draw_rect()` ... draws a rectangle
 * `gpx_fill_rect()` ... draws a filled rectangle
 * `gpx_draw_glyph()` ... draws a bitmap
 * `gpx_draw_mglyph()` ... draws a masked bitmap
 * `gpx_read_glyph()` ... read a bitmap from screen

 > All functions are optimized. For example - when drawing a line,
 > horizontal line is detected and drawn using super- speeed function.

## Fonts

Fonts are implemented using the glyph group of drawing functions, because each letter is just a bitmap, with some extra drawing hints. 

(...to be continued...)