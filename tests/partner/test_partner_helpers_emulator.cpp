/* Exercise the linked Z80 helpers over the complete 16-bit input range.
 * Expected results use host signed arithmetic and the documented GDP command
 * fields, independently of the instruction sequences under test. */
#include <array>
#include <cstdint>
#include <fstream>
#include <iostream>
#include <sstream>
#include <string>

#include "emulator.hpp"
#include "z80.hpp"

namespace {

uint8_t read_byte(void *memory, unsigned short address)
{
    return static_cast<MMU *>(memory)->ram[address];
}

void write_byte(void *memory, unsigned short address, unsigned char value)
{
    static_cast<MMU *>(memory)->ram[address] = value;
}

unsigned char ready_port(void *, unsigned short)
{
    return 4;                           // EF9367 READY
}

void write_port(void *memory, unsigned short port, unsigned char value)
{
    static_cast<MMU *>(memory)->io[port & 255] = value;
}

uint16_t symbol_address(const std::string &name)
{
    std::ifstream map("bin/partner-gdp/bench_prims.map");
    std::string line;
    while (std::getline(map, line)) {
        std::istringstream fields(line);
        unsigned address;
        std::string symbol;
        if ((fields >> std::hex >> address >> symbol) && symbol == name)
            return static_cast<uint16_t>(address);
    }
    return 0;
}

uint16_t hl(const Z80 &cpu)
{
    return (cpu.reg.pair.H << 8) | cpu.reg.pair.L;
}

uint16_t de(const Z80 &cpu)
{
    return (cpu.reg.pair.D << 8) | cpu.reg.pair.E;
}

bool invoke(Z80 &cpu, MMU &memory, uint16_t address,
            uint16_t lhs, uint16_t rhs)
{
    cpu.reg.PC = address;
    cpu.reg.SP = 0x7000;
    cpu.reg.IFF = 0;
    cpu.reg.pair.H = lhs >> 8;
    cpu.reg.pair.L = lhs;
    cpu.reg.pair.D = rhs >> 8;
    cpu.reg.pair.E = rhs;
    cpu.reg.pair.F = 0xFF;              // prior flags must not affect results
    memory.ram[0x7000] = 0;
    memory.ram[0x7001] = 0x70;          // synthetic return address
    for (unsigned n = 0; n < 40 && cpu.reg.PC != 0x7000; ++n)
        cpu.execute(1);
    return cpu.reg.PC == 0x7000;
}

} // namespace

int main()
{
    MMU memory;
    uint16_t base, top;
    if (!load_intel_hex(memory, "bin/partner-gdp/bench_prims.ihx", base, top))
        return 1;

    const uint16_t compare = symbol_address("__rect_cmp16s_lt");
    const uint16_t delta = symbol_address("__ef9367_get_delta_cmd");
    const uint16_t xy = symbol_address("__ef9367_set_xy");
    const uint16_t max_y = symbol_address("__ef9367_max_y");
    if (!compare || !delta || !xy || !max_y) {
        std::cerr << "Partner helper symbols missing from benchmark map\n";
        return 1;
    }

    Z80 cpu(read_byte, write_byte, ready_port, write_port, &memory);
    const std::array<uint16_t, 16> boundaries = {
        0, 1, 2, 127, 128, 255, 256, 511, 512, 1023,
        0x7FFF, 0x8000, 0x8001, 0xFF00, 0xFFFE, 0xFFFF
    };

    for (uint32_t lhs = 0; lhs < 65536; ++lhs) {
        for (uint16_t rhs : boundaries) {
            const bool expected = int16_t(lhs) < int16_t(rhs);
            if (!invoke(cpu, memory, compare, lhs, rhs) ||
                cpu.reg.pair.A != expected ||
                bool(cpu.reg.pair.F & 0x40) == expected ||
                (cpu.reg.pair.F & 1) || hl(cpu) != lhs || de(cpu) != rhs) {
                std::cerr << "Signed comparison failed: " << lhs << ", "
                          << rhs << "\n";
                return 1;
            }
        }
    }
    std::cout << "1,048,576 signed comparisons, flags and operands passed.\n";

    for (uint32_t dx = 0; dx < 65536; ++dx) {
        for (uint16_t dy : boundaries) {
            const unsigned sx = (dx & 0x8000) ? 2 : 0;
            const unsigned sy = (dy & 0x8000) ? 4 : 0;
            const unsigned expected = dx == 0 ? (((sy >> 1) | sy) ^ 4) | 16
                                    : dy == 0 ? sx | (sx << 1) | 16
                                    : (17 | sx | sy) ^ 4;
            if (!invoke(cpu, memory, delta, dx, dy) ||
                cpu.reg.pair.A != expected || hl(cpu) != dx || de(cpu) != dy) {
                std::cerr << "Delta command failed: " << dx << ", "
                          << dy << "\n";
                return 1;
            }
        }
    }
    std::cout << "1,048,576 signed delta command encodings passed.\n";

    for (unsigned height : {256, 512}) {
        memory.ram[max_y] = 255;
        memory.ram[max_y + 1] = (height - 1) >> 8;
        for (uint32_t y = 0; y < 65536; ++y) {
            const uint16_t expected = uint16_t(height - 1 - y);
            if (!invoke(cpu, memory, xy, 0x02AF, y) ||
                memory.io[0x29] != 0xAF || memory.io[0x28] != 2 ||
                memory.io[0x2B] != (expected & 255) ||
                memory.io[0x2A] != (expected >> 8) ||
                hl(cpu) != 0x02AF || de(cpu) != y) {
                std::cerr << "Reverse Y failed: " << height << ", "
                          << y << "\n";
                return 1;
            }
        }
    }
    std::cout << "131,072 reverse-Y transforms across both modes passed.\n";
}
