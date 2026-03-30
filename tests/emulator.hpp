#ifndef LIBGPX_EMULATOR_HPP
#define LIBGPX_EMULATOR_HPP

#include <cstdint>
#include <string>
#include <vector>
#include "libgpx.h"

struct MMU
{
    unsigned char ram[0x10000];
    unsigned char io[0x100];
    std::vector<uint8_t> partner_fb;
    int partner_fb_width;
    int partner_fb_height;

    MMU();
};

uint8_t read_memory(void *arg, unsigned short addr);
void write_memory(void *arg, unsigned short addr, unsigned char value);
unsigned char in_port(void * /*arg*/, unsigned short /*port*/);
void out_port(void * /*arg*/, unsigned short /*port*/, unsigned char /*value*/);

bool load_intel_hex(
    MMU &mmu,
    const std::string &path,
    unsigned short &loadBase,
    unsigned short &loadTop);
bool run_ihx(
    const std::string &path,
    MMU &mmu,
    unsigned short &loadBase,
    unsigned short &loadTop);
bool run_partner_ihx(
    const std::string &path,
    MMU &mmu,
    unsigned short &loadBase,
    unsigned short &loadTop);

uint16_t zx_screen_offset(int x, int y);
std::vector<uint8_t> screen_snapshot(const MMU &mmu);
uint32_t partner_screen_offset(int x, int y, int width = 1024);
std::vector<uint8_t> partner_screen_snapshot(
    const MMU &mmu,
    int width = 1024,
    int height = 256);

void set_expected_pixel(std::vector<uint8_t> &expected, int x, int y);
void xor_expected_pixel(std::vector<uint8_t> &expected, int x, int y);
void draw_expected_bmp(
    std::vector<uint8_t> &expected,
    int x,
    int y,
    const bmp_t *b,
    const rect_t *clip);
void draw_expected_hline(
    std::vector<uint8_t> &expected,
    int x0,
    int x1,
    int y,
    uint8_t lpatt,
    const rect_t *clip);
void draw_expected_line(
    std::vector<uint8_t> &expected,
    int x0,
    int y0,
    int x1,
    int y1,
    uint8_t lpatt,
    const rect_t *clip);
void draw_expected_rectangle(
    std::vector<uint8_t> &expected,
    const rect_t *r,
    const rect_t *clip,
    uint8_t lpatt = 0xFF);
void fill_expected_rectangle(
    std::vector<uint8_t> &expected,
    const rect_t *r,
    const uint8_t *fpatt,
    uint8_t fpatt_len,
    const rect_t *clip);

#endif // LIBGPX_EMULATOR_HPP
