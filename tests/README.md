# Tests

This directory contains emulator-driven validation and utility workflows for `libgpx`.

## Test Layout

- `tests/host/`: host-side runners (`test_emulator`, coverage binary).
- `tests/zx/test-src/`: ZX scenario sources (`test_*.c`) and ZX emulator unit file.
- `tests/zx/stub/`: independent oracle/stub implementation and host stub checks.
- `tests/zx/debug/`: visual capture/compare tools.
- `tests/size/`: size baseline entry and size makeflow.

Top-level orchestration is in `tests/Makefile`.

## What `make tests` Does

For each source in `tests/zx/test-src/test_*.c`:

1. Build real target linked with real ZX backend (`src/zx`).
2. Build oracle target linked with independent stub (`tests/zx/stub/gpx_stub.c`).
3. Execute both IHX binaries in host emulator (`tests/emulator.cpp`, `tests/z80.hpp`).
4. Compare captured VRAM snapshots byte-for-byte.

If all pairs match, tests pass.

## Key Commands

- `make tests -j1`: full real-vs-oracle emulator suite.
- `make stub-visuals -j1`: generate stub scene artifacts in `bin/stub-visuals/`.
- `make lib-visuals -j1`: generate stacked real-vs-oracle artifacts in `bin/lib-visuals/`.
- `make coverage -j1`: run coverage binaries and write `.gcov` into `build/coverage/`.
- `make lib-size -j1`: run payload size estimation flow.
- `make clean`: remove generated test/build artifacts.

## Coverage Outputs

Coverage binaries:
- `build/tests/test_emulator_cov`
- `build/tests/test_zx_api_host_cov`

Coverage report files:
- `build/coverage/*.gcov`
- `build/coverage/gcov-summary.txt`

## Size Flow

`tests/size/lib_size_main.c` is linked twice:

1. baseline-only entry
2. entry + full ZX libgpx object set

Reported payload estimate is:
- `payload = total_binary_bytes - baseline_bytes`
