# Tests

Three backends live in this repository, and each is tested on a real emulator
driven over MCP (JSON-RPC on stdio). Every emulator ships inside that
backend's toolchain Docker image, so there is nothing extra to install.

| Backend | Emulator | What it is checked against |
|---|---|---|
| ZX Spectrum | [`zx-spectrum-mcp`](https://github.com/tstih/zx-spectrum-mcp) | an independent C oracle, differentially |
| Iskra Delta Partner | `idp-mcp` (a real emulated EF9367) | recorded golden rasters |
| Amstrad CPC | `amstrad-cpc-mcp` | recorded golden rasters, once per display mode |

On top of those, `make conformance` runs one program on all three and diffs
the results, so a backend cannot drift on its own.

The Partner also keeps a small in-repo Z80 + EF9367 host harness under
`tests/partner/`, which predates `idp-mcp` and still runs as part of
`make tests`.

## Layout

| Path | What it holds |
|---|---|
| `tests/mcp/` | MCP clients, test runners, benchmark runners, profilers, visual capture |
| `tests/zx/test-src/` | ZX scenarios (`test_*.c`) and their shared header |
| `tests/zx/bench-src/` | ZX micro-benchmarks (`bench_*.c`) plus the recorded baseline |
| `tests/zx/stub/` | The independent C oracle and its host-side self-check |
| `tests/partner/` | Partner scenarios, the in-repo EF9367 harness, and `gdp-golden/` |
| `tests/cpc/` | CPC scenarios, benchmarks and `golden/` (one set per display mode) |
| `tests/conformance/` | Scenarios compiled for every backend and compared |
| `tests/crossbench/` | The same picture, at fixed coordinates, timed on every backend |
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

## How a CPC test works

There is one library for both display modes, so each scenario is built twice,
with `-DDEMO_MODE=0` (640x200) and `-DDEMO_MODE=1` (320x200), as a raw binary
loaded at `0x8000`. A scenario runs to `HALT` once per phase and its raster is
read **out of display memory** rather than taken from a screenshot, which
also sidesteps the emulator's one-scanline crop bug (see
`docs/todo/EMULATION-CPC.md`).

Building both modes from one source only works if the scenario actually honours
`DEMO_MODE` -- pass it to `gpx_create()`, not `GPXM_DEFAULT`. A scenario that
ignores it renders identically twice and looks like it is passing in both
modes.

## How conformance works

`tests/conformance/src/conf_lines.c` is compiled for the ZX, the Partner, and
the CPC in each mode. Every image is run on its own emulator, the top-left
256x192 of each raster is extracted, and everything is diffed against the ZX.

The Partner has exactly three documented exceptions, recorded with their pixel
budgets in `ACCEPTED` at the top of `tests/mcp/conformance.py`: slanted solid
lines, and the two text phases (it ships a different font). The CPC has **no**
exceptions in either mode -- it shares the ZX's font, stock cursors and
software rasteriser, so anything but an exact match is a bug.

## Commands

```sh
make tests             # everything
make zx-tests          # ZX differential suite
make partner-gdp-tests # Partner suite on the emulated EF9367
make cpc-tests         # CPC suite, both display modes
make conformance       # one program, every backend, diffed
make crossbench        # the same picture timed on every backend
make zx-bench          # T-state benchmarks
make cpc-bench         # CPC T-state benchmarks, both modes
make lib-size          # per-module code size
make lib-visuals       # PNG of every scenario, real and oracle, via MCP
make coverage          # gcov over the host build of the oracle
```

Most measurement targets take `ARGS=--diff` to compare against the recorded
baseline and `ARGS=--save` to re-record it. The golden-raster suites take
`ARGS=--bless` instead; read the divergence notes before blessing anything.

Iterating on one scenario is much faster than rebuilding everything:

```sh
make -C tests/zx one TEST=test_line_fan
python3 tests/mcp/run_zx_tests.py test_line_fan
python3 tests/mcp/run_cpc_tests.py cpc_prims
python3 tests/mcp/conformance.py conf_lines
```

To find out where the time goes in a benchmark:

```sh
python3 tests/mcp/profile_zx.py bench_bmp --top 12
python3 tests/mcp/profile_cpc.py bench_text 640x200
```

## Baselines

`tests/size/baseline.json`, `tests/zx/bench-src/baseline.json` and
`tests/cpc/bench-src/baseline.json` record the size and speed of the library at
a known-good point. Re-record with `ARGS=--save` after a deliberate change, and
use `ARGS=--diff` while optimizing.

A failed assembly leaves the previous binary in place, so a benchmark can
silently re-measure the old code -- which looks exactly like "the change had no
effect". Check that the build succeeded before believing a null result.

## Writing a scenario

Drop a `test_*.c` into `tests/zx/test-src/` (or a `*.c` into `tests/cpc/src/`)
and it is picked up automatically. Include the suite's header, end with
`TEST_END()`, and prefer seeding the screen with `seed_screen_wash()` when the
behaviour under test only shows up over existing content: on a blank screen a
`CO_BACK` draw and a no-op look identical.

Seed the *asymmetric* case in particular. A masked sprite drawn on a cleared
screen looks the same whether or not its mask is applied, and opaque `CO_BACK`
text matches by coincidence when the gap colour equals the background. Both of
those hid real bugs until a scenario drew over solid ink.

Helpers in the test headers never call into libgpx, so a broken primitive
cannot hide a failure by corrupting the scaffolding.
