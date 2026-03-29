ROOT_DIR ?= $(abspath ../..)
BUILD_DIR ?= $(ROOT_DIR)/build
TEST_BUILD_DIR ?= $(BUILD_DIR)/tests

TEST_EMULATOR := $(TEST_BUILD_DIR)/test_emulator
TEST_EMULATOR_COV := $(TEST_BUILD_DIR)/test_emulator_cov

.PHONY: build run coverage-build coverage-run clean

build: $(TEST_EMULATOR)

run: $(TEST_EMULATOR)
	cd $(ROOT_DIR) && $(TEST_EMULATOR)

coverage-build: $(TEST_EMULATOR_COV)

coverage-run: $(TEST_EMULATOR_COV)
	cd $(ROOT_DIR) && $(TEST_EMULATOR_COV)

$(TEST_BUILD_DIR)/:
	mkdir -p $@

$(TEST_EMULATOR): $(ROOT_DIR)/tests/test_emulator.cpp $(ROOT_DIR)/tests/zx/test-src/test_emulator_unit.cpp $(ROOT_DIR)/tests/emulator.cpp $(ROOT_DIR)/tests/emulator.hpp $(ROOT_DIR)/tests/z80.hpp | $(TEST_BUILD_DIR)/
	g++ -std=c++17 -DLIBGPX_UNIT_NO_MAIN -I$(ROOT_DIR)/include -I$(ROOT_DIR)/tests -O2 -Wall -Wextra -o $@ $(ROOT_DIR)/tests/test_emulator.cpp $(ROOT_DIR)/tests/zx/test-src/test_emulator_unit.cpp $(ROOT_DIR)/tests/emulator.cpp

$(TEST_EMULATOR_COV): $(ROOT_DIR)/tests/test_emulator.cpp $(ROOT_DIR)/tests/zx/test-src/test_emulator_unit.cpp $(ROOT_DIR)/tests/emulator.cpp $(ROOT_DIR)/tests/emulator.hpp $(ROOT_DIR)/tests/z80.hpp | $(TEST_BUILD_DIR)/
	g++ -std=c++17 --coverage -DLIBGPX_UNIT_NO_MAIN -I$(ROOT_DIR)/include -I$(ROOT_DIR)/tests -O0 -Wall -Wextra -o $@ $(ROOT_DIR)/tests/test_emulator.cpp $(ROOT_DIR)/tests/zx/test-src/test_emulator_unit.cpp $(ROOT_DIR)/tests/emulator.cpp

clean:
	rm -f $(TEST_EMULATOR) $(TEST_EMULATOR_COV) $(TEST_EMULATOR_COV)-*.gcda $(TEST_EMULATOR_COV)-*.gcno
