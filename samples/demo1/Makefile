# Stock cursor and screen-dimensions demo, built for both machines.

ROOT_DIR ?= $(abspath ../..)
BUILD_DIR := $(ROOT_DIR)/build/demo1
BIN_DIR := $(ROOT_DIR)/bin/demo1

include $(ROOT_DIR)/scripts/mk/toolchain.mk

TARGET ?= demo1
ZX_LOAD_HEX ?= 0x8000
ZX_LOAD_DEC ?= $(shell printf '%d\n' $(ZX_LOAD_HEX))
PARTNER_LOAD_HEX ?= 0x100

MAIN_SRC := $(ROOT_DIR)/samples/demo1/src/main.c
ZX_CRT0_SRC := $(ROOT_DIR)/samples/demo1/src/crt0.s
PARTNER_CRT0_SRC := $(ROOT_DIR)/samples/demo1/src/crt0-partner.s

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
		$(XAS) -o build/demo1/crt0-zx.rel samples/demo1/src/crt0.s; \
		$(XCC) $(XCFLAGS) -c -o build/demo1/main-zx.rel samples/demo1/src/main.c; \
		$(XCC) $(XLDFLAGS) -o build/demo1/$(TARGET).bin \
			build/demo1/crt0-zx.rel build/demo1/main-zx.rel bin/libgpx.lib \
			-Wl,--oformat=binary -Wl,-b,_CODE=$(ZX_LOAD_HEX); \
		xprog --tap build/demo1/$(TARGET).bin -o bin/demo1/$(TARGET).tap \
			-n $(TARGET) --load-address $(ZX_LOAD_DEC) --entry $(ZX_LOAD_DEC)'

$(COM): $(MAIN_SRC) $(PARTNER_CRT0_SRC) $(PARTNER_LIB) | $(BUILD_DIR) $(BIN_DIR)
	$(IDPRUN) 'set -e; \
		$(XAS) -o build/demo1/crt0-partner.rel samples/demo1/src/crt0-partner.s; \
		$(XCC) $(XCFLAGS) -c -o build/demo1/main-partner.rel samples/demo1/src/main.c; \
		$(XCC) $(XLDFLAGS) -o bin/demo1/$(TARGET).com \
			build/demo1/crt0-partner.rel build/demo1/main-partner.rel \
			bin/partner/libgpx.lib -Wl,--oformat=binary \
			-Wl,-b,_CODE=$(PARTNER_LOAD_HEX)'

clean:
	rm -rf "$(BUILD_DIR)" "$(BIN_DIR)"
