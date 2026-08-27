# idp-emu / idp-mcp — defects and verification checklist

This document records emulator-facing observations only. Reproduction cases
should use minimal register and MCP command sequences, independent of any
guest program or graphics library.

Everything previously listed here has been fixed in `idp-emu`. Verified
against the local build 2026-08-27: CTRL2 vector line styles render (dotted
2 on 2 off, dashed 4 on 4 off, dash-dot 10/2/2/2), `include_border` selects
the raster (1056x624 with, 1024x512 without), EF9367 busy duration varies
with the command and a vector's extent, and XOR mode toggles on erasing
strokes.

A packaged toolchain image can still be behind the emulator tree -- the one
named in `.mcp.json` was, on the day those fixes were verified. That is what
`IDP_MCP` is for: point it at a local `idp-mcp` build to run the suites
against current behaviour.

What remains below is not a defect list. It is EF9367 behaviour that still
needs checking against the datasheet or a physical Partner.

## Hardware behaviour to verify

These are not confirmed emulator bugs. They are hardware questions that need a
small conformance case and, ideally, comparison with a physical Partner.

### X/Y pen address persistence between commands

Question: after a vector completes, do the EF9367 X and Y address registers
remain at its endpoint until explicitly changed?

The datasheet describes X and Y as a plotter-like write address (p. 6-57) and
says the vector generator increments or decrements them (p. 6-66). It also
describes drawing-mode and pen-state selection as CTRL1 bit operations, which
suggests that changing those fields must not reset X or Y.

Emulator check:

1. Set X and Y once and issue a vector.
2. Without rewriting X or Y, issue a second vector using only new deltas and a
   direction command.
3. Verify that the second vector starts at the first vector's endpoint.
4. Repeat while changing drawing mode and pen state between the vectors; the
   start address must remain unchanged.

### Oblique vectors with one zero delta

Question: is an ordinary oblique-vector command with `DELTAX=0` or `DELTAY=0`
pixel-identical to the corresponding axis-parallel command?

The datasheet documents axis-parallel commands as variants that ignore one
delta register by treating it as zero (p. 6-66). The emulator currently makes
the ordinary zero-delta and special axis-parallel forms equivalent.

Emulator check: for every direction, drawing mode, and pen operation, compare
the raster and final X/Y address produced by:

- an oblique command with `DELTAX=0` against the vertical command
- an oblique command with `DELTAY=0` against the horizontal command

Any difference should be checked on physical hardware before changing the
emulator.
