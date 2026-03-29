ROOT_DIR ?= $(abspath ../..)
BUILD_DIR ?= $(ROOT_DIR)/build
BIN_DIR ?= $(ROOT_DIR)/bin
BUILD_TMP ?= $(BUILD_DIR)/tmp
DOCKER_SPEC ?= wischner/sdcc-z80-zx-spectrum
DOCKER_USER ?= $(shell id -u):$(shell id -g)

LIB_SIZE_ENTRY_SRC := $(ROOT_DIR)/tests/size/lib_size_main.c
LIB_SIZE_ENTRY_REL := $(BUILD_TMP)/lib_size_main.rel
LIB_SIZE_BASE_IHX := $(BUILD_DIR)/zx/libgpx_size_base.ihx
LIB_SIZE_BASE_BIN := $(BIN_DIR)/zx/libgpx_size_base.bin
LIB_SIZE_IHX := $(BUILD_DIR)/zx/libgpx_size.ihx
LIB_SIZE_BIN := $(BIN_DIR)/zx/libgpx_size.bin

.PHONY: lib-size clean
.PRECIOUS: $(BUILD_DIR)/%/ $(BIN_DIR)/%/ $(BUILD_TMP)/

lib-size: $(LIB_SIZE_BASE_BIN) $(LIB_SIZE_BIN)
	@base_bytes=$$(wc -c < "$(LIB_SIZE_BASE_BIN)"); \
	total_bytes=$$(wc -c < "$(LIB_SIZE_BIN)"); \
	lib_bytes=$$((total_bytes - base_bytes)); \
	echo "libgpx zx binary size (total): $$total_bytes bytes ($(LIB_SIZE_BIN))"; \
	echo "baseline entry size: $$base_bytes bytes ($(LIB_SIZE_BASE_BIN))"; \
	echo "estimated libgpx payload: $$lib_bytes bytes"; \
	echo "linker maps: $(BUILD_DIR)/zx/libgpx_size.map, $(BUILD_DIR)/zx/libgpx_size_base.map"

$(BUILD_DIR)/%/:
	mkdir -p $@

$(BIN_DIR)/%/:
	mkdir -p $@

$(BUILD_TMP)/:
	mkdir -p $@

$(LIB_SIZE_ENTRY_REL): $(LIB_SIZE_ENTRY_SRC) | $(BUILD_TMP)/
	docker run --rm -u $(DOCKER_USER) -v "$(ROOT_DIR)":/work -w /work $(DOCKER_SPEC) sh -lc '/opt/sdcc/bin/sdcc -mz80 --no-std-crt0 -Iinclude -c -o "build/tmp/lib_size_main.rel" "tests/size/lib_size_main.c"'

$(LIB_SIZE_BASE_IHX): $(LIB_SIZE_ENTRY_REL) | $(BUILD_DIR)/zx/
	docker run --rm -u $(DOCKER_USER) -v "$(ROOT_DIR)":/work -w /work $(DOCKER_SPEC) sh -lc '/opt/sdcc/bin/sdcc -mz80 --no-std-crt0 -Wl -m -o "build/zx/libgpx_size_base.ihx" "build/tmp/lib_size_main.rel"'

$(LIB_SIZE_BASE_BIN): $(LIB_SIZE_BASE_IHX) | $(BIN_DIR)/zx/
	docker run --rm -u $(DOCKER_USER) -v "$(ROOT_DIR)":/work -w /work $(DOCKER_SPEC) sh -lc '/opt/sdcc/bin/sdobjcopy -I ihex -O binary "build/zx/libgpx_size_base.ihx" "bin/zx/libgpx_size_base.bin"'

$(LIB_SIZE_IHX): $(LIB_SIZE_ENTRY_REL) | $(BUILD_DIR)/zx/
	$(MAKE) -C $(ROOT_DIR)/src zx-lib-objs
	docker run --rm -u $(DOCKER_USER) -v "$(ROOT_DIR)":/work -w /work $(DOCKER_SPEC) sh -lc '/opt/sdcc/bin/sdcc -mz80 --no-std-crt0 -Wl -m -o "build/zx/libgpx_size.ihx" "build/tmp/lib_size_main.rel" build/zx/*.rel'

$(LIB_SIZE_BIN): $(LIB_SIZE_IHX) | $(BIN_DIR)/zx/
	docker run --rm -u $(DOCKER_USER) -v "$(ROOT_DIR)":/work -w /work $(DOCKER_SPEC) sh -lc '/opt/sdcc/bin/sdobjcopy -I ihex -O binary "build/zx/libgpx_size.ihx" "bin/zx/libgpx_size.bin"'

clean:
	rm -f $(LIB_SIZE_ENTRY_REL) $(LIB_SIZE_BASE_IHX) $(LIB_SIZE_BASE_BIN) $(LIB_SIZE_IHX) $(LIB_SIZE_BIN) $(BUILD_DIR)/zx/libgpx_size.map $(BUILD_DIR)/zx/libgpx_size_base.map
