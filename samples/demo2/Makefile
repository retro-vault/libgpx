# Full-API smoke-test scene, built for both machines.

ROOT_DIR ?= $(abspath ../..)
BUILD_DIR := $(ROOT_DIR)/build/demo2
BIN_DIR := $(ROOT_DIR)/bin/demo2

include $(ROOT_DIR)/scripts/mk/toolchain.mk

TARGET ?= demo2
ZX_LOAD_HEX ?= 0x8000
ZX_LOAD_DEC ?= $(shell printf '%d\n' $(ZX_LOAD_HEX))
PARTNER_LOAD_HEX ?= 0x100

MAIN_SRC := $(ROOT_DIR)/samples/demo2/src/main.c
ZX_CRT0_SRC := $(ROOT_DIR)/samples/demo2/src/crt0-zx.s
PARTNER_CRT0_SRC := $(ROOT_DIR)/samples/demo2/src/crt0.s

ZX_LIB := $(ROOT_DIR)/bin/libgpx.lib
PARTNER_LIB := $(ROOT_DIR)/bin/partner/libgpx.lib
TAP := $(BIN_DIR)/$(TARGET).tap
COM := $(BIN_DIR)/$(TARGET).com

.PHONY: all build zx partner clean

all: build

build: zx partner

zx: $(TAP)

partner: $(COM)

$(BUILD_DIR) $(BIN_DIR):
	mkdir -p "$@"

$(ZX_LIB):
	$(MAKE) -C $(ROOT_DIR)/src lib

$(PARTNER_LIB):
	$(MAKE) -C $(ROOT_DIR)/src partner-lib

$(TAP): $(MAIN_SRC) $(ZX_CRT0_SRC) $(ZX_LIB) | $(BUILD_DIR) $(BIN_DIR)
	$(ZXRUN) 'set -e; \
		$(XAS) -o build/demo2/crt0-zx.rel samples/demo2/src/crt0-zx.s; \
		$(XCC) $(XCFLAGS) -c -o build/demo2/main-zx.rel samples/demo2/src/main.c; \
		$(XCC) $(XLDFLAGS) -o build/demo2/$(TARGET).bin \
			build/demo2/crt0-zx.rel build/demo2/main-zx.rel bin/libgpx.lib \
			-Wl,--oformat=binary -Wl,-b,_CODE=$(ZX_LOAD_HEX); \
		xprog --tap build/demo2/$(TARGET).bin -o bin/demo2/$(TARGET).tap \
			-n $(TARGET) --load-address $(ZX_LOAD_DEC) --entry $(ZX_LOAD_DEC)'

$(COM): $(MAIN_SRC) $(PARTNER_CRT0_SRC) $(PARTNER_LIB) | $(BUILD_DIR) $(BIN_DIR)
	$(IDPRUN) 'set -e; \
		$(XAS) -o build/demo2/crt0-partner.rel samples/demo2/src/crt0.s; \
		$(XCC) $(XCFLAGS) -c -o build/demo2/main-partner.rel samples/demo2/src/main.c; \
		$(XCC) $(XLDFLAGS) -o bin/demo2/$(TARGET).com \
			build/demo2/crt0-partner.rel build/demo2/main-partner.rel \
			bin/partner/libgpx.lib -Wl,--oformat=binary \
			-Wl,-b,_CODE=$(PARTNER_LOAD_HEX)'

clean:
	rm -rf "$(BUILD_DIR)" "$(BIN_DIR)"
