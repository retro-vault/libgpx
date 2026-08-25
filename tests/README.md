# Tests

Two very different backends live in this repository, so they are tested two
different ways.

- **ZX Spectrum** scenarios run on a real cycle-accurate emulator,
  [`zx-spectrum-mcp`](https://github.com/tstih/zx-spectrum-mcp), driven over
  MCP (JSON-RPC on stdio). The emulator ships inside the same Docker image as
  the toolchain, so there is nothing extra to install.
- **Iskra Delta Partner** scenarios still use the small in-repo Z80 + EF9367
  host harness under `tests/partner/`, because the MCP emulator only models a
  Spectrum.

## Layout

| Path | What it holds |
|---|---|
| `tests/mcp/` | MCP client, test runner, benchmark runner, profiler, visual capture |
| `tests/zx/test-src/` | ZX scenarios (`test_*.c`) and their shared header |
| `tests/zx/bench-src/` | ZX micro-benchmarks (`bench_*.c`) plus the recorded baseline |
| `tests/zx/stub/` | The independent C oracle and its host-side self-check |
| `tests/partner/` | Partner scenarios and the in-repo EF9367 harness |
| `tests/size/` | Per-module code-size measurement and its baseline |

## How a ZX test works

Every scenario is compiled twice:

1. against the real assembler backend in `src/zx`
2. against `tests/zx/stub/gpx_stub.c`, an independent C implementation of the
   same API written per-pixel

Both images are loaded at `0x8000` and run to `HALT` on the emulator. The
runner then compares, byte for byte:

- the 6144-byte display file
- the 768-byte attribute area
- the border colour
- `test_results`, a block scenarios write return values into, so assertions on
  `gpx_measure_text` or the rotated pattern from `gpx_draw_line` are checked
  too, without going through the code under test

A scenario that differs from the oracle in any of those fails, and the runner
reports the mismatch in screen coordinates rather than raw offsets.

## Commands

```sh
make tests             # ZX differential suite, then the Partner suite
make zx-tests          # ZX only
make zx-bench          # T-state benchmarks
make zx-bench ARGS=--diff     # compare against the recorded baseline
make lib-size          # per-module code size
make lib-size ARGS=--diff     # compare against the recorded baseline
make lib-visuals       # PNG of every scenario, real and oracle, via MCP
make coverage          # gcov over the host build of the oracle
```

Iterating on one scenario is much faster than rebuilding everything:

```sh
make -C tests/zx one TEST=test_line_fan
python3 tests/mcp/run_zx_tests.py test_line_fan
```

To find out where the time goes in a benchmark:

```sh
python3 tests/mcp/profile_zx.py bench_bmp --top 12
```

## Baselines

`tests/size/baseline.json` and `tests/zx/bench-src/baseline.json` record the
size and speed of the library at a known-good point. Re-record them with
`ARGS=--save` after a deliberate change, and use `ARGS=--diff` while
optimizing.

## Writing a scenario

Drop a `test_*.c` into `tests/zx/test-src/` and it is picked up automatically.
Include `zxtest.h`, end with `TEST_END()`, and prefer seeding the screen with
`seed_screen_wash()` when the behaviour under test only shows up over existing
content: on a blank screen a `CO_BACK` draw and a no-op look identical.

Helpers in `zxtest.h` never call into libgpx, so a broken primitive cannot
hide a failure by corrupting the scaffolding.
