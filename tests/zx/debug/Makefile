ROOT_DIR ?= $(abspath ../../..)
BUILD_DIR ?= $(ROOT_DIR)/build
TEST_BUILD_DIR ?= $(BUILD_DIR)/tests

TEST_EXPORT_LIB_VISUALS := $(TEST_BUILD_DIR)/export_lib_visuals

.PHONY: build lib-visuals clean

build: $(TEST_EXPORT_LIB_VISUALS)

lib-visuals: $(TEST_EXPORT_LIB_VISUALS)
	python3 $(ROOT_DIR)/tests/zx/debug/generate_lib_visuals.py

$(TEST_BUILD_DIR)/:
	mkdir -p $@

$(TEST_EXPORT_LIB_VISUALS): $(ROOT_DIR)/tests/zx/debug/export_lib_visuals.cpp $(ROOT_DIR)/tests/emulator.cpp $(ROOT_DIR)/tests/emulator.hpp $(ROOT_DIR)/tests/z80.hpp | $(TEST_BUILD_DIR)/
	g++ -std=c++17 -I$(ROOT_DIR)/include -I$(ROOT_DIR)/tests -O2 -Wall -Wextra -o $@ $(ROOT_DIR)/tests/zx/debug/export_lib_visuals.cpp $(ROOT_DIR)/tests/emulator.cpp

clean:
	rm -f $(TEST_EXPORT_LIB_VISUALS)
