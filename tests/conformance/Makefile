ROOT_DIR ?= $(abspath ../..)
BUILD_DIR ?= $(ROOT_DIR)/build
BIN_DIR ?= $(ROOT_DIR)/bin

PYTHON ?= python3

include $(ROOT_DIR)/scripts/mk/toolchain.mk

# One source, both backends. Scenarios stay inside 256x192 so the ZX display
# file and the Partner raster can be compared pixel for pixel.
CONF_SRCS := $(wildcard $(ROOT_DIR)/tests/conformance/src/conf_*.c)
CONF_NAMES := $(patsubst $(ROOT_DIR)/tests/conformance/src/%.c,%,$(CONF_SRCS))
# Relink when the backends change, not just when the scenario does: these
# images link build/{zx,partner-lib}/*.rel, so a change under src/ must
# invalidate them or the comparison silently runs against yesterday's library.
ZX_LIB_SRCS := $(wildcard $(ROOT_DIR)/src/zx/*.s) $(wildcard $(ROOT_DIR)/src/zx/*.c) \
	$(ADVANCED_SRCS)
PARTNER_LIB_SRCS := $(wildcard $(ROOT_DIR)/src/partner/*.s) \
	$(wildcard $(ROOT_DIR)/src/partner/*.c) \
	$(wildcard $(ROOT_DIR)/src/partner/*.inc) \
	$(ADVANCED_SRCS)

CONF_BIN := $(BIN_DIR)/conf
# The CPC is compared in both display modes: it shares the ZX's font and
# stock cursors, so it must match pixel for pixel with no exceptions.
CPC_LIB_SRCS := $(wildcard $(ROOT_DIR)/src/cpc/*.s) \
	$(wildcard $(ROOT_DIR)/src/cpc/*.inc) \
	$(ADVANCED_SRCS)
CONF_OUT := $(foreach n,$(CONF_NAMES),$(CONF_BIN)/$(n)_zx.ihx \
	$(CONF_BIN)/$(n)_partner.ihx \
	$(CONF_BIN)/$(n)_cpc-640x200.bin $(CONF_BIN)/$(n)_cpc-320x200.bin)
CODE_LOC ?= 0x8000

.PHONY: build run clean

build: $(CONF_OUT)

run: build
	$(PYTHON) $(ROOT_DIR)/tests/mcp/conformance.py $(ARGS)

$(BUILD_DIR)/conf/ $(CONF_BIN)/:
	mkdir -p $@

$(CONF_BIN)/%_zx.ihx: $(ROOT_DIR)/tests/conformance/src/%.c $(ZX_LIB_SRCS) | $(BUILD_DIR)/conf/ $(CONF_BIN)/
	$(MAKE) -C $(ROOT_DIR)/src zx-lib-objs
	$(ZXRUN) 'set -e; \
		$(XCC) $(XCFLAGS) -c -o build/conf/$*_z.rel tests/conformance/src/$*.c; \
		$(XCC) $(XLDFLAGS) -o bin/conf/$*_zx.ihx build/conf/$*_z.rel build/zx/*.rel \
			-Wl,--oformat=ihx -Wl,-b,_CODE=$(CODE_LOC) -Wl,-Map=bin/conf/$*_zx.map'

$(CONF_BIN)/%_partner.ihx: $(ROOT_DIR)/tests/conformance/src/%.c $(PARTNER_LIB_SRCS) | $(BUILD_DIR)/conf/ $(CONF_BIN)/
	$(MAKE) -C $(ROOT_DIR)/src partner-lib-objs
	$(IDPRUN) 'set -e; \
		$(XCC) $(XCFLAGS) -c -o build/conf/$*_p.rel tests/conformance/src/$*.c; \
		$(XCC) $(XLDFLAGS) -o bin/conf/$*_partner.ihx build/conf/$*_p.rel build/partner-lib/*.rel \
			-Wl,--oformat=ihx -Wl,-b,_CODE=$(CODE_LOC) -Wl,-Map=bin/conf/$*_partner.map'

clean:
	rm -rf $(CONF_BIN) $(BUILD_DIR)/conf

$(CONF_BIN)/%_cpc-640x200.bin: $(ROOT_DIR)/tests/conformance/src/%.c \
		$(CPC_LIB_SRCS) | $(BUILD_DIR)/conf/ $(CONF_BIN)/
	$(MAKE) -C $(ROOT_DIR)/src cpc-lib-objs
	$(CPCRUN) 'set -e; \
		$(XCC) $(XCFLAGS) -DDEMO_MODE=0 -c -o build/conf/$*_c2.rel \
			tests/conformance/src/$*.c; \
		$(XLD) --oformat=binary -b _CODE=$(CODE_LOC) -nostartfiles \
			-Map=bin/conf/$*_cpc-640x200.map \
			-o bin/conf/$*_cpc-640x200.bin build/cpc/crt0-cpc.rel \
			build/conf/$*_c2.rel \
			$$(ls build/cpc/*.rel | grep -v crt0-cpc)'

$(CONF_BIN)/%_cpc-320x200.bin: $(ROOT_DIR)/tests/conformance/src/%.c \
		$(CPC_LIB_SRCS) | $(BUILD_DIR)/conf/ $(CONF_BIN)/
	$(MAKE) -C $(ROOT_DIR)/src cpc-lib-objs
	$(CPCRUN) 'set -e; \
		$(XCC) $(XCFLAGS) -DDEMO_MODE=1 -c -o build/conf/$*_c1.rel \
			tests/conformance/src/$*.c; \
		$(XLD) --oformat=binary -b _CODE=$(CODE_LOC) -nostartfiles \
			-Map=bin/conf/$*_cpc-320x200.map \
			-o bin/conf/$*_cpc-320x200.bin build/cpc/crt0-cpc.rel \
			build/conf/$*_c1.rel \
			$$(ls build/cpc/*.rel | grep -v crt0-cpc)'
