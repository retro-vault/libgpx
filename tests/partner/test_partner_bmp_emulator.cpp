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

    if (!run_partner_ihx("build/partner-tests/test_partner_bmp.ihx", mmu, base, top)) {
        std::cerr << "[fail] run_partner_ihx failed\n";
        return 1;
    }

    std::vector<uint8_t> screen = partner_screen_snapshot(mmu, width, height);
    int failures = 0;

    // Raster glyph is unsupported on Partner and must be ignored.
    check(!pixel_on(screen, 10, 5, width, height), "raster bmp should be ignored (10,5)", failures);
    check(!pixel_on(screen, 13, 5, width, height), "raster bmp should be ignored (13,5)", failures);
    check(!pixel_on(screen, 14, 6, width, height), "raster bmp should be ignored (14,6)", failures);
    check(!pixel_on(screen, 17, 6, width, height), "raster bmp should be ignored (17,6)", failures);
    check(!pixel_on(screen, 10, 7, width, height), "raster bmp should be ignored (10,7)", failures);

    // Tiny clipped move glyph checks (no-origin tiny payload + back/erase move).
    check(pixel_on(screen, 20, 20, width, height), "tiny point 20,20 missing", failures);
    check(pixel_on(screen, 22, 20, width, height), "tiny point 22,20 missing", failures);
    check(pixel_on(screen, 23, 20, width, height), "tiny point 23,20 missing", failures);
    check(pixel_on(screen, 23, 21, width, height), "tiny point 23,21 missing", failures);
    check(!pixel_on(screen, 21, 20, width, height), "tiny erased point 21,20 still on", failures);
    check(!pixel_on(screen, 23, 22, width, height), "tiny erased point 23,22 still on", failures);

    // Tiny with large clip (relative clip preparation + 0x20 tiny signature).
    check(pixel_on(screen, 40, 30, width, height), "tiny-large point 40,30 missing", failures);
    check(pixel_on(screen, 42, 30, width, height), "tiny-large point 42,30 missing", failures);
    check(pixel_on(screen, 43, 30, width, height), "tiny-large point 43,30 missing", failures);
    check(pixel_on(screen, 43, 31, width, height), "tiny-large point 43,31 missing", failures);
    check(!pixel_on(screen, 41, 30, width, height), "tiny-large erased point 41,30 still on", failures);
    check(!pixel_on(screen, 43, 32, width, height), "tiny-large erased point 43,32 still on", failures);

    if (failures == 0) {
        std::cout << "Partner bmp emulator test passed.\n";
        return 0;
    }

    std::cerr << failures << " partner bmp checks failed.\n";
    return 1;
}
