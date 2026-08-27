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

/* A fill takes its pattern MSB-first from the rectangle's own left edge, and
   its row from the rectangle's own top edge -- both measured on the
   unclipped rectangle, so clipping never shifts the pattern. Same rule as
   the ZX backend. Checking every pixel of the visible span states that rule
   directly instead of transcribing a handful of expected pixels. */
void check_fill(const std::vector<uint8_t> &screen,
                int rx0, int ry0, int rx1, int ry1,
                const int *clip,
                const uint8_t *fpatt, int len,
                int width, int height, int &failures, const char *label)
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
