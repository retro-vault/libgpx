# Shared X Tools (xcc) toolchain definitions.
#
# Every target is built inside a pinned Docker image so the toolchain is the
# same on a developer machine and in CI. The ZX image also ships the
# zx-spectrum-mcp emulator that the ZX test suite drives.

DOCKER_ZX ?= wischner/xcc-z80-zx-spectrum
DOCKER_IDP ?= wischner/xcc-z80-idp
# The CPC needs no emulator in its image: amstrad-cpc-mcp is a native binary
# driven from tests/mcp/cpcmcp.py, so the plain Z80 toolchain is enough.
DOCKER_CPC ?= wischner/xcc-z80
DOCKER_USER ?= $(shell id -u):$(shell id -g)

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
