# amstrad-cpc-mcp — defects and verification checklist

This document records emulator-facing observations only. Each item is either a
detected defect in `amstrad-cpc-mcp` or CPC behaviour that still needs to be
checked against real hardware. Reproduction cases use minimal register and MCP
command sequences, independent of any guest program or graphics library.

## Open defects

### The 640x200 crop is one scanline too high

`machine::display_pixels()` crops the 768x272 overscan framebuffer at the
fixed constant `display_y = 36` (`lib/cpc/include/cpc/machine.h`). The actual
display area starts one line lower, so `screen`/`screenshot` with
`include_border: false` prepend one border scanline and clip the last
displayed line.

Measured two independent ways, both giving rows 37..236:

1. Boot stock CPC6128 firmware to BASIC, then recolour the border away from
   the paper so the display area can be seen:

   ```
   write_port 0x7F00 0x10     # select the border pen
   write_port 0x7F00 0x54     # hardware colour 20, black
   screenshot include_border=true
   ```

   The paper (hardware colour 4) occupies exactly rows 37..236.

2. Program the CRTC directly with the stock values the firmware itself uses
   (R0=63, R1=40, R2=46, R3=0x8E, R4=38, R5=0, R6=25, R7=30, R8=0, R9=7,
   R12=0x30, R13=0), clear the screen, and set the first and last displayed
   scanlines. They appear at rows 37 and 236 of the overscan frame.

So `display_y` should be 37, not 36. As it stands the last line of every
`include_border: false` capture is lost, which a program that draws a border
around the full 200 lines shows immediately.

Workaround in libgpx: capture with `include_border: true` and crop
`(64, 37, 704, 237)`.
