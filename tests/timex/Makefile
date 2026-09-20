ROOT_DIR ?= $(abspath ../..)
BUILD_DIR ?= $(ROOT_DIR)/build
BIN_DIR ?= $(ROOT_DIR)/bin
PYTHON ?= python3

include $(ROOT_DIR)/scripts/mk/toolchain.mk

TIMEX_LIB := $(BIN_DIR)/timex/libgpx.lib
TEST_REL := $(BUILD_DIR)/timex/test_timex.rel
TEST_IHX := $(BUILD_DIR)/timex/test_timex.ihx
TEST_MAP := $(BUILD_DIR)/timex/test_timex.map

.PHONY: build run clean

build: $(TEST_IHX)

run: build
	$(PYTHON) $(ROOT_DIR)/tests/timex/run-tests.py

$(TIMEX_LIB): $(ROOT_DIR)/src/Makefile \
		$(wildcard $(ROOT_DIR)/src/timex/*.s) \
		$(wildcard $(ROOT_DIR)/src/timex/*.inc) \
		$(CORE_ASM_SRCS) $(ADVANCED_SRCS) $(ADVANCED_WITNESS)
	$(MAKE) -C $(ROOT_DIR)/src timex-lib

$(BUILD_DIR)/timex/:
	mkdir -p $@

$(TEST_IHX): $(ROOT_DIR)/tests/timex/test_timex.c $(TIMEX_LIB) | $(BUILD_DIR)/timex/
	$(ZXRUN) 'set -e; \
		$(XCC) $(XCFLAGS) -c -o build/timex/test_timex.rel tests/timex/test_timex.c; \
		$(XCC) $(XLDFLAGS) -o build/timex/test_timex.ihx \
			build/timex/test_timex.rel bin/timex/libgpx.lib \
			-Wl,--oformat=ihx -Wl,-b,_CODE=0x8000 \
			-Wl,-Map=build/timex/test_timex.map'

clean:
	rm -f $(TEST_REL) $(TEST_IHX) $(TEST_MAP) $(BUILD_DIR)/timex/test_timex.bin
