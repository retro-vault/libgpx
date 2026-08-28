# Toolchain and emulator packaging — pending work

libgpx currently reaches outside its pinned Docker images for part of the
Partner setup, because the packaged image does not yet carry what it needs.
It is not a libgpx defect and does not block a build today — but it means a
fresh checkout does not behave identically to this machine, which is exactly
what the pinned images exist to prevent.

The matching CPC item is done: `wischner/xcc-z80-cpc` ships the toolchain,
`amstrad-cpc-mcp` and the CPC ROMs, and `scripts/mk/toolchain.mk`,
`tests/mcp/cpcmcp.py` and `.mcp.json` all use it. `CPC_MCP` is now only the
escape hatch for a local emulator build, mirroring `IDP_MCP`.

## Move the Partner MCP back to the packaged image

`tests/mcp/idpmcp.py` honours `IDP_MCP` to run a local `idp-mcp` build instead
of the one inside `wischner/xcc-z80-idp`. That escape hatch is currently
load-bearing: as of 2026-08-27 the packaged image lagged the emulator tree and
rendered every CTRL2-styled vector as continuous, while the local build
rendered the styles correctly (see `EMULATION.md` for what was verified).

**When the image is refreshed**, confirm against it directly rather than
assuming — draw one vector per CTRL2 style and check the four rasters differ:

```text
SOLID     ################################
DOTTED    ##..##..##..##..##..##..##..##..
DASHED    ####....####....####....####....
DOT_DASH  ##########..##..##########..##..
```

and that `include_border` selects the raster (1056x624 with, 1024x512
without). Then run `make tests` with `IDP_MCP` unset, so the default path is
the one being exercised.

Until then, anything that depends on hardware line styles has to be developed
with `IDP_MCP` pointed at a local build, and cannot be committed without
making the default setup fail.

### What this is holding up

`gpx_draw_line` walks every non-solid pattern in software on the Partner,
which measures about 48x slower than a hardware vector (`make crossbench`:
1,716 ms against 36 ms for the same rays). Two patterns fit an 8-bit `lpatt`
and could go to the vector generator instead:

| CTRL2 style | shape | period | `lpatt`, LSB-first |
|---|---|---|---|
| dotted | 2 on, 2 off | 4 | `0x33`, `0x66`, `0xCC`, `0x99` |
| dashed | 4 on, 4 off | 8 | `0x0F` `0x1E` `0x3C` `0x78` `0xF0` `0xE1` `0xC3` `0x87` |
| dash-dot | 10 on, 2 off, 2 on, 2 off | 16 | none — the period exceeds a byte |

A rotated pattern can still use the hardware: plot the first
`(period - k) mod period` pixels by hand, then start the vector after them so
the chip's own phase lines up. The rotation `gpx_draw_line` returns is a pure
function of the pattern and the pixel count, so it needs no read-back from the
chip — which was the original reason this was abandoned.

The remaining constraint is real and independent of packaging: the EF9367's
Bresenham picks different interior pixels from libgpx's, so this is only safe
for **axis-aligned** lines, where the two agree exactly. Slanted styled
vectors would diverge far beyond the accepted conformance budget.
