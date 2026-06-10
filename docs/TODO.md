# libgpx ZX Backend Optimization TODO

**Scope**: All code under `src/zx/`.

**Goals**
- **Size**: Reduce code size for ROM-oriented targets (the primary motivation for the hand-written assembly in the first place). Target the library payload measured by `make lib-size`.
- **Speed**: Improve hot drawing paths (pixels, h/vlines, bitmap blits, text, sprites) while keeping behavior identical to the C oracle in `tests/zx/stub/gpx_stub.c`.
- Preserve the existing SDCC `sdcccall(1)` + callee-cleans-stack ABI and the real-vs-oracle test discipline.

All changes must continue to pass `make tests` (and the visual/coverage/size flows).

## Constraints

- **Font format is immutable.** The serialized layout of `font_t` (header fields, `FONT_FLAG_*`, offset table at byte 8, LE/BE support, and inline `bmp_t` glyph payloads) is frozen. This includes the "Envy" font data in `_gpx_font_envy.s`. Both `gpx_get_system_font()` and `gpx_get_tiny_font()` currently alias the same blob for size reasons. No optimization work may change the on-wire font format, the offset table encoding, or how glyphs are stored/parsed inside font blobs. All text path improvements (drawing, measurement, gap fill) must consume the existing format exactly as defined in `include/libgpx.h` and interpreted by the current assembly.

## High-Level Observations

- The ZX backend is mature and already uses fast paths (dedicated hline/vline, byte-span hline, custom video row addressing, 2-plane windowed bitmap blitter).
- Major size and speed costs come from:
  - Heavy per-call `push ix; ld ix,#0; add ix,sp` frames + repeated `(ix)` accesses even in setup.
  - Duplicated logic for coordinate normalization, pattern rotation/reversal, mask computation, and clipping across modules.
  - Every plotted pixel in Bresenham going through the full `_gpx_draw_pixel` public entry (stack frame + full clipping).
  - The bitmap blitter (`gpx_bmp.s`) is by far the largest and most complex module (~860 lines of sophisticated per-byte windowing, shifting, masking, and mode dispatch).
  - `__rect_cmp16s_lt` and clip helpers are called extremely frequently.
  - Mask/rotate loops (djnz + srl/rl) instead of small lookup tables.
  - Text gap-fill and some sprite paths go through heavy rectangle/bitmap machinery.
- The C stub oracle + emulator harness is an excellent safety net for refactoring.

## Priority Proposals

### 1. Foundational: Fast Internal Pixel Path (High Impact on Speed + Size)

> **STATUS (done)**: `__gpx_plot_raw` register-fed core added in `gpx_draw_pixel.s`
> (DE=x, HL=y, BC=clip, A=packed color|mode); `gpx_draw_pixel` is now a thin
> wrapper and Bresenham calls the core directly (no per-pixel IX frame / stack
> marshalling, ~100 T/pixel saved). Clipping stays per-pixel so the oracle still
> matches. Covered by `test_plot_raw.c`. The hline/vline byte loops already write
> bytes directly and don't need the plotter.

**File**: `gpx_draw_pixel.s`, `_gpx_bresenham_line.s`, `_gpx_hline.s`, `_gpx_vline.s`

**Problem**
- Bresenham calls the full public `_gpx_draw_pixel` (with clip pointer) for every pixel on a general line. This is very expensive.
- Even the no-clip fast path in `draw_pixel` still builds an IX frame and does several tests.

**Proposals**
- Introduce an internal `__gpx_plot_pixel_raw` (or similar) that assumes on-screen coordinates, no clip, and takes color/mode in registers or a very small frame. Used by:
  - Bresenham inner loop (when no clip or after initial acceptance).
  - Hline/vline byte loops where we already know the byte and bit.
- Keep the public `_gpx_draw_pixel` as a thin wrapper that does the quick [0..255]x[0..191] + optional clip rejection then tails into the raw plotter.
- In the raw plotter, compute the VRAM address + mask with a small unrolled/jump-table mask generator or 8-byte rotate table instead of the djnz loop.
- Consider a "plot with current pattern bit" variant for line drawers so pattern rotation can stay in registers.

**Expected wins**: Big speed win on all non-axis-aligned lines and clipped general cases. Modest size win by removing duplicated early-exit + clip logic from callers.

### 2. Horizontal Line (`_gpx_hline.s`) — Core Hot Path

**Current state**: Excellent algorithmic approach (byte spans + first/middle/last masks + pattern phase). 11-byte IX frame + pattern reversal + rotation done on every call.

**Proposals (Size + Speed)**
- Factor the pattern-reversal + x-phase rotation into a small shared helper (currently duplicated in `gpx_fill_rectangle.s` and the stub).
- Provide a raw entry that skips all clipping and the original-x tracking when the caller (fill, rect, already-clipped hline) has already normalized.
- Hoist color inversion (CO_BACK) and mode selection out of the per-byte path; precompute an "effective pattern byte" once.
- Replace the `ghl_apply_cpy_mask` / `ghl_apply_xor_mask` with inline or tail-called versions that avoid the extra push/pop bc on every call.
- For the single-byte span fast case, special-case it earlier with fewer IX reads.
- Consider a table-driven mask generator (8 bytes for 0xFF >> n and 0xFF << (7-n)).

**Related**: `gpx_draw_rectangle.s` calls `__gpx_hline` twice and then falls back to per-pixel sides. The side pixels could use a raw vline or direct plot.

### 3. Vertical Line (`_gpx_vline.s`)

**Current state**: Good register hot loop (`B=patt`, `C=mask`, `DE=count`, `HL=ptr`, `rrc b` + `__vid_nextrow`).

**Proposals**
- Hoist color/mode out of `gvl_apply_mask` (the three small tails still read `(ix)` on every plotted pixel).
- Provide a raw entry point (no clip, y0<=y1, x on screen) used by rectangle sides and bresenham when it degenerates to vertical.
- The mask generation loop can use a table.
- When pattern is solid (0xFF), have a specialized "solid vline" path that just ors/ands/xors the mask byte down the column without rotating anything.

### 4. Bresenham Line (`_gpx_bresenham_line.s`)

**Current state**: 25-byte frame. Every plotted pixel does a full `_gpx_draw_pixel` call (including clip). Pattern is rotated via memory (`rrca` + store).

**Proposals (High Priority)**
- After initial acceptance (or when clip==NULL), switch to a raw pixel plotter (see item 1).
- Keep pattern state in a register (or a single memory byte touched minimally) inside the loop.
- Precompute `dx`, `dy`, `sx`, `sy`, `err` more compactly; many of the 16-bit locals are only used at setup.
- Consider separate "mostly-horizontal" vs "mostly-vertical" unrolled decision paths (classic optimization) to reduce the two comparisons per step.
- When `lpatt == 0xFF`, bypass pattern test entirely.

**Size note**: The current implementation is reasonably compact for a full 16-bit clipped bresenham; the main bloat is the frame + repeated pixel call overhead.

### 5. Bitmap Blitter (`gpx_bmp.s`) — Largest Single Target

This is the biggest file and implements the most sophisticated logic (full 16-bit clip intersection, source skipping, 2-plane masked + unmasked, arbitrary shift, per-byte keep/inside masks, multiple draw modes, and a 2-byte sliding window for sub-byte alignment).

**Proposals (Size first, then Speed)**
- **Table-driven shifts and masks**: Many small djnz loops that build `lmask`, `rmask`, `rshift` windows, etc. An 8- or 16-byte table (or two) plus a couple of indexed loads would be smaller and faster.
- **Factor the 2-byte window logic**: The hot path inlines `gb_win`; the cold path calls it. The windowing + `SUB`/`SRCREMAIN`/`REMAINDER` state machine is complex. Consider a small set of specialized inner loops for the common cases (no shift, shift < 4, stride=1, unmasked, etc.).
- **Reduce the IY frame**: `L_SIZE` is ~76 bytes. Many fields are only used in setup or at row boundaries. Push less per call; recompute cheap values (e.g. `L_DSTLAST`) or pass in registers across row transitions.
- **Early outs and span=1 fast path**: The single-destination-byte case is already detected; make it even leaner (fewer IY traffic).
- **Mode dispatch**: The `L_DRAWMODE` table (0..3) is good, but the public "skip zero bits" path still has extra ANDs. Provide specialized entry points from text (`_gpx_draw_bmp_clip` already exists) for the common `BM_CPY + CO_FORE` glyph case (still consuming standard serialized font glyphs).
- **Source row skipping**: The current loop walks source rows with repeated `add hl, stride`. A small multiply or unrolled advance for small `SRCY` values may help, but size is more important here.
- Specialized inner loops or fast paths for common small glyph sizes (e.g. many 8px-wide font glyphs) are allowed only when they continue to parse glyphs from the existing frozen font format and produce identical results.

This module is the place where a 10-20% size reduction in the whole library is most plausible.

### 6. Text and Measurement

**Files**: `gpx_draw_text.s`, `gpx_measure_text.s`, `gpx_bmp.s` (via `_gpx_draw_bmp_clip`)

**Constraints**: All work here must operate strictly on the existing frozen `font_t` serialized format (see top-level Constraints section). No changes to header layout, offset table, glyph encoding, or flags are permitted. The current aliasing of system and tiny font to the same Envy blob is intentional for footprint.

> **STATUS**: gap-fill behavior is now codified in the oracle stub and covered by
> `test_text_gaps.c` (gaps are filled with opaque inverse color, not transparent;
> validated over a solid band + under a clip). Also fixed a latent stub divergence:
> glyphs render OPAQUE (mode-aware CPY) on the real backend, now matched in the stub
> + tested over a background. The gap-fill FAST PATH below is still TODO but is now
> safely testable.

**Proposals**
- Gap-fill (the inter-character advance + empty glyph "inverse color" fill) currently builds a `rect_t` on the stack and calls `_gpx_fill_rectangle` (which itself does heavy normalization + hline dispatch). For the common case of small advance (often 1) this is extremely heavy.
  - Provide a fast internal "fill horizontal span with solid pattern" (or a height-bounded horizontal fill primitive) that the text drawer can call directly. This must still respect the current font's `advance` and `empty_width` values read from the serialized header.
- `gpx_measure_text` and the text drawer duplicate a lot of font header parsing and offset-table walking. Consider a small shared internal helper (e.g. "get glyph width and bmp_t* for a codepoint") that both can use. The helper must parse the existing header + offset table exactly as today.
- The BE/LE offset flag test is fine, but the "missing glyph" path (offset==0 or unsupported encoding) goes through the same empty-width fill. Measure can short-circuit earlier while still reading the same `empty_width` field.
- Specialized fast paths inside the text drawer (e.g. for the common `BM_CPY + CO_FORE` glyph case, or for stride-1 1bpp glyphs) are allowed, provided they still walk the standard serialized font and hand the same glyph `bmp_t` payloads to the bitmap machinery (or a thin internal variant).

### 7. Sprites (`gpx_show_sprite.s`, `gpx_hide_sprite.s`, `_gpx_sprite_blit_raw.s`, `_gpx_store_background.s`)

**Current state**: Quite sophisticated (right/bottom clip only, shift handling with 3-byte spans, pinned IY pointers, masked vs standard, background capture into a stride-2 bmp_t).

**Proposals**
- There is some conceptual overlap with the main bitmap blitter's shift + mask + span logic. If the sprite size cap (16x16) is firm, a more compact specialized implementation may be smaller than the current general one.
- `store_background` clears the whole 32-byte payload with `ldir` even for smaller visible sizes — acceptable, but the subsequent per-row masking still runs for the full declared w/h.
- Hide path (`gpx_hide_sprite`) forces "standard copy mode" (A=1). This is correct but the blitter has a lot of setup for this simple case.
- Consider a "restore from background bmp" fast path that knows the exact stride-2 layout and does straight byte copies (or masked copies) with the pre-stored shift information.

### 8. Clipping & Rect Infrastructure (Cross-Cutting Size Win)

Multiple overlapping implementations:
- Stub has its own Cohen-Sutherland + line clip.
- Asm has `__gpx_cohen_sutherland` + `_gpx_cs_intersection_bisect` (bisection, not the incremental version), `__clip_seg`, `__rect_unpack_norm`, `__gpx_clip_rect_effective`, `__gpx_point_in_rect`, `__gpx_line_needs_clip`, and the per-primitive clip code in pixel/hline/vline/fill/bmp.
- `__rect_cmp16s_lt` is small but called from almost every module.

**Proposals**
- Unify on one line-clipping strategy for the asm backend (the current bisection is faithful to the oracle). Consider whether the full Cohen-Sutherland state machine is worth the size for the relatively rare "line crosses clip edge in complex ways" case vs. a simpler "clip endpoints then let the drawer reject pixels".
- Provide a single `clip_line_to_rect` that hline/vline/bres can share instead of each doing partial axis clips + `__clip_seg`.
- Make `__rect_cmp16s_lt` even smaller or inline the common "both positive / both negative" fast path at key call sites.
- The rect normalization in `_rect_helpers.s` (`__rect_unpack_norm`) and the one in `fill_rectangle` / `draw_rectangle` have duplicated swap logic.

### 9. Video & Misc Utilities

**Files**: `_video.s`, `gpx_clrscr.s`, `gpx_create.s`, accessors, `_rect_helpers.s`

- `__vid_rowaddr` and `__vid_nextrow` are well-tuned for the Spectrum layout. `__vid_nextrow` is already register-friendly.
- Consider a "rowaddr + X byte offset" combined helper to reduce the three-instruction sequence that appears in many places (`call __vid_rowaddr; ld a, byte; add a,l; ld l,a; jr nc,ok; inc h`).
- `clrscr` is fine (two `ldir`s + border). It always resets attributes/border — document whether callers ever want to preserve them.
- Trivial accessors (`gpx_width`, `gpx_height`, `gpx_set_page`, `gpx_destroy`, `gpx_get_*_font`, `gpx_get_stock_bmp`) are already minimal. The only easy size win is to merge the three get-font/stock functions if the linker isn't already folding identical tails.
- `gpx_create` always calls `clrscr`. This matches the documented behavior but costs every init.

### 10. Data (Fonts + Cursors)

- `_gpx_font_envy.s` and the cursor bitmaps in `_gpx_cursors.s` are hand-packed. Look for any repeated row patterns across cursors that could be deduplicated via small subroutines (probably not worth it — data is tiny compared to code).
- The current aliasing of system and tiny font to the exact same `_gpx_font_envy` blob (see `_gpx_get_tiny_font.s`) is intentional for size. Because the font format itself is frozen, any future "tiny" font would still have to be a valid `font_t` blob using the same layout; the two getter functions can simply return different pointers if a second blob is ever added. No format changes are permitted to enable a smaller tiny font.

## Cross-Cutting Techniques

1. **Lookup tables for shifts/masks/rotates** (almost always a win on Z80 for both size and speed when the domain is 0..7).
2. **Reduce IX frame traffic in hot loops**. Pin pointers (as already done nicely with IY in the sprite and bmp code) or move live state into registers across loop iterations.
3. **Specialized solid-pattern fast paths** (lpatt==0xFF, fpatt all 0xFF, etc.).
4. **Tail calls and raw internal entries** instead of full public API round-trips.
5. **Callee-cleanup consolidation**. The manual `pop de; ld hl,#N; add hl,sp; ld sp,hl; push de` sequences are repeated and error-prone. A small macro or shared epilogue helper can save bytes if register pressure allows.
6. **Self-modifying code** (classic Spectrum trick) for the inner byte loops of hline or the bmp blitter if the code is running from RAM and size is secondary to speed. Use with care (the current design appears re-entrant/thread-safe on the stack).
7. **Profile-guided specialization** using the existing test corpus (many tests exercise spans, patterns, edge clips, off-screen, xor, etc.).

## Validation & Process

- Every change must pass the full `make tests -j1` (real vs. oracle byte-compare on all ~35 ZX scenarios).
- Use `make lib-size` before/after to quantify payload impact.
- Use `make stub-visuals` / `make lib-visuals` for visual spot-checks of complex features (clipped bitmaps, patterned fills, sprites, text gapfill).
- For large refactors of `gpx_bmp.s` or the line drawers, consider adding a couple of extra unit tests in `tests/zx/test-src/` that stress the modified paths (e.g., all shift combinations for blits, long patterned lines, etc.).
- Keep the C stub (`tests/zx/stub/gpx_stub.c`) in sync with any semantic changes (it is the executable specification).

## Suggested Order of Attack (Rough)

1. Fast internal pixel plotter + wire Bresenham to it (biggest easy speed win).
2. Solid-pattern special cases in hline/vline + table-driven masks.
3. Reduce duplication in pattern reversal/rotation (hline + fill).
4. Table-driven masks + smaller frame in the bitmap blitter (biggest size target).
5. Fast gap-fill path for text (big perceived speed win for UI).
6. Unify clipping helpers and reduce `__rect_cmp16s_lt` traffic.
7. Sprite background/blit compaction.

Contributions that come with before/after `lib-size` numbers and a note that `make tests` is green are especially welcome.

---

*This document lives in the repo so that optimization work stays coordinated with the strong test harness and the "size first for ROM targets" philosophy of the project.*