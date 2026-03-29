ROOT_DIR ?= $(abspath ../../..)
BUILD_DIR ?= $(ROOT_DIR)/build
TEST_BUILD_DIR ?= $(BUILD_DIR)/tests

TEST_ZX_API_HOST := $(TEST_BUILD_DIR)/test_zx_api_host
TEST_ZX_API_HOST_COV := $(TEST_BUILD_DIR)/test_zx_api_host_cov

.PHONY: host-test run-host-test host-test-cov run-host-test-cov stub-visuals clean

host-test: $(TEST_ZX_API_HOST)

run-host-test: $(TEST_ZX_API_HOST)
	$(TEST_ZX_API_HOST)

host-test-cov: $(TEST_ZX_API_HOST_COV)

run-host-test-cov: $(TEST_ZX_API_HOST_COV)
	$(TEST_ZX_API_HOST_COV)

stub-visuals:
	python3 $(ROOT_DIR)/tests/zx/stub/generate_stub_visuals.py

$(TEST_BUILD_DIR)/:
	mkdir -p $@

$(TEST_ZX_API_HOST): $(ROOT_DIR)/tests/zx/stub/test_zx_api_host.c $(ROOT_DIR)/tests/zx/stub/gpx_stub.c $(ROOT_DIR)/include/libgpx.h | $(TEST_BUILD_DIR)/
	gcc -std=c11 -DGPX_STUB_HOST -I$(ROOT_DIR)/include -O0 -Wall -Wextra -o $@ $(ROOT_DIR)/tests/zx/stub/test_zx_api_host.c $(ROOT_DIR)/tests/zx/stub/gpx_stub.c

$(TEST_ZX_API_HOST_COV): $(ROOT_DIR)/tests/zx/stub/test_zx_api_host.c $(ROOT_DIR)/tests/zx/stub/gpx_stub.c $(ROOT_DIR)/include/libgpx.h | $(TEST_BUILD_DIR)/
	gcc -std=c11 --coverage -DGPX_STUB_HOST -I$(ROOT_DIR)/include -O0 -Wall -Wextra -o $@ $(ROOT_DIR)/tests/zx/stub/test_zx_api_host.c $(ROOT_DIR)/tests/zx/stub/gpx_stub.c

clean:
	rm -f $(TEST_ZX_API_HOST) $(TEST_ZX_API_HOST_COV) $(TEST_ZX_API_HOST_COV)-*.gcda $(TEST_ZX_API_HOST_COV)-*.gcno $(TEST_BUILD_DIR)/generate_stub_visuals
