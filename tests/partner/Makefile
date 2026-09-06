ROOT_DIR ?= $(abspath ../..)
BUILD_DIR ?= $(ROOT_DIR)/build
TEST_BUILD_DIR ?= $(BUILD_DIR)/tests
BIN_DIR ?= $(ROOT_DIR)/bin
PARTNER_BUILD_DIR ?= $(BUILD_DIR)/partner-tests

include $(ROOT_DIR)/scripts/mk/toolchain.mk

PARTNER_TEST_SRCS := \
	$(ROOT_DIR)/tests/partner/test_partner_bmp.c \
	$(ROOT_DIR)/tests/partner/test_partner_line.c \
	$(ROOT_DIR)/tests/partner/test_partner_rect_fill.c \
	$(ROOT_DIR)/tests/partner/test_partner_api.c \
	$(ROOT_DIR)/tests/partner/test_partner_stress.c
PARTNER_HOST_SRCS := \
	$(ROOT_DIR)/tests/partner/test_partner_bmp_emulator.cpp \
	$(ROOT_DIR)/tests/partner/test_partner_line_emulator.cpp \
	$(ROOT_DIR)/tests/partner/test_partner_rect_fill_emulator.cpp \
	$(ROOT_DIR)/tests/partner/test_partner_api_emulator.cpp \
	$(ROOT_DIR)/tests/partner/test_partner_stress_emulator.cpp

PARTNER_TEST_RELS := $(patsubst $(ROOT_DIR)/tests/partner/%.c,$(PARTNER_BUILD_DIR)/%.rel,$(PARTNER_TEST_SRCS))
PARTNER_TEST_IHXS := $(patsubst $(ROOT_DIR)/tests/partner/%.c,$(PARTNER_BUILD_DIR)/%.ihx,$(PARTNER_TEST_SRCS))
PARTNER_HOST_TESTS := $(patsubst $(ROOT_DIR)/tests/partner/%.cpp,$(TEST_BUILD_DIR)/%,$(PARTNER_HOST_SRCS))
PARTNER_VIS_HARNESS := $(TEST_BUILD_DIR)/export_partner_visuals

# Scenarios that run on the real Partner GDP behind idp-mcp. They link at
# 0x8000 and HALT between phases; the runner captures the raster at each one.
GDP_CODE_LOC ?= 0x8000
GDP_SRCS := $(wildcard $(ROOT_DIR)/tests/partner/gdp-src/test_*.c)
GDP_NAMES := $(patsubst $(ROOT_DIR)/tests/partner/gdp-src/%.c,%,$(GDP_SRCS))
GDP_HDRS := $(wildcard $(ROOT_DIR)/tests/partner/gdp-src/*.h)
GDP_BENCH_SRCS := $(wildcard $(ROOT_DIR)/tests/partner/gdp-bench/bench_*.c)
GDP_BENCH_NAMES := $(patsubst $(ROOT_DIR)/tests/partner/gdp-bench/%.c,%,$(GDP_BENCH_SRCS))
GDP_BIN := $(BIN_DIR)/partner-gdp
GDP_IHXS := $(addprefix $(GDP_BIN)/,$(addsuffix .ihx,$(GDP_NAMES)))
GDP_MAPS := $(GDP_IHXS:.ihx=.map)
GDP_BENCH_IHXS := $(addprefix $(GDP_BIN)/,$(addsuffix .ihx,$(GDP_BENCH_NAMES)))
GDP_BENCH_MAPS := $(GDP_BENCH_IHXS:.ihx=.map)

PARTNER_ASM_SRCS := \
	$(ROOT_DIR)/src/partner/gpx_width.s \
	$(ROOT_DIR)/src/partner/gpx_height.s \
	$(ROOT_DIR)/src/partner/gpx_create.s \
	$(ROOT_DIR)/src/partner/gpx_destroy.s \
	$(ROOT_DIR)/src/partner/gpx_set_page.s \
	$(ROOT_DIR)/src/partner/gpx_set_text_background.s \
	$(ROOT_DIR)/src/partner/gpx_clrscr.s \
	$(ROOT_DIR)/src/partner/gpx_draw_pixel.s \
	$(ROOT_DIR)/src/partner/gpx_draw_bmp.s \
	$(ROOT_DIR)/src/partner/gpx_measure_text.s \
	$(ROOT_DIR)/src/partner/gpx_draw_text.s \
	$(ROOT_DIR)/src/partner/gpx_draw_line.s \
	$(ROOT_DIR)/src/partner/gpx_draw_rectangle.s \
	$(ROOT_DIR)/src/partner/gpx_show_sprite.s \
	$(ROOT_DIR)/src/partner/gpx_fill_rectangle.s \
	$(ROOT_DIR)/src/partner/_gpx_get_system_font.s \
	$(ROOT_DIR)/src/partner/_gpx_get_tiny_font.s \
	$(ROOT_DIR)/src/partner/_gpx_get_stock_bmp.s \
	$(ROOT_DIR)/src/partner/_gpx_cursors_tiny.s \
	$(ROOT_DIR)/src/partner/_gpx_bresenham_line.s \
	$(ROOT_DIR)/src/partner/_gpx_cohen_sutherland.s \
	$(ROOT_DIR)/src/partner/_ef9367.s \
	$(ROOT_DIR)/src/partner/_rect_helpers.s \
	$(ROOT_DIR)/src/partner/_qmath.s \
	$(ROOT_DIR)/src/partner/_gpx_font-unscii-8-tiny.s

PARTNER_ASM_RELS := $(patsubst $(ROOT_DIR)/src/partner/%.s,$(PARTNER_BUILD_DIR)/%.rel,$(PARTNER_ASM_SRCS))
PARTNER_COMMON_RELS := $(PARTNER_ASM_RELS)

.PHONY: build run helpers pattern-tests tiny-tests partner-visuals gdp gdp-bench gdp-tests clean

build: $(PARTNER_TEST_IHXS) $(PARTNER_HOST_TESTS)

gdp: $(GDP_IHXS) $(GDP_MAPS)

gdp-bench: $(GDP_BENCH_IHXS) $(GDP_BENCH_MAPS)

pattern-tests: gdp gdp-bench
	python3 $(ROOT_DIR)/tests/mcp/check_partner_patterns.py
	python3 $(ROOT_DIR)/tests/partner/test_fill_phase_mcp.py

tiny-tests:
	python3 $(ROOT_DIR)/tests/mcp/check_partner_tiny.py

gdp-tests: pattern-tests tiny-tests
	python3 $(ROOT_DIR)/tests/mcp/run_partner_tests.py $(ARGS)

helpers: gdp-bench $(TEST_BUILD_DIR)/test_partner_helpers_emulator
	cd $(ROOT_DIR) && $(TEST_BUILD_DIR)/test_partner_helpers_emulator

run: build
	cd $(ROOT_DIR) && $(TEST_BUILD_DIR)/test_partner_bmp_emulator
	cd $(ROOT_DIR) && $(TEST_BUILD_DIR)/test_partner_line_emulator
	cd $(ROOT_DIR) && $(TEST_BUILD_DIR)/test_partner_rect_fill_emulator
	cd $(ROOT_DIR) && $(TEST_BUILD_DIR)/test_partner_api_emulator
	cd $(ROOT_DIR) && $(TEST_BUILD_DIR)/test_partner_stress_emulator

partner-visuals: build $(PARTNER_VIS_HARNESS)
	python3 $(ROOT_DIR)/tests/partner/generate_partner_visuals.py

$(PARTNER_BUILD_DIR)/:
	mkdir -p $@

$(TEST_BUILD_DIR)/:
	mkdir -p $@

$(PARTNER_BUILD_DIR)/%.rel: $(ROOT_DIR)/src/partner/%.s | $(PARTNER_BUILD_DIR)/
	$(IDPRUN) '$(XAS) -o "$(REL)" "$(SRC)"'

$(PARTNER_BUILD_DIR)/%.rel: $(ROOT_DIR)/src/partner/%.c | $(PARTNER_BUILD_DIR)/
	$(IDPRUN) '$(XCC) $(XCFLAGS) -c -o "$(REL)" "$(SRC)"'

$(PARTNER_BUILD_DIR)/test_%.rel: $(ROOT_DIR)/tests/partner/test_%.c | $(PARTNER_BUILD_DIR)/
	$(IDPRUN) '$(XCC) $(XCFLAGS) -c -o "$(REL)" "$(SRC)"'

$(PARTNER_TEST_IHXS): $(PARTNER_BUILD_DIR)/%.ihx: $(PARTNER_BUILD_DIR)/%.rel $(PARTNER_COMMON_RELS) | $(PARTNER_BUILD_DIR)/
	$(IDPRUN) '$(XCC) $(XLDFLAGS) -o "$(REL)" $(INS) -Wl,--oformat=ihx'

$(TEST_BUILD_DIR)/test_%_emulator: $(ROOT_DIR)/tests/partner/test_%_emulator.cpp $(ROOT_DIR)/tests/partner/emulator.cpp $(ROOT_DIR)/tests/partner/emulator.hpp $(ROOT_DIR)/tests/partner/z80.hpp | $(TEST_BUILD_DIR)/
	g++ -std=c++17 -I$(ROOT_DIR)/include -I$(ROOT_DIR)/tests/partner -O2 -Wall -Wextra -o $@ $< $(ROOT_DIR)/tests/partner/emulator.cpp

$(PARTNER_VIS_HARNESS): $(ROOT_DIR)/tests/partner/export_partner_visuals.cpp $(ROOT_DIR)/tests/partner/emulator.cpp $(ROOT_DIR)/tests/partner/emulator.hpp $(ROOT_DIR)/tests/partner/z80.hpp | $(TEST_BUILD_DIR)/
	g++ -std=c++17 -I$(ROOT_DIR)/include -I$(ROOT_DIR)/tests/partner -O2 -Wall -Wextra -o $@ $(ROOT_DIR)/tests/partner/export_partner_visuals.cpp $(ROOT_DIR)/tests/partner/emulator.cpp

$(GDP_BIN)/:
	mkdir -p $@

# One rule for scenarios and benches: both link the whole backend.
$(GDP_BIN)/%.ihx: $(ROOT_DIR)/tests/partner/gdp-src/%.c $(GDP_HDRS) $(PARTNER_COMMON_RELS) | $(GDP_BIN)/ $(PARTNER_BUILD_DIR)/
	$(IDPRUN) 'set -e; \
		$(XCC) $(XCFLAGS) -Itests/partner/gdp-src -c -o "build/partner-tests/$*.rel" "tests/partner/gdp-src/$*.c"; \
		$(XCC) $(XLDFLAGS) -o "bin/partner-gdp/$*.ihx" "build/partner-tests/$*.rel" $(patsubst $(ROOT_DIR)/%,%,$(PARTNER_COMMON_RELS)) \
			-Wl,--oformat=ihx -Wl,-b,_CODE=$(GDP_CODE_LOC) -Wl,-Map=bin/partner-gdp/$*.map'

$(GDP_BIN)/%.ihx: $(ROOT_DIR)/tests/partner/gdp-bench/%.c $(GDP_HDRS) $(PARTNER_COMMON_RELS) | $(GDP_BIN)/ $(PARTNER_BUILD_DIR)/
	$(IDPRUN) 'set -e; \
		$(XCC) $(XCFLAGS) -Itests/partner/gdp-src -c -o "build/partner-tests/$*.rel" "tests/partner/gdp-bench/$*.c"; \
		$(XCC) $(XLDFLAGS) -o "bin/partner-gdp/$*.ihx" "build/partner-tests/$*.rel" $(patsubst $(ROOT_DIR)/%,%,$(PARTNER_COMMON_RELS)) \
			-Wl,--oformat=ihx -Wl,-b,_CODE=$(GDP_CODE_LOC) -Wl,-Map=bin/partner-gdp/$*.map'

$(GDP_MAPS): %.map: %.ihx
$(GDP_BENCH_MAPS): %.map: %.ihx

clean:
	rm -rf $(GDP_BIN)
	rm -rf $(PARTNER_BUILD_DIR)
	rm -f $(PARTNER_HOST_TESTS) $(PARTNER_VIS_HARNESS) $(TEST_BUILD_DIR)/test_partner_helpers_emulator
