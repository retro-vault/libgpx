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

enum PatternMode
{
    PM_SOLID = 0,
    PM_DOTTED = 1,
    PM_DASHED = 2,
    PM_DOT_DASH = 3,
    PM_FALLBACK = 4
};

bool style_on(PatternMode mode, int step)
{
    switch (mode) {
    case PM_SOLID:
        return true;
    case PM_DOTTED:
        return (step & 0x03) < 2;
    case PM_DASHED:
        return (step & 0x07) < 4;
    default: {
        int p = step & 0x0F;
        return p < 10 || (p >= 12 && p < 14);
    }
    }
}

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
    PatternMode mode,
    uint8_t lpatt,
    int width,
    int height,
    int &failures,
    const std::string &label)
{
    for (int i = 0; i < len; ++i) {
        bool expected = (mode == PM_FALLBACK) ? fallback_on(lpatt, i) : style_on(mode, i);
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

    for (int x = 60; x <= 63; ++x)
        check(pixel_on(screen, x, 10, width, height), "dashed line on-segment missing", failures);
    for (int x = 64; x <= 67; ++x)
        check(!pixel_on(screen, x, 10, width, height), "dashed line off-segment drawn", failures);

    for (int x = 100; x <= 500; ++x)
        check(pixel_on(screen, x, 50, width, height), "long recursive solid line pixel missing", failures);

    for (int x = 50; x <= 400; ++x)
        check(pixel_on(screen, x, 80, width, height), "long clipped recursive line pixel missing", failures);
    check(!pixel_on(screen, 49, 80, width, height), "long clipped line leaked at left edge", failures);
    check(!pixel_on(screen, 401, 80, width, height), "long clipped line leaked at right edge", failures);

    check_hline_pattern(screen, 10, 100, 16, PM_SOLID, 0xFF, width, height, failures, "pattern solid mismatch");
    check_hline_pattern(screen, 10, 101, 16, PM_DOTTED, 0x33, width, height, failures, "pattern 0x33 mismatch");
    check_hline_pattern(screen, 10, 102, 16, PM_DOTTED, 0x66, width, height, failures, "pattern 0x66 mismatch");
    check_hline_pattern(screen, 10, 103, 16, PM_DOTTED, 0xCC, width, height, failures, "pattern 0xCC mismatch");
    check_hline_pattern(screen, 10, 104, 16, PM_DOTTED, 0x99, width, height, failures, "pattern 0x99 mismatch");
    check_hline_pattern(screen, 10, 105, 16, PM_DOTTED, 0xAA, width, height, failures, "pattern 0xAA mismatch");
    check_hline_pattern(screen, 10, 106, 16, PM_DOTTED, 0x55, width, height, failures, "pattern 0x55 mismatch");
    check_hline_pattern(screen, 10, 107, 16, PM_DASHED, 0xF0, width, height, failures, "pattern 0xF0 mismatch");
    check_hline_pattern(screen, 10, 108, 16, PM_DASHED, 0x3C, width, height, failures, "pattern 0x3C mismatch");
    check_hline_pattern(screen, 10, 109, 16, PM_DOT_DASH, 0xE4, width, height, failures, "pattern 0xE4 mismatch");
    check_hline_pattern(screen, 10, 110, 16, PM_DOT_DASH, 0x72, width, height, failures, "pattern 0x72 mismatch");
    check_hline_pattern(screen, 10, 111, 16, PM_FALLBACK, 0xA5, width, height, failures, "pattern 0xA5 mismatch");

    if (failures == 0) {
        std::cout << "Partner line emulator test passed.\n";
        return 0;
    }

    std::cerr << failures << " partner emulator checks failed.\n";
    return 1;
}
