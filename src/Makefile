ROOT_DIR ?= $(abspath ..)
BUILD_DIR ?= $(ROOT_DIR)/build
BIN_DIR ?= $(ROOT_DIR)/bin
BUILD_TMP ?= $(BUILD_DIR)/tmp

DOCKER_SPEC ?= wischner/sdcc-z80-zx-spectrum
DOCKER_PARTNER ?= wischner/sdcc-z80-idp
DOCKER_USER ?= $(shell id -u):$(shell id -g)
SDCC ?= /opt/sdcc/bin/sdcc

ZX_LIB_STAMP := $(BUILD_DIR)/zx/.lib-objs.stamp
BIN_LIBGPX_LIB := $(BIN_DIR)/libgpx.lib

PARTNER_SRC := $(ROOT_DIR)/src/partner/hello.c
PARTNER_TEST_SRC := $(ROOT_DIR)/tests/partner/test_draw.c
BUILD_PARTNER_IHX := $(BUILD_DIR)/partner/hello.ihx
BUILD_PARTNER_TEST_IHX := $(BUILD_DIR)/partner/test_draw.ihx
BIN_PARTNER_IHX := $(BIN_DIR)/partner/hello.ihx
BIN_PARTNER_TEST_IHX := $(BIN_DIR)/partner/test_draw.ihx
BIN_PARTNER_BIN := $(BIN_DIR)/partner/hello.bin
BIN_PARTNER_TEST_BIN := $(BIN_DIR)/partner/test_draw.bin

.PHONY: build lib partner zx-lib-objs clean
.PRECIOUS: $(BUILD_DIR)/%/ $(BIN_DIR)/%/ $(BIN_DIR)/ $(BUILD_TMP)/

build: lib partner

lib: $(BIN_LIBGPX_LIB)

partner: $(BIN_PARTNER_IHX) $(BIN_PARTNER_TEST_IHX) $(BIN_PARTNER_BIN) $(BIN_PARTNER_TEST_BIN)

zx-lib-objs: $(ZX_LIB_STAMP)

$(BUILD_DIR)/%/:
	mkdir -p $@

$(BIN_DIR)/%/:
	mkdir -p $@

$(BIN_DIR)/:
	mkdir -p $@

$(BUILD_TMP)/:
	mkdir -p $@

$(ZX_LIB_STAMP): $(ROOT_DIR)/src/zx/*.s $(ROOT_DIR)/src/zx/*.c | $(BUILD_DIR)/zx/
	mkdir -p $(BUILD_DIR)/zx
	docker run --rm -u $(DOCKER_USER) -v "$(ROOT_DIR)":/work -w /work $(DOCKER_SPEC) sh -lc '\
		set -e; \
		for src in src/zx/*.s; do \
			base="$$(basename "$$src" .s)"; \
			case "$$base" in gpx_rect_clip|_gpx_cohen_sutherland|_gpx_cs_intersection|_gpx_line_normalize) continue;; esac; \
			dest="build/zx/$$base.rel"; \
			/opt/sdcc/bin/sdasz80 -o "$$dest" "$$src"; \
		done; \
		for src in src/zx/*.c; do \
			base="$$(basename "$$src" .c)"; \
			case "$$base" in rect_helpers|shape_ref) continue;; esac; \
			dest="build/zx/$$base.rel"; \
			/opt/sdcc/bin/sdcc -mz80 --no-std-crt0 -Iinclude -c -o "$$dest" "$$src"; \
		done'
	touch $@

$(BIN_LIBGPX_LIB): $(ZX_LIB_STAMP) | $(BIN_DIR)/
	ar rcs "$@" $(BUILD_DIR)/zx/*.rel

$(BUILD_PARTNER_IHX): $(PARTNER_SRC) | $(BUILD_DIR)/partner/
	mkdir -p $(BUILD_DIR)/partner
	docker run --rm -u $(DOCKER_USER) -v "$(ROOT_DIR)":/work -w /work $(DOCKER_PARTNER) sh -lc '$(SDCC) -mz80 --no-std-crt0 -Iinclude -o "build/partner/hello.ihx" "src/partner/hello.c"'

$(BUILD_PARTNER_TEST_IHX): $(PARTNER_TEST_SRC) $(ROOT_DIR)/tests/partner/gpx_stub.c | $(BUILD_DIR)/partner/ $(BUILD_TMP)/
	mkdir -p $(BUILD_DIR)/partner $(BUILD_TMP)
	docker run --rm -u $(DOCKER_USER) -v "$(ROOT_DIR)":/work -w /work $(DOCKER_PARTNER) sh -lc 'set -e; /opt/sdcc/bin/sdcc -mz80 --no-std-crt0 -Iinclude -c -o build/tmp/test_draw.rel tests/partner/test_draw.c; /opt/sdcc/bin/sdcc -mz80 --no-std-crt0 -Iinclude -c -o build/tmp/gpx_stub.rel tests/partner/gpx_stub.c; /opt/sdcc/bin/sdcc -mz80 --no-std-crt0 -o build/partner/test_draw.ihx build/tmp/test_draw.rel build/tmp/gpx_stub.rel'

$(BIN_PARTNER_IHX): $(BUILD_PARTNER_IHX) | $(BIN_DIR)/partner/
	cp "$<" "$@"

$(BIN_PARTNER_TEST_IHX): $(BUILD_PARTNER_TEST_IHX) | $(BIN_DIR)/partner/
	cp "$<" "$@"

$(BIN_PARTNER_BIN): $(BIN_PARTNER_IHX) | $(BIN_DIR)/partner/
	docker run --rm -u $(DOCKER_USER) -v "$(ROOT_DIR)":/work -w /work $(DOCKER_PARTNER) sh -lc '/opt/sdcc/bin/sdobjcopy -I ihex -O binary "bin/partner/hello.ihx" "bin/partner/hello.bin"'

$(BIN_PARTNER_TEST_BIN): $(BIN_PARTNER_TEST_IHX) | $(BIN_DIR)/partner/
	docker run --rm -u $(DOCKER_USER) -v "$(ROOT_DIR)":/work -w /work $(DOCKER_PARTNER) sh -lc '/opt/sdcc/bin/sdobjcopy -I ihex -O binary "bin/partner/test_draw.ihx" "bin/partner/test_draw.bin"'

clean:
	rm -f $(BUILD_DIR)/zx/.lib-objs.stamp $(BIN_LIBGPX_LIB)
	rm -rf $(BUILD_DIR)/partner $(BIN_DIR)/partner
