ROOT_DIR ?= $(abspath ..)
BUILD_DIR ?= $(ROOT_DIR)/build
TEST_BUILD_DIR ?= $(BUILD_DIR)/tests

TEST_EMULATOR_COV := $(TEST_BUILD_DIR)/test_emulator_cov
TEST_ZX_API_HOST_COV := $(TEST_BUILD_DIR)/test_zx_api_host_cov

.PHONY: build tests visual-inputs coverage stub-visuals lib-visuals lib-size clean

build:
	$(MAKE) -C host build
	$(MAKE) -C zx build

tests: visual-inputs
	$(MAKE) -C host run

visual-inputs:
	$(MAKE) -C zx visual-inputs

coverage: visual-inputs
	mkdir -p $(BUILD_DIR)/coverage
	find $(TEST_BUILD_DIR) -maxdepth 1 -name '*.gcda' -delete
	find $(TEST_BUILD_DIR) -maxdepth 1 -name '*.gcno' -delete
	rm -f $(BUILD_DIR)/coverage/*.gcov
	$(MAKE) -B -C host coverage-build
	$(MAKE) -B -C zx/stub host-test-cov
	$(MAKE) -C host coverage-run
	$(MAKE) -C zx/stub run-host-test-cov
	cd $(BUILD_DIR)/coverage && gcov -b -c -f $(TEST_EMULATOR_COV)-emulator.gcno $(TEST_EMULATOR_COV)-test_emulator.gcno $(TEST_EMULATOR_COV)-test_emulator_unit.gcno $(TEST_ZX_API_HOST_COV)-gpx_stub.gcno $(TEST_ZX_API_HOST_COV)-test_zx_api_host.gcno | tee gcov-summary.txt

stub-visuals:
	$(MAKE) -C zx/stub stub-visuals

lib-visuals: visual-inputs
	$(MAKE) -C zx/debug lib-visuals

lib-size:
	$(MAKE) -C size lib-size

clean:
	$(MAKE) -C host clean
	$(MAKE) -C zx clean
	$(MAKE) -C zx/stub clean
	$(MAKE) -C zx/debug clean
	$(MAKE) -C size clean
