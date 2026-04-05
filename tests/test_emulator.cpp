#include <iostream>
#include <sstream>
#include <string>
#include <vector>
#include "emulator.hpp"
#include "zx/test-src/test_bitmaps.h"

int run_emulator_unit_tests();

struct packed_bmp_header_t
{
    uint8_t signature;
    uint8_t w;
    uint8_t h;
    uint16_t size;
} __attribute__((packed));

static bool in_clip(int x, int y, const rect_t *clip)
{
    if (x < 0 || x >= 256 || y < 0 || y >= 192)
        return false;
    if (clip) {
        if (x < clip->x0 || x > clip->x1 || y < clip->y0 || y > clip->y1)
            return false;
    }
    return true;
}

static void draw_expected_bmp_packed(
    std::vector<uint8_t> &expected,
    int x,
    int y,
    const uint8_t *raw,
    const rect_t *clip)
{
    const packed_bmp_header_t *header =
        reinterpret_cast<const packed_bmp_header_t *>(raw);
    const uint8_t *bitmap = raw + sizeof(packed_bmp_header_t);
    uint8_t stride = BMP_STRIDE(header->signature);
    for (coord row = 0; row < header->h; ++row) {
        uint16_t row_offset = (uint16_t)(row * stride);
        for (coord col = 0; col < header->w; ++col) {
            uint8_t byte = bitmap[row_offset + (col >> 3)];
            uint8_t mask = (uint8_t)(0x80 >> (col & 7));
            if (byte & mask) {
                int px = x + col;
                int py = y + row;
                if (in_clip(px, py, clip))
                    set_expected_pixel(expected, px, py);
            }
        }
    }
}

static bool compare_screen(
    const std::vector<uint8_t> &actual,
    const std::vector<uint8_t> &expected,
    std::string &message)
{
    if (actual.size() < 0x1800 || expected.size() < 0x1800) {
        message = "screen snapshot size mismatch";
        return false;
    }

    // Compare ZX bitmap area only (0x4000..0x57FF). Attribute bytes may
    // differ by backend defaults and are validated separately when needed.
    for (size_t i = 0; i < 0x1800; ++i) {
        if (actual[i] != expected[i]) {
            unsigned int addr = 0x4000 + (unsigned int)i;
            std::ostringstream ss;
            ss << "mismatch at 0x" << std::hex << addr
               << ": actual=0x" << std::hex << (int)actual[i]
               << " expected=0x" << std::hex << (int)expected[i];
            message = ss.str();
            return false;
        }
    }
    return true;
}

static std::vector<uint8_t> expected_clrscr()
{
    return std::vector<uint8_t>(0x1B00, 0);
}

static std::vector<uint8_t> expected_width_height()
{
    std::vector<uint8_t> expected(0x1B00, 0);
    set_expected_pixel(expected, 255, 191);
    return expected;
}

static std::vector<uint8_t> expected_draw_pixel()
{
    std::vector<uint8_t> expected(0x1B00, 0);
    set_expected_pixel(expected, 0, 0);
    set_expected_pixel(expected, 5, 5);
    set_expected_pixel(expected, 255, 191);
    return expected;
}

static std::vector<uint8_t> expected_draw_line()
{
    std::vector<uint8_t> expected(0x1B00, 0);
    draw_expected_line(expected, 0, 0, 7, 0, 0x81, nullptr);
    draw_expected_line(expected, 7, 2, 0, 2, 0x3C, nullptr);
    draw_expected_line(expected, 2, 3, 2, 9, 0xF0, nullptr);
    draw_expected_line(expected, 10, 5, 5, 10, 0xAA, nullptr);
    draw_expected_line(expected, 12, 12, 12, 12, 0x80, nullptr);
    return expected;
}

static std::vector<uint8_t> expected_draw_line_clip()
{
    std::vector<uint8_t> expected(0x1B00, 0);
    rect_t clipA = {4, 4, 11, 11};
    rect_t clipB = {0, 0, 5, 5};

    draw_expected_line(expected, 0, 0, 15, 15, 0xF0, &clipA);
    draw_expected_line(expected, 15, 4, 0, 4, 0xAA, &clipA);
    draw_expected_line(expected, 8, 0, 8, 15, 0xCC, &clipA);
    draw_expected_line(expected, 20, 20, 25, 25, 0xFF, &clipA);
    draw_expected_line(expected, 11, 11, 11, 11, 0x80, &clipA);
    draw_expected_line(expected, 3, 3, 3, 3, 0x80, &clipA);
    draw_expected_line(expected, 5, 0, 0, 5, 0xFF, &clipB);
    draw_expected_line(expected, 4, 11, 11, 4, 0x00, &clipA);
    draw_expected_line(expected, 0, 11, 15, 11, 0xFF, &clipA);
    draw_expected_line(expected, 4, 0, 4, 15, 0xFF, &clipA);
    return expected;
}

static std::vector<uint8_t> expected_draw_rectangle()
{
    std::vector<uint8_t> expected(0x1B00, 0);
    rect_t outer = {2, 2, 10, 6};
    rect_t inner = {12, 10, 18, 15};
    rect_t swapped = {30, 14, 24, 9};
    rect_t clipped = {38, 0, 48, 10};
    rect_t clip = {40, 2, 46, 8};
    rect_t point = {50, 5, 50, 5};
    rect_t flat = {52, 7, 57, 7};
    draw_expected_rectangle(expected, &outer, nullptr, 0xFF);
    draw_expected_rectangle(expected, &inner, nullptr, 0xF0);
    draw_expected_rectangle(expected, &swapped, nullptr, 0xAA);
    draw_expected_rectangle(expected, &clipped, &clip, 0xFF);
    draw_expected_rectangle(expected, &point, nullptr, 0xFF);
    draw_expected_rectangle(expected, &flat, nullptr, 0xCC);
    return expected;
}

static std::vector<uint8_t> expected_fill_rectangle()
{
    std::vector<uint8_t> expected(0x1B00, 0);
    rect_t a = {3, 3, 12, 9};
    uint8_t pa[2] = {0xAA, 0x55};
    fill_expected_rectangle(expected, &a, pa, 2, nullptr);

    rect_t b = {20, 12, 14, 8};
    uint8_t pb[1] = {0xF0};
    fill_expected_rectangle(expected, &b, pb, 1, nullptr);

    rect_t c = {30, 4, 38, 10};
    rect_t clip = {32, 5, 36, 8};
    uint8_t pc[3] = {0xFF, 0x18, 0x81};
    fill_expected_rectangle(expected, &c, pc, 3, &clip);

    set_expected_pixel(expected, 60, 10);
    return expected;
}

static std::vector<uint8_t> expected_draw_bmp()
{
    std::vector<uint8_t> expected(0x1B00, 0);
    draw_expected_bmp_packed(expected, 0, 0, bmp_checker, nullptr);
    draw_expected_bmp_packed(expected, 7, 3, bmp_checker, nullptr);
    rect_t clip_a = {10, 6, 17, 13};
    draw_expected_bmp_packed(expected, 12, 8, bmp_diagonal, &clip_a);
    set_expected_pixel(expected, 42, 20);
    set_expected_pixel(expected, 45, 20);
    set_expected_pixel(expected, 41, 20);
    set_expected_pixel(expected, 42, 20);
    set_expected_pixel(expected, 45, 20);
    set_expected_pixel(expected, 46, 20);
    draw_expected_bmp_packed(expected, -2, 190, bmp_checker, nullptr);
    rect_t clip_b = {252, 188, 255, 191};
    draw_expected_bmp_packed(expected, 254, 189, bmp_diagonal, &clip_b);
    return expected;
}

static std::vector<uint8_t> expected_public_api()
{
    std::vector<uint8_t> expected(0x1B00, 0);
    set_expected_pixel(expected, 0, 191);
    return expected;
}

static std::vector<uint8_t> expected_measure_text()
{
    std::vector<uint8_t> expected(0x1B00, 0);
    set_expected_pixel(expected, 1, 191);
    return expected;
}

static std::vector<uint8_t> expected_draw_text_api()
{
    std::vector<uint8_t> expected(0x1B00, 0);
    auto clear_expected_pixel = [&](int px, int py) {
        if (!in_clip(px, py, nullptr))
            return;
        uint16_t off = zx_screen_offset(px, py);
        uint8_t mask = (uint8_t)(0x80 >> (px & 7));
        expected[off] &= (uint8_t)~mask;
    };
    auto draw_stub_glyph_expected = [&](int x, int y, char ch, bmode m, const rect_t *clip) {
        uint8_t seed = (uint8_t)ch;
        for (coord row = 0; row < 5; ++row) {
            for (coord col = 0; col < 4; ++col) {
                int px = x + col;
                int py = y + row;
                if (!in_clip(px, py, clip))
                    continue;
                clear_expected_pixel(px, py);
            }
        }
        for (coord row = 0; row < 5; ++row) {
            uint8_t pattern = (uint8_t)((seed << row) | (seed >> (8 - row)));
            for (coord col = 0; col < 3; ++col) {
                if (pattern & (0x80 >> col)) {
                    int px = x + col;
                    int py = y + row;
                    if (!in_clip(px, py, clip))
                        continue;
                    if (m == BM_XOR)
                        xor_expected_pixel(expected, px, py);
                    else
                        set_expected_pixel(expected, px, py);
                }
            }
        }
    };

    draw_stub_glyph_expected(0, 0, 'A', BM_CPY, nullptr);
    draw_stub_glyph_expected(8, 0, 'B', BM_CPY, nullptr);
    rect_t clip = {9, 8, 10, 12};
    draw_stub_glyph_expected(8, 8, 'Z', BM_CPY, &clip);
    draw_stub_glyph_expected(0, 0, 'A', BM_XOR, nullptr);
    draw_stub_glyph_expected(252, 190, 'A', BM_CPY, nullptr);
    return expected;
}

static std::vector<uint8_t> expected_draw_text_gapfill()
{
    std::vector<uint8_t> expected(0x1B00, 0);
    set_expected_pixel(expected, 6, 191);
    return expected;
}

static std::vector<uint8_t> expected_get_stock_bmp()
{
    std::vector<uint8_t> expected(0x1B00, 0);
    set_expected_pixel(expected, 3, 191);
    set_expected_pixel(expected, 4, 191);
    set_expected_pixel(expected, 5, 191);
    set_expected_pixel(expected, 6, 191);
    set_expected_pixel(expected, 7, 191);
    set_expected_pixel(expected, 8, 191);
    return expected;
}

static std::vector<uint8_t> expected_get_cursor()
{
    std::vector<uint8_t> expected(0x1B00, 0);
    set_expected_pixel(expected, 4, 191);
    return expected;
}

static std::vector<uint8_t> expected_cursor_set()
{
    std::vector<uint8_t> expected(0x1B00, 0);
    set_expected_pixel(expected, 5, 191);
    return expected;
}

static int run_target(
    const char *name,
    const char *path,
    const std::vector<uint8_t> &expected)
{
    std::cout << "[test] " << name << " => " << path << "\n";

    MMU mmu;
    unsigned short loadBase = 0;
    unsigned short loadTop = 0;
    if (!run_ihx(path, mmu, loadBase, loadTop)) {
        std::cerr << "ERROR: cannot run IHX file '" << path << "'\n";
        return 1;
    }

    std::vector<uint8_t> actual = screen_snapshot(mmu);
    std::string message;
    if (!compare_screen(actual, expected, message)) {
        std::cerr << "ERROR: " << name << " failed: " << message << "\n";
        return 1;
    }

    std::cout << "[ok] " << name << "\n";
    return 0;
}

static int run_target_against_oracle(
    const char *name,
    const char *real_path,
    const char *oracle_path)
{
    std::cout << "[test] " << name << " => real:" << real_path
              << " oracle:" << oracle_path << "\n";

    MMU mmu_real;
    MMU mmu_oracle;
    unsigned short loadBase = 0;
    unsigned short loadTop = 0;

    if (!run_ihx(real_path, mmu_real, loadBase, loadTop)) {
        std::cerr << "ERROR: cannot run IHX file '" << real_path << "'\n";
        return 1;
    }
    if (!run_ihx(oracle_path, mmu_oracle, loadBase, loadTop)) {
        std::cerr << "ERROR: cannot run IHX file '" << oracle_path << "'\n";
        return 1;
    }

    std::vector<uint8_t> actual = screen_snapshot(mmu_real);
    std::vector<uint8_t> expected = screen_snapshot(mmu_oracle);

    std::string message;
    if (!compare_screen(actual, expected, message)) {
        std::cerr << "ERROR: " << name << " failed: " << message << "\n";
        return 1;
    }

    std::cout << "[ok] " << name << "\n";
    return 0;
}

static int test_compare_screen_paths()
{
    int status = 0;
    std::string message;

    std::vector<uint8_t> a(0x1800, 0);
    std::vector<uint8_t> b(0x17FF, 0);
    if (compare_screen(a, b, message)) {
        std::cerr << "ERROR: compare_screen expected size mismatch failure\n";
        status |= 1;
    }

    b.resize(0x1800);
    b[1] = 1;
    if (compare_screen(a, b, message)) {
        std::cerr << "ERROR: compare_screen expected byte mismatch failure\n";
        status |= 1;
    }

    b[1] = 0;
    if (!compare_screen(a, b, message)) {
        std::cerr << "ERROR: compare_screen expected success on equal buffers\n";
        status |= 1;
    }

    return status;
}

int main()
{
    int status = 0;
    status |= run_emulator_unit_tests();
    status |= test_compare_screen_paths();
    status |= run_target_against_oracle("ZX Spectrum clrscr", "bin/zx/test_clrscr.ihx", "bin/zx-oracle/test_clrscr.ihx");
    status |= run_target_against_oracle("ZX Spectrum width/height", "bin/zx/test_width_height.ihx", "bin/zx-oracle/test_width_height.ihx");
    status |= run_target_against_oracle("ZX Spectrum draw pixel", "bin/zx/test_draw_pixel.ihx", "bin/zx-oracle/test_draw_pixel.ihx");
    status |= run_target_against_oracle("ZX Spectrum draw line", "bin/zx/test_draw_line.ihx", "bin/zx-oracle/test_draw_line.ihx");
    status |= run_target_against_oracle("ZX Spectrum draw line (clip)", "bin/zx/test_draw_line_clip.ihx", "bin/zx-oracle/test_draw_line_clip.ihx");
    status |= run_target_against_oracle("ZX Spectrum draw rectangle", "bin/zx/test_draw_rectangle.ihx", "bin/zx-oracle/test_draw_rectangle.ihx");
    status |= run_target_against_oracle("ZX Spectrum fill rectangle", "bin/zx/test_fill_rectangle.ihx", "bin/zx-oracle/test_fill_rectangle.ihx");
    status |= run_target("ZX Spectrum draw bitmap (expected)", "bin/zx/test_draw_bmp.ihx", expected_draw_bmp());
    status |= run_target_against_oracle("ZX Spectrum draw bitmap", "bin/zx/test_draw_bmp.ihx", "bin/zx-oracle/test_draw_bmp.ihx");
    status |= run_target_against_oracle("ZX Spectrum get fonts", "bin/zx/test_get_fonts.ihx", "bin/zx-oracle/test_get_fonts.ihx");
    status |= run_target_against_oracle("ZX Spectrum measure text", "bin/zx/test_measure_text.ihx", "bin/zx-oracle/test_measure_text.ihx");
    status |= run_target("ZX Spectrum draw text gap fill", "bin/zx/test_draw_text_gapfill.ihx", expected_draw_text_gapfill());
    status |= run_target_against_oracle("ZX Spectrum get stock bmp", "bin/zx/test_get_stock_bmp.ihx", "bin/zx-oracle/test_get_stock_bmp.ihx");
    status |= run_target_against_oracle("ZX Spectrum stock cursors", "bin/zx/test_get_cursor.ihx", "bin/zx-oracle/test_get_cursor.ihx");
    status |= run_target_against_oracle("ZX Spectrum set page API", "bin/zx/test_cursor_set.ihx", "bin/zx-oracle/test_cursor_set.ihx");
    if (status == 0)
        std::cout << "All emulator tests passed." << std::endl;
    return status;
}
