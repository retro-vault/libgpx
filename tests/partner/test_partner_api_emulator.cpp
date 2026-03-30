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

bool any_pixel_in_rect(
    const std::vector<uint8_t> &screen,
    int x0, int y0, int x1, int y1,
    int width, int height)
{
    for (int y = y0; y <= y1; ++y) {
        for (int x = x0; x <= x1; ++x) {
            if (pixel_on(screen, x, y, width, height))
                return true;
        }
    }
    return false;
}

} // namespace

int main()
{
    const int width = 1024;
    const int height = 512;

    MMU mmu;
    unsigned short base = 0;
    unsigned short top = 0;

    if (!run_partner_ihx("build/partner-tests/test_partner_api.ihx", mmu, base, top)) {
        std::cerr << "[fail] run_partner_ihx failed\n";
        return 1;
    }

    std::vector<uint8_t> screen = partner_screen_snapshot(mmu, width, height);
    int failures = 0;

    check(pixel_on(screen, 1, 0, width, height), "mode0 marker missing", failures);
    check(pixel_on(screen, 2, 0, width, height), "mode2 fallback marker missing", failures);
    check(pixel_on(screen, 3, 0, width, height), "mode1 marker missing", failures);
    check(pixel_on(screen, 4, 0, width, height), "font getter marker missing", failures);
    check(pixel_on(screen, 5, 0, width, height), "measure_text marker missing", failures);
    check(pixel_on(screen, 6, 0, width, height), "cursor map marker missing", failures);
    check(pixel_on(screen, 7, 0, width, height), "cursor_set(hand) marker missing", failures);
    check(pixel_on(screen, 8, 0, width, height), "cursor_set(bad) marker missing", failures);
    check(pixel_on(screen, 9, 0, width, height), "cursor_set(null) marker missing", failures);
    check(pixel_on(screen, 10, 0, width, height), "overall pass marker missing", failures);

    check(pixel_on(screen, 10, 400, width, height), "mode1 y>255 pixel missing", failures);

    check(any_pixel_in_rect(screen, 20, 20, 31, 35, width, height),
        "draw_text produced no pixels in expected area", failures);

    if (failures == 0) {
        std::cout << "Partner API emulator test passed.\n";
        return 0;
    }

    std::cerr << failures << " partner API checks failed.\n";
    return 1;
}
