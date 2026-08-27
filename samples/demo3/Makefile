# Examples from docs/manuals/PROGRAMMING-LIBGPX.md (demo3).
#
# One source per example, built for both machines: a .tap for the ZX
# Spectrum (loads at 0x8000, returns to BASIC) and a CP/M .com for the
# Iskra Delta Partner (loads at 0x100). Everything runs inside the pinned
# toolchain images, so no host toolchain is needed.

ROOT_DIR ?= $(abspath ../..)
BUILD_DIR := $(ROOT_DIR)/build/demo3
BIN_DIR := $(ROOT_DIR)/bin/demo3

include $(ROOT_DIR)/scripts/mk/toolchain.mk

EXAMPLES := panels bounce

ZX_LOAD_HEX ?= 0x8000
ZX_LOAD_DEC ?= $(shell printf '%d\n' $(ZX_LOAD_HEX))
PARTNER_LOAD_HEX ?= 0x100

ZX_LIB := $(ROOT_DIR)/bin/libgpx.lib
PARTNER_LIB := $(ROOT_DIR)/bin/partner/libgpx.lib

TAPS := $(addprefix $(BIN_DIR)/,$(addsuffix .tap,$(EXAMPLES)))
COMS := $(addprefix $(BIN_DIR)/,$(addsuffix .com,$(EXAMPLES)))

.PHONY: all build zx partner clean

all: build

build: zx partner

zx: $(TAPS)

partner: $(COMS)

$(BUILD_DIR)/ $(BIN_DIR)/:
	mkdir -p "$@"

$(ZX_LIB):
	$(MAKE) -C $(ROOT_DIR)/src lib

$(PARTNER_LIB):
	$(MAKE) -C $(ROOT_DIR)/src partner-lib

# ---- ZX Spectrum ----------------------------------------------------
$(BIN_DIR)/%.tap: $(ROOT_DIR)/samples/demo3/src/%.c \
                  $(ROOT_DIR)/samples/demo3/src/crt0-zx.s \
                  $(ZX_LIB) | $(BUILD_DIR)/ $(BIN_DIR)/
	$(ZXRUN) 'set -e; \
		$(XAS) -o build/demo3/crt0-zx.rel samples/demo3/src/crt0-zx.s; \
		$(XCC) $(XCFLAGS) -c -o build/demo3/$*-zx.rel samples/demo3/src/$*.c; \
		$(XCC) $(XLDFLAGS) -o build/demo3/$*.bin \
			build/demo3/crt0-zx.rel build/demo3/$*-zx.rel bin/libgpx.lib \
			-Wl,--oformat=binary -Wl,-b,_CODE=$(ZX_LOAD_HEX); \
		xprog --tap build/demo3/$*.bin -o bin/demo3/$*.tap \
			-n $* --load-address $(ZX_LOAD_DEC) --entry $(ZX_LOAD_DEC)'

# ---- Iskra Delta Partner --------------------------------------------
$(BIN_DIR)/%.com: $(ROOT_DIR)/samples/demo3/src/%.c \
                  $(ROOT_DIR)/samples/demo3/src/crt0-partner.s \
                  $(PARTNER_LIB) | $(BUILD_DIR)/ $(BIN_DIR)/
	$(IDPRUN) 'set -e; \
		$(XAS) -o build/demo3/crt0-partner.rel samples/demo3/src/crt0-partner.s; \
		$(XCC) $(XCFLAGS) -c -o build/demo3/$*-p.rel samples/demo3/src/$*.c; \
		$(XCC) $(XLDFLAGS) -o bin/demo3/$*.com \
			build/demo3/crt0-partner.rel build/demo3/$*-p.rel bin/partner/libgpx.lib \
			-Wl,--oformat=binary -Wl,-b,_CODE=$(PARTNER_LOAD_HEX)'

clean:
	rm -rf "$(BUILD_DIR)" "$(BIN_DIR)"
