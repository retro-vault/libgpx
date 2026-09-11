/* Single-page 1920x1080 1bpp mmap framebuffer shared with Rasta.
 * The viewer and application must use the same file and geometry.
 * GPL2 License (see: LICENSE), Copyright (C) 2026 tomaz stih. */
#define _POSIX_C_SOURCE 200809L
#include "rasta_internal.h"

#include <errno.h>
#include <fcntl.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>

static gpx_t context;
static uint8_t *framebuffer;

gpx_t *gpx_create(gmode mode)
{
    const char *path = getenv("GPX_RASTA_FRAMEBUFFER");
    int fd;
    int saved_errno;
    void *mapping;

    (void)mode;
    if (framebuffer) {
        errno = EBUSY;
        return NULL;
    }
    if (!path || !*path)
        path = "/tmp/rasta.framebuffer";
    fd = open(path, O_RDWR | O_CREAT, 0600);
    if (fd < 0)
        return NULL;
    if (ftruncate(fd, (off_t)RASTA_SIZE) != 0) {
        saved_errno = errno;
        close(fd);
        errno = saved_errno;
        return NULL;
    }
    mapping = mmap(NULL, RASTA_SIZE, PROT_READ | PROT_WRITE,
        MAP_SHARED, fd, 0);
    saved_errno = errno;
    close(fd);
    if (mapping == MAP_FAILED) {
        errno = saved_errno;
        return NULL;
    }
    framebuffer = (uint8_t *)mapping;
    context.width = RASTA_WIDTH;
    context.height = RASTA_HEIGHT;
    context.pages = 1;
    context.text_background = GPX_TEXT_BG_OPAQUE;
    gpx_clrscr();
    return &context;
}

void gpx_destroy(gpx_t *gpx)
{
    if (gpx == &context && framebuffer) {
        munmap(framebuffer, RASTA_SIZE);
        framebuffer = NULL;
    }
}

void gpx_set_text_background(gpx_t *gpx, textbg background)
{
    if (gpx)
        gpx->text_background = background & 1;
}

void gpx_set_page(uint8_t op, uint8_t page)
{
    /* One shared display/write page, just like the Spectrum backend. */
    (void)op;
    (void)page;
}

dim gpx_width(void) { return RASTA_WIDTH; }
dim gpx_height(void) { return RASTA_HEIGHT; }

void gpx_clrscr(void)
{
    if (framebuffer)
        memset(framebuffer, 0, RASTA_SIZE);
}

void rasta_pixel(gpx_t *gpx, int32_t x, int32_t y,
    color c, bmode m, const rect_t *clip)
{
    size_t offset;
    uint8_t mask;
    (void)gpx;
    if (!framebuffer || x < 0 || x >= RASTA_WIDTH ||
        y < 0 || y >= RASTA_HEIGHT)
        return;
    if (clip && (x < clip->x0 || x > clip->x1 ||
        y < clip->y0 || y > clip->y1))
        return;
    offset = (size_t)y * RASTA_STRIDE + (size_t)x / 8;
    mask = (uint8_t)(0x80u >> (x & 7));
    if (m == BM_XOR)
        framebuffer[offset] ^= mask;
    else if (c & 1)
        framebuffer[offset] |= mask;
    else
        framebuffer[offset] &= (uint8_t)~mask;
}

int rasta_get_pixel(int32_t x, int32_t y)
{
    if (!framebuffer || x < 0 || x >= RASTA_WIDTH ||
        y < 0 || y >= RASTA_HEIGHT)
        return 0;
    return (framebuffer[(size_t)y * RASTA_STRIDE + (size_t)x / 8] &
        (0x80u >> (x & 7))) != 0;
}

void gpx_draw_pixel(gpx_t *gpx, coord x, coord y,
    color c, bmode m, const rect_t *clip)
{
    rasta_pixel(gpx, x, y, c, m, clip);
}

void rasta_pattern_span(gpx_t *gpx, int32_t x0, int32_t x1, int32_t y,
    int32_t origin_x, uint8_t pattern, color c, bmode m,
    const rect_t *clip)
{
    if (y < 0 || y >= RASTA_HEIGHT)
        return;
    if (clip) {
        if (y < clip->y0 || y > clip->y1)
            return;
        if (x0 < clip->x0) x0 = clip->x0;
        if (x1 > clip->x1) x1 = clip->x1;
    }
    if (x0 < 0) x0 = 0;
    if (x1 >= RASTA_WIDTH) x1 = RASTA_WIDTH - 1;
    for (; x0 <= x1; ++x0) {
        uint8_t bit = (uint8_t)(
            pattern & (0x80u >> ((uint32_t)(x0 - origin_x) & 7)));
        if (m == BM_CPY)
            rasta_pixel(gpx, x0, y,
                bit ? c : (color)((c ^ 1u) & 1u), BM_CPY, NULL);
        else if (bit)
            rasta_pixel(gpx, x0, y, c, m, NULL);
    }
}
