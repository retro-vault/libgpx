ROOT_DIR ?= $(abspath ..)
BUILD_DIR ?= $(ROOT_DIR)/build
TEST_BUILD_DIR ?= $(BUILD_DIR)/tests

TEST_ZX_API_HOST_COV := $(TEST_BUILD_DIR)/test_zx_api_host_cov

PYTHON ?= python3
ARGS ?=
ZX_RUNNER := $(ROOT_DIR)/tests/mcp/run_zx_tests.py
ZX_BENCH := $(ROOT_DIR)/tests/mcp/bench_zx.py
ZX_CAPTURE := $(ROOT_DIR)/tests/mcp/capture_zx.py
PARTNER_RUNNER := $(ROOT_DIR)/tests/mcp/run_partner_tests.py
PARTNER_BENCH := $(ROOT_DIR)/tests/mcp/bench_partner.py

.PHONY: cpc-tests cpc-bench build tests zx-tests zx-bench partner-gdp-tests partner-gdp-bench conformance visual-inputs coverage stub-visuals lib-visuals partner-visuals lib-size clean crossbench

build:
	$(MAKE) -C zx build
	$(MAKE) -C partner build
	$(MAKE) -C cpc build

# ZX scenarios run on the cycle-accurate emulator behind zx-spectrum-mcp.
# The Partner backend runs twice: against the in-repo EF9367 host harness,
# and against the real emulated GDP behind idp-mcp.
tests: zx-tests
	$(MAKE) -C partner run
	$(MAKE) partner-gdp-tests
	$(MAKE) cpc-tests
	$(MAKE) conformance

# The CPC scenarios run on amstrad-cpc-mcp, once per display mode, and are
# compared against golden rasters read straight out of display memory.
cpc-tests:
	$(MAKE) -C cpc run ARGS="$(ARGS)"

cpc-bench:
	$(MAKE) -C cpc bench ARGS="$(ARGS)" 

# One program, every backend, compared pixel for pixel against the ZX. The CPC
# is run in both display modes and must match exactly. Anything built on top of
# libgpx has to behave the same on every machine, so this is the gate that
# keeps them from drifting apart.
conformance:
	$(MAKE) -C conformance run ARGS="$(ARGS)"

# The same picture, at fixed coordinates, timed on all three machines. The
# per-backend suites size their work from gpx_width()/gpx_height(), so their
# numbers cannot be put side by side; these can.
crossbench:
	$(MAKE) -C crossbench run ARGS="$(ARGS)"

# Partner scenarios on the real EF9367 inside the xcc-z80-idp image. Rasters
# are compared against tests/partner/gdp-golden; pass ARGS="--bless" to
# re-record them. See EMULATION.md before doing that.
partner-gdp-tests:
	$(MAKE) -C partner gdp
	$(PYTHON) $(PARTNER_RUNNER) $(ARGS)

partner-gdp-bench:
	$(MAKE) -C partner gdp-bench
	$(PYTHON) $(PARTNER_BENCH) $(ARGS)

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
