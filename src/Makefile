ROOT_DIR ?= $(abspath ..)
BUILD_DIR ?= $(ROOT_DIR)/build
BIN_DIR ?= $(ROOT_DIR)/bin
BUILD_TMP ?= $(BUILD_DIR)/tmp

include $(ROOT_DIR)/scripts/mk/toolchain.mk

ZX_LIB_STAMP := $(BUILD_DIR)/zx/.lib-objs.stamp
BIN_LIBGPX_LIB := $(BIN_DIR)/libgpx.lib
# src/common holds the portable modules gated by ADVANCED; they are
# assembled into each backend's object directory so the archives and every
# link line that globs those directories pick them up unchanged.
ZX_ASM_SRCS := $(wildcard $(ROOT_DIR)/src/zx/*.s)
ZX_C_SRCS := $(wildcard $(ROOT_DIR)/src/zx/*.c)
PARTNER_LIB_BUILD_DIR := $(BUILD_DIR)/partner-lib
PARTNER_LIB_STAMP := $(PARTNER_LIB_BUILD_DIR)/.lib-objs.stamp
BIN_PARTNER_LIBGPX_LIB := $(BIN_DIR)/partner/libgpx.lib
PARTNER_ASM_SRCS := $(wildcard $(ROOT_DIR)/src/partner/*.s)

# One CPC library serves both display modes; gpx_create() picks the mode and
# the mode-dependent paths read it from _gpx_mode.s.
CPC_ASM_SRCS := $(wildcard $(ROOT_DIR)/src/cpc/*.s) \
	$(wildcard $(ROOT_DIR)/src/cpc/*.inc)
CPC_LIB_BUILD_DIR := $(BUILD_DIR)/cpc
CPC_LIB_STAMP := $(CPC_LIB_BUILD_DIR)/.lib-objs.stamp
BIN_CPC_LIB := $(BIN_DIR)/cpc/libgpx.lib

PARTNER_TEST_SRC := $(ROOT_DIR)/tests/partner/test_draw.c
BUILD_PARTNER_TEST_IHX := $(BUILD_DIR)/partner/test_draw.ihx
BIN_PARTNER_TEST_IHX := $(BIN_DIR)/partner/test_draw.ihx

.PHONY: build lib partner partner-lib zx-lib-objs partner-lib-objs \
	cpc cpc-lib cpc-lib-objs clean
.PRECIOUS: $(BUILD_DIR)/%/ $(BIN_DIR)/%/ $(BIN_DIR)/ $(BUILD_TMP)/

build: lib partner cpc

lib: $(BIN_LIBGPX_LIB)

partner: $(BIN_PARTNER_TEST_IHX)

zx-lib-objs: $(ZX_LIB_STAMP)

partner-lib: $(BIN_PARTNER_LIBGPX_LIB)

partner-lib-objs: $(PARTNER_LIB_STAMP)

cpc: $(BIN_CPC_LIB)

cpc-lib: $(BIN_CPC_LIB)

cpc-lib-objs: $(CPC_LIB_STAMP)

$(BUILD_DIR)/%/:
	mkdir -p $@

$(BIN_DIR)/%/:
	mkdir -p $@

$(BIN_DIR)/:
	mkdir -p $@

$(BUILD_TMP)/:
	mkdir -p $@

$(ZX_LIB_STAMP): $(ZX_ASM_SRCS) $(ZX_C_SRCS) $(ADVANCED_SRCS) \
		$(ADVANCED_WITNESS) | $(BUILD_DIR)/zx/
	rm -f $(BUILD_DIR)/zx/*.rel
	$(ZXRUN) '\
		set -e; \
		for src in src/zx/*.s $(ADVANCED_GLOB); do \
			[ -e "$$src" ] || continue; \
			$(XAS) -o "build/zx/$$(basename "$$src" .s).rel" "$$src"; \
		done; \
		for src in src/zx/*.c; do \
			[ -e "$$src" ] || continue; \
			$(XCC) $(XCFLAGS) -c -o "build/zx/$$(basename "$$src" .c).rel" "$$src"; \
		done'
	touch $@

$(BIN_LIBGPX_LIB): $(ZX_LIB_STAMP) | $(BIN_DIR)/
	rm -f $(BIN_LIBGPX_LIB)
	$(ZXRUN) '$(XAR) rc "bin/libgpx.lib" build/zx/*.rel'

$(PARTNER_LIB_STAMP): $(PARTNER_ASM_SRCS) $(ADVANCED_SRCS) \
		$(ADVANCED_WITNESS) | $(PARTNER_LIB_BUILD_DIR)/
	rm -f $(PARTNER_LIB_BUILD_DIR)/*.rel
	$(IDPRUN) '\
		set -e; \
		for src in src/partner/*.s $(ADVANCED_GLOB); do \
			[ -e "$$src" ] || continue; \
			$(XAS) -o "build/partner-lib/$$(basename "$$src" .s).rel" "$$src"; \
		done'
	touch $@

$(BIN_PARTNER_LIBGPX_LIB): $(PARTNER_LIB_STAMP) | $(BIN_DIR)/partner/
	rm -f $(BIN_PARTNER_LIBGPX_LIB)
	$(IDPRUN) '$(XAR) rc "bin/partner/libgpx.lib" build/partner-lib/*.rel'

$(CPC_LIB_STAMP): $(CPC_ASM_SRCS) $(ADVANCED_SRCS) \
		$(ADVANCED_WITNESS) | $(CPC_LIB_BUILD_DIR)/
	rm -f $(CPC_LIB_BUILD_DIR)/*.rel
	$(CPCRUN) '\
		set -e; \
		for src in src/cpc/*.s $(ADVANCED_GLOB); do \
			[ -e "$$src" ] || continue; \
			$(XAS) -I src/cpc \
				-o "build/cpc/$$(basename "$$src" .s).rel" "$$src"; \
		done'
	touch $@

# crt0-cpc.rel is a startup file, not library code, so it is shipped beside
# the library rather than inside it.
$(BIN_CPC_LIB): $(CPC_LIB_STAMP) | $(BIN_DIR)/cpc/
	rm -f $(BIN_CPC_LIB)
	$(CPCRUN) '$(XAR) rc "bin/cpc/libgpx.lib" \
		$$(ls build/cpc/*.rel | grep -v crt0-cpc)'
	cp $(CPC_LIB_BUILD_DIR)/crt0-cpc.rel $(BIN_DIR)/cpc/crt0-cpc.rel

$(BUILD_PARTNER_TEST_IHX): $(PARTNER_TEST_SRC) $(ROOT_DIR)/tests/partner/gpx_stub.c | $(BUILD_DIR)/partner/ $(BUILD_TMP)/
	$(IDPRUN) 'set -e; \
		$(XCC) $(XCFLAGS) -c -o build/tmp/test_draw.rel tests/partner/test_draw.c; \
		$(XCC) $(XCFLAGS) -c -o build/tmp/gpx_stub.rel tests/partner/gpx_stub.c; \
		$(XCC) $(XLDFLAGS) -o build/partner/test_draw.ihx build/tmp/test_draw.rel build/tmp/gpx_stub.rel -Wl,--oformat=ihx'

$(BIN_PARTNER_TEST_IHX): $(BUILD_PARTNER_TEST_IHX) | $(BIN_DIR)/partner/
	cp "$<" "$@"

clean:
	rm -f $(BUILD_DIR)/zx/.lib-objs.stamp $(BIN_LIBGPX_LIB)
	rm -rf $(BUILD_DIR)/partner $(PARTNER_LIB_BUILD_DIR) $(BIN_DIR)/partner
