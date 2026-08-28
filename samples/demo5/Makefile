# Polygon demo (demo5).
#
# Built for both machines: a .tap for the ZX Spectrum (loads at 0x8000,
# returns to BASIC) and a CP/M .com for the Iskra Delta Partner (loads at
# 0x100). Everything runs inside the pinned toolchain images, so no host
# toolchain is needed.
#
# The program calls gpx_draw_polygon and gpx_fill_polygon, so it needs a
# library built with ADVANCED enabled -- the default. Against an
# ADVANCED=0 library the link fails with an unresolved symbol.
#
# Its crt0 asks for a 768-byte stack rather than the usual 512:
# gpx_fill_polygon keeps its edge table there, about 250 bytes deep.

ROOT_DIR ?= $(abspath ../..)
BUILD_DIR := $(ROOT_DIR)/build/demo5
BIN_DIR := $(ROOT_DIR)/bin/demo5

include $(ROOT_DIR)/scripts/mk/toolchain.mk

EXAMPLES := polygons

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
$(BIN_DIR)/%.tap: $(ROOT_DIR)/samples/demo5/src/%.c \
                  $(ROOT_DIR)/samples/demo5/src/crt0-zx.s \
                  $(ZX_LIB) | $(BUILD_DIR)/ $(BIN_DIR)/
	$(ZXRUN) 'set -e; \
		$(XAS) -o build/demo5/crt0-zx.rel samples/demo5/src/crt0-zx.s; \
		$(XCC) $(XCFLAGS) -c -o build/demo5/$*-zx.rel samples/demo5/src/$*.c; \
		$(XCC) $(XLDFLAGS) -o build/demo5/$*.bin \
			build/demo5/crt0-zx.rel build/demo5/$*-zx.rel bin/libgpx.lib \
			-Wl,--oformat=binary -Wl,-b,_CODE=$(ZX_LOAD_HEX); \
		xprog --tap build/demo5/$*.bin -o bin/demo5/$*.tap \
			-n $* --load-address $(ZX_LOAD_DEC) --entry $(ZX_LOAD_DEC)'

# ---- Iskra Delta Partner --------------------------------------------
$(BIN_DIR)/%.com: $(ROOT_DIR)/samples/demo5/src/%.c \
                  $(ROOT_DIR)/samples/demo5/src/crt0-partner.s \
                  $(PARTNER_LIB) | $(BUILD_DIR)/ $(BIN_DIR)/
	$(IDPRUN) 'set -e; \
		$(XAS) -o build/demo5/crt0-partner.rel samples/demo5/src/crt0-partner.s; \
		$(XCC) $(XCFLAGS) -c -o build/demo5/$*-p.rel samples/demo5/src/$*.c; \
		$(XCC) $(XLDFLAGS) -o bin/demo5/$*.com \
			build/demo5/crt0-partner.rel build/demo5/$*-p.rel bin/partner/libgpx.lib \
			-Wl,--oformat=binary -Wl,-b,_CODE=$(PARTNER_LOAD_HEX)'

clean:
	rm -rf "$(BUILD_DIR)" "$(BIN_DIR)"
