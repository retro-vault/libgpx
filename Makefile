DOCKER_SPEC ?= wischner/sdcc-z80-zx-spectrum
DOCKER_PARTNER ?= wischner/sdcc-z80-idp
DOCKER_USER ?= $(shell id -u):$(shell id -g)
SDCC ?= /opt/sdcc/bin/sdcc

ROOT_DIR := $(CURDIR)
BUILD_DIR ?= $(ROOT_DIR)/build
BIN_DIR ?= $(ROOT_DIR)/bin
BUILD_TMP ?= $(BUILD_DIR)/tmp
TEST_BUILD_DIR ?= $(BUILD_DIR)/tests

export DOCKER_SPEC DOCKER_PARTNER DOCKER_USER SDCC
export ROOT_DIR BUILD_DIR BIN_DIR BUILD_TMP TEST_BUILD_DIR

.PHONY: all build lib tests coverage visual-inputs stub-visuals lib-visuals lib-size clean

all: build

build:
	$(MAKE) -C src build
	$(MAKE) -C tests build

lib:
	$(MAKE) -C src lib

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

lib-size:
	$(MAKE) -C tests lib-size

clean:
	$(MAKE) -C src clean
	$(MAKE) -C tests clean
	rm -rf $(BUILD_DIR) $(BIN_DIR)
