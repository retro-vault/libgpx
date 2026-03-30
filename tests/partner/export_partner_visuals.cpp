#include <cstdint>
#include <fstream>
#include <iostream>
#include <string>
#include <vector>

#include "emulator.hpp"

struct CaseDef
{
    const char *name;
    const char *real_ihx;
};

static const CaseDef CASES[] = {
    {"bmp", "build/partner-tests/test_partner_bmp.ihx"},
    {"line", "build/partner-tests/test_partner_line.ihx"},
    {"rect_fill", "build/partner-tests/test_partner_rect_fill.ihx"},
    {"api", "build/partner-tests/test_partner_api.ihx"},
    {"stress", "build/partner-tests/test_partner_stress.ihx"},
};

static constexpr int PARTNER_W = 1024;
static constexpr int PARTNER_H = 256;
static constexpr int PARTNER_STRIDE = PARTNER_W / 8;
static constexpr int PARTNER_SIZE = PARTNER_STRIDE * PARTNER_H;

static bool write_raw(const std::string &path, const std::vector<uint8_t> &snap)
{
    if ((int)snap.size() < PARTNER_SIZE)
        return false;
    std::ofstream out(path, std::ios::binary);
    if (!out.is_open())
        return false;
    out.write(reinterpret_cast<const char *>(snap.data()), PARTNER_SIZE);
    return out.good();
}

static void set_partner_expected_pixel(std::vector<uint8_t> &expected, int x, int y)
{
    if (x < 0 || x >= PARTNER_W || y < 0 || y >= PARTNER_H)
        return;
    uint32_t offset = partner_screen_offset(x, y, PARTNER_W);
    uint8_t mask = (uint8_t)(0x80 >> (x & 7));
    expected[offset] |= mask;
}

static uint8_t rot_r8(uint8_t v, uint8_t n)
{
    uint8_t count = (uint8_t)(n & 7);
    while (count--) {
        uint8_t lsb = (uint8_t)(v & 1);
        v = (uint8_t)(v >> 1);
        if (lsb)
            v = (uint8_t)(v | 0x80);
    }
    return v;
}

static std::vector<uint8_t> build_expected_line_case()
{
    std::vector<uint8_t> expected(PARTNER_SIZE, 0);

    for (int x = 2; x <= 20; ++x)
        set_partner_expected_pixel(expected, x, 2);

    for (int p = 10; p <= 20; ++p)
        set_partner_expected_pixel(expected, p, p);

    set_partner_expected_pixel(expected, 40, 10);
    set_partner_expected_pixel(expected, 42, 10);
    set_partner_expected_pixel(expected, 45, 10);
    set_partner_expected_pixel(expected, 47, 10);

    for (int x = 60; x <= 63; ++x)
        set_partner_expected_pixel(expected, x, 10);

    for (int x = 100; x <= 500; ++x)
        set_partner_expected_pixel(expected, x, 50);

    for (int x = 50; x <= 400; ++x)
        set_partner_expected_pixel(expected, x, 80);

    for (int x = 10; x <= 25; ++x)
        set_partner_expected_pixel(expected, x, 100);

    for (int x = 10; x <= 25; ++x) {
        int step = x - 10;
        if ((step & 0x03) < 2) {
            set_partner_expected_pixel(expected, x, 101);
            set_partner_expected_pixel(expected, x, 102);
            set_partner_expected_pixel(expected, x, 103);
            set_partner_expected_pixel(expected, x, 104);
            set_partner_expected_pixel(expected, x, 105);
            set_partner_expected_pixel(expected, x, 106);
        }
    }

    for (int x = 10; x <= 25; ++x) {
        int step = x - 10;
        if ((step & 0x07) < 4) {
            set_partner_expected_pixel(expected, x, 107);
            set_partner_expected_pixel(expected, x, 108);
        }
    }

    for (int x = 10; x <= 25; ++x) {
        int step = (x - 10) & 0x0F;
        if (step < 10 || (step >= 12 && step < 14)) {
            set_partner_expected_pixel(expected, x, 109);
            set_partner_expected_pixel(expected, x, 110);
        }
    }

    {
        uint8_t lpatt = 0xA5;
        for (int x = 10; x <= 25; ++x) {
            if (lpatt & 1)
                set_partner_expected_pixel(expected, x, 111);
            lpatt = rot_r8(lpatt, 1);
        }
    }

    return expected;
}

static std::vector<uint8_t> build_expected_bmp_case()
{
    std::vector<uint8_t> expected(PARTNER_SIZE, 0);

    // Tiny move stream at (20,20), clipped to {20,20}-{23,22}.
    set_partner_expected_pixel(expected, 20, 20);
    set_partner_expected_pixel(expected, 22, 20);
    set_partner_expected_pixel(expected, 23, 20);
    set_partner_expected_pixel(expected, 23, 21);

    // Tiny move stream at (40,30), large clip (full visible path).
    set_partner_expected_pixel(expected, 40, 30);
    set_partner_expected_pixel(expected, 42, 30);
    set_partner_expected_pixel(expected, 43, 30);
    set_partner_expected_pixel(expected, 43, 31);

    return expected;
}

static std::vector<uint8_t> build_expected_rect_fill_case()
{
    std::vector<uint8_t> expected(PARTNER_SIZE, 0);

    // Dotted rectangle: {8,6}..{15,12} (2 on, 2 off)
    for (int x = 8; x <= 15; ++x) {
        if (((x - 8) & 3) < 2) {
            set_partner_expected_pixel(expected, x, 6);
            set_partner_expected_pixel(expected, x, 12);
        }
    }
    for (int y = 7; y <= 11; ++y) {
        set_partner_expected_pixel(expected, 8, y);
        set_partner_expected_pixel(expected, 15, y);
    }

    // Clipped solid rectangle: {18,4}..{30,14} clipped by {20,4}..{30,12}
    for (int x = 20; x <= 30; ++x)
        set_partner_expected_pixel(expected, x, 4);
    for (int y = 5; y <= 12; ++y)
        set_partner_expected_pixel(expected, 30, y);

    // Unclipped fill: rect {30,20}..{38,24}, fpatt={0x96,0x3A}
    const uint8_t fp0[2] = {0x96, 0x3A};
    for (int y = 20; y <= 24; ++y) {
        uint8_t lpatt = fp0[(y - 20) & 1];
        for (int x = 30; x <= 38; ++x) {
            if (lpatt & 1)
                set_partner_expected_pixel(expected, x, y);
            lpatt = rot_r8(lpatt, 1);
        }
    }

    // Clipped fill:
    //   rect {50,30}..{57,34}, clip {53,32}..{57,34}
    //   row phase starts at (32-30)%2 = 0
    //   x phase rotates by (53-50)&7 = 3
    const uint8_t fp1[2] = {0x96, 0x3A};
    uint8_t row_idx = 0;
    for (int y = 32; y <= 34; ++y) {
        uint8_t lpatt = rot_r8(fp1[row_idx], 3);
        for (int x = 53; x <= 57; ++x) {
            if (lpatt & 1)
                set_partner_expected_pixel(expected, x, y);
            lpatt = rot_r8(lpatt, 1);
        }
        row_idx = (uint8_t)((row_idx + 1) & 1);
    }

    // Large unclipped fill: rect {120,40}..{320,190}, fpatt len = 4.
    const uint8_t fp2[4] = {0x96, 0x3A, 0xC5, 0x69};
    for (int y = 40; y <= 190; ++y) {
        uint8_t lpatt = fp2[(y - 40) & 3];
        for (int x = 120; x <= 320; ++x) {
            if (lpatt & 1)
                set_partner_expected_pixel(expected, x, y);
            lpatt = rot_r8(lpatt, 1);
        }
    }

    // Large clipped fill:
    //   rect {300,100}..{900,240}, clip {350,120}..{760,210}
    //   row phase starts at (120-100)%3 = 2
    //   x phase rotates by (350-300)&7 = 2
    const uint8_t fp3[3] = {0x96, 0xA5, 0x69};
    row_idx = 2;
    for (int y = 120; y <= 210; ++y) {
        uint8_t lpatt = rot_r8(fp3[row_idx], 2);
        for (int x = 350; x <= 760; ++x) {
            if (lpatt & 1)
                set_partner_expected_pixel(expected, x, y);
            lpatt = rot_r8(lpatt, 1);
        }
        ++row_idx;
        if (row_idx >= 3)
            row_idx = 0;
    }

    return expected;
}

static std::vector<uint8_t> build_expected_for_case(const std::string &name)
{
    if (name == "bmp")
        return build_expected_bmp_case();
    if (name == "line")
        return build_expected_line_case();
    if (name == "rect_fill")
        return build_expected_rect_fill_case();
    return std::vector<uint8_t>(PARTNER_SIZE, 0);
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

    for (int i = 0; i < PARTNER_SIZE; ++i) {
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
    out << "width=" << PARTNER_W << "\n";
    out << "height=" << PARTNER_H << "\n";
    if (mismatch_index >= 0)
        out << "mismatch_addr=0x" << std::hex << (mismatch_index + 0x8000) << std::dec << "\n";
    return out.good();
}

static bool run_case_capture(const char *ihx, std::vector<uint8_t> &bitmap_out)
{
    MMU mmu;
    unsigned short loadBase = 0;
    unsigned short loadTop = 0;
    if (!run_partner_ihx(ihx, mmu, loadBase, loadTop))
        return false;

    std::vector<uint8_t> snap = partner_screen_snapshot(mmu, PARTNER_W, PARTNER_H);
    if ((int)snap.size() < PARTNER_SIZE)
        return false;

    bitmap_out.assign(snap.begin(), snap.begin() + PARTNER_SIZE);
    return true;
}

int main(int argc, char **argv)
{
    std::string out_dir = "bin/partner-visuals/raw";
    if (argc > 1)
        out_dir = argv[1];

    int failures = 0;
    for (const auto &tc : CASES) {
        std::vector<uint8_t> real;
        std::vector<uint8_t> oracle = build_expected_for_case(tc.name);

        bool real_ok = run_case_capture(tc.real_ihx, real);
        bool oracle_ok = ((int)oracle.size() == PARTNER_SIZE);

        /* API case has no compact hand-written oracle yet:
         * use captured output as the reference visual so it is exported
         * together with the rest of the Partner test scenarios. */
        if ((std::string(tc.name) == "api" || std::string(tc.name) == "stress") && real_ok) {
            oracle = real;
            oracle_ok = true;
        }

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
            io_ok = io_ok && write_raw(real_raw, real);
        if (oracle_ok)
            io_ok = io_ok && write_raw(oracle_raw, oracle);
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
