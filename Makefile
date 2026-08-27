ROOT_DIR := $(CURDIR)
BUILD_DIR ?= $(ROOT_DIR)/build
BIN_DIR ?= $(ROOT_DIR)/bin
BUILD_TMP ?= $(BUILD_DIR)/tmp
TEST_BUILD_DIR ?= $(BUILD_DIR)/tests
RELEASE_DIR ?= $(BUILD_DIR)/release
VERSION ?= dev
PYTHON ?= python3

ZX_RELEASE_NAME := libgpx-zx-spectrum-$(VERSION)
PARTNER_RELEASE_NAME := libgpx-partner-$(VERSION)
CPC_RELEASE_NAME := libgpx-amstrad-cpc-$(VERSION)
ZX_RELEASE_STAGE := $(RELEASE_DIR)/$(ZX_RELEASE_NAME)
PARTNER_RELEASE_STAGE := $(RELEASE_DIR)/$(PARTNER_RELEASE_NAME)
CPC_RELEASE_STAGE := $(RELEASE_DIR)/$(CPC_RELEASE_NAME)
ZX_RELEASE_ARCHIVE := $(RELEASE_DIR)/$(ZX_RELEASE_NAME).tar.gz
PARTNER_RELEASE_ARCHIVE := $(RELEASE_DIR)/$(PARTNER_RELEASE_NAME).tar.gz
CPC_RELEASE_ARCHIVE := $(RELEASE_DIR)/$(CPC_RELEASE_NAME).tar.gz

include $(ROOT_DIR)/scripts/mk/toolchain.mk

export DOCKER_ZX DOCKER_IDP DOCKER_USER
export ROOT_DIR BUILD_DIR BIN_DIR BUILD_TMP TEST_BUILD_DIR RELEASE_DIR VERSION

.PHONY: cpc-tests cpc-bench all build lib partner-lib cpc-lib package-zx package-partner package-cpc release-packages tests zx-tests zx-bench partner-gdp-tests partner-gdp-bench conformance crossbench check-style coverage visual-inputs stub-visuals lib-visuals partner-visuals lib-size demo1 demo2 demo3 clean

all: build

build:
	$(MAKE) -C src build
	$(MAKE) -C tests build

lib:
	$(MAKE) -C src lib

partner-lib:
	$(MAKE) -C src partner-lib

cpc-lib:
	$(MAKE) -C src cpc-lib

package-zx: $(ZX_RELEASE_ARCHIVE)

package-partner: $(PARTNER_RELEASE_ARCHIVE)

package-cpc: $(CPC_RELEASE_ARCHIVE)

release-packages: package-zx package-partner package-cpc

tests:
	$(MAKE) -C tests tests

zx-tests:
	$(MAKE) -C tests zx-tests

zx-bench:
	$(MAKE) -C tests zx-bench ARGS="$(ARGS)"

cpc-tests:
	$(MAKE) -C tests cpc-tests ARGS="$(ARGS)"

cpc-bench:
	$(MAKE) -C tests cpc-bench ARGS="$(ARGS)"

partner-gdp-tests:
	$(MAKE) -C tests partner-gdp-tests ARGS="$(ARGS)"

partner-gdp-bench:
	$(MAKE) -C tests partner-gdp-bench ARGS="$(ARGS)"

conformance:
	$(MAKE) -C tests conformance ARGS="$(ARGS)"

crossbench:
	$(MAKE) -C tests crossbench ARGS="$(ARGS)"

# Mechanical conformance to docs/standards/ASSEMBLY_STYLE_GUIDE.md.
# `make check-style ARGS=--list` prints one line per violation;
# scripts/check/format-asm-style.py fixes the mechanical ones.
check-style:
	$(PYTHON) $(ROOT_DIR)/scripts/check/check-asm-style.py $(ARGS)

coverage:
	$(MAKE) -C tests coverage

visual-inputs:
	$(MAKE) -C tests visual-inputs

stub-visuals:
	$(MAKE) -C tests stub-visuals

lib-visuals:
	$(MAKE) -C tests lib-visuals

partner-visuals:
	$(MAKE) -C tests partner-visuals

lib-size:
	$(MAKE) -C tests lib-size ARGS="$(ARGS)"

demo1:
	$(MAKE) -C samples/demo1 build

demo2:
	$(MAKE) -C samples/demo2 build

demo3:
	$(MAKE) -C samples/demo3 build

$(RELEASE_DIR):
	mkdir -p $@

$(BIN_DIR)/libgpx.lib: $(ROOT_DIR)/src/Makefile $(wildcard $(ROOT_DIR)/src/zx/*.s) $(wildcard $(ROOT_DIR)/src/zx/*.c)
	$(MAKE) -C src lib

$(BIN_DIR)/partner/libgpx.lib: $(ROOT_DIR)/src/Makefile $(wildcard $(ROOT_DIR)/src/partner/*.s)
	$(MAKE) -C src partner-lib

$(BIN_DIR)/cpc/libgpx.lib: $(ROOT_DIR)/src/Makefile $(wildcard $(ROOT_DIR)/src/cpc/*.s) $(wildcard $(ROOT_DIR)/src/cpc/*.inc)
	$(MAKE) -C src cpc-lib

$(ZX_RELEASE_STAGE): $(BIN_DIR)/libgpx.lib $(ROOT_DIR)/include/libgpx.h $(ROOT_DIR)/README.md | $(RELEASE_DIR)
	rm -rf $@
	mkdir -p $@/lib $@/include
	cp $(BIN_DIR)/libgpx.lib $@/lib/libgpx.lib
	cp $(ROOT_DIR)/include/libgpx.h $@/include/libgpx.h
	cp $(ROOT_DIR)/README.md $@/README.md

$(PARTNER_RELEASE_STAGE): $(BIN_DIR)/partner/libgpx.lib $(ROOT_DIR)/include/libgpx.h $(ROOT_DIR)/README.md | $(RELEASE_DIR)
	rm -rf $@
	mkdir -p $@/lib $@/include
	cp $(BIN_DIR)/partner/libgpx.lib $@/lib/libgpx.lib
	cp $(ROOT_DIR)/include/libgpx.h $@/include/libgpx.h
	cp $(ROOT_DIR)/README.md $@/README.md

$(CPC_RELEASE_STAGE): $(BIN_DIR)/cpc/libgpx.lib $(ROOT_DIR)/include/libgpx.h $(ROOT_DIR)/README.md | $(RELEASE_DIR)
	rm -rf $@
	mkdir -p $@/lib $@/include
	cp $(BIN_DIR)/cpc/libgpx.lib $@/lib/libgpx.lib
	cp $(BIN_DIR)/cpc/crt0-cpc.rel $@/lib/crt0-cpc.rel
	cp $(ROOT_DIR)/include/libgpx.h $@/include/libgpx.h
	cp $(ROOT_DIR)/README.md $@/README.md

$(ZX_RELEASE_ARCHIVE): $(BIN_DIR)/libgpx.lib $(ROOT_DIR)/include/libgpx.h $(ROOT_DIR)/README.md | $(RELEASE_DIR)
	rm -rf $(ZX_RELEASE_STAGE)
	mkdir -p $(ZX_RELEASE_STAGE)/lib $(ZX_RELEASE_STAGE)/include
	cp $(BIN_DIR)/libgpx.lib $(ZX_RELEASE_STAGE)/lib/libgpx.lib
	cp $(ROOT_DIR)/include/libgpx.h $(ZX_RELEASE_STAGE)/include/libgpx.h
	cp $(ROOT_DIR)/README.md $(ZX_RELEASE_STAGE)/README.md
	tar -C $(RELEASE_DIR) -czf $@ $(ZX_RELEASE_NAME)

$(PARTNER_RELEASE_ARCHIVE): $(BIN_DIR)/partner/libgpx.lib $(ROOT_DIR)/include/libgpx.h $(ROOT_DIR)/README.md | $(RELEASE_DIR)
	rm -rf $(PARTNER_RELEASE_STAGE)
	mkdir -p $(PARTNER_RELEASE_STAGE)/lib $(PARTNER_RELEASE_STAGE)/include
	cp $(BIN_DIR)/partner/libgpx.lib $(PARTNER_RELEASE_STAGE)/lib/libgpx.lib
	cp $(ROOT_DIR)/include/libgpx.h $(PARTNER_RELEASE_STAGE)/include/libgpx.h
	cp $(ROOT_DIR)/README.md $(PARTNER_RELEASE_STAGE)/README.md
	tar -C $(RELEASE_DIR) -czf $@ $(PARTNER_RELEASE_NAME)

# The CPC package carries crt0-cpc.rel beside the library: a CPC program is a
# raw binary with no firmware under it, so the toolchain's default startup
# file (which expects _main and a C runtime) cannot be used.
$(CPC_RELEASE_ARCHIVE): $(BIN_DIR)/cpc/libgpx.lib $(ROOT_DIR)/include/libgpx.h $(ROOT_DIR)/README.md | $(RELEASE_DIR)
	rm -rf $(CPC_RELEASE_STAGE)
	mkdir -p $(CPC_RELEASE_STAGE)/lib $(CPC_RELEASE_STAGE)/include
	cp $(BIN_DIR)/cpc/libgpx.lib $(CPC_RELEASE_STAGE)/lib/libgpx.lib
	cp $(BIN_DIR)/cpc/crt0-cpc.rel $(CPC_RELEASE_STAGE)/lib/crt0-cpc.rel
	cp $(ROOT_DIR)/include/libgpx.h $(CPC_RELEASE_STAGE)/include/libgpx.h
	cp $(ROOT_DIR)/README.md $(CPC_RELEASE_STAGE)/README.md
	tar -C $(RELEASE_DIR) -czf $@ $(CPC_RELEASE_NAME)

clean:
	$(MAKE) -C src clean
	$(MAKE) -C tests clean
	rm -rf $(BUILD_DIR) $(BIN_DIR)
