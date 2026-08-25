#ifndef LIBGPX_PARTNER_EMULATOR_HPP
#define LIBGPX_PARTNER_EMULATOR_HPP

/* Host-side Z80 + EF9367 harness for the Iskra Delta Partner backend.
 *
 * The ZX Spectrum backend is not tested here: it runs on the real
 * cycle-accurate emulator behind zx-spectrum-mcp, driven by
 * tests/mcp/run_zx_tests.py. */

#include <cstdint>
#include <string>
#include <vector>

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
bool run_partner_ihx(
    const std::string &path,
    MMU &mmu,
    unsigned short &loadBase,
    unsigned short &loadTop);

uint32_t partner_screen_offset(int x, int y, int width = 1024);
std::vector<uint8_t> partner_screen_snapshot(
    const MMU &mmu,
    int width = 1024,
    int height = 256);

#endif // LIBGPX_PARTNER_EMULATOR_HPP
