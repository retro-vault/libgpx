ROOT_DIR ?= $(abspath ../..)
BUILD_DIR ?= $(ROOT_DIR)/build
BIN_DIR ?= $(ROOT_DIR)/bin
BUILD_TMP ?= $(BUILD_DIR)/tmp

include $(ROOT_DIR)/scripts/mk/toolchain.mk

# Scenarios link at 0x8000 so they run from real 48K RAM under the emulator
# behind zx-spectrum-mcp, where 0x0000-0x3FFF is ROM.
CODE_LOC ?= 0x8000

ZX_TEST_SRCS := $(wildcard $(ROOT_DIR)/tests/zx/test-src/test_*.c)
ZX_TEST_NAMES := $(patsubst $(ROOT_DIR)/tests/zx/test-src/%.c,%,$(ZX_TEST_SRCS))
ZX_TEST_HDRS := $(wildcard $(ROOT_DIR)/tests/zx/test-src/*.h)
ZX_BENCH_SRCS := $(wildcard $(ROOT_DIR)/tests/zx/bench-src/bench_*.c)
ZX_BENCH_NAMES := $(patsubst $(ROOT_DIR)/tests/zx/bench-src/%.c,%,$(ZX_BENCH_SRCS))
ZX_BENCH_HDRS := $(wildcard $(ROOT_DIR)/tests/zx/bench-src/*.h)
ZX_BENCH_STAMP := $(BUILD_DIR)/zx-bench/.built.stamp
BIN_ZX_BENCH_IHXS := $(addprefix $(BIN_DIR)/zx-bench/,$(addsuffix .ihx,$(ZX_BENCH_NAMES)))
BIN_ZX_BENCH_MAPS := $(BIN_ZX_BENCH_IHXS:.ihx=.map)
ZX_REAL_TESTS_STAMP := $(BUILD_DIR)/zx/.tests-built.stamp
ZX_ORACLE_TESTS_STAMP := $(BUILD_DIR)/zx-oracle/.tests-built.stamp
# Relink scenarios whenever the backend they link against changes.
ZX_LIB_STAMP := $(BUILD_DIR)/zx/.lib-objs.stamp
ZX_LIB_SRCS := $(wildcard $(ROOT_DIR)/src/zx/*.s) $(wildcard $(ROOT_DIR)/src/zx/*.c) \
	$(ADVANCED_SRCS)

BIN_ZX_TEST_IHXS := $(addprefix $(BIN_DIR)/zx/,$(addsuffix .ihx,$(ZX_TEST_NAMES)))
BIN_ZX_ORACLE_TEST_IHXS := $(addprefix $(BIN_DIR)/zx-oracle/,$(addsuffix .ihx,$(ZX_TEST_NAMES)))
# The runner takes each image's entry point from its map.
BIN_ZX_TEST_MAPS := $(BIN_ZX_TEST_IHXS:.ihx=.map)
BIN_ZX_ORACLE_TEST_MAPS := $(BIN_ZX_ORACLE_TEST_IHXS:.ihx=.map)

.PHONY: build one bench visual-inputs tests clean
.PRECIOUS: $(BUILD_DIR)/%/ $(BIN_DIR)/%/ $(BUILD_TMP)/
# The images under build/ are produced by a stamp rule and consumed by the
# copy into bin/. Without this make treats them as intermediates and deletes
# them, and the next build fails its existence check.
.SECONDARY:

build: $(BIN_ZX_TEST_IHXS) $(BIN_ZX_ORACLE_TEST_IHXS) \
	$(BIN_ZX_TEST_MAPS) $(BIN_ZX_ORACLE_TEST_MAPS)

visual-inputs: build

tests: build

bench: $(BIN_ZX_BENCH_IHXS) $(BIN_ZX_BENCH_MAPS)

# Rebuild a single scenario (real + oracle) without touching the rest:
#   make -C tests/zx one TEST=test_line_octants
one:
	@test -n "$(TEST)" || { echo "usage: make one TEST=test_name" >&2; exit 2; }
	$(MAKE) -C $(ROOT_DIR)/src zx-lib-objs
	@mkdir -p $(BUILD_DIR)/zx $(BUILD_DIR)/zx-oracle $(BUILD_TMP) $(BIN_DIR)/zx $(BIN_DIR)/zx-oracle
	$(ZXRUN) 'set -e; \
		$(XCC) $(XCFLAGS) -c -o "build/tmp/$(TEST).rel" "tests/zx/test-src/$(TEST).c"; \
		$(XCC) $(XLDFLAGS) -o "build/zx/$(TEST).ihx" "build/tmp/$(TEST).rel" build/zx/*.rel \
			-Wl,--oformat=ihx -Wl,-b,_CODE=$(CODE_LOC) -Wl,-Map=build/zx/$(TEST).map; \
		[ build/tmp/gpx_stub_oracle.rel -nt tests/zx/stub/gpx_stub.c ] || \
			$(XCC) $(XCFLAGS) -c -o build/tmp/gpx_stub_oracle.rel tests/zx/stub/gpx_stub.c; \
		$(XCC) $(XLDFLAGS) -o "build/zx-oracle/$(TEST).ihx" "build/tmp/$(TEST).rel" \
			build/tmp/gpx_stub_oracle.rel build/zx/_gpx_font_envy.rel \
			-Wl,--oformat=ihx -Wl,-b,_CODE=$(CODE_LOC) -Wl,-Map=build/zx-oracle/$(TEST).map'
	cp $(BUILD_DIR)/zx/$(TEST).ihx $(BUILD_DIR)/zx/$(TEST).map $(BIN_DIR)/zx/
	cp $(BUILD_DIR)/zx-oracle/$(TEST).ihx $(BUILD_DIR)/zx-oracle/$(TEST).map $(BIN_DIR)/zx-oracle/

$(BUILD_DIR)/%/:
	mkdir -p $@

$(BIN_DIR)/%/:
	mkdir -p $@

$(BUILD_TMP)/:
	mkdir -p $@

# Real backend: every scenario linked against the assembler library in src/zx.
$(ZX_REAL_TESTS_STAMP): $(ZX_TEST_SRCS) $(ZX_TEST_HDRS) $(ZX_LIB_SRCS) | $(BUILD_DIR)/zx/ $(BUILD_TMP)/
	$(MAKE) -C $(ROOT_DIR)/src zx-lib-objs
	$(ZXRUN) 'set -e; \
		for src in tests/zx/test-src/test_*.c; do \
			name="$$(basename "$$src" .c)"; \
			$(XCC) $(XCFLAGS) -c -o "build/tmp/$$name.rel" "$$src"; \
			$(XCC) $(XLDFLAGS) -o "build/zx/$$name.ihx" "build/tmp/$$name.rel" build/zx/*.rel \
				-Wl,--oformat=ihx -Wl,-b,_CODE=$(CODE_LOC) -Wl,-Map=build/zx/$$name.map; \
		done'
	touch $@

$(BUILD_DIR)/zx/%.ihx: $(ZX_REAL_TESTS_STAMP)
	@test -f "$@"

$(BIN_DIR)/zx/%.ihx: $(BUILD_DIR)/zx/%.ihx | $(BIN_DIR)/zx/
	cp "$<" "$@"

$(BUILD_DIR)/zx/%.map: $(ZX_REAL_TESTS_STAMP)
	@test -f "$@"

$(BIN_DIR)/zx/%.map: $(BUILD_DIR)/zx/%.map | $(BIN_DIR)/zx/
	cp "$<" "$@"

# Oracle: the same scenarios linked against the independent C reference in
# tests/zx/stub, which shares only the real font blob.
$(ZX_ORACLE_TESTS_STAMP): $(ZX_TEST_SRCS) $(ZX_TEST_HDRS) $(ROOT_DIR)/tests/zx/stub/gpx_stub.c $(ZX_LIB_SRCS) | $(BUILD_DIR)/zx-oracle/ $(BUILD_TMP)/
	$(MAKE) -C $(ROOT_DIR)/src zx-lib-objs
	$(ZXRUN) 'set -e; \
		$(XCC) $(XCFLAGS) -c -o build/tmp/gpx_stub_oracle.rel tests/zx/stub/gpx_stub.c; \
		for src in tests/zx/test-src/test_*.c; do \
			name="$$(basename "$$src" .c)"; \
			$(XCC) $(XCFLAGS) -c -o "build/tmp/$$name.rel" "$$src"; \
			$(XCC) $(XLDFLAGS) -o "build/zx-oracle/$$name.ihx" "build/tmp/$$name.rel" \
				build/tmp/gpx_stub_oracle.rel build/zx/_gpx_font_envy.rel \
				-Wl,--oformat=ihx -Wl,-b,_CODE=$(CODE_LOC) -Wl,-Map=build/zx-oracle/$$name.map; \
		done'
	touch $@

$(BUILD_DIR)/zx-oracle/%.ihx: $(ZX_ORACLE_TESTS_STAMP)
	@test -f "$@"

$(BIN_DIR)/zx-oracle/%.ihx: $(BUILD_DIR)/zx-oracle/%.ihx | $(BIN_DIR)/zx-oracle/
	cp "$<" "$@"

$(BUILD_DIR)/zx-oracle/%.map: $(ZX_ORACLE_TESTS_STAMP)
	@test -f "$@"

$(BIN_DIR)/zx-oracle/%.map: $(BUILD_DIR)/zx-oracle/%.map | $(BIN_DIR)/zx-oracle/
	cp "$<" "$@"

# Benchmarks link against the real backend only: there is nothing to
# compare them against, the emulator's T-state counter is the measurement.
$(ZX_BENCH_STAMP): $(ZX_BENCH_SRCS) $(ZX_BENCH_HDRS) $(ZX_LIB_SRCS) | $(BUILD_DIR)/zx-bench/ $(BUILD_TMP)/
	$(MAKE) -C $(ROOT_DIR)/src zx-lib-objs
	$(ZXRUN) 'set -e; \
		for src in tests/zx/bench-src/bench_*.c; do \
			name="$$(basename "$$src" .c)"; \
			$(XCC) $(XCFLAGS) -c -o "build/tmp/$$name.rel" "$$src"; \
			$(XCC) $(XLDFLAGS) -o "build/zx-bench/$$name.ihx" "build/tmp/$$name.rel" build/zx/*.rel \
				-Wl,--oformat=ihx -Wl,-b,_CODE=$(CODE_LOC) -Wl,-Map=build/zx-bench/$$name.map; \
		done'
	touch $@

$(BUILD_DIR)/zx-bench/%.ihx: $(ZX_BENCH_STAMP)
	@test -f "$@"

$(BUILD_DIR)/zx-bench/%.map: $(ZX_BENCH_STAMP)
	@test -f "$@"

$(BIN_DIR)/zx-bench/%.ihx: $(BUILD_DIR)/zx-bench/%.ihx | $(BIN_DIR)/zx-bench/
	cp "$<" "$@"

$(BIN_DIR)/zx-bench/%.map: $(BUILD_DIR)/zx-bench/%.map | $(BIN_DIR)/zx-bench/
	cp "$<" "$@"

clean:
	rm -f $(ZX_REAL_TESTS_STAMP) $(ZX_ORACLE_TESTS_STAMP) $(ZX_BENCH_STAMP)
	rm -rf $(BIN_DIR)/zx-bench $(BUILD_DIR)/zx-bench
	rm -f $(BUILD_DIR)/zx/test_*.ihx $(BUILD_DIR)/zx/test_*.map
	rm -f $(BUILD_DIR)/zx-oracle/test_*.ihx $(BUILD_DIR)/zx-oracle/test_*.map
	rm -f $(BUILD_TMP)/test_*.rel $(BUILD_TMP)/gpx_stub_oracle.rel
	rm -rf $(BIN_DIR)/zx $(BIN_DIR)/zx-oracle $(BUILD_DIR)/zx-oracle
