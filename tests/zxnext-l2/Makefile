ROOT_DIR ?= $(abspath ../..)
BUILD_DIR ?= $(ROOT_DIR)/build
BIN_DIR ?= $(ROOT_DIR)/bin
include $(ROOT_DIR)/scripts/mk/toolchain.mk

LIB := $(BIN_DIR)/zxnext-l2/libgpx.lib
IMAGE := $(BUILD_DIR)/zxnext-l2/test_next_l2.ihx

.PHONY: build clean
build: $(IMAGE)

$(IMAGE): test_next_l2.c $(LIB)
	$(ZXRUN) 'set -e; $(XCC) $(XCFLAGS) -c -o build/zxnext-l2/test_next_l2.rel tests/zxnext-l2/test_next_l2.c; $(XCC) $(XLDFLAGS) -o build/zxnext-l2/test_next_l2.ihx build/zxnext-l2/test_next_l2.rel bin/zxnext-l2/libgpx.lib -Wl,--oformat=ihx -Wl,-b,_CODE=0x8000'

clean:
	rm -f $(IMAGE) $(BUILD_DIR)/zxnext-l2/test_next_l2.rel
