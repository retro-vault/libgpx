#include <cstdio>
#include <fstream>
#include <iostream>
#include <string>
#include <unistd.h>
#include <vector>

#include "emulator.hpp"

namespace {

int g_failures = 0;
int g_temp_counter = 0;
std::vector<std::string> g_temp_files;

void check(bool condition, const std::string &message)
{
    if (!condition) {
        ++g_failures;
        std::cerr << "[fail] " << message << "\n";
    }
}

std::string write_temp_ihx(const std::string &contents)
{
    std::string path = "/tmp/libgpx_emulator_" + std::to_string(getpid()) +
        "_" + std::to_string(++g_temp_counter) + ".ihx";
    std::ofstream out(path);
    out << contents;
    out.close();
    g_temp_files.push_back(path);
    return path;
}

void cleanup_temp_files()
{
    for (const std::string &path : g_temp_files)
        std::remove(path.c_str());
    g_temp_files.clear();
}

bool pixel_on(const std::vector<uint8_t> &screen, int x, int y)
{
    if (x < 0 || x >= 256 || y < 0 || y >= 192)
        return false;
    uint16_t offset = zx_screen_offset(x, y);
    uint8_t mask = (uint8_t)(0x80 >> (x & 7));
    return (screen[offset] & mask) != 0;
}

int pixel_count(const std::vector<uint8_t> &screen)
{
    int count = 0;
    for (uint8_t b : screen)
        count += __builtin_popcount((unsigned int)b);
    return count;
}

void test_memory_io_helpers()
{
    MMU mmu;
    check(read_memory(&mmu, 0x1234) == 0x00, "read_memory should return initialized zero");
    write_memory(&mmu, 0x1234, 0xAB);
    check(read_memory(&mmu, 0x1234) == 0xAB, "write_memory should store value");
    check(in_port(&mmu, 0x00FE) == 0x00, "in_port should return zero");
    out_port(&mmu, 0x00FE, 0x55);
}

void test_load_intel_hex_paths()
{
    MMU mmu;
    unsigned short base = 0;
    unsigned short top = 0;

    check(!load_intel_hex(mmu, "/tmp/definitely_missing_ihx_file.ihx", base, top),
          "load_intel_hex should fail for missing files");

    std::string bad_prefix = write_temp_ihx(";010100007600\n");
    check(!load_intel_hex(mmu, bad_prefix, base, top),
          "load_intel_hex should reject records without ':' prefix");

    std::string too_short = write_temp_ihx(":0000\n");
    check(!load_intel_hex(mmu, too_short, base, top),
          "load_intel_hex should reject short records");

    std::string bad_header_hex = write_temp_ihx(":0G010000AA00\n");
    check(!load_intel_hex(mmu, bad_header_hex, base, top),
          "load_intel_hex should reject invalid header hex");

    std::string bad_data_hex = write_temp_ihx(":01010000G000\n");
    check(!load_intel_hex(mmu, bad_data_hex, base, top),
          "load_intel_hex should reject invalid data hex");

    std::string unsupported_type = write_temp_ihx(":00000002FF\n");
    check(!load_intel_hex(mmu, unsupported_type, base, top),
          "load_intel_hex should reject unsupported record type");

    std::string bad_extended_size = write_temp_ihx(":010000040000\n");
    check(!load_intel_hex(mmu, bad_extended_size, base, top),
          "load_intel_hex should reject type 04 records with size != 2");

    std::string overflow_address = write_temp_ihx(
        ":02000004000100\n"
        ":01000000AA00\n"
        ":00000001FF\n");
    check(!load_intel_hex(mmu, overflow_address, base, top),
          "load_intel_hex should reject data writes above 64K");

    std::string no_data = write_temp_ihx(":00000001FF\n");
    check(!load_intel_hex(mmu, no_data, base, top),
          "load_intel_hex should fail when no data records are present");

    std::string valid = write_temp_ihx(
        ":02000004000000\n"
        ":010A1F00Ab00\n"
        ":010A2000cD00\n"
        ":00000001FF\n");
    check(load_intel_hex(mmu, valid, base, top), "load_intel_hex should accept valid input");
    check(base == 0x0A1F, "load_intel_hex should set expected load base");
    check(top == 0x0A20, "load_intel_hex should set expected load top");
    check(mmu.ram[0x0A1F] == 0xAB, "load_intel_hex should load first data byte");
    check(mmu.ram[0x0A20] == 0xCD, "load_intel_hex should load second data byte");
}

void test_run_ihx_paths()
{
    MMU mmu;
    unsigned short base = 0;
    unsigned short top = 0;

    check(!run_ihx("/tmp/definitely_missing_ihx_file.ihx", mmu, base, top),
          "run_ihx should fail when load_intel_hex fails");

    std::string halt_program = write_temp_ihx(
        ":010100007600\n"
        ":00000001FF\n");
    check(run_ihx(halt_program, mmu, base, top),
          "run_ihx should succeed for halting program");
    check(base == 0x0100 && top == 0x0100,
          "run_ihx should report expected bounds for halt program");

    std::string loop_program = write_temp_ihx(
        ":0201000018FE00\n"
        ":00000001FF\n");
    check(!run_ihx(loop_program, mmu, base, top),
          "run_ihx should fail (timeout) for non-halting program");
}

void test_screen_helpers()
{
    check(zx_screen_offset(0, 0) == 0x0000, "zx_screen_offset origin should be zero");
    check(zx_screen_offset(8, 0) == 0x0001, "zx_screen_offset should advance by byte on x");
    check(zx_screen_offset(0, 8) == 0x0020, "zx_screen_offset should map y=8 block");
    check(zx_screen_offset(0, 64) == 0x0800, "zx_screen_offset should map y=64 block");

    MMU mmu;
    mmu.ram[0x4000] = 0x12;
    mmu.ram[0x5AFF] = 0x34;
    std::vector<uint8_t> snap = screen_snapshot(mmu);
    check(snap.size() == 0x1B00, "screen_snapshot should return ZX screen size");
    check(snap[0] == 0x12, "screen_snapshot should include first screen byte");
    check(snap[0x1AFF] == 0x34, "screen_snapshot should include last screen byte");

    std::vector<uint8_t> expected(0x1B00, 0);
    set_expected_pixel(expected, 0, 0);
    check(pixel_on(expected, 0, 0), "set_expected_pixel should set in-bounds pixel");
    int before = pixel_count(expected);
    set_expected_pixel(expected, -1, 0);
    set_expected_pixel(expected, 256, 0);
    set_expected_pixel(expected, 0, 192);
    check(pixel_count(expected) == before,
          "set_expected_pixel should ignore out-of-bounds coordinates");
    xor_expected_pixel(expected, 0, 0);
    check(!pixel_on(expected, 0, 0), "xor_expected_pixel should clear set pixel");
    xor_expected_pixel(expected, 0, 0);
    check(pixel_on(expected, 0, 0), "xor_expected_pixel should set cleared pixel");
    int xor_before = pixel_count(expected);
    xor_expected_pixel(expected, -1, 0);
    xor_expected_pixel(expected, 256, 0);
    xor_expected_pixel(expected, 0, 192);
    check(pixel_count(expected) == xor_before,
          "xor_expected_pixel should ignore out-of-bounds coordinates");

    std::vector<uint8_t> line_pattern(0x1B00, 0);
    draw_expected_line(line_pattern, 0, 0, 3, 0, 0xA0, nullptr);
    check(pixel_on(line_pattern, 0, 0) && pixel_on(line_pattern, 2, 0),
          "draw_expected_line should apply line pattern bits");
    check(!pixel_on(line_pattern, 1, 0) && !pixel_on(line_pattern, 3, 0),
          "draw_expected_line should skip pixels when pattern bit is zero");

    std::vector<uint8_t> line_clip(0x1B00, 0);
    rect_t lclip = {1, 1, 3, 3};
    draw_expected_line(line_clip, 0, 0, 4, 4, 0xFF, &lclip);
    check(pixel_on(line_clip, 1, 1) && pixel_on(line_clip, 2, 2) && pixel_on(line_clip, 3, 3),
          "draw_expected_line should draw clipped diagonal segment");
    check(!pixel_on(line_clip, 0, 0) && !pixel_on(line_clip, 4, 4),
          "draw_expected_line should reject pixels outside clip");

    std::vector<uint8_t> rectbuf(0x1B00, 0);
    rect_t r = {4, 4, 2, 2};
    rect_t rclip = {3, 2, 4, 4};
    draw_expected_rectangle(rectbuf, &r, &rclip, 0xFF);
    check(pixel_on(rectbuf, 3, 2) && pixel_on(rectbuf, 4, 2) && pixel_on(rectbuf, 4, 3) &&
          pixel_on(rectbuf, 3, 4) && pixel_on(rectbuf, 4, 4),
          "draw_expected_rectangle should normalize coordinates and draw clipped border");
    check(!pixel_on(rectbuf, 2, 2), "draw_expected_rectangle should not draw outside clip");

    std::vector<uint8_t> fill(0x1B00, 0);
    rect_t fr = {3, 3, 1, 1};
    uint8_t p1[1] = {0x80};
    fill_expected_rectangle(fill, &fr, p1, 1, nullptr);
    check(pixel_on(fill, 1, 1) && pixel_on(fill, 1, 2) && pixel_on(fill, 1, 3),
          "fill_expected_rectangle should normalize coordinates and repeat pattern");
    check(!pixel_on(fill, 2, 1), "fill_expected_rectangle should honor pattern bits");
    int fill_before = pixel_count(fill);
    fill_expected_rectangle(fill, &fr, p1, 0, nullptr);
    check(pixel_count(fill) == fill_before,
          "fill_expected_rectangle should do nothing when pattern length is zero");

    std::vector<uint8_t> fill_clip(0x1B00, 0);
    uint8_t p2[1] = {0xFF};
    rect_t fclip = {2, 2, 2, 3};
    fill_expected_rectangle(fill_clip, &fr, p2, 1, &fclip);
    check(pixel_on(fill_clip, 2, 2) && pixel_on(fill_clip, 2, 3),
          "fill_expected_rectangle should draw inside clip");
    check(!pixel_on(fill_clip, 1, 2) && !pixel_on(fill_clip, 3, 2),
          "fill_expected_rectangle should clip out pixels");

    std::vector<uint8_t> bmpbuf(0x1B00, 0);
    std::vector<uint8_t> blob(sizeof(bmp_t) + 2, 0);
    bmp_t *bmp = reinterpret_cast<bmp_t *>(blob.data());
    bmp->signature = BMP_SIG_STRIDE(BMP_ENC_1BPP, 1);
    bmp->w = 8;
    bmp->h = 2;
    bmp->size = 2;
    bmp->bitmap[0] = 0xA0;
    bmp->bitmap[1] = 0x50;
    rect_t bclip = {2, 1, 6, 2};
    draw_expected_bmp(bmpbuf, 1, 1, bmp, &bclip);
    check(pixel_on(bmpbuf, 3, 1) && pixel_on(bmpbuf, 2, 2) && pixel_on(bmpbuf, 4, 2),
          "draw_expected_bmp should draw expected clipped bitmap pixels");
    check(!pixel_on(bmpbuf, 1, 1),
          "draw_expected_bmp should skip set bits outside clip");
}

} // namespace

int run_emulator_unit_tests()
{
    test_memory_io_helpers();
    test_load_intel_hex_paths();
    test_run_ihx_paths();
    test_screen_helpers();
    cleanup_temp_files();

    if (g_failures == 0) {
        std::cout << "All emulator unit tests passed.\n";
        return 0;
    }

    std::cerr << g_failures << " emulator unit test(s) failed.\n";
    return 1;
}

#ifndef LIBGPX_UNIT_NO_MAIN
int main()
{
    return run_emulator_unit_tests();
}
#endif
