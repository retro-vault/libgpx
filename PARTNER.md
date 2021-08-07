# Iskra Delta Partner Internals

## Caching mode and pen status for performance

The library internally caches mode and pen status and requests for pen down and up and change to blit mode (XOR/NOR) are first evaluated against cached state. If equal, nothing is done. 

## How do I...

### ...set pen up?

`gpx_set_blit(BL_NONE);`

### ...set XOR mode?

Use the `gpx_set_blit(BL_XOR);`. The blit operation incorporates two commands: pen up/down, and the xor/nor flag into one command. Here is what happens when you set blit mode to
 * BL_NONE ... pen up
 * BL_COPY ... xor off, pen down
 * BL_XOR ... xor on, pen down

### ...draw a fast line?

The `gpx_draw_line()` is smart. It checks if line style is one of available built in partner styles (solid, dotted, dashed, dash and dot) and uses hardware acceleration if available. If not, it uses line dot by dot and that's a bit slower.

It implements mid point algorithm to draw long lines by dividing line length by two until it is less then 256 and then using the delta drawing functions.

### ...draw a fast pixel

You can't. There's no such thing on Partner, sorry. But all drawing operations (lines, rectangles, fills) internally use the delta functions to optimize drawing. And only use pixel drawing when nothing else is available. So whatever drawing operation you want to do - try to avoid drawing pixels. There are a lot of other options available: fast line drawing, optimized glyph drawing, fast rectangles, etc...

### ...write to a different page

The `gpx_set_page()` function accepts the `pgop` (page operation) parameter, which tells the system to set page for writing or for displaying. To wrote to page 1 but keep displaying page 0, use `gpx_set_page(1,PG_WRITE);`.