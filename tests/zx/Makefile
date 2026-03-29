ROOT_DIR ?= $(abspath ../..)
BUILD_DIR ?= $(ROOT_DIR)/build
BIN_DIR ?= $(ROOT_DIR)/bin
BUILD_TMP ?= $(BUILD_DIR)/tmp
DOCKER_SPEC ?= wischner/sdcc-z80-zx-spectrum
DOCKER_USER ?= $(shell id -u):$(shell id -g)

ZX_TEST_SRCS := $(wildcard $(ROOT_DIR)/tests/zx/test-src/test_*.c)
ZX_TEST_NAMES := $(patsubst $(ROOT_DIR)/tests/zx/test-src/%.c,%,$(ZX_TEST_SRCS))
ZX_REAL_TESTS_STAMP := $(BUILD_DIR)/zx/.tests-built.stamp
ZX_ORACLE_TESTS_STAMP := $(BUILD_DIR)/zx-oracle/.tests-built.stamp

BIN_ZX_TEST_IHXS := $(addprefix $(BIN_DIR)/zx/,$(addsuffix .ihx,$(ZX_TEST_NAMES)))
BIN_ZX_TEST_BINS := $(patsubst %.ihx,%.bin,$(BIN_ZX_TEST_IHXS))
BIN_ZX_ORACLE_TEST_IHXS := $(addprefix $(BIN_DIR)/zx-oracle/,$(addsuffix .ihx,$(ZX_TEST_NAMES)))

.PHONY: build visual-inputs tests clean
.PRECIOUS: $(BUILD_DIR)/%/ $(BIN_DIR)/%/ $(BUILD_TMP)/

build: $(BIN_ZX_TEST_IHXS) $(BIN_ZX_TEST_BINS) $(BIN_ZX_ORACLE_TEST_IHXS)

visual-inputs: $(BIN_ZX_TEST_IHXS) $(BIN_ZX_ORACLE_TEST_IHXS)

tests: visual-inputs

$(BUILD_DIR)/%/:
	mkdir -p $@

$(BIN_DIR)/%/:
	mkdir -p $@

$(BUILD_TMP)/:
	mkdir -p $@

$(ZX_REAL_TESTS_STAMP): $(ZX_TEST_SRCS) | $(BUILD_DIR)/zx/ $(BUILD_TMP)/
	$(MAKE) -C $(ROOT_DIR)/src zx-lib-objs
	docker run --rm -u $(DOCKER_USER) -v "$(ROOT_DIR)":/work -w /work $(DOCKER_SPEC) sh -lc 'set -e; for src in tests/zx/test-src/test_*.c; do rel="build/tmp/$$(basename "$$src" .c).rel"; out="build/zx/$$(basename "$$src" .c).ihx"; /opt/sdcc/bin/sdcc -mz80 --no-std-crt0 -Iinclude -c -o "$$rel" "$$src"; /opt/sdcc/bin/sdcc -mz80 --no-std-crt0 -o "$$out" "$$rel" build/zx/*.rel; done'
	touch $@

$(BUILD_DIR)/zx/%.ihx: $(ZX_REAL_TESTS_STAMP)
	@test -f "$@"

$(BIN_DIR)/zx/%.ihx: $(BUILD_DIR)/zx/%.ihx | $(BIN_DIR)/zx/
	cp "$<" "$@"

$(BIN_DIR)/zx/%.bin: $(BIN_DIR)/zx/%.ihx | $(BIN_DIR)/zx/
	docker run --rm -u $(DOCKER_USER) -v "$(ROOT_DIR)":/work -w /work $(DOCKER_SPEC) sh -lc '/opt/sdcc/bin/sdobjcopy -I ihex -O binary "bin/zx/$*.ihx" "bin/zx/$*.bin"'

$(ZX_ORACLE_TESTS_STAMP): $(ZX_TEST_SRCS) $(ROOT_DIR)/tests/zx/stub/gpx_stub.c | $(BUILD_DIR)/zx-oracle/ $(BUILD_TMP)/
	$(MAKE) -C $(ROOT_DIR)/src zx-lib-objs
	docker run --rm -u $(DOCKER_USER) -v "$(ROOT_DIR)":/work -w /work $(DOCKER_SPEC) sh -lc 'set -e; /opt/sdcc/bin/sdcc -mz80 --no-std-crt0 -Iinclude -c -o build/tmp/gpx_stub_oracle.rel tests/zx/stub/gpx_stub.c; for src in tests/zx/test-src/test_*.c; do rel="build/tmp/$$(basename "$$src" .c).rel"; out="build/zx-oracle/$$(basename "$$src" .c).ihx"; /opt/sdcc/bin/sdcc -mz80 --no-std-crt0 -Iinclude -c -o "$$rel" "$$src"; /opt/sdcc/bin/sdcc -mz80 --no-std-crt0 -o "$$out" "$$rel" build/tmp/gpx_stub_oracle.rel build/zx/_gpx_font_envy.rel; done'
	touch $@

$(BUILD_DIR)/zx-oracle/%.ihx: $(ZX_ORACLE_TESTS_STAMP)
	@test -f "$@"

$(BIN_DIR)/zx-oracle/%.ihx: $(BUILD_DIR)/zx-oracle/%.ihx | $(BIN_DIR)/zx-oracle/
	cp "$<" "$@"

clean:
	rm -f $(ZX_REAL_TESTS_STAMP) $(ZX_ORACLE_TESTS_STAMP)
	rm -f $(BUILD_DIR)/zx/test_*.ihx $(BUILD_DIR)/zx-oracle/test_*.ihx
	rm -f $(BUILD_TMP)/test_*.rel $(BUILD_TMP)/gpx_stub_oracle.rel
	rm -rf $(BIN_DIR)/zx $(BIN_DIR)/zx-oracle $(BUILD_DIR)/zx-oracle
