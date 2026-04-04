ROOT_DIR ?= $(abspath ../..)
DEMO_BUILD_DIR := $(ROOT_DIR)/build/demo1
DEMO_BIN_DIR := $(ROOT_DIR)/bin/demo1
DOCKER_SPEC ?= wischner/sdcc-z80-zx-spectrum
DOCKER_USER ?= $(shell id -u):$(shell id -g)

TARGET ?= demo1
LOAD_ADDR_HEX ?= 0x8000
LOAD_ADDR_DEC ?= $(shell printf '%d\n' $(LOAD_ADDR_HEX))

APP_MAIN_SRC := $(ROOT_DIR)/samples/demo1/src/main.c
APP_CRT0_SRC := $(ROOT_DIR)/samples/demo1/src/crt0.s

APP_MAIN_REL := $(DEMO_BUILD_DIR)/main.rel
APP_CRT0_REL := $(DEMO_BUILD_DIR)/crt0.rel
APP_IHX := $(DEMO_BUILD_DIR)/$(TARGET).ihx
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
	docker run --rm -u $(DOCKER_USER) -v "$(ROOT_DIR)":/work -w /work $(DOCKER_SPEC) sh -lc '/opt/sdcc/bin/sdcc -mz80 --std-c11 --no-std-crt0 -Iinclude -c -o "build/demo1/main.rel" "samples/demo1/src/main.c"'

$(APP_CRT0_REL): $(APP_CRT0_SRC) | $(DEMO_BUILD_DIR)
	docker run --rm -u $(DOCKER_USER) -v "$(ROOT_DIR)":/work -w /work $(DOCKER_SPEC) sh -lc '/opt/sdcc/bin/sdasz80 -o "build/demo1/crt0.rel" "samples/demo1/src/crt0.s"'

$(APP_IHX): $(APP_CRT0_REL) $(APP_MAIN_REL) $(LIBGPX_LIB) | $(DEMO_BUILD_DIR)
	docker run --rm -u $(DOCKER_USER) -v "$(ROOT_DIR)":/work -w /work $(DOCKER_SPEC) sh -lc '/opt/sdcc/bin/sdcc -mz80 --no-std-crt0 --code-loc $(LOAD_ADDR_HEX) -o "build/demo1/$(TARGET).ihx" "build/demo1/crt0.rel" "build/demo1/main.rel" "bin/libgpx.lib"'

$(APP_BIN): $(APP_IHX)
	docker run --rm -u $(DOCKER_USER) -v "$(ROOT_DIR)":/work -w /work $(DOCKER_SPEC) sh -lc '/opt/sdcc/bin/sdobjcopy -I ihex -O binary "build/demo1/$(TARGET).ihx" "build/demo1/$(TARGET).bin"'

$(APP_TAP): $(APP_BIN) | $(DEMO_BIN_DIR)
	docker run --rm -u $(DOCKER_USER) -v "$(ROOT_DIR)":/work -w /work $(DOCKER_SPEC) sh -lc '/usr/local/bin/bin2tap -b -a $(LOAD_ADDR_DEC) -r $(LOAD_ADDR_DEC) -o "bin/demo1/$(TARGET).tap" "build/demo1/$(TARGET).bin"'

clean:
	rm -rf "$(DEMO_BUILD_DIR)" "$(DEMO_BIN_DIR)"
