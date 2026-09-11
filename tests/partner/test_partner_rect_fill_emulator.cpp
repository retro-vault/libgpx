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

/* Box patterns advance clockwise over each unique outline pixel: top,
   right, bottom in reverse, then left in reverse. */
void check_box(const std::vector<uint8_t> &screen,
               int x0, int y0, int x1, int y1, uint8_t pattern,
               int width, int height, int &failures, const char *label)
{
    int phase = 0;
    auto check_pixel = [&](int x, int y) {
        bool expected = ((pattern >> (phase & 7)) & 1) != 0;
        check(pixel_on(screen, x, y, width, height) == expected,
              label, failures);
        ++phase;
    };

    for (int x = x0; x <= x1; ++x)
        check_pixel(x, y0);
    for (int y = y0 + 1; y <= y1; ++y)
        check_pixel(x1, y);
    for (int x = x1 - 1; x >= x0; --x)
        check_pixel(x, y1);
    for (int y = y1 - 1; y > y0; --y)
        check_pixel(x0, y);
}

/* A fill takes its pattern MSB-first from the rectangle's own left edge, and
   its row from the rectangle's own top edge -- both measured on the
   unclipped rectangle, so clipping never shifts the pattern. Same rule as
   the ZX backend. Checking every pixel of the visible span states that rule
   directly instead of transcribing a handful of expected pixels. */
void check_fill(const std::vector<uint8_t> &screen,
                int rx0, int ry0, int rx1, int ry1,
                const int *clip,
                const uint8_t *fpatt, int len,
                int width, int height, int &failures, const char *label,
                bool invert = false)
{
    int vx0 = rx0, vy0 = ry0, vx1 = rx1, vy1 = ry1;
    if (clip) {
        if (clip[0] > vx0) vx0 = clip[0];
        if (clip[1] > vy0) vy0 = clip[1];
        if (clip[2] < vx1) vx1 = clip[2];
        if (clip[3] < vy1) vy1 = clip[3];
    }
    for (int y = vy0; y <= vy1; ++y) {
        uint8_t p = fpatt[(y - ry0) % len];
        for (int x = vx0; x <= vx1; ++x) {
            bool expected = ((p >> (7 - ((x - rx0) & 7))) & 1) != 0;
            expected = expected != invert;
            check(pixel_on(screen, x, y, width, height) == expected,
                  label, failures);
        }
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

    check_box(screen, 8, 6, 15, 12, 0x33,
              width, height, failures, "rect0 continuous pattern mismatch");

    // Clipped solid rectangle: only clipped top edge and clipped right side survive.
    for (int x = 20; x <= 30; ++x)
        check(pixel_on(screen, x, 4, width, height), "rect1 clipped top missing", failures);
    for (int y = 5; y <= 12; ++y)
        check(pixel_on(screen, 30, y, width, height), "rect1 clipped right side missing", failures);
    check(!pixel_on(screen, 19, 4, width, height), "rect1 leaked left of clip", failures);
    check(!pixel_on(screen, 30, 13, width, height), "rect1 leaked below clip", failures);
    check(!pixel_on(screen, 18, 10, width, height), "rect1 unclipped left side drawn", failures);

    static const uint8_t fp0[2] = {0x96, 0x3A};
    static const uint8_t fp2[4] = {0x96, 0x3A, 0xC5, 0x69};
    static const uint8_t fp3[3] = {0x96, 0xA5, 0x69};
    static const int fr1_clip[4] = {53, 32, 57, 34};
    static const int fr3_clip[4] = {350, 120, 760, 210};

    check_fill(screen, 30, 20, 38, 24, nullptr, fp0, 2,
               width, height, failures, "fill0 mismatch");
    check_fill(screen, 50, 30, 57, 34, fr1_clip, fp0, 2,
               width, height, failures, "fill1 mismatch");
    check_fill(screen, 120, 40, 320, 190, nullptr, fp2, 4,
               width, height, failures, "fill2 mismatch");
    check_fill(screen, 300, 100, 900, 240, fr3_clip, fp3, 3,
               width, height, failures, "fill3 mismatch");

    static const uint8_t checker[2] = {0x55, 0xAA};
    check_fill(screen, 20, 60, 83, 75, nullptr, checker, 2,
               width, height, failures, "opaque COPY fill mismatch");
    static const uint8_t alternating[1] = {0xAA};
    check_fill(screen, 20, 78, 83, 93, nullptr, alternating, 1,
               width, height, failures,
               "CO_BACK alternating COPY fill mismatch", true);
    static const uint8_t or_result[1] = {0x44};
    check_fill(screen, 20, 96, 83, 111, nullptr, or_result, 1,
               width, height, failures, "BM_OR fill mismatch");

    /* Nothing may escape a clip window or a rectangle's own bounds. */
    check(!pixel_on(screen, 52, 32, width, height), "fill1 leaked left of clip", failures);
    check(!pixel_on(screen, 53, 31, width, height), "fill1 leaked above clip", failures);
    check(!pixel_on(screen, 119, 40, width, height), "fill2 leaked left", failures);
    check(!pixel_on(screen, 321, 40, width, height), "fill2 leaked right", failures);
    check(!pixel_on(screen, 200, 39, width, height), "fill2 leaked above", failures);
    check(!pixel_on(screen, 349, 150, width, height), "fill3 leaked left of clip", failures);
    check(!pixel_on(screen, 761, 150, width, height), "fill3 leaked right of clip", failures);
    check(!pixel_on(screen, 500, 119, width, height), "fill3 leaked above clip", failures);
    check(!pixel_on(screen, 500, 211, width, height), "fill3 leaked below clip", failures);

    if (failures == 0) {
        std::cout << "Partner rectangle/fill emulator test passed.\n";
        return 0;
    }

    std::cerr << failures << " partner rectangle/fill checks failed.\n";
    return 1;
}
