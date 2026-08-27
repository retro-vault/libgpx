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

/* Every pattern is applied literally, one bit per pixel, LSB first from the
   line's start -- the same rule the ZX backend uses. The EF9367 can dot and
   dash a vector itself, but its CTRL2 styles are fixed shapes that do not
   match the lpatt byte that would select them, so the backend no longer uses
   them and there is only this one semantics to test. */

uint8_t rot_r8(uint8_t v)
{
    return (uint8_t)((v >> 1) | (uint8_t)(v << 7));
}

bool fallback_on(uint8_t lpatt, int step)
{
    uint8_t v = lpatt;
    for (int i = 0; i < step; ++i)
        v = rot_r8(v);
    return (v & 1) != 0;
}

void check_hline_pattern(
    const std::vector<uint8_t> &screen,
    int x0,
    int y,
    int len,
    uint8_t lpatt,
    int width,
    int height,
    int &failures,
    const std::string &label)
{
    for (int i = 0; i < len; ++i) {
        bool expected = fallback_on(lpatt, i);
        bool on = pixel_on(screen, x0 + i, y, width, height);
        check(on == expected, label, failures);
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

    if (!run_partner_ihx("build/partner-tests/test_partner_line.ihx", mmu, base, top)) {
        std::cerr << "[fail] run_partner_ihx failed\n";
        return 1;
    }

    std::vector<uint8_t> screen = partner_screen_snapshot(mmu, width, height);
    int failures = 0;

    for (int x = 2; x <= 20; ++x)
        check(pixel_on(screen, x, 2, width, height), "solid line pixel missing", failures);

    check(!pixel_on(screen, 5, 5, width, height), "clipped line leaked outside clip", failures);
    for (int p = 10; p <= 20; ++p)
        check(pixel_on(screen, p, p, width, height), "clipped diagonal pixel missing", failures);

    const bool expectedA5[8] = {true, false, true, false, false, true, false, true};
    for (int i = 0; i < 8; ++i) {
        bool on = pixel_on(screen, 40 + i, 10, width, height);
        check(on == expectedA5[i], "fallback pattern mismatch", failures);
    }

    /* 0xF0 taken LSB-first from x=60: four clear, then four set. */
    for (int x = 60; x <= 63; ++x)
        check(!pixel_on(screen, x, 10, width, height), "0xF0 low nibble should be clear", failures);
    for (int x = 64; x <= 67; ++x)
        check(pixel_on(screen, x, 10, width, height), "0xF0 high nibble should be set", failures);

    for (int x = 100; x <= 500; ++x)
        check(pixel_on(screen, x, 50, width, height), "long recursive solid line pixel missing", failures);

    for (int x = 50; x <= 400; ++x)
        check(pixel_on(screen, x, 80, width, height), "long clipped recursive line pixel missing", failures);
    check(!pixel_on(screen, 49, 80, width, height), "long clipped line leaked at left edge", failures);
    check(!pixel_on(screen, 401, 80, width, height), "long clipped line leaked at right edge", failures);

    check_hline_pattern(screen, 10, 100, 16, 0xFF, width, height, failures, "pattern solid mismatch");
    check_hline_pattern(screen, 10, 101, 16, 0x33, width, height, failures, "pattern 0x33 mismatch");
    check_hline_pattern(screen, 10, 102, 16, 0x66, width, height, failures, "pattern 0x66 mismatch");
    check_hline_pattern(screen, 10, 103, 16, 0xCC, width, height, failures, "pattern 0xCC mismatch");
    check_hline_pattern(screen, 10, 104, 16, 0x99, width, height, failures, "pattern 0x99 mismatch");
    check_hline_pattern(screen, 10, 105, 16, 0xAA, width, height, failures, "pattern 0xAA mismatch");
    check_hline_pattern(screen, 10, 106, 16, 0x55, width, height, failures, "pattern 0x55 mismatch");
    check_hline_pattern(screen, 10, 107, 16, 0xF0, width, height, failures, "pattern 0xF0 mismatch");
    check_hline_pattern(screen, 10, 108, 16, 0x3C, width, height, failures, "pattern 0x3C mismatch");
    check_hline_pattern(screen, 10, 109, 16, 0xE4, width, height, failures, "pattern 0xE4 mismatch");
    check_hline_pattern(screen, 10, 110, 16, 0x72, width, height, failures, "pattern 0x72 mismatch");
    check_hline_pattern(screen, 10, 111, 16, 0xA5, width, height, failures, "pattern 0xA5 mismatch");

    if (failures == 0) {
        std::cout << "Partner line emulator test passed.\n";
        return 0;
    }

    std::cerr << failures << " partner emulator checks failed.\n";
    return 1;
}
