# Toolchain and emulator packaging — pending work

Both items below are the same shape: libgpx currently reaches outside its
pinned Docker images for part of the CPC and Partner setup, because the images
do not yet carry what it needs. Neither is a libgpx defect, and neither blocks
a build today — but both mean a fresh checkout does not behave identically to
this machine, which is exactly what the pinned images exist to prevent.

## 1. A CPC toolchain image (`wischner/xcc-z80-cpc`)

The ZX and Partner backends each build inside a dedicated image
(`wischner/xcc-z80-zx-spectrum`, `wischner/xcc-z80-idp`). The CPC does not:
`scripts/mk/toolchain.mk` sets

```make
DOCKER_CPC ?= wischner/xcc-z80
```

— the plain Z80 toolchain, with no emulator in it — and `amstrad-cpc-mcp` is
run as a native binary instead. `tests/mcp/cpcmcp.py` and `.mcp.json` both
default to an absolute path outside the repo:

```python
CPC_MCP = os.environ.get("CPC_MCP", "/home/tstih/data/retro-vault/amstrad-cpc-mcp")
```

The direction is the wrong way round compared with the Partner: there, Docker
is the default and `IDP_MCP` is the escape hatch. Here the local build *is*
the default, so `make cpc-tests`, `make cpc-bench` and the CPC half of
`make conformance` only run on a machine where that binary and its ROMs exist
at that path. CI cannot run them at all.

**When a CPC image is prepared**, it should ship `xcc`/`xas`/`xld`/`xar` plus
`amstrad-cpc-mcp` and the CPC ROMs, exactly as the ZX image ships
`zx-spectrum-mcp`. Then:

* point `DOCKER_CPC` at it in `scripts/mk/toolchain.mk`;
* invert the default in `cpcmcp.py` so the container is used unless `CPC_MCP`
  is set, mirroring `idpmcp.py`'s `DOCKER_IDP` / `IDP_MCP` pair;
* drop the absolute path from `.mcp.json`;
* teach `cpcmcp.py` to rewrite paths into the `/work` mount when it runs under
  Docker. Its `guest_path()` currently returns the host path unchanged, which
  is correct only for a native server.

## 2. Move the Partner MCP back to the packaged image

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
