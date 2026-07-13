DOCKER_SPEC ?= wischner/sdcc-z80-zx-spectrum
DOCKER_PARTNER ?= wischner/sdcc-z80-idp
DOCKER_USER ?= $(shell id -u):$(shell id -g)
SDCC ?= /opt/sdcc/bin/sdcc

ROOT_DIR := $(CURDIR)
BUILD_DIR ?= $(ROOT_DIR)/build
BIN_DIR ?= $(ROOT_DIR)/bin
BUILD_TMP ?= $(BUILD_DIR)/tmp
TEST_BUILD_DIR ?= $(BUILD_DIR)/tests
RELEASE_DIR ?= $(BUILD_DIR)/release
VERSION ?= dev

ZX_RELEASE_NAME := libgpx-zx-spectrum-$(VERSION)
PARTNER_RELEASE_NAME := libgpx-partner-$(VERSION)
ZX_RELEASE_STAGE := $(RELEASE_DIR)/$(ZX_RELEASE_NAME)
PARTNER_RELEASE_STAGE := $(RELEASE_DIR)/$(PARTNER_RELEASE_NAME)
ZX_RELEASE_ARCHIVE := $(RELEASE_DIR)/$(ZX_RELEASE_NAME).tar.gz
PARTNER_RELEASE_ARCHIVE := $(RELEASE_DIR)/$(PARTNER_RELEASE_NAME).tar.gz

export DOCKER_SPEC DOCKER_PARTNER DOCKER_USER SDCC
export ROOT_DIR BUILD_DIR BIN_DIR BUILD_TMP TEST_BUILD_DIR RELEASE_DIR VERSION

.PHONY: all build lib partner-lib package-zx package-partner release-packages tests coverage visual-inputs stub-visuals lib-visuals partner-visuals lib-size demo1 demo2 clean

all: build

build:
	$(MAKE) -C src build
	$(MAKE) -C tests build

lib:
	$(MAKE) -C src lib

partner-lib:
	$(MAKE) -C src partner-lib

package-zx: $(ZX_RELEASE_ARCHIVE)

package-partner: $(PARTNER_RELEASE_ARCHIVE)

release-packages: package-zx package-partner

tests:
	$(MAKE) -C tests tests

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
	$(MAKE) -C tests lib-size

demo1:
	$(MAKE) -C samples/demo1 build

demo2:
	$(MAKE) -C samples/demo2 build

$(RELEASE_DIR):
	mkdir -p $@

$(BIN_DIR)/libgpx.lib: $(ROOT_DIR)/src/Makefile $(wildcard $(ROOT_DIR)/src/zx/*.s) $(wildcard $(ROOT_DIR)/src/zx/*.c)
	$(MAKE) -C src lib

$(BIN_DIR)/partner/libgpx.lib: $(ROOT_DIR)/src/Makefile $(wildcard $(ROOT_DIR)/src/partner/*.s)
	$(MAKE) -C src partner-lib

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

clean:
	$(MAKE) -C src clean
	$(MAKE) -C tests clean
	rm -rf $(BUILD_DIR) $(BIN_DIR)
