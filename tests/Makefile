ROOT_DIR ?= $(abspath ..)
BUILD_DIR ?= $(ROOT_DIR)/build
TEST_BUILD_DIR ?= $(BUILD_DIR)/tests

TEST_ZX_API_HOST_COV := $(TEST_BUILD_DIR)/test_zx_api_host_cov

PYTHON ?= python3
ARGS ?=
ZX_RUNNER := $(ROOT_DIR)/tests/mcp/run_zx_tests.py
ZX_BENCH := $(ROOT_DIR)/tests/mcp/bench_zx.py
ZX_CAPTURE := $(ROOT_DIR)/tests/mcp/capture_zx.py

.PHONY: build tests zx-tests zx-bench visual-inputs coverage stub-visuals lib-visuals partner-visuals lib-size clean

build:
	$(MAKE) -C zx build
	$(MAKE) -C partner build

# ZX scenarios run on the cycle-accurate emulator behind zx-spectrum-mcp;
# the Partner backend still uses the in-repo EF9367 host harness.
tests: zx-tests
	$(MAKE) -C partner run

zx-tests:
	$(MAKE) -C zx build
	$(PYTHON) $(ZX_RUNNER)

zx-bench:
	$(MAKE) -C zx bench
	$(PYTHON) $(ZX_BENCH) $(ARGS)

visual-inputs:
	$(MAKE) -C zx build

coverage:
	mkdir -p $(BUILD_DIR)/coverage
	find $(TEST_BUILD_DIR) -maxdepth 1 -name '*.gcda' -delete
	find $(TEST_BUILD_DIR) -maxdepth 1 -name '*.gcno' -delete
	rm -f $(BUILD_DIR)/coverage/*.gcov
	$(MAKE) -B -C zx/stub host-test-cov
	$(MAKE) -C zx/stub run-host-test-cov
	cd $(BUILD_DIR)/coverage && gcov -b -c -f $(TEST_ZX_API_HOST_COV)-gpx_stub.gcno $(TEST_ZX_API_HOST_COV)-test_zx_api_host.gcno | tee gcov-summary.txt

stub-visuals:
	$(MAKE) -C zx/stub stub-visuals

lib-visuals:
	$(MAKE) -C zx build
	$(PYTHON) $(ZX_CAPTURE)

partner-visuals:
	$(MAKE) -C partner partner-visuals

lib-size:
	$(MAKE) -C size lib-size ARGS="$(ARGS)"

clean:
	$(MAKE) -C zx clean
	$(MAKE) -C partner clean
	$(MAKE) -C zx/stub clean
	$(MAKE) -C size clean
