# Developers' Journal

## Technological Debt
 - ZX Spectrum functions `_hline`, `_vline`, `_line`, `_stridexy`, and `_tinyxy` are not implemented. Version is not compilable.

## Log

### Updates on 27 Dec 2021
- Implemented `gpx_get_disp_page_resolution` for quick display resolution info.
- `gpx_set_clip_area` now allows NULL values and sets default resolution as clipping rectangle if passed.

### Updates on 26 Dec 2021
- The Iskra Delta Partner port compiles without warnings.
- Removed native dependency `_ef9367_draw_line` from portable function `gpx_draw_line`.