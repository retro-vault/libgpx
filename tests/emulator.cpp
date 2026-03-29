#include "emulator.hpp"

#include <algorithm>
#include <cassert>
#include <fstream>
#include <iostream>
#include <sstream>
#include <cstring>
#include "z80.hpp"

MMU::MMU()
{
    std::memset(ram, 0, sizeof(ram));
    std::memset(io, 0, sizeof(io));
}

uint8_t read_memory(void *arg, unsigned short addr)
{
    return ((MMU *)arg)->ram[addr];
}

void write_memory(void *arg, unsigned short addr, unsigned char value)
{
    ((MMU *)arg)->ram[addr] = value;
}

unsigned char in_port(void * /*arg*/, unsigned short /*port*/)
{
    return 0;
}

void out_port(void * /*arg*/, unsigned short /*port*/, unsigned char /*value*/)
{
}

static int parse_hex_digit(char c)
{
    if (c >= '0' && c <= '9')
        return c - '0';
    if (c >= 'A' && c <= 'F')
        return c - 'A' + 10;
    if (c >= 'a' && c <= 'f')
        return c - 'a' + 10;
    return -1;
}

bool load_intel_hex(
    MMU &mmu,
    const std::string &path,
    unsigned short &loadBase,
    unsigned short &loadTop)
{
    std::ifstream input(path);
    if (!input.is_open())
        return false;

    std::string line;
    unsigned int extended = 0;
    bool loaded = false;
    loadBase = 0xFFFF;
    loadTop = 0;

    while (std::getline(input, line)) {
        if (line.empty() || line[0] != ':')
            return false;
        if (line.size() < 11)
            return false;

        int count = parse_hex_digit(line[1]) * 16 + parse_hex_digit(line[2]);
        int address = parse_hex_digit(line[3]) * 4096 + parse_hex_digit(line[4]) * 256 +
                      parse_hex_digit(line[5]) * 16 + parse_hex_digit(line[6]);
        int type = parse_hex_digit(line[7]) * 16 + parse_hex_digit(line[8]);
        if (count < 0 || address < 0 || type < 0)
            return false;

        std::vector<unsigned char> data;
        data.reserve(count);
        for (int i = 0; i < count; ++i) {
            int hi = parse_hex_digit(line[9 + i * 2]);
            int lo = parse_hex_digit(line[10 + i * 2]);
            if (hi < 0 || lo < 0)
                return false;
            data.push_back((unsigned char)((hi << 4) | lo));
        }

        if (type == 0x00) {
            unsigned int base = extended + (unsigned int)address;
            for (int i = 0; i < count; ++i) {
                unsigned int addr = base + (unsigned int)i;
                if (addr > 0xFFFF)
                    return false;
                mmu.ram[addr] = data[i];
                if (!loaded || addr < loadBase)
                    loadBase = (unsigned short)addr;
                if (!loaded || addr > loadTop)
                    loadTop = (unsigned short)addr;
                loaded = true;
            }
        } else if (type == 0x01) {
            break;
        } else if (type == 0x04) {
            if (data.size() != 2)
                return false;
            extended = ((unsigned int)data[0] << 24) | ((unsigned int)data[1] << 16);
        } else {
            return false;
        }
    }

    return loaded;
}

bool run_ihx(
    const std::string &path,
    MMU &mmu,
    unsigned short &loadBase,
    unsigned short &loadTop)
{
    if (!load_intel_hex(mmu, path, loadBase, loadTop))
        return false;

    Z80 cpu(read_memory, write_memory, in_port, out_port, &mmu);
    cpu.reg.PC = loadBase;
    cpu.reg.SP = 0xFFFE;

    // Keep enough headroom for heavier API tests that scan screen memory.
    int maxTicks = 5000000;
    for (int i = 0; i < maxTicks; ++i) {
        cpu.execute(1);
        if (cpu.reg.IFF & 0x80)
            return true;
    }

    return false;
}

uint16_t zx_screen_offset(int x, int y)
{
    return (uint16_t)(((y & 0x07) << 8)
        + ((y & 0x38) << 2)
        + ((y & 0xC0) << 5)
        + (x >> 3));
}

std::vector<uint8_t> screen_snapshot(const MMU &mmu)
{
    std::vector<uint8_t> result(0x1B00);
    for (size_t i = 0; i < result.size(); ++i)
        result[i] = mmu.ram[0x4000 + i];
    return result;
}

static bool zx_in_clip(int x, int y, const rect_t *clip)
{
    if (x < 0 || x >= 256 || y < 0 || y >= 192)
        return false;
    if (clip) {
        if (x < clip->x0 || x > clip->x1 || y < clip->y0 || y > clip->y1)
            return false;
    }
    return true;
}

void set_expected_pixel(std::vector<uint8_t> &expected, int x, int y)
{
    if (!zx_in_clip(x, y, nullptr))
        return;
    uint16_t offset = zx_screen_offset(x, y);
    uint8_t mask = (uint8_t)(0x80 >> (x & 7));
    expected[offset] |= mask;
}

void xor_expected_pixel(std::vector<uint8_t> &expected, int x, int y)
{
    if (!zx_in_clip(x, y, nullptr))
        return;
    uint16_t offset = zx_screen_offset(x, y);
    uint8_t mask = (uint8_t)(0x80 >> (x & 7));
    expected[offset] ^= mask;
}

void draw_expected_bmp(
    std::vector<uint8_t> &expected,
    int x,
    int y,
    const bmp_t *b,
    const rect_t *clip)
{
    coord w = b->w;
    coord h = b->h;
    int16_t stride = b->stride;
    for (coord row = 0; row < h; ++row) {
        uint16_t row_offset = (uint16_t)(row * stride);
        for (coord col = 0; col < w; ++col) {
            uint8_t byte = b->bitmap[row_offset + (col >> 3)];
            uint8_t mask = (uint8_t)(0x80 >> (col & 7));
            if (byte & mask) {
                int px = x + col;
                int py = y + row;
                if (zx_in_clip(px, py, clip))
                    set_expected_pixel(expected, px, py);
            }
        }
    }
}

static uint8_t rotate_pattern(uint8_t lpatt)
{
    return (uint8_t)((lpatt << 1) | (lpatt >> 7));
}

void draw_expected_line(
    std::vector<uint8_t> &expected,
    int x0,
    int y0,
    int x1,
    int y1,
    uint8_t lpatt,
    const rect_t *clip)
{
    int dx = abs(x1 - x0);
    int sx = x0 < x1 ? 1 : -1;
    int dy = -abs(y1 - y0);
    int sy = y0 < y1 ? 1 : -1;
    int err = dx + dy;

    while (true) {
        if ((lpatt & 0x80) && zx_in_clip(x0, y0, clip))
            set_expected_pixel(expected, x0, y0);
        if (x0 == x1 && y0 == y1)
            break;
        int e2 = err * 2;
        if (e2 >= dy) {
            err += dy;
            x0 += sx;
        }
        if (e2 <= dx) {
            err += dx;
            y0 += sy;
        }
        lpatt = rotate_pattern(lpatt);
    }
}

void draw_expected_hline(
    std::vector<uint8_t> &expected,
    int x0,
    int x1,
    int y,
    uint8_t lpatt,
    const rect_t *clip)
{
    if (x1 < x0)
        std::swap(x0, x1);
    for (int x = x0; x <= x1; ++x) {
        if ((lpatt & 0x80) && zx_in_clip(x, y, clip))
            set_expected_pixel(expected, x, y);
        lpatt = rotate_pattern(lpatt);
    }
}

void draw_expected_rectangle(
    std::vector<uint8_t> &expected,
    const rect_t *r,
    const rect_t *clip,
    uint8_t lpatt)
{
    rect_t norm = *r;
    if (norm.x0 > norm.x1) std::swap(norm.x0, norm.x1);
    if (norm.y0 > norm.y1) std::swap(norm.y0, norm.y1);
    draw_expected_hline(expected, norm.x0, norm.x1, norm.y0, lpatt, clip);
    draw_expected_hline(expected, norm.x0, norm.x1, norm.y1, lpatt, clip);
    for (coord y = norm.y0 + 1; y < norm.y1; ++y) {
        if (zx_in_clip(norm.x0, y, clip))
            set_expected_pixel(expected, norm.x0, y);
        if (zx_in_clip(norm.x1, y, clip))
            set_expected_pixel(expected, norm.x1, y);
    }
}

void fill_expected_rectangle(
    std::vector<uint8_t> &expected,
    const rect_t *r,
    const uint8_t *fpatt,
    uint8_t fpatt_len,
    const rect_t *clip)
{
    if (fpatt_len == 0)
        return;
    rect_t norm = *r;
    if (norm.x0 > norm.x1) std::swap(norm.x0, norm.x1);
    if (norm.y0 > norm.y1) std::swap(norm.y0, norm.y1);
    for (coord row = norm.y0; row <= norm.y1; ++row) {
        uint8_t pattern = fpatt[(row - norm.y0) % fpatt_len];
        for (coord col = norm.x0; col <= norm.x1; ++col) {
            if (pattern & (0x80 >> ((col - norm.x0) & 7))) {
                if (zx_in_clip(col, row, clip))
                    set_expected_pixel(expected, col, row);
            }
        }
    }
}
