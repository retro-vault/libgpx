# CPC UI drawing, November 2026

Alto profiling in Charlie Papa Charlie identified opaque spans, clipped text,
and vertical window borders as substantial costs. The renderer already used
packed bitmap and text rows; there was no pixel-by-pixel bitmap fallback to remove.

Opaque COPY spans now resolve mode, pattern halves and phase once per row.
Only their two boundary bytes use coverage masks. Interior bytes use register
patterns; MODE 1 processes four screen bytes per loop and preserves the other
pen plane. Single-byte spans intersect both edge masks. Alternating patterns,
odd lengths, both colors, and MODE 2 remain supported.

Solid ascending vertical lines, including points, use direct segment clipping
and row stepping. Patterned and reversed verticals retain the general raster.
Text rejects invisible vertical bands and suffixes, and skips bitmap setup for
fully clipped leading glyphs. Text spacing, masking, XOR and clipping semantics
remain unchanged.

Building the supplied source exposed dot-prefixed macro parameters in the
Bresenham loops: xas tokenizes the dot separately, leaving those parameters
unsubstituted. Dot-free formal names now expand to the original local labels.
The actual loop instructions are unchanged.

Validation uses `make -C tests/cpc run`, in both 640x200 and 320x200 modes.
`ui_regressions.py` adds 96 vertical, 96 opaque-span and 36 clipped-text cases
per mode. Independent byte-level oracles retain random second-plane pixels and
untouched video-bank gaps. Existing line, bitmap, sprite and fill regressions
also pass. Set `CPC_MCP` to a Charlie MCP launcher and `CPC_ROMS` to its ROMs to
use Charlie instead of the emulator bundled in the compiler image.

The two phase-3 sprite golden files were stale relative to the current stock
cursor assets. Original and optimized span routines produced identical output
in all four phases of both modes; the independent sprite oracle also passed.
Only those two stale references changed.

Alto's end-to-end measurements and comparison with Infinity's Spectrum 128
are recorded in Alto's `docs/notes/CPC-PERFORMANCE.md`. Those results include
Alto input and redraw changes as well as these graphics improvements.
