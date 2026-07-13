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
    check(pixel_on(screen, 6, 0, width, height), "stock bitmap marker missing", failures);
    check(pixel_on(screen, 7, 0, width, height), "set_page(PG_WRITE,1) marker missing", failures);
    check(pixel_on(screen, 8, 0, width, height), "set_page(PG_DISPLAY,0) marker missing", failures);
    check(pixel_on(screen, 9, 0, width, height), "set_page(PG_DISPLAY|PG_WRITE,0) marker missing", failures);
    check(pixel_on(screen, 10, 0, width, height), "overall pass marker missing", failures);

    check(pixel_on(screen, 10, 400, width, height), "mode1 y>255 pixel missing", failures);

    check(any_pixel_in_rect(screen, 20, 20, 31, 35, width, height),
        "draw_text produced no pixels in expected area", failures);

    /* XOR sprite: region B (show+hide over backdrop at y=190) must equal
     * region C (pure backdrop at y=230) pixel for pixel; region A
     * (lasting sprite at y=150) must differ from C somewhere. */
    {
        int identity_bad = 0;
        bool shown_differs = false;
        for (int k = -10; k <= 26; ++k) {
            for (int x = 780; x <= 870; ++x) {
                bool a = pixel_on(screen, x, 150 + k, width, height);
                bool b = pixel_on(screen, x, 190 + k, width, height);
                bool c = pixel_on(screen, x, 230 + k, width, height);
                if (b != c)
                    ++identity_bad;
                if (a != c)
                    shown_differs = true;
            }
        }
        check(identity_bad == 0,
            "XOR sprite show+hide must restore the screen", failures);
        check(shown_differs,
            "XOR sprite show must change pixels", failures);
    }

    /* window-clipped sprite column: D (lasting, clip {905,140,920,158})
     * vs F (pure backdrop); E (show+hide under clip) must equal F. */
    {
        int identity_bad = 0;
        int outside_bad = 0;
        bool clipped_differs = false;
        for (int k = -10; k <= 26; ++k) {
            for (int x = 890; x <= 950; ++x) {
                bool d = pixel_on(screen, x, 150 + k, width, height);
                bool e = pixel_on(screen, x, 190 + k, width, height);
                bool f = pixel_on(screen, x, 230 + k, width, height);
                if (e != f)
                    ++identity_bad;
                if (d != f) {
                    clipped_differs = true;
                    bool inside = x >= 905 && x <= 920 &&
                                  (150 + k) >= 140 && (150 + k) <= 158;
                    if (!inside)
                        ++outside_bad;
                }
            }
        }
        check(identity_bad == 0,
            "clipped XOR sprite show+hide must restore the screen", failures);
        check(clipped_differs,
            "clipped sprite must draw inside its window", failures);
        check(outside_bad == 0,
            "clipped sprite must not draw outside its window", failures);
    }

    if (failures == 0) {
        std::cout << "Partner API emulator test passed.\n";
        return 0;
    }

    std::cerr << failures << " partner API checks failed.\n";
    return 1;
}
