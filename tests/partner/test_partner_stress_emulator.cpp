#include <iostream>
#include <string>
#include <vector>

#include "emulator.hpp"

namespace {

static constexpr int kWidth = 1024;
static constexpr int kHeight = 512;

bool pixel_on(const std::vector<uint8_t> &screen, int x, int y)
{
    if (x < 0 || y < 0 || x >= kWidth || y >= kHeight)
        return false;
    uint32_t offset = partner_screen_offset(x, y, kWidth);
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

void require_on(const std::vector<uint8_t> &screen, int x, int y, const std::string &label, int &failures)
{
    check(pixel_on(screen, x, y), label, failures);
}

void require_off(const std::vector<uint8_t> &screen, int x, int y, const std::string &label, int &failures)
{
    check(!pixel_on(screen, x, y), label, failures);
}

int count_on_rect(const std::vector<uint8_t> &screen, int x0, int y0, int x1, int y1)
{
    int count = 0;
    if (x0 > x1)
        std::swap(x0, x1);
    if (y0 > y1)
        std::swap(y0, y1);
    x0 = std::max(0, x0);
    y0 = std::max(0, y0);
    x1 = std::min(kWidth - 1, x1);
    y1 = std::min(kHeight - 1, y1);
    for (int y = y0; y <= y1; ++y) {
        for (int x = x0; x <= x1; ++x) {
            if (pixel_on(screen, x, y))
                ++count;
        }
    }
    return count;
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

} // namespace

int main()
{
    MMU mmu;
    unsigned short base = 0;
    unsigned short top = 0;

    if (!run_partner_ihx("build/partner-tests/test_partner_stress.ihx", mmu, base, top)) {
        std::cerr << "[fail] run_partner_ihx failed\n";
        return 1;
    }

    std::vector<uint8_t> screen = partner_screen_snapshot(mmu, kWidth, kHeight);
    int failures = 0;

    check(mmu.partner_fb_height == 512, "mode 1 height not set", failures);

    require_on(screen, 0, 0, "marker (0,0) missing", failures);
    require_off(screen, 1, 0, "xor marker (1,0) should be cleared", failures);
    require_on(screen, 3, 0, "clipped marker (3,0) missing", failures);
    require_off(screen, 4, 0, "clipped marker leak at (4,0)", failures);

    require_on(screen, 0, 100, "long recursive line start missing", failures);
    require_on(screen, 900, 450, "long recursive line end missing", failures);

    require_on(screen, 200, 10, "vertical line start missing", failures);
    require_on(screen, 200, 155, "vertical line middle missing", failures);
    require_on(screen, 200, 300, "vertical line end missing", failures);

    require_on(screen, 50, 250, "horizontal line start missing", failures);
    require_on(screen, 400, 250, "horizontal line middle missing", failures);
    require_on(screen, 700, 250, "horizontal line end missing", failures);

    require_on(screen, 500, 500, "degenerate point draw missing", failures);

    for (int x = 100; x <= 200; ++x)
        require_on(screen, x, 220, "left-clipped horizontal pixel missing", failures);
    require_off(screen, 99, 220, "left clip leaked one pixel", failures);

    for (int y = 100; y <= 200; ++y)
        require_on(screen, 210, y, "top-clipped vertical pixel missing", failures);
    check(pixel_on(screen, 210, 99) || pixel_on(screen, 210, 100), "top clip entry mismatch", failures);
    require_off(screen, 210, 95, "top clip leaked beyond boundary", failures);

    for (int x = 200; x <= 300; ++x)
        require_on(screen, x, 210, "right-clipped horizontal pixel missing", failures);
    require_off(screen, 301, 210, "right clip leaked one pixel", failures);

    for (int y = 200; y <= 300; ++y)
        require_on(screen, 220, y, "bottom-clipped vertical pixel missing", failures);
    require_off(screen, 220, 301, "bottom clip leaked one pixel", failures);

    require_off(screen, 900, 10, "fully rejected clipped line drew at start", failures);
    require_off(screen, 925, 15, "fully rejected clipped line drew in middle", failures);
    require_off(screen, 950, 20, "fully rejected clipped line drew at end", failures);

    for (int i = 0; i <= 100; ++i) {
        bool expected = fallback_on(0xA5, i);
        bool on = pixel_on(screen, 20 + i, 480);
        check(on == expected, "fallback lpatt 0xA5 mismatch", failures);
    }

    /* Every pattern is literal now -- the EF9367's own CTRL2 styles are not
       used, because their fixed shapes do not match the lpatt that would
       select them and the ZX backend would draw something else. */
    for (int i = 0; i <= 100; ++i) {
        check(pixel_on(screen, 20 + i, 481) == fallback_on(0x33, i), "lpatt 0x33 mismatch", failures);
        check(pixel_on(screen, 20 + i, 482) == fallback_on(0xF0, i), "lpatt 0xF0 mismatch", failures);
        check(pixel_on(screen, 20 + i, 483) == fallback_on(0xE4, i), "lpatt 0xE4 mismatch", failures);
    }

    require_on(screen, 260, 20, "normalized rectangle top-left missing", failures);
    require_off(screen, 262, 20, "normalized rectangle pattern expected off", failures);
    require_on(screen, 260, 21, "normalized rectangle left side missing", failures);
    require_on(screen, 300, 49, "normalized rectangle right side missing", failures);

    for (int y = 80; y <= 110; ++y) {
        require_on(screen, 350, y, "clipped rectangle left side missing", failures);
        require_on(screen, 420, y, "clipped rectangle right side missing", failures);
    }
    require_off(screen, 349, 80, "clipped rectangle leaked left", failures);
    require_off(screen, 421, 80, "clipped rectangle leaked right", failures);

    require_on(screen, 500, 60, "clipped fill first pixel missing", failures);
    require_off(screen, 504, 60, "clipped fill expected off pixel set", failures);
    require_off(screen, 499, 60, "clipped fill leaked left", failures);
    require_off(screen, 651, 60, "clipped fill leaked right", failures);

    require_on(screen, 710, 40, "solid fill top-left missing", failures);
    require_on(screen, 900, 100, "solid fill bottom-right missing", failures);
    require_off(screen, 925, 45, "null/zero-len fill should not draw", failures);

    require_off(screen, 50, 320, "raster bmp should be ignored (50,320)", failures);
    require_off(screen, 57, 320, "raster bmp should be ignored (57,320)", failures);
    require_off(screen, 52, 322, "masked raster bmp should be ignored (52,322)", failures);
    require_off(screen, 54, 323, "masked raster bmp should be ignored (54,323)", failures);
    require_off(screen, 58, 322, "masked raster bmp should remain off (58,322)", failures);

    require_on(screen, 100, 320, "tiny compact start missing", failures);
    check(count_on_rect(screen, 100, 320, 120, 330) > 3, "tiny compact draw too sparse", failures);
    require_off(screen, 102, 321, "tiny legacy clipped draw should be empty here", failures);

    check(count_on_rect(screen, 20, 350, 260, 365) > 100, "HELLO WORLD text too sparse", failures);
    check(count_on_rect(screen, 20, 370, 140, 390) > 20, "clipped text missing", failures);
    require_off(screen, 20, 369, "clipped text leaked above clip", failures);
    require_off(screen, 19, 375, "clipped text leaked left of clip", failures);

    if (failures == 0) {
        std::cout << "Partner stress emulator test passed.\n";
        return 0;
    }

    std::cerr << failures << " partner stress checks failed.\n";
    return 1;
}
