ROOT_DIR ?= $(abspath ../..)
DEMO_BUILD_DIR := $(ROOT_DIR)/build/demo1
DEMO_BIN_DIR := $(ROOT_DIR)/bin/demo1

include $(ROOT_DIR)/mk/toolchain.mk

TARGET ?= demo1
LOAD_ADDR_HEX ?= 0x8000
LOAD_ADDR_DEC ?= $(shell printf '%d\n' $(LOAD_ADDR_HEX))

APP_MAIN_SRC := $(ROOT_DIR)/samples/demo1/src/main.c
APP_CRT0_SRC := $(ROOT_DIR)/samples/demo1/src/crt0.s

APP_MAIN_REL := $(DEMO_BUILD_DIR)/main.rel
APP_CRT0_REL := $(DEMO_BUILD_DIR)/crt0.rel
APP_BIN := $(DEMO_BUILD_DIR)/$(TARGET).bin
APP_TAP := $(DEMO_BIN_DIR)/$(TARGET).tap

LIBGPX_LIB := $(ROOT_DIR)/bin/libgpx.lib

.PHONY: all build clean

all: $(APP_TAP)

build: all

$(DEMO_BUILD_DIR):
	mkdir -p "$@"

$(DEMO_BIN_DIR):
	mkdir -p "$@"

$(LIBGPX_LIB):
	$(MAKE) -C $(ROOT_DIR)/src lib

$(APP_MAIN_REL): $(APP_MAIN_SRC) | $(DEMO_BUILD_DIR)
	$(ZXRUN) '$(XCC) $(XCFLAGS) -c -o "build/demo1/main.rel" "samples/demo1/src/main.c"'

$(APP_CRT0_REL): $(APP_CRT0_SRC) | $(DEMO_BUILD_DIR)
	$(ZXRUN) '$(XAS) -o "build/demo1/crt0.rel" "samples/demo1/src/crt0.s"'

$(APP_BIN): $(APP_CRT0_REL) $(APP_MAIN_REL) $(LIBGPX_LIB) | $(DEMO_BUILD_DIR)
	$(ZXRUN) '$(XCC) $(XLDFLAGS) -o "build/demo1/$(TARGET).bin" "build/demo1/crt0.rel" "build/demo1/main.rel" "bin/libgpx.lib" -Wl,--oformat=binary -Wl,-b,_CODE=$(LOAD_ADDR_HEX)'

$(APP_TAP): $(APP_BIN) | $(DEMO_BIN_DIR)
	$(ZXRUN) 'xprog --tap "build/demo1/$(TARGET).bin" -o "bin/demo1/$(TARGET).tap" -n $(TARGET) --load-address $(LOAD_ADDR_DEC) --entry $(LOAD_ADDR_DEC)'

clean:
	rm -rf "$(DEMO_BUILD_DIR)" "$(DEMO_BIN_DIR)"
