ROOT_DIR ?= $(abspath ../..)
DEMO_BUILD_DIR := $(ROOT_DIR)/build/demo2
DEMO_BIN_DIR := $(ROOT_DIR)/bin/demo2
include $(ROOT_DIR)/mk/toolchain.mk

TARGET ?= demo2
LOAD_ADDR_HEX ?= 0x100

APP_MAIN_SRC := $(ROOT_DIR)/samples/demo2/src/main.c
APP_CRT0_SRC := $(ROOT_DIR)/samples/demo2/src/crt0.s

APP_MAIN_REL := $(DEMO_BUILD_DIR)/main.rel
APP_CRT0_REL := $(DEMO_BUILD_DIR)/crt0.rel
APP_COM := $(DEMO_BIN_DIR)/$(TARGET).com

LIBGPX_LIB := $(ROOT_DIR)/bin/partner/libgpx.lib

.PHONY: all build clean

all: $(APP_COM)

build: all

$(DEMO_BUILD_DIR):
	mkdir -p "$@"

$(DEMO_BIN_DIR):
	mkdir -p "$@"

$(LIBGPX_LIB):
	$(MAKE) -C $(ROOT_DIR)/src partner-lib

$(APP_MAIN_REL): $(APP_MAIN_SRC) | $(DEMO_BUILD_DIR)
	$(IDPRUN) '$(XCC) $(XCFLAGS) -c -o "build/demo2/main.rel" "samples/demo2/src/main.c"'

$(APP_CRT0_REL): $(APP_CRT0_SRC) | $(DEMO_BUILD_DIR)
	$(IDPRUN) '$(XAS) -o "build/demo2/crt0.rel" "samples/demo2/src/crt0.s"'

$(APP_COM): $(APP_CRT0_REL) $(APP_MAIN_REL) $(LIBGPX_LIB) | $(DEMO_BIN_DIR)
	$(IDPRUN) '$(XCC) $(XLDFLAGS) -o "bin/demo2/$(TARGET).com" "build/demo2/crt0.rel" "build/demo2/main.rel" "bin/partner/libgpx.lib" -Wl,--oformat=binary -Wl,-b,_CODE=$(LOAD_ADDR_HEX)'

clean:
	rm -rf "$(DEMO_BUILD_DIR)" "$(DEMO_BIN_DIR)"
