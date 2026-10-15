# Save a ggplot at HVTI manuscript defaults

A thin wrapper around
[`ggplot2::ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html)
that enforces the house manuscript figure size, 6 inches wide by 4
inches tall, so journal figures come out at a consistent size in one
call. It is the manuscript counterpart of
[`save_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/save_ppt.md),
which enforces the slide panel box.

## Usage

``` r
save_manuscript(
  plot,
  file,
  width = 6,
  height = 4,
  units = "in",
  device = NULL,
  dpi = 300,
  draft_file = NULL,
  draft_dpi = NULL,
  format = c("tiff", "png"),
  ...
)
```

## Arguments

- plot:

  A
  [`ggplot2::ggplot()`](https://ggplot2.tidyverse.org/reference/ggplot.html)
  object, e.g. `plot(hv_*())` finished with
  [`theme_hv_manuscript()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md).

- file:

  Output file path. Its extension sets the format (`.pdf`, `.tiff`,
  `.png`, ...). Without an extension, `format` supplies one.

- width, height, units:

  Figure size. Default `6` x `4` `"in"`, the HVTI manuscript default.

- device:

  Graphics device. `NULL` (default) lets ggplot2 pick from the file
  extension, and a TIFF is written LZW-compressed by
  [`ragg::agg_tiff()`](https://ragg.r-lib.org/reference/agg_tiff.html).
  When you pass a `device`, `file` is used as given and `format` adds no
  extension. For font embedding in a PDF, pass
  [`grDevices::cairo_pdf`](https://rdrr.io/r/grDevices/cairo.html)
  (requires cairo/X11 support).

- dpi:

  Resolution for raster formats. Default `300`.

- draft_file:

  Optional second output file path (typically `.png`). When supplied, an
  additional raster copy of `plot` is written here at the same
  `width`/`height`/`units`, for dragging into a Word draft manuscript.
  Default `NULL` (no draft copy written).

- draft_dpi:

  Resolution for `draft_file`. Default `NULL`, which falls back to
  `dpi`.

- format:

  Raster format, `"tiff"` (default) or `"png"`, for a `file` or
  `draft_file` given without an extension. A path that has an extension
  keeps it. Passing a `format` that contradicts a raster extension, such
  as `format = "png"` with a `.tiff` path, is an error.

- ...:

  Further arguments passed to
  [`ggplot2::ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html)
  for the primary `file`. Not applied to `draft_file`.

## Value

Invisibly, the `file` path, with the extension `format` added when it
had none.

## Details

Pair it with
[`theme_hv_manuscript()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md),
whose 12 pt `base_size` supplies the manuscript typography. Like
[`save_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/save_ppt.md),
`save_manuscript()` fixes the output geometry, not the theme; style the
plot first, then save.

The device is inferred from the file extension by default. A `.tif` or
`.tiff` file is written as an LZW-compressed TIFF at `dpi`, so a 6 x 4
in figure is 1800 x 1200 pixels, the same geometry as the PNG, without
the tens of megabytes an uncompressed TIFF takes. A path with no
extension takes one from `format`, which defaults to `"tiff"`, the
raster format journals ask for. An extension you write is never
overridden, so a `.png` path, such as one a Quarto or R Markdown report
embeds, stays a PNG: browsers do not display TIFF.

For a `.pdf` where you want fonts embedded (so 12 pt type renders
exactly as designed), pass `device = grDevices::cairo_pdf` (on a system
with cairo/X11 support).

Publisher-accepted formats, vector (PDF, EPS) or TIFF (a raster format
also accepted by journals), often produce large or fragile files when
dragged into a Word manuscript. Word has no native PDF-as-picture
support and silently converts them to bloated, sometimes unreadable EMF.
Pass `draft_file` (typically a `.png` path) to also write a small raster
copy alongside `file` in the same call: keep `file` as the publisher
deliverable submitted to the journal, and drag `draft_file` into the
Word draft instead.

## See also

[`save_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/save_ppt.md)
for slides,
[`theme_hv_manuscript()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md)
for the 12 pt typography,
[`hv_ggsave_dims()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_ggsave_dims.md)
for fixed-panel sizing. Worked examples live in the HVTI ggplot graphics
recipes book, <https://ehrlinger.github.io/hvtiGraphics/>.

## Examples

``` r
# \donttest{
p <- plot(hv_survival(sample_survival_data(n = 200, seed = 42))) +
  theme_hv_manuscript()
save_manuscript(p, file.path(tempdir(), "survival.pdf"))

# no extension: a 300 dpi, LZW-compressed survival.tiff
save_manuscript(p, file.path(tempdir(), "survival"))

# the same figure as a PNG
save_manuscript(p, file.path(tempdir(), "survival"), format = "png")

# also write a small draft PNG for dragging into Word
save_manuscript(p, file.path(tempdir(), "survival.pdf"),
                 draft_file = file.path(tempdir(), "survival_draft.png"))
# }
```
