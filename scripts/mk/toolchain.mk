# Shared X Tools (xcc) toolchain definitions.
#
# Every target is built inside a pinned Docker image so the toolchain is the
# same on a developer machine and in CI. Each image also ships the emulator
# that its test suite drives: zx-spectrum-mcp, idp-mcp and amstrad-cpc-mcp.

DOCKER_ZX ?= wischner/xcc-z80-zx-spectrum
DOCKER_IDP ?= wischner/xcc-z80-idp
DOCKER_CPC ?= wischner/xcc-z80-cpc
DOCKER_USER ?= $(shell id -u):$(shell id -g)

# ADVANCED selects the optional half of the library. Set it to 0, no or
# false (any case) and the build is exactly the core set of primitives;
# anything else -- the default -- also assembles src/common, the portable
# modules that are written against the public API rather than against one
# machine's framebuffer. They cost nothing in a program that does not call
# them, because the linker only pulls the archive members it needs.
ADVANCED ?= 1
ADVANCED_FALSE := 0 n N no No NO nO false False FALSE off Off OFF
ifeq ($(strip $(filter $(ADVANCED),$(ADVANCED_FALSE))),)
ADVANCED_ON := 1
ADVANCED_SRCS := $(wildcard $(ROOT_DIR)/src/common/*.s)
# Expanded by the shell inside the container, where the repo is /work.
ADVANCED_GLOB := src/common/*.s
else
ADVANCED_ON := 0
ADVANCED_SRCS :=
ADVANCED_GLOB :=
endif

# Flipping ADVANCED has to invalidate the object stamps, which otherwise
# only watch source files. The witness file's name carries the setting, so
# a changed setting means a missing file, which means the stamps rebuild.
ADVANCED_WITNESS := $(BUILD_DIR)/.advanced-$(ADVANCED_ON)

$(ADVANCED_WITNESS):
	mkdir -p $(BUILD_DIR)
	rm -f $(BUILD_DIR)/.advanced-*
	touch $@

XCC ?= xcc
XAS ?= xas
XLD ?= xld
XAR ?= xar

# Repo is mounted at /work, so recipes use repo-relative paths.
DOCKER_RUN = docker run --rm -u $(DOCKER_USER) -v "$(ROOT_DIR)":/work -w /work
ZXRUN := $(DOCKER_RUN) $(DOCKER_ZX) sh -lc
IDPRUN := $(DOCKER_RUN) $(DOCKER_IDP) sh -lc
CPCRUN := $(DOCKER_RUN) $(DOCKER_CPC) sh -lc

# Repo-relative forms of the automatic variables, for use inside the container.
REL = $(patsubst $(ROOT_DIR)/%,%,$@)
SRC = $(patsubst $(ROOT_DIR)/%,%,$<)
INS = $(patsubst $(ROOT_DIR)/%,%,$^)

# Compile flags. The library itself is hand-written assembly; these apply to
# test scenarios, the C oracle and the samples.
XCFLAGS ?= -mz80 -std=c11 -Os -Iinclude
XLDFLAGS ?= -mz80 -nostartfiles

# Link a set of .rel files into an Intel HEX image based at $(1).
xlink_ihx = -Wl,--oformat=ihx -Wl,-b,_CODE=$(1)

# The CPC runs raw binaries: the firmware never gets a chance to load a
# header, because gpx_create pages both ROMs out.
xlink_bin = --oformat=binary -b _CODE=$(1) -nostartfiles
