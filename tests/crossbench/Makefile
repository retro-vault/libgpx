ROOT_DIR ?= $(abspath ../..)
BUILD_DIR ?= $(ROOT_DIR)/build
BIN_DIR ?= $(ROOT_DIR)/bin

PYTHON ?= python3

include $(ROOT_DIR)/scripts/mk/toolchain.mk

# One source, every backend. Unlike the per-backend suites these size their
# work from fixed coordinates rather than gpx_width()/gpx_height(), so the
# three machines are asked to draw exactly the same picture and the numbers
# can be put side by side.
XB_SRCS := $(wildcard $(ROOT_DIR)/tests/crossbench/src/xb_*.c)
XB_NAMES := $(patsubst $(ROOT_DIR)/tests/crossbench/src/%.c,%,$(XB_SRCS))
XB_HDR := $(ROOT_DIR)/tests/crossbench/src/xbench.h

# Relink when a backend changes, not just when the scenario does.
ZX_LIB_SRCS := $(wildcard $(ROOT_DIR)/src/zx/*.s) $(wildcard $(ROOT_DIR)/src/zx/*.c)
PARTNER_LIB_SRCS := $(wildcard $(ROOT_DIR)/src/partner/*.s) \
	$(wildcard $(ROOT_DIR)/src/partner/*.c) \
	$(wildcard $(ROOT_DIR)/src/partner/*.inc)
CPC_LIB_SRCS := $(wildcard $(ROOT_DIR)/src/cpc/*.s) \
	$(wildcard $(ROOT_DIR)/src/cpc/*.inc)

XB_BIN := $(BIN_DIR)/xbench
XB_OUT := $(foreach n,$(XB_NAMES),$(XB_BIN)/$(n)_zx.ihx \
	$(XB_BIN)/$(n)_partner.ihx \
	$(XB_BIN)/$(n)_cpc-640x200.bin $(XB_BIN)/$(n)_cpc-320x200.bin)
CODE_LOC ?= 0x8000

.PHONY: build run clean

build: $(XB_OUT)

run: build
	$(PYTHON) $(ROOT_DIR)/tests/mcp/crossbench.py $(ARGS)

$(BUILD_DIR)/xbench/ $(XB_BIN)/:
	mkdir -p $@

$(XB_BIN)/%_zx.ihx: $(ROOT_DIR)/tests/crossbench/src/%.c $(XB_HDR) $(ZX_LIB_SRCS) | $(BUILD_DIR)/xbench/ $(XB_BIN)/
	$(MAKE) -C $(ROOT_DIR)/src zx-lib-objs
	$(ZXRUN) 'set -e; \
		$(XCC) $(XCFLAGS) -Itests/crossbench/src -c -o build/xbench/$*_z.rel \
			tests/crossbench/src/$*.c; \
		$(XCC) $(XLDFLAGS) -o bin/xbench/$*_zx.ihx build/xbench/$*_z.rel build/zx/*.rel \
			-Wl,--oformat=ihx -Wl,-b,_CODE=$(CODE_LOC) -Wl,-Map=bin/xbench/$*_zx.map'

$(XB_BIN)/%_partner.ihx: $(ROOT_DIR)/tests/crossbench/src/%.c $(XB_HDR) $(PARTNER_LIB_SRCS) | $(BUILD_DIR)/xbench/ $(XB_BIN)/
	$(MAKE) -C $(ROOT_DIR)/src partner-lib-objs
	$(IDPRUN) 'set -e; \
		$(XCC) $(XCFLAGS) -Itests/crossbench/src -c -o build/xbench/$*_p.rel \
			tests/crossbench/src/$*.c; \
		$(XCC) $(XLDFLAGS) -o bin/xbench/$*_partner.ihx build/xbench/$*_p.rel build/partner-lib/*.rel \
			-Wl,--oformat=ihx -Wl,-b,_CODE=$(CODE_LOC) -Wl,-Map=bin/xbench/$*_partner.map'

$(XB_BIN)/%_cpc-640x200.bin: $(ROOT_DIR)/tests/crossbench/src/%.c $(XB_HDR) \
		$(CPC_LIB_SRCS) | $(BUILD_DIR)/xbench/ $(XB_BIN)/
	$(MAKE) -C $(ROOT_DIR)/src cpc-lib-objs
	$(CPCRUN) 'set -e; \
		$(XCC) $(XCFLAGS) -Itests/crossbench/src -DDEMO_MODE=0 \
			-c -o build/xbench/$*_c2.rel tests/crossbench/src/$*.c; \
		$(XLD) --oformat=binary -b _CODE=$(CODE_LOC) -nostartfiles \
			-Map=bin/xbench/$*_cpc-640x200.map \
			-o bin/xbench/$*_cpc-640x200.bin build/cpc/crt0-cpc.rel \
			build/xbench/$*_c2.rel \
			$$(ls build/cpc/*.rel | grep -v crt0-cpc)'

$(XB_BIN)/%_cpc-320x200.bin: $(ROOT_DIR)/tests/crossbench/src/%.c $(XB_HDR) \
		$(CPC_LIB_SRCS) | $(BUILD_DIR)/xbench/ $(XB_BIN)/
	$(MAKE) -C $(ROOT_DIR)/src cpc-lib-objs
	$(CPCRUN) 'set -e; \
		$(XCC) $(XCFLAGS) -Itests/crossbench/src -DDEMO_MODE=1 \
			-c -o build/xbench/$*_c1.rel tests/crossbench/src/$*.c; \
		$(XLD) --oformat=binary -b _CODE=$(CODE_LOC) -nostartfiles \
			-Map=bin/xbench/$*_cpc-320x200.map \
			-o bin/xbench/$*_cpc-320x200.bin build/cpc/crt0-cpc.rel \
			build/xbench/$*_c1.rel \
			$$(ls build/cpc/*.rel | grep -v crt0-cpc)'

clean:
	rm -rf $(XB_BIN) $(BUILD_DIR)/xbench
