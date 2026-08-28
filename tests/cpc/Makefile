ROOT_DIR ?= $(abspath ../..)
BUILD_DIR ?= $(ROOT_DIR)/build

include $(ROOT_DIR)/scripts/mk/toolchain.mk

PYTHON ?= python3
ARGS ?=

# One library, two modes: each scenario is built twice, differing only in
# the mode it hands gpx_create(). xcc's -D takes integers, so these are the
# numeric values of GPXM_CPC_640X200 and GPXM_CPC_320X200.
CPC_TEST_SRCS := $(filter-out %/cpctest.c, \
	$(wildcard $(ROOT_DIR)/tests/cpc/src/*.c))
CPC_TEST_NAMES := $(patsubst $(ROOT_DIR)/tests/cpc/src/%.c,%,$(CPC_TEST_SRCS))
CPC_LIB_SRCS := $(wildcard $(ROOT_DIR)/src/cpc/*.s) \
	$(wildcard $(ROOT_DIR)/src/cpc/*.inc) \
	$(ADVANCED_SRCS)
CPC_IMG_DIR := $(BUILD_DIR)/cpc-tests
CPC_STAMP := $(CPC_IMG_DIR)/.built.stamp
CODE_LOC ?= 0x8000

CPC_BENCH_SRCS := $(wildcard $(ROOT_DIR)/tests/cpc/bench-src/bench_*.c)
CPC_BENCH_NAMES := $(patsubst $(ROOT_DIR)/tests/cpc/bench-src/%.c,%,$(CPC_BENCH_SRCS))
CPC_BENCH_DIR := $(BUILD_DIR)/cpc-bench
CPC_BENCH_STAMP := $(CPC_BENCH_DIR)/.built.stamp

.PHONY: build run bench bench-build clean

build: $(CPC_STAMP)

run: build
	$(PYTHON) $(ROOT_DIR)/tests/mcp/run_cpc_tests.py $(ARGS)

$(CPC_IMG_DIR)/:
	mkdir -p $@

$(CPC_STAMP): $(CPC_TEST_SRCS) $(ROOT_DIR)/tests/cpc/src/cpctest.h \
		$(ROOT_DIR)/tests/cpc/src/cpctest.c $(CPC_LIB_SRCS) | $(CPC_IMG_DIR)/
	$(MAKE) -C $(ROOT_DIR)/src cpc-lib-objs
	$(CPCRUN) 'set -e; \
		for name in $(CPC_TEST_NAMES); do \
			for m in 0 1; do \
				case $$m in 0) tag=640x200;; 1) tag=320x200;; esac; \
				$(XCC) $(XCFLAGS) -Itests/cpc/src -DDEMO_MODE=$$m \
					-c -o build/cpc-tests/$$name-$$tag.rel \
					tests/cpc/src/$$name.c; \
				$(XCC) $(XCFLAGS) -Itests/cpc/src \
					-c -o build/cpc-tests/cpctest-$$tag.rel \
					tests/cpc/src/cpctest.c; \
				$(XLD) --oformat=binary -b _CODE=$(CODE_LOC) -nostartfiles \
					-Map=build/cpc-tests/$$name-$$tag.map \
					-o build/cpc-tests/$$name-$$tag.bin \
					build/cpc/crt0-cpc.rel \
					build/cpc-tests/$$name-$$tag.rel \
					build/cpc-tests/cpctest-$$tag.rel \
					$$(ls build/cpc/*.rel | grep -v crt0-cpc); \
			done; \
		done'
	touch $@

bench-build: $(CPC_BENCH_STAMP)

bench: bench-build
	$(PYTHON) $(ROOT_DIR)/tests/mcp/bench_cpc.py $(ARGS)

$(CPC_BENCH_DIR)/:
	mkdir -p $@

$(CPC_BENCH_STAMP): $(CPC_BENCH_SRCS) \
		$(ROOT_DIR)/tests/cpc/bench-src/bench.h $(CPC_LIB_SRCS) \
		| $(CPC_BENCH_DIR)/
	$(MAKE) -C $(ROOT_DIR)/src cpc-lib-objs
	$(CPCRUN) 'set -e; \
		for name in $(CPC_BENCH_NAMES); do \
			for m in 0 1; do \
				case $$m in 0) tag=640x200;; 1) tag=320x200;; esac; \
				$(XCC) $(XCFLAGS) -Itests/cpc/bench-src -DDEMO_MODE=$$m \
					-c -o build/cpc-bench/$$name-$$tag.rel \
					tests/cpc/bench-src/$$name.c; \
				$(XLD) --oformat=binary -b _CODE=$(CODE_LOC) -nostartfiles \
					-Map=build/cpc-bench/$$name-$$tag.map \
					-o build/cpc-bench/$$name-$$tag.bin \
					build/cpc/crt0-cpc.rel \
					build/cpc-bench/$$name-$$tag.rel \
					$$(ls build/cpc/*.rel | grep -v crt0-cpc); \
			done; \
		done'
	touch $@

clean:
	rm -rf $(CPC_IMG_DIR) $(CPC_BENCH_DIR)
