ROOT_DIR ?= $(abspath ../..)
DEMO_BUILD_DIR := $(ROOT_DIR)/build/demo2
DEMO_BIN_DIR := $(ROOT_DIR)/bin/demo2
DOCKER_PARTNER ?= wischner/sdcc-z80-idp
DOCKER_USER ?= $(shell id -u):$(shell id -g)

TARGET ?= demo2
LOAD_ADDR_HEX ?= 0x100

APP_MAIN_SRC := $(ROOT_DIR)/samples/demo2/src/main.c
APP_CRT0_SRC := $(ROOT_DIR)/samples/demo2/src/crt0.s

APP_MAIN_REL := $(DEMO_BUILD_DIR)/main.rel
APP_CRT0_REL := $(DEMO_BUILD_DIR)/crt0.rel
APP_IHX := $(DEMO_BUILD_DIR)/$(TARGET).ihx
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
	docker run --rm -u $(DOCKER_USER) -v "$(ROOT_DIR)":/work -w /work $(DOCKER_PARTNER) sh -lc '/opt/sdcc/bin/sdcc -mz80 --std-c11 --no-std-crt0 -Iinclude -c -o "build/demo2/main.rel" "samples/demo2/src/main.c"'

$(APP_CRT0_REL): $(APP_CRT0_SRC) | $(DEMO_BUILD_DIR)
	docker run --rm -u $(DOCKER_USER) -v "$(ROOT_DIR)":/work -w /work $(DOCKER_PARTNER) sh -lc '/opt/sdcc/bin/sdasz80 -o "build/demo2/crt0.rel" "samples/demo2/src/crt0.s"'

$(APP_IHX): $(APP_CRT0_REL) $(APP_MAIN_REL) $(LIBGPX_LIB) | $(DEMO_BUILD_DIR)
	docker run --rm -u $(DOCKER_USER) -v "$(ROOT_DIR)":/work -w /work $(DOCKER_PARTNER) sh -lc '/opt/sdcc/bin/sdcc -mz80 --no-std-crt0 --code-loc $(LOAD_ADDR_HEX) -o "build/demo2/$(TARGET).ihx" "build/demo2/crt0.rel" "build/demo2/main.rel" "bin/partner/libgpx.lib"'

$(APP_COM): $(APP_IHX) | $(DEMO_BIN_DIR)
	docker run --rm -u $(DOCKER_USER) -v "$(ROOT_DIR)":/work -w /work $(DOCKER_PARTNER) sh -lc '/opt/sdcc/bin/sdobjcopy -I ihex -O binary "build/demo2/$(TARGET).ihx" "bin/demo2/$(TARGET).com"'

clean:
	rm -rf "$(DEMO_BUILD_DIR)" "$(DEMO_BIN_DIR)"
