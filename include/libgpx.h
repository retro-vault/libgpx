/*
 * libgpx.h
 *
 * Low-level 1-bit-per-pixel (1bpp) graphics primitives.  Defines
 * the platform-independent drawing API: pixels, lines, rectangles,
 * text, bitmaps and sprites.  Every function declared here is
 * implemented by each backend under src/ in hand-written Z80
 * assembly -- against a packed framebuffer on the ZX Spectrum, and
 * against the EF9367 drawing processor on the Iskra Delta Partner,
 * whose display memory the CPU cannot read at all.
 *
 * NOTES: All drawing functions accept an optional clip rectangle.
 * Pass NULL to disable clipping.  Colors are 1bpp values: CO_FORE
 * sets a pixel, CO_BACK clears it.  BM_XOR inverts the existing pixel
 * regardless of the color argument.
 *
 * The backends are held to identical behaviour, so a program built on
 * this API draws the same picture on either machine.  Two differences
 * are unavoidable and expected.  Bitmap and font payloads are per
 * platform -- the ZX takes rasters, the Partner takes vector move
 * streams -- so glyphs and sprite artwork differ by design.  And the
 * interior pixels of a slanted solid line differ by about one pixel,
 * because the Partner hands those to the EF9367's own vector
 * generator; endpoints, clipping and every line pattern still match
 * exactly.  tests/conformance checks all of this.
 *
 * Line patterns (lpatt) are applied one bit per pixel, LSB first from
 * the line's start, and gpx_draw_line returns the pattern rotated by
 * however many pixels it drew so segments can be chained.  Clipping
 * does not shift the phase: a clipped line lights the same pixels it
 * would have if the whole line had been drawn and the outside part
 * simply not shown.  Fill patterns (fpatt) instead run MSB first from
 * the rectangle's own left edge, one byte per row from its top edge,
 * both measured before clipping.
 *
 * GPL2 License (see: LICENSE)
 * copyright (c) 2026 tomaz stih
 *
 * tstih
 */
#ifndef __LIBGPX_H__
#define __LIBGPX_H__

#include <stdint.h>
#include <stdlib.h>

/* Screen coordinate (signed 16-bit). */
typedef int16_t coord;

/* Colors in a 1bpp world. */
#define CO_FORE 0x01 /* set pixel bit */
#define CO_BACK 0x00 /* clear pixel bit */
typedef uint8_t color;

/* Blit mode: copy or XOR. */
#define BM_CPY 0x00 /* set bit to whatever is in the mask */
#define BM_XOR 0x01 /* xor with existing framebuffer content */
typedef uint8_t bmode;

/* Text cell background policy. Opaque text paints glyph boxes and spacing
 * in the inverse text color; transparent text draws glyph ink only. */
#define GPX_TEXT_BG_OPAQUE      0x00
#define GPX_TEXT_BG_TRANSPARENT 0x01
typedef uint8_t textbg;

/* 2-D point in screen coordinates. */
typedef struct point_s
{
    coord x;
    coord y;
} point_t;

/* Screen dimension (unsigned 16-bit). */
typedef uint16_t dim;

/* Axis-aligned rectangle (inclusive corners). */
typedef struct rect_s
{
    coord x0;
    coord y0;
    coord x1;
    coord y1;
} rect_t;

/* Bitmap signature byte:
 * bits 7..4 = encoding
 * bits 3..0 = stride encoding (stored as stride-1, valid range 0..15 => stride 1..16). */
/* Known encoding ids (signature high nibble).
 * Not every backend decodes every encoding: the ZX backend handles the
 * two 1bpp forms, the Partner backend the two tiny move-stream forms. */
#define BMP_ENC_1BPP            0x0 /* 0000: standard 1bpp */
#define BMP_ENC_1BPP_MASK       0x1 /* 0001: masked 1bpp (AND/OR) */
#define BMP_ENC_TINY            0x2 /* 0010: tiny move-stream bitmap */
#define BMP_ENC_TINY_MASK       0x3 /* 0011: tiny move-stream, with mask strokes */

/* Helpers for signature byte handling. */
#define BMP_SIG(enc) ((uint8_t)(((enc) & 0x0F) << 4)) /* default stride=1 */
#define BMP_ENC(sig) ((uint8_t)(((sig) >> 4) & 0x0F))
#define BMP_STRIDE_ENC(stride) ((uint8_t)(((stride) - 1) & 0x0F))
#define BMP_STRIDE(sig) ((uint8_t)(((sig) & 0x0F) + 1))
#define BMP_SIG_STRIDE(enc, stride) \
    ((uint8_t)(BMP_SIG(enc) | BMP_STRIDE_ENC(stride)))

/* Backward-compatibility alias: standard 1bpp signature. */
#define S_BMP BMP_SIG(BMP_ENC_1BPP)

/* Packed 1bpp bitmap (single on-wire header format). */
typedef struct bmp_s
{
    uint8_t signature; /* Signature byte: encoding in high nibble. */
    uint8_t w;         /* Width in pixels. */
    uint8_t h;         /* Height in pixels. */
    uint16_t size;     /* Total bitmap data size in bytes. */
    uint8_t bitmap[];  /* Payload per encoding (MSB-first bits). */
} bmp_t;

/* Optional trailer convention:
 * For masked bitmaps (BMP_ENC_1BPP_MASK), two trailing bytes may follow payload:
 *   bitmap[size + 0] = hotspot x
 *   bitmap[size + 1] = hotspot y
 * This is used by cursor assets; generic blitters may ignore it. */

/* Forward declaration for APIs that take gpx_t* before full struct definition. */
typedef struct gpx_s gpx_t;

/* Sprite background storage is always a standard 1bpp bitmap with a
 * fixed 2-byte stride and room for the worst-case 16x16 capture. */
#define GPX_SPRITE_BG_HEADER_SIZE  5
#define GPX_SPRITE_BG_PAYLOAD_SIZE 32
#define GPX_SPRITE_BG_SIZE         (GPX_SPRITE_BG_HEADER_SIZE + GPX_SPRITE_BG_PAYLOAD_SIZE)

/* Save-under sprite descriptor. The bitmap pointer is the source image;
 * the background pointer must reference writable storage of at least
 * GPX_SPRITE_BG_SIZE bytes (unused on vector platforms, may be NULL).
 * clip is an optional window rect: the sprite renders only inside it
 * (NULL = whole screen). Show and hide both read it from the descriptor
 * so they use the same window; keep it unchanged between the two calls.
 * ZX captures/restores the full background box regardless, so hide also
 * heals pixels the clip suppressed. */
typedef struct sprite_s
{
    coord x;
    coord y;
    bmp_t *bitmap;
    bmp_t *background;
    const rect_t *clip;
} sprite_t;

/* Font header flags (byte 0). Only FONT_FLAG_OFFSETS_BE changes how the
 * backends read a font; the other two describe the asset for tools and
 * are not branched on at render time, so clearing PROPORTIONAL does not
 * select a fixed-width path. */
#define FONT_FLAG_PROPORTIONAL 0x01 /* Variable-width glyphs. */
#define FONT_FLAG_OFFSETS_BE 0x02 /* Offset table uses big-endian uint16_t. */
#define FONT_FLAG_VECTOR 0x04 /* 1=vector font, 0=bitmap font. */

/* Serialized font format:
 * [0] flags
 * [1] first ASCII
 * [2] last ASCII
 * [3] empty width
 * [4] max glyph width
 * [5] glyph height
 * [6] advance
 * [7] descent
 * [8..] glyph offset table + serialized bmp_t glyph payloads. */
typedef struct font_s
{
    uint8_t flags;
    uint8_t first_ascii;
    uint8_t last_ascii;
    uint8_t empty_width;
    uint8_t max_glyph_width;
    uint8_t glyph_height;
    uint8_t advance;
    uint8_t descent;
    uint8_t data[];
} font_t;

/* Return platform default UI font (menus, controls, text). */
extern const font_t *gpx_get_system_font(void);

/* Return platform tiny font (icons/small labels). */
extern const font_t *gpx_get_tiny_font(void);

/* Stock bitmap identifiers.
 * The returned data format is platform-specific. */
#define GPXSB_CURSOR_CLASSIC   0
#define GPXSB_CURSOR_STD       1
#define GPXSB_CURSOR_HOURGLASS 2
#define GPXSB_CURSOR_CARET     3
#define GPXSB_CURSOR_HAND      4

/* Return a pointer to a platform stock bitmap/glyph by id.
 * Returns NULL if the id is not supported on the active platform. */
extern bmp_t *gpx_get_stock_bmp(const uint8_t which);

/* Measure text width in pixels for a serialized font. */
extern coord gpx_measure_text(const char *text, const font_t *font);

/* Draw text at (x, y) in desktop coordinates. The context's
 * text_background policy applies to glyph boxes, missing glyph cells,
 * and the advance between adjacent characters. */
extern void gpx_draw_text(
    gpx_t *gpx, coord x, coord y,
    const char *text, const font_t *font,
    color c, bmode m, const rect_t *clip);

/* Graphics context — tracks framebuffer geometry.
 * The actual framebuffer pointer is managed by the platform. */
struct gpx_s
{
    dim width;               /* Display width in pixels. */
    dim height;              /* Display height in pixels. */
    uint8_t pages;           /* Number of framebuffer pages available. */
    textbg text_background;  /* Opaque or transparent text cells. */
};

/* Graphics initialisation mode. Mode numbers beyond the default are
 * platform-specific: the Partner takes 1 for its 1024x512 layout, and
 * the ZX Spectrum has one fixed mode and ignores the argument. Read
 * the geometry back from the returned gpx_t rather than assuming it. */
#define GPXM_DEFAULT 0
/* Amstrad CPC display modes. One library serves both: the mode is chosen
 * here, at gpx_create() time, and gpx_width() reports it afterwards.
 * Backends with a single layout accept these and ignore them. */
#define GPXM_CPC_640X200 0
#define GPXM_CPC_320X200 1
typedef uint8_t gmode;

/* Initialise the platform graphics subsystem and return a gpx_t. */
extern gpx_t *gpx_create(gmode mode);

/* Select whether text clears its cell background or leaves it transparent. */
extern void gpx_set_text_background(gpx_t *gpx, textbg background);

/* Tear down the graphics subsystem and free the gpx_t. */
extern void gpx_destroy(gpx_t *gpx);

/* Page-selection operation flags for gpx_set_page(). */
#define PG_DISPLAY 0x01
#define PG_WRITE   0x02

/* Set active display and/or write page when the platform supports paging.
 * op may combine PG_DISPLAY and PG_WRITE; page is usually 0 or 1. */
extern void gpx_set_page(uint8_t op, uint8_t page);

/* Return the current display width in pixels. */
extern dim gpx_width(void);

/* Return the current display height in pixels. */
extern dim gpx_height(void);

/* Clear the active framebuffer/screen. */
extern void gpx_clrscr(void);

/* Plot a single pixel at (x, y) with color c and blit mode m.
 * Clipped to clip if non-NULL. */
extern void gpx_draw_pixel(
    gpx_t *gpx, coord x, coord y,
    color c, bmode m, const rect_t *clip);

/* Draw a line from (x0,y0) to (x1,y1) using Bresenham's algorithm.
 * lpatt is an 8-bit dash pattern (0xFF = solid), applied one bit per
 * pixel LSB-first from (x0,y0).
 * Returns the rotated pattern byte at the point where the line stopped,
 * so callers can chain patterns seamlessly across multiple segments.
 * Clipped to clip if non-NULL. */
extern uint8_t gpx_draw_line(
    gpx_t *gpx, coord x0, coord y0, coord x1, coord y1,
    color c, bmode m, uint8_t lpatt, const rect_t *clip);

/* Blit a bitmap at (x, y), in whichever encoding its signature names.
 * For the 1bpp forms, pixels set to 1 are drawn in CO_FORE and zero
 * pixels are skipped; the tiny forms carry their own per-stroke color.
 * Clipped to clip if non-NULL. */
extern void gpx_draw_bmp(
    gpx_t *gpx, coord x, coord y,
    bmp_t *b, const rect_t *clip);

/* Show a sprite at sprite->x, sprite->y. The sprite origin must already be
 * on-screen; only right/bottom clipping is applied. */
extern void gpx_show_sprite(gpx_t *gpx, sprite_t *sprite);

/* Restore the background currently stored in sprite->background at
 * sprite->x, sprite->y. */
extern void gpx_hide_sprite(gpx_t *gpx, sprite_t *sprite);

/* Draw the outline of rectangle r with line pattern lpatt. */
extern void gpx_draw_rectangle(
    gpx_t *gpx, rect_t *r,
    color c, bmode m, uint8_t lpatt, const rect_t *clip);

/* Fill rectangle r using repeating fill pattern fpatt[fpatt_len].
 * One byte per row from r's top edge, applied MSB-first from r's left
 * edge; both are measured on the unclipped rectangle, so clipping never
 * shifts the pattern. fpatt_len must be >= 1. */
extern void gpx_fill_rectangle(
    gpx_t *gpx, rect_t *r,
    color c, bmode m,
    uint8_t *fpatt, uint8_t fpatt_len, const rect_t *clip);

#endif /* __LIBGPX_H__ */
