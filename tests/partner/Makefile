ROOT_DIR ?= $(abspath ../..)
BUILD_DIR ?= $(ROOT_DIR)/build
TEST_BUILD_DIR ?= $(BUILD_DIR)/tests
PARTNER_BUILD_DIR ?= $(BUILD_DIR)/partner-tests

DOCKER_PARTNER ?= wischner/sdcc-z80-idp
DOCKER_USER ?= $(shell id -u):$(shell id -g)
SDCC ?= /opt/sdcc/bin/sdcc
SDASZ80 ?= /opt/sdcc/bin/sdasz80

# Run a toolchain command inside the partner SDCC image (paths are made
# repo-relative since the container mounts the repo root at /work).
DRUN := docker run --rm -u $(DOCKER_USER) -v "$(ROOT_DIR)":/work -w /work $(DOCKER_PARTNER) sh -lc
REL = $(patsubst $(ROOT_DIR)/%,%,$@)
SRC = $(patsubst $(ROOT_DIR)/%,%,$<)
INS = $(patsubst $(ROOT_DIR)/%,%,$^)

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

PARTNER_ASM_SRCS := \
	$(ROOT_DIR)/src/partner/gpx_width.s \
	$(ROOT_DIR)/src/partner/gpx_height.s \
	$(ROOT_DIR)/src/partner/gpx_create.s \
	$(ROOT_DIR)/src/partner/gpx_destroy.s \
	$(ROOT_DIR)/src/partner/gpx_set_page.s \
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
	$(ROOT_DIR)/src/partner/_gpx_font-12x16_tiny.s

PARTNER_ASM_RELS := $(patsubst $(ROOT_DIR)/src/partner/%.s,$(PARTNER_BUILD_DIR)/%.rel,$(PARTNER_ASM_SRCS))
PARTNER_COMMON_RELS := $(PARTNER_ASM_RELS)

.PHONY: build run partner-visuals clean

build: $(PARTNER_TEST_IHXS) $(PARTNER_HOST_TESTS)

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
	$(DRUN) '$(SDASZ80) -o "$(REL)" "$(SRC)"'

$(PARTNER_BUILD_DIR)/%.rel: $(ROOT_DIR)/src/partner/%.c | $(PARTNER_BUILD_DIR)/
	$(DRUN) '$(SDCC) -mz80 --no-std-crt0 -Iinclude -c -o "$(REL)" "$(SRC)"'

$(PARTNER_BUILD_DIR)/test_%.rel: $(ROOT_DIR)/tests/partner/test_%.c | $(PARTNER_BUILD_DIR)/
	$(DRUN) '$(SDCC) -mz80 --no-std-crt0 -Iinclude -c -o "$(REL)" "$(SRC)"'

$(PARTNER_TEST_IHXS): $(PARTNER_BUILD_DIR)/%.ihx: $(PARTNER_BUILD_DIR)/%.rel $(PARTNER_COMMON_RELS) | $(PARTNER_BUILD_DIR)/
	$(DRUN) '$(SDCC) -mz80 --no-std-crt0 -o "$(REL)" $(INS)'

$(TEST_BUILD_DIR)/test_%_emulator: $(ROOT_DIR)/tests/partner/test_%_emulator.cpp $(ROOT_DIR)/tests/emulator.cpp $(ROOT_DIR)/tests/emulator.hpp $(ROOT_DIR)/tests/z80.hpp | $(TEST_BUILD_DIR)/
	g++ -std=c++17 -I$(ROOT_DIR)/include -I$(ROOT_DIR)/tests -O2 -Wall -Wextra -o $@ $< $(ROOT_DIR)/tests/emulator.cpp

$(PARTNER_VIS_HARNESS): $(ROOT_DIR)/tests/partner/export_partner_visuals.cpp $(ROOT_DIR)/tests/emulator.cpp $(ROOT_DIR)/tests/emulator.hpp $(ROOT_DIR)/tests/z80.hpp | $(TEST_BUILD_DIR)/
	g++ -std=c++17 -I$(ROOT_DIR)/include -I$(ROOT_DIR)/tests -O2 -Wall -Wextra -o $@ $(ROOT_DIR)/tests/partner/export_partner_visuals.cpp $(ROOT_DIR)/tests/emulator.cpp

clean:
	rm -rf $(PARTNER_BUILD_DIR)
	rm -f $(PARTNER_HOST_TESTS) $(PARTNER_VIS_HARNESS)
