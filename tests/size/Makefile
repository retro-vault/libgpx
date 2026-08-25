ROOT_DIR ?= $(abspath ../..)

PYTHON ?= python3
ARGS ?=

.PHONY: lib-size clean

lib-size:
	$(MAKE) -C $(ROOT_DIR)/src zx-lib-objs
	$(PYTHON) $(ROOT_DIR)/tests/size/lib_size.py $(ARGS)

clean:
	@:
