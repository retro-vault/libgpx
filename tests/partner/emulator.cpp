#include "emulator.hpp"

#include <algorithm>
#include <cassert>
#include <cstdlib>
#include <fstream>
#include <iostream>
#include <sstream>
#include <cstring>
#include "z80.hpp"

MMU::MMU()
{
    std::memset(ram, 0, sizeof(ram));
    std::memset(io, 0, sizeof(io));
    partner_fb_width = 1024;
    partner_fb_height = 256;
    partner_fb.assign((1024 >> 3) * 256, 0);
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

namespace {

constexpr uint16_t PARTNER_DEFAULT_W = 1024;
constexpr uint16_t PARTNER_DEFAULT_H = 256;

constexpr uint8_t EF9367_CMD = 0x20;
constexpr uint8_t EF9367_CR1 = 0x21;
constexpr uint8_t EF9367_CR2 = 0x22;
constexpr uint8_t EF9367_DX = 0x25;
constexpr uint8_t EF9367_DY = 0x27;
constexpr uint8_t EF9367_XPOS_HI = 0x28;
constexpr uint8_t EF9367_XPOS_LO = 0x29;
constexpr uint8_t EF9367_YPOS_HI = 0x2A;
constexpr uint8_t EF9367_YPOS_LO = 0x2B;
constexpr uint8_t EF9367_STS_NI = 0x2F;
constexpr uint8_t PIO_GR_CMN = 0x30;

constexpr uint8_t EF9367_STS_NI_VBLANK = 0x02;
constexpr uint8_t EF9367_STS_NI_READY = 0x04;
constexpr uint8_t PIO_GR_CMN_XOR_MODE = 0x04;
constexpr uint8_t PIO_GR_CMN_1024x512 = 0x18;

constexpr uint8_t EF9367_CMD_DMOD_SET = 0x00;
constexpr uint8_t EF9367_CMD_DMOD_CLR = 0x01;
constexpr uint8_t EF9367_CMD_PEN_DOWN = 0x02;
constexpr uint8_t EF9367_CMD_PEN_UP = 0x03;
constexpr uint8_t EF9367_CMD_CLS = 0x04;
constexpr uint8_t EF9367_CMD_PLOT = 0x80;

struct PartnerGpu
{
    uint16_t width = PARTNER_DEFAULT_W;
    uint16_t height = PARTNER_DEFAULT_H;
    uint16_t x = 0;
    uint16_t y = 0;
    uint16_t xpos_raw = 0;
    uint16_t ypos_raw = 0;
    uint8_t dx = 0;
    uint8_t dy = 0;
    uint8_t cr2 = 0;
    uint8_t pio_gr_cmn = 0;
    bool pen_down = true;
    bool draw_set = true;
    bool xor_mode = false;
};

struct PartnerRunContext
{
    MMU *mmu = nullptr;
    PartnerGpu gpu;
    Z80 *cpu = nullptr;
};

static void partner_plot(PartnerRunContext *ctx, int x, int y)
{
    if (!ctx->gpu.pen_down)
        return;
    if (x < 0 || y < 0 || x >= ctx->gpu.width || y >= ctx->gpu.height)
        return;

    uint32_t stride = (uint32_t)ctx->gpu.width >> 3;
    uint32_t offset = (uint32_t)y * stride + (uint32_t)(x >> 3);
    if (offset >= ctx->mmu->partner_fb.size())
        return;

    uint8_t mask = (uint8_t)(0x80u >> (x & 7));
    if (ctx->gpu.xor_mode) {
        ctx->mmu->partner_fb[offset] ^= mask;
    } else if (ctx->gpu.draw_set) {
        ctx->mmu->partner_fb[offset] |= mask;
    } else {
        ctx->mmu->partner_fb[offset] &= (uint8_t)~mask;
    }
}

static bool partner_style_on(uint8_t style, int step)
{
    switch (style & 0x03) {
    case 0x00: // solid
        return true;
    case 0x01: // dotted: 2 on, 2 off
        return (step & 0x03) < 2;
    case 0x02: // dashed: 4 on, 4 off
        return (step & 0x07) < 4;
    default: { // dot-dash: 10 on, 2 off, 2 on, 2 off
        int p = step & 0x0F;
        return p < 10 || (p >= 12 && p < 14);
    }
    }
}

static void partner_vector_draw(PartnerRunContext *ctx, uint8_t cmd)
{
    int adx = (int)ctx->gpu.dx;
    int ady = (int)ctx->gpu.dy;
    int sdx = 0;
    int sdy = 0;
    int b1 = (cmd >> 1) & 0x01;
    int b2 = (cmd >> 2) & 0x01;

    if (cmd & 0x01) {
        sdx = b1 ? -adx : adx;
        sdy = b2 ? ady : -ady;
    } else if (b1 == b2) {
        sdx = b1 ? -adx : adx;
        sdy = 0;
    } else {
        sdx = 0;
        sdy = b1 ? -ady : ady;
    }

    int x0 = (int)ctx->gpu.x;
    int y0 = (int)ctx->gpu.y;
    int x1 = x0 + sdx;
    int y1 = y0 + sdy;

    int dx = std::abs(x1 - x0);
    int sx = x0 < x1 ? 1 : -1;
    int dy = -std::abs(y1 - y0);
    int sy = y0 < y1 ? 1 : -1;
    int err = dx + dy;
    int step = 0;
    uint8_t style = (uint8_t)(ctx->gpu.cr2 & 0x03);

    while (true) {
        if (partner_style_on(style, step))
            partner_plot(ctx, x0, y0);
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
        ++step;
    }

    ctx->gpu.x = (uint16_t)x1;
    ctx->gpu.y = (uint16_t)y1;
}

static void partner_handle_command(PartnerRunContext *ctx, uint8_t cmd)
{
    if (std::getenv("LIBGPX_PARTNER_TRACE")) {
        std::cerr
            << "[partner-cmd] cmd=0x" << std::hex << (int)cmd
            << " pc=0x" << (ctx->cpu ? ctx->cpu->reg.PC : 0)
            << " x=" << std::dec << (int)ctx->gpu.x
            << " y=" << (int)ctx->gpu.y
            << " dx=" << (int)ctx->gpu.dx
            << " dy=" << (int)ctx->gpu.dy
            << " cr2=" << (int)(ctx->gpu.cr2 & 0x03)
            << "\n";
    }

    switch (cmd) {
    case EF9367_CMD_DMOD_SET:
        ctx->gpu.draw_set = true;
        return;
    case EF9367_CMD_DMOD_CLR:
        ctx->gpu.draw_set = false;
        return;
    case EF9367_CMD_PEN_DOWN:
        ctx->gpu.pen_down = true;
        return;
    case EF9367_CMD_PEN_UP:
        ctx->gpu.pen_down = false;
        return;
    case EF9367_CMD_CLS: {
        std::fill(ctx->mmu->partner_fb.begin(), ctx->mmu->partner_fb.end(), 0);
        return;
    }
    case EF9367_CMD_PLOT:
        partner_plot(ctx, (int)ctx->gpu.x, (int)ctx->gpu.y);
        return;
    default:
        if (cmd & 0x10)
            partner_vector_draw(ctx, cmd);
        return;
    }
}

static void partner_apply_xy(PartnerRunContext *ctx)
{
    ctx->gpu.x = ctx->gpu.xpos_raw;
    if (ctx->gpu.height == 0) {
        ctx->gpu.y = 0;
        return;
    }
    int maxy = (int)ctx->gpu.height - 1;
    int y = maxy - (int)ctx->gpu.ypos_raw;
    ctx->gpu.y = (uint16_t)y;
}

static uint8_t read_memory_partner(void *arg, unsigned short addr)
{
    PartnerRunContext *ctx = (PartnerRunContext *)arg;
    return ctx->mmu->ram[addr];
}

static void write_memory_partner(void *arg, unsigned short addr, unsigned char value)
{
    PartnerRunContext *ctx = (PartnerRunContext *)arg;
    ctx->mmu->ram[addr] = value;
}

static unsigned char in_port_partner(void *arg, unsigned short port)
{
    PartnerRunContext *ctx = (PartnerRunContext *)arg;
    uint8_t p = (uint8_t)(port & 0xFF);
    switch (p) {
    case EF9367_STS_NI:
        return (uint8_t)(EF9367_STS_NI_READY | EF9367_STS_NI_VBLANK);
    case EF9367_CR2:
        return ctx->gpu.cr2;
    case PIO_GR_CMN:
        return ctx->gpu.pio_gr_cmn;
    default:
        return 0;
    }
}

static void out_port_partner(void *arg, unsigned short port, unsigned char value)
{
    PartnerRunContext *ctx = (PartnerRunContext *)arg;
    uint8_t p = (uint8_t)(port & 0xFF);

    switch (p) {
    case EF9367_CMD:
        partner_handle_command(ctx, value);
        break;
    case EF9367_CR1:
        ctx->gpu.pen_down = (value & 0x01) != 0;
        ctx->gpu.draw_set = (value & 0x02) != 0;
        break;
    case EF9367_CR2:
        ctx->gpu.cr2 = value;
        break;
    case EF9367_DX:
        ctx->gpu.dx = value;
        break;
    case EF9367_DY:
        ctx->gpu.dy = value;
        break;
    case EF9367_XPOS_LO:
        ctx->gpu.xpos_raw = (uint16_t)((ctx->gpu.xpos_raw & 0xFF00) | value);
        partner_apply_xy(ctx);
        break;
    case EF9367_XPOS_HI:
        ctx->gpu.xpos_raw = (uint16_t)((ctx->gpu.xpos_raw & 0x00FF) | ((uint16_t)value << 8));
        partner_apply_xy(ctx);
        break;
    case EF9367_YPOS_LO:
        ctx->gpu.ypos_raw = (uint16_t)((ctx->gpu.ypos_raw & 0xFF00) | value);
        partner_apply_xy(ctx);
        break;
    case EF9367_YPOS_HI:
        ctx->gpu.ypos_raw = (uint16_t)((ctx->gpu.ypos_raw & 0x00FF) | ((uint16_t)value << 8));
        partner_apply_xy(ctx);
        break;
    case PIO_GR_CMN:
        ctx->gpu.pio_gr_cmn = value;
        ctx->gpu.xor_mode = (value & PIO_GR_CMN_XOR_MODE) != 0;
        {
            uint16_t new_height = (value & PIO_GR_CMN_1024x512) ? 512 : 256;
            if (new_height != ctx->gpu.height) {
                ctx->gpu.height = new_height;
                ctx->mmu->partner_fb_width = ctx->gpu.width;
                ctx->mmu->partner_fb_height = ctx->gpu.height;
                ctx->mmu->partner_fb.assign(
                    (ctx->gpu.width >> 3) * ctx->gpu.height,
                    0);
            }
        }
        partner_apply_xy(ctx);
        break;
    default:
        break;
    }
}

} // namespace

bool run_partner_ihx(
    const std::string &path,
    MMU &mmu,
    unsigned short &loadBase,
    unsigned short &loadTop)
{
    if (!load_intel_hex(mmu, path, loadBase, loadTop))
        return false;

    PartnerRunContext ctx;
    ctx.mmu = &mmu;
    mmu.partner_fb_width = PARTNER_DEFAULT_W;
    mmu.partner_fb_height = PARTNER_DEFAULT_H;
    mmu.partner_fb.assign((PARTNER_DEFAULT_W >> 3) * PARTNER_DEFAULT_H, 0);

    Z80 cpu(read_memory_partner, write_memory_partner, in_port_partner, out_port_partner, &ctx);
    ctx.cpu = &cpu;
    cpu.reg.PC = loadBase;
    cpu.reg.SP = 0xFFFE;

    int maxTicks = 8000000;
    for (int i = 0; i < maxTicks; ++i) {
        cpu.execute(1);
        if (cpu.reg.IFF & 0x80)
            return true;
    }

    if (std::getenv("LIBGPX_PARTNER_TRACE")) {
        std::cerr
            << "[partner-timeout] pc=0x" << std::hex << cpu.reg.PC
            << " sp=0x" << cpu.reg.SP
            << " ticks=" << std::dec << maxTicks
            << "\n";
    }

    return false;
}

uint32_t partner_screen_offset(int x, int y, int width)
{
    return (uint32_t)y * (uint32_t)(width >> 3) + (uint32_t)(x >> 3);
}

std::vector<uint8_t> partner_screen_snapshot(const MMU &mmu, int width, int height)
{
    uint32_t req_size = (uint32_t)(width >> 3) * (uint32_t)height;
    if (width == mmu.partner_fb_width &&
        height == mmu.partner_fb_height &&
        mmu.partner_fb.size() == req_size) {
        return mmu.partner_fb;
    }

    std::vector<uint8_t> result(req_size, 0);
    int copy_h = std::min(height, mmu.partner_fb_height);
    int copy_w_bytes = std::min(width >> 3, mmu.partner_fb_width >> 3);
    int src_stride = mmu.partner_fb_width >> 3;
    int dst_stride = width >> 3;
    for (int y = 0; y < copy_h; ++y) {
        uint32_t src_off = (uint32_t)y * (uint32_t)src_stride;
        uint32_t dst_off = (uint32_t)y * (uint32_t)dst_stride;
        for (int x = 0; x < copy_w_bytes; ++x)
            result[dst_off + (uint32_t)x] = mmu.partner_fb[src_off + (uint32_t)x];
    }
    return result;
}

