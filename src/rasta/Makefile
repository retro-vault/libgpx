.DEFAULT_GOAL := build
ROOT_DIR ?= $(abspath ../..)
BUILD_DIR ?= $(ROOT_DIR)/build
BIN_DIR ?= $(ROOT_DIR)/bin
VERSION ?= dev
include $(ROOT_DIR)/scripts/mk/rasta.mk

ADVANCED ?= 1
ADVANCED_FALSE := 0 n N no No NO nO false False FALSE off Off OFF
ADVANCED_ON := $(if $(filter $(ADVANCED),$(ADVANCED_FALSE)),0,1)
RASTA_REVISION := 3dd2426f5c4bddf7d0eb4961d73c2e8c68e3510a
OBJ_DIR := $(BUILD_DIR)/rasta-lib
OUT_DIR := $(BIN_DIR)/rasta
SOURCES := context primitives bitmap text assets box
ifeq ($(ADVANCED_ON),1)
SOURCES += advanced
endif
OBJECTS := $(addprefix $(OBJ_DIR)/,$(addsuffix .o,$(SOURCES)))
CONFIG := $(OBJ_DIR)/.advanced-$(ADVANCED_ON)
NATIVE_FLAGS := -std=c11 -O2 -Wall -Wextra -Wpedantic -Werror -fPIC
REL = $(patsubst $(ROOT_DIR)/%,%,$(1))

.PHONY: build lib emulator fetch demo tests clean package
build: lib emulator
lib: $(OUT_DIR)/libgpx.a $(OUT_DIR)/libgpx.so $(OUT_DIR)/include/libgpx.h

$(OBJ_DIR)/ $(OUT_DIR)/ $(OUT_DIR)/include/:
	mkdir -p $@

$(CONFIG): | $(OBJ_DIR)/
	rm -f $(OBJ_DIR)/.advanced-*
	touch $@

$(OBJ_DIR)/assets.inc: $(ROOT_DIR)/scripts/assets/gen-rasta-assets.py \
	$(ROOT_DIR)/src/zx/_gpx_font_envy.s $(ROOT_DIR)/src/zx/_gpx_cursors.s | $(OBJ_DIR)/ rasta-docker
	$(RASTA_RUN) python3 scripts/assets/gen-rasta-assets.py $(call REL,$@)

$(OBJ_DIR)/assets.o: $(OBJ_DIR)/assets.inc

$(OBJ_DIR)/%.o: $(ROOT_DIR)/src/rasta/%.c rasta_internal.h $(ROOT_DIR)/include/libgpx.h $(CONFIG) | $(OBJ_DIR)/ rasta-docker
	$(RASTA_RUN) gcc $(NATIVE_FLAGS) -Iinclude -I$(call REL,$(OBJ_DIR)) -c $(call REL,$<) -o $(call REL,$@)

$(OUT_DIR)/libgpx.a: $(OBJECTS) $(CONFIG) | $(OUT_DIR)/ rasta-docker
	rm -f $@
	$(RASTA_RUN) ar rcs $(call REL,$@) $(call REL,$(OBJECTS))

$(OUT_DIR)/libgpx.so: $(OBJECTS) $(CONFIG) | $(OUT_DIR)/ rasta-docker
	$(RASTA_RUN) gcc -shared -Wl,--no-undefined -o $(call REL,$@) $(call REL,$(OBJECTS))

$(OUT_DIR)/include/libgpx.h: $(ROOT_DIR)/include/libgpx.h | $(OUT_DIR)/include/
	cp $< $@

fetch: rasta-docker
	$(RASTA_RUN) python3 scripts/deps/fetch-rasta.py $(call REL,$(BUILD_DIR))/rasta $(RASTA_REVISION)

emulator: fetch | $(OUT_DIR)/
	$(RASTA_RUN) cmake -S $(call REL,$(BUILD_DIR))/rasta -B $(call REL,$(BUILD_DIR))/rasta-emulator -DCMAKE_BUILD_TYPE=Release
	$(RASTA_RUN) cmake --build $(call REL,$(BUILD_DIR))/rasta-emulator --target rasta --parallel
	cp $(BUILD_DIR)/rasta/bin/rasta $(OUT_DIR)/rasta

demo: build $(OUT_DIR)/demo

$(OUT_DIR)/demo: $(ROOT_DIR)/samples/rasta/main.c $(OUT_DIR)/libgpx.a | rasta-docker
	$(RASTA_RUN) gcc $(NATIVE_FLAGS) -DGPX_ADVANCED=$(ADVANCED_ON) -Iinclude $(call REL,$<) $(call REL,$(OUT_DIR))/libgpx.a -o $(call REL,$@)

tests: build
	$(MAKE) -C $(ROOT_DIR)/tests/rasta tests

package: build
	mkdir -p $(BUILD_DIR)/release/libgpx-rasta-$(VERSION)/lib $(BUILD_DIR)/release/libgpx-rasta-$(VERSION)/include
	cp $(OUT_DIR)/libgpx.a $(OUT_DIR)/libgpx.so $(BUILD_DIR)/release/libgpx-rasta-$(VERSION)/lib/
	cp $(ROOT_DIR)/include/libgpx.h $(BUILD_DIR)/release/libgpx-rasta-$(VERSION)/include/
	sed 's|../images/screenshots/|images/|g' $(ROOT_DIR)/docs/manuals/RASTA.md > $(BUILD_DIR)/release/libgpx-rasta-$(VERSION)/README.md
	mkdir -p $(BUILD_DIR)/release/libgpx-rasta-$(VERSION)/images
	cp $(ROOT_DIR)/docs/images/screenshots/*-rasta.png $(BUILD_DIR)/release/libgpx-rasta-$(VERSION)/images/
	cp $(ROOT_DIR)/LICENSE $(BUILD_DIR)/release/libgpx-rasta-$(VERSION)/LICENSE
	tar -C $(BUILD_DIR)/release -czf $(BUILD_DIR)/release/libgpx-rasta-$(VERSION).tar.gz libgpx-rasta-$(VERSION)

clean:
	rm -rf $(OBJ_DIR) $(BUILD_DIR)/rasta-emulator $(OUT_DIR)
