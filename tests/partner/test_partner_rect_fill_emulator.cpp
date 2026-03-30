#include <iostream>
#include <string>
#include <vector>

#include "emulator.hpp"

namespace {

bool pixel_on(const std::vector<uint8_t> &screen, int x, int y, int width, int height)
{
    if (x < 0 || y < 0 || x >= width || y >= height)
        return false;
    uint32_t offset = partner_screen_offset(x, y, width);
    uint8_t mask = (uint8_t)(0x80 >> (x & 7));
    return (screen[offset] & mask) != 0;
}

void check(bool condition, const std::string &message, int &failures)
{
    if (!condition) {
        ++failures;
        std::cerr << "[fail] " << message << "\n";
    }
}

} // namespace

int main()
{
    const int width = 1024;
    const int height = 256;

    MMU mmu;
    unsigned short base = 0;
    unsigned short top = 0;

    if (!run_partner_ihx("build/partner-tests/test_partner_rect_fill.ihx", mmu, base, top)) {
        std::cerr << "[fail] run_partner_ihx failed\n";
        return 1;
    }

    std::vector<uint8_t> screen = partner_screen_snapshot(mmu, width, height);
    int failures = 0;

    // Dotted rectangle top/bottom (2 on, 2 off) and solid sides.
    check(pixel_on(screen, 8, 6, width, height), "rect0 top x8 missing", failures);
    check(pixel_on(screen, 9, 6, width, height), "rect0 top x9 missing", failures);
    check(!pixel_on(screen, 10, 6, width, height), "rect0 top x10 should be off", failures);
    check(!pixel_on(screen, 11, 6, width, height), "rect0 top x11 should be off", failures);
    check(pixel_on(screen, 12, 6, width, height), "rect0 top x12 missing", failures);
    check(pixel_on(screen, 13, 6, width, height), "rect0 top x13 missing", failures);
    check(!pixel_on(screen, 14, 6, width, height), "rect0 top x14 should be off", failures);
    check(!pixel_on(screen, 15, 6, width, height), "rect0 top x15 should be off", failures);

    check(pixel_on(screen, 8, 12, width, height), "rect0 bottom x8 missing", failures);
    check(pixel_on(screen, 9, 12, width, height), "rect0 bottom x9 missing", failures);
    check(!pixel_on(screen, 10, 12, width, height), "rect0 bottom x10 should be off", failures);
    check(!pixel_on(screen, 11, 12, width, height), "rect0 bottom x11 should be off", failures);
    check(pixel_on(screen, 12, 12, width, height), "rect0 bottom x12 missing", failures);
    check(pixel_on(screen, 13, 12, width, height), "rect0 bottom x13 missing", failures);
    check(!pixel_on(screen, 14, 12, width, height), "rect0 bottom x14 should be off", failures);
    check(!pixel_on(screen, 15, 12, width, height), "rect0 bottom x15 should be off", failures);
    for (int y = 7; y <= 11; ++y) {
        check(pixel_on(screen, 8, y, width, height), "rect0 left side missing", failures);
        check(pixel_on(screen, 15, y, width, height), "rect0 right side missing", failures);
    }

    // Clipped solid rectangle: only clipped top edge and clipped right side survive.
    for (int x = 20; x <= 30; ++x)
        check(pixel_on(screen, x, 4, width, height), "rect1 clipped top missing", failures);
    for (int y = 5; y <= 12; ++y)
        check(pixel_on(screen, 30, y, width, height), "rect1 clipped right side missing", failures);
    check(!pixel_on(screen, 19, 4, width, height), "rect1 leaked left of clip", failures);
    check(!pixel_on(screen, 30, 13, width, height), "rect1 leaked below clip", failures);
    check(!pixel_on(screen, 18, 10, width, height), "rect1 unclipped left side drawn", failures);

    // Unclipped fill with fpatt={0x96,0x3A}, rendered through horizontal line fallback.
    check(!pixel_on(screen, 30, 20, width, height), "fill0 row0 x0 should be off", failures);
    check(pixel_on(screen, 31, 20, width, height), "fill0 row0 x1 should be on", failures);
    check(pixel_on(screen, 32, 20, width, height), "fill0 row0 x2 should be on", failures);
    check(!pixel_on(screen, 33, 20, width, height), "fill0 row0 x3 should be off", failures);

    check(!pixel_on(screen, 30, 21, width, height), "fill0 row1 x0 should be off", failures);
    check(pixel_on(screen, 31, 21, width, height), "fill0 row1 x1 should be on", failures);
    check(!pixel_on(screen, 32, 21, width, height), "fill0 row1 x2 should be off", failures);
    check(pixel_on(screen, 33, 21, width, height), "fill0 row1 x3 should be on", failures);

    // Clipped fill: verify x/y phase rotation after pre-clipping.
    check(!pixel_on(screen, 53, 32, width, height), "fill1 row0 x0 phase mismatch", failures);
    check(pixel_on(screen, 54, 32, width, height), "fill1 row0 x1 phase mismatch", failures);
    check(!pixel_on(screen, 55, 32, width, height), "fill1 row0 x2 phase mismatch", failures);
    check(!pixel_on(screen, 56, 32, width, height), "fill1 row0 x3 phase mismatch", failures);
    check(pixel_on(screen, 57, 32, width, height), "fill1 row0 x4 phase mismatch", failures);

    check(pixel_on(screen, 53, 33, width, height), "fill1 row1 x0 phase mismatch", failures);
    check(pixel_on(screen, 54, 33, width, height), "fill1 row1 x1 phase mismatch", failures);
    check(pixel_on(screen, 55, 33, width, height), "fill1 row1 x2 phase mismatch", failures);
    check(!pixel_on(screen, 56, 33, width, height), "fill1 row1 x3 phase mismatch", failures);
    check(!pixel_on(screen, 57, 33, width, height), "fill1 row1 x4 phase mismatch", failures);

    check(!pixel_on(screen, 52, 32, width, height), "fill1 leaked left of clip", failures);
    check(!pixel_on(screen, 53, 31, width, height), "fill1 leaked above clip", failures);

    // Large unclipped fill (fr2): verify repeating 4-row pattern over a wider area.
    check(!pixel_on(screen, 120, 40, width, height), "fill2 row0 x0 should be off", failures);
    check(pixel_on(screen, 121, 40, width, height), "fill2 row0 x1 should be on", failures);
    check(pixel_on(screen, 122, 40, width, height), "fill2 row0 x2 should be on", failures);
    check(!pixel_on(screen, 123, 40, width, height), "fill2 row0 x3 should be off", failures);
    check(pixel_on(screen, 124, 40, width, height), "fill2 row0 x4 should be on", failures);
    check(pixel_on(screen, 319, 40, width, height), "fill2 row0 right edge-1 should be on", failures);
    check(!pixel_on(screen, 320, 40, width, height), "fill2 row0 right edge should be off", failures);

    check(!pixel_on(screen, 120, 41, width, height), "fill2 row1 x0 should be off", failures);
    check(pixel_on(screen, 121, 41, width, height), "fill2 row1 x1 should be on", failures);
    check(!pixel_on(screen, 122, 41, width, height), "fill2 row1 x2 should be off", failures);
    check(pixel_on(screen, 123, 41, width, height), "fill2 row1 x3 should be on", failures);
    check(pixel_on(screen, 124, 41, width, height), "fill2 row1 x4 should be on", failures);

    check(!pixel_on(screen, 119, 40, width, height), "fill2 leaked left", failures);
    check(!pixel_on(screen, 321, 40, width, height), "fill2 leaked right", failures);
    check(!pixel_on(screen, 200, 39, width, height), "fill2 leaked above", failures);

    // Large clipped fill (fr3): verify x/y phase after clipping on a wide span.
    check(!pixel_on(screen, 350, 120, width, height), "fill3 row0 x0 phase mismatch", failures);
    check(pixel_on(screen, 351, 120, width, height), "fill3 row0 x1 phase mismatch", failures);
    check(!pixel_on(screen, 352, 120, width, height), "fill3 row0 x2 phase mismatch", failures);
    check(pixel_on(screen, 353, 120, width, height), "fill3 row0 x3 phase mismatch", failures);
    check(pixel_on(screen, 354, 120, width, height), "fill3 row0 x4 phase mismatch", failures);

    check(pixel_on(screen, 350, 121, width, height), "fill3 row1 x0 phase mismatch", failures);
    check(!pixel_on(screen, 351, 121, width, height), "fill3 row1 x1 phase mismatch", failures);
    check(pixel_on(screen, 352, 121, width, height), "fill3 row1 x2 phase mismatch", failures);
    check(!pixel_on(screen, 353, 121, width, height), "fill3 row1 x3 phase mismatch", failures);

    check(pixel_on(screen, 350, 122, width, height), "fill3 row2 x0 phase mismatch", failures);
    check(!pixel_on(screen, 351, 122, width, height), "fill3 row2 x1 phase mismatch", failures);
    check(!pixel_on(screen, 352, 122, width, height), "fill3 row2 x2 phase mismatch", failures);
    check(pixel_on(screen, 353, 122, width, height), "fill3 row2 x3 phase mismatch", failures);

    check(pixel_on(screen, 759, 120, width, height), "fill3 far right x-1 mismatch", failures);
    check(!pixel_on(screen, 760, 120, width, height), "fill3 far right edge mismatch", failures);
    check(pixel_on(screen, 351, 210, width, height), "fill3 bottom row phase mismatch", failures);

    check(!pixel_on(screen, 349, 120, width, height), "fill3 leaked left of clip", failures);
    check(!pixel_on(screen, 761, 120, width, height), "fill3 leaked right of clip", failures);
    check(!pixel_on(screen, 500, 119, width, height), "fill3 leaked above clip", failures);
    check(!pixel_on(screen, 500, 211, width, height), "fill3 leaked below clip", failures);

    if (failures == 0) {
        std::cout << "Partner rectangle/fill emulator test passed.\n";
        return 0;
    }

    std::cerr << failures << " partner rectangle/fill checks failed.\n";
    return 1;
}
