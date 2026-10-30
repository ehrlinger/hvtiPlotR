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
  footnote = NULL,
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

- footnote:

  Optional provenance note, `NULL` (default) for none. A character
  vector of fields, which are joined by a middle dot (U+00B7) with a
  space either side, or a single string, which is split into fields at
  that separator. Fields may not contain line breaks. With `NULL`, the
  output is exactly what it is without the argument. R's
  [`pdf()`](https://rdrr.io/r/grDevices/pdf.html) device draws only
  Latin-1 text and warns on anything else; use
  `device = grDevices::cairo_pdf` for a note in another script.

- ...:

  Further arguments passed to
  [`ggplot2::ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html)
  for the primary `file`. Not applied to `draft_file`.

## Value

Invisibly, the `file` path, with the extension `format` added when it
had none. With a `footnote`, the path carries the attribute `"dims"`, a
list of the saved `width`, `height` and `units` of `file`, after any
`scale` passed in `...`, the height including the strip, and, when
`draft_file` is written, `"draft_dims"` for that file.

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

Pass `footnote` to print the figure's provenance, typically the fields
[`provenance_footnote()`](https://ehrlinger.github.io/hvtiPlotR/reference/provenance_footnote.md)
builds, in a strip reserved below the plot. The strip is added to the
figure, never drawn over it: the plot keeps its `width` x `height` and
the saved file is taller by the strip. The note is measured with each
output device's own font metrics, so a PDF, PNG and TIFF of one figure
may get strips of slightly different height. It is set at 8 pt and
shrinks to fit one line, down to a floor of 6 pt. Past the floor it
wraps: first between fields, so a field that fits on a line, the commit
ID among them, is never broken; then inside a field too wide for a line,
at `/`, `.` and spaces, so a long job path breaks at its directory and
name parts. Nothing is clipped or truncated; the strip grows to as many
lines as the note needs. The saved height is rounded up to a whole pixel
(raster) or point (PDF), so the reported height is the height written.
The note goes on publication figures too: a journal crops it in
typesetting, and the study's copy keeps the record of which version of
the job drew it.

## See also

[`provenance_footnote()`](https://ehrlinger.github.io/hvtiPlotR/reference/provenance_footnote.md)
to build the `footnote` fields,
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

# print the render's provenance in a strip below the figure
out <- save_manuscript(
  p, file.path(tempdir(), "survival.pdf"),
  footnote = provenance_footnote(
    commit = "3f9c2a1", job = "30_analyses/survival.qmd",
    time = as.POSIXct("2026-10-29 14:40")
  )
)
attr(out, "dims")
#> $width
#> [1] 6
#> 
#> $height
#> [1] 4.291667
#> 
#> $units
#> [1] "in"
#> 
# }
```
