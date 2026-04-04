/*
 * libgpx.h
 *
 * Low-level 1-bit-per-pixel (1bpp) graphics primitives.  Defines
 * the platform-independent drawing API: pixels, lines, rectangles,
 * circles, polygons, and bitmaps.  Each platform supplies its own
 * gpx.c that implements these against its native framebuffer.
 *
 * NOTES: All drawing functions accept an optional clip rectangle.
 * Pass NULL to disable clipping.  Colors are 1bpp values: CO_FORE
 * sets a pixel, CO_BACK clears it.  BM_XOR inverts the existing
 * pixel regardless of the color argument.
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
/* Known encoding ids (signature high nibble). */
#define BMP_ENC_1BPP            0x0 /* 0000: standard 1bpp */
#define BMP_ENC_1BPP_MASK       0x1 /* 0001: masked 1bpp (AND/OR) */
#define BMP_ENC_TINY            0x2 /* 0010: tiny move-stream bitmap */

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

/* Font header flags (byte 0). */
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

/* Draw text at (x, y) in desktop coordinates. */
extern void gpx_draw_text(
    gpx_t *gpx, coord x, coord y,
    const char *text, const font_t *font,
    color c, bmode m, const rect_t *clip);

/* Graphics context — tracks framebuffer geometry.
 * The actual framebuffer pointer is managed by the platform. */
struct gpx_s
{
    dim width;       /* Display width in pixels. */
    dim height;      /* Display height in pixels. */
    uint8_t pages;   /* Number of framebuffer pages available. */
};

/* Graphics initialisation mode. */
#define GPXM_DEFAULT 0
typedef uint8_t gmode;

/* Initialise the platform graphics subsystem and return a gpx_t. */
extern gpx_t *gpx_create(gmode mode);

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
 * lpatt is an 8-bit dash pattern (0xFF = solid).
 * Returns the rotated pattern byte at the point where the line stopped,
 * so callers can chain patterns seamlessly across multiple segments.
 * Clipped to clip if non-NULL. */
extern uint8_t gpx_draw_line(
    gpx_t *gpx, coord x0, coord y0, coord x1, coord y1,
    color c, bmode m, uint8_t lpatt, const rect_t *clip);

/* Blit a packed 1bpp bitmap at (x, y).
 * Pixels set to 1 are drawn in CO_FORE; zero pixels are skipped.
 * Clipped to clip if non-NULL. */
extern void gpx_draw_bmp(
    gpx_t *gpx, coord x, coord y,
    bmp_t *b, const rect_t *clip);

/* Draw the outline of rectangle r with line pattern lpatt. */
extern void gpx_draw_rectangle(
    gpx_t *gpx, rect_t *r,
    color c, bmode m, uint8_t lpatt, const rect_t *clip);

/* Fill rectangle r using repeating fill pattern fpatt[fpatt_len].
 * Pattern bytes are applied row-by-row; fpatt_len must be >= 1. */
extern void gpx_fill_rectangle(
    gpx_t *gpx, rect_t *r,
    color c, bmode m,
    uint8_t *fpatt, uint8_t fpatt_len, const rect_t *clip);

#endif /* __LIBGPX_H__ */
