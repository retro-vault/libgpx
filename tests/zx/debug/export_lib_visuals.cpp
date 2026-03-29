#include <cstdint>
#include <cstdio>
#include <cstring>
#include <fstream>
#include <iostream>
#include <string>
#include <vector>

#include "emulator.hpp"

struct CaseDef
{
    const char *name;
    const char *real_ihx;
    const char *oracle_ihx;
};

static const CaseDef CASES[] = {
    {"clrscr", "bin/zx/test_clrscr.ihx", "bin/zx-oracle/test_clrscr.ihx"},
    {"width_height", "bin/zx/test_width_height.ihx", "bin/zx-oracle/test_width_height.ihx"},
    {"draw_pixel", "bin/zx/test_draw_pixel.ihx", "bin/zx-oracle/test_draw_pixel.ihx"},
    {"draw_line", "bin/zx/test_draw_line.ihx", "bin/zx-oracle/test_draw_line.ihx"},
    {"draw_line_clip", "bin/zx/test_draw_line_clip.ihx", "bin/zx-oracle/test_draw_line_clip.ihx"},
    {"draw_rectangle", "bin/zx/test_draw_rectangle.ihx", "bin/zx-oracle/test_draw_rectangle.ihx"},
    {"fill_rectangle", "bin/zx/test_fill_rectangle.ihx", "bin/zx-oracle/test_fill_rectangle.ihx"},
    {"draw_bmp", "bin/zx/test_draw_bmp.ihx", "bin/zx-oracle/test_draw_bmp.ihx"},
    {"get_fonts", "bin/zx/test_get_fonts.ihx", "bin/zx-oracle/test_get_fonts.ihx"},
    {"measure_text", "bin/zx/test_measure_text.ihx", "bin/zx-oracle/test_measure_text.ihx"},
    {"draw_text", "bin/zx/test_draw_text.ihx", "bin/zx-oracle/test_draw_text.ihx"},
    {"get_stock_bmp", "bin/zx/test_get_stock_bmp.ihx", "bin/zx-oracle/test_get_stock_bmp.ihx"},
    {"get_cursor", "bin/zx/test_get_cursor.ihx", "bin/zx-oracle/test_get_cursor.ihx"},
    {"cursor_set", "bin/zx/test_cursor_set.ihx", "bin/zx-oracle/test_cursor_set.ihx"},
};

static bool write_raw_0x1800(const std::string &path, const std::vector<uint8_t> &snap)
{
    if (snap.size() < 0x1800)
        return false;
    std::ofstream out(path, std::ios::binary);
    if (!out.is_open())
        return false;
    out.write(reinterpret_cast<const char *>(snap.data()), 0x1800);
    return out.good();
}

static bool run_case_capture(const char *ihx, std::vector<uint8_t> &bitmap_out)
{
    MMU mmu;
    unsigned short loadBase = 0;
    unsigned short loadTop = 0;
    if (!run_ihx(ihx, mmu, loadBase, loadTop))
        return false;

    std::vector<uint8_t> snap = screen_snapshot(mmu);
    if (snap.size() < 0x1800)
        return false;

    bitmap_out.assign(snap.begin(), snap.begin() + 0x1800);
    return true;
}

static void compare_bitmaps(
    const std::vector<uint8_t> &a,
    const std::vector<uint8_t> &b,
    bool &match,
    int &mismatch_index,
    int &diff_count)
{
    match = true;
    mismatch_index = -1;
    diff_count = 0;

    const int n = 0x1800;
    for (int i = 0; i < n; ++i) {
        if (a[i] != b[i]) {
            if (mismatch_index < 0)
                mismatch_index = i;
            ++diff_count;
            match = false;
        }
    }
}

static bool write_meta(
    const std::string &path,
    bool real_ok,
    bool oracle_ok,
    bool match,
    int mismatch_index,
    int diff_count)
{
    std::ofstream out(path);
    if (!out.is_open())
        return false;
    out << "real_ok=" << (real_ok ? 1 : 0) << "\n";
    out << "oracle_ok=" << (oracle_ok ? 1 : 0) << "\n";
    out << "match=" << (match ? 1 : 0) << "\n";
    out << "mismatch_index=" << mismatch_index << "\n";
    out << "diff_count=" << diff_count << "\n";
    if (mismatch_index >= 0)
        out << "mismatch_addr=0x" << std::hex << (0x4000 + mismatch_index) << std::dec << "\n";
    return out.good();
}

int main(int argc, char **argv)
{
    std::string out_dir = "bin/lib-visuals/raw";
    if (argc > 1)
        out_dir = argv[1];

    int failures = 0;
    for (const auto &tc : CASES) {
        std::vector<uint8_t> real;
        std::vector<uint8_t> oracle;

        bool real_ok = run_case_capture(tc.real_ihx, real);
        bool oracle_ok = run_case_capture(tc.oracle_ihx, oracle);

        bool match = false;
        int mismatch_index = -1;
        int diff_count = 0;

        if (real_ok && oracle_ok)
            compare_bitmaps(real, oracle, match, mismatch_index, diff_count);

        std::string real_raw = out_dir + "/" + tc.name + ".real.raw";
        std::string oracle_raw = out_dir + "/" + tc.name + ".oracle.raw";
        std::string meta = out_dir + "/" + tc.name + ".meta";

        bool io_ok = true;
        if (real_ok)
            io_ok = io_ok && write_raw_0x1800(real_raw, real);
        if (oracle_ok)
            io_ok = io_ok && write_raw_0x1800(oracle_raw, oracle);
        io_ok = io_ok && write_meta(meta, real_ok, oracle_ok, match, mismatch_index, diff_count);

        if (!real_ok || !oracle_ok || !match || !io_ok)
            ++failures;

        std::cout << tc.name << ": real_ok=" << (real_ok ? 1 : 0)
                  << " oracle_ok=" << (oracle_ok ? 1 : 0)
                  << " match=" << (match ? 1 : 0)
                  << " diff_count=" << diff_count
                  << "\n";
    }

    return failures == 0 ? 0 : 1;
}
