# Render a plot or page as an interactive HTML widget

Wraps
[`ggiraph::girafe()`](https://davidgohel.github.io/ggiraph/reference/girafe.html)
for EDA pages drawn with `interactive = TRUE` (see
[`plot.hv_eda()`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hv_eda.md)),
so hovering a bar shows its tooltip.

## Usage

``` r
hv_girafe(x, width = 6.5, height = 9, ...)
```

## Arguments

- x:

  A ggplot or patchwork object.

- width, height:

  Size of the drawing in inches. Default 6.5 by 9, the printed page.

- ...:

  Passed to
  [`ggiraph::girafe()`](https://davidgohel.github.io/ggiraph/reference/girafe.html),
  for example `options`.

## Value

An htmlwidget of class `girafe`. Printed in a knitr or Quarto HTML
document, it is drawn in place.

## Details

**No fonts are embedded.** By default ggiraph embeds its font files in
the widget, which made one 8-panel page 8.6 MB instead of 0.4 MB. Here
text is set in Arial (or the nearest system sans serif) and the browser
draws it in the reader's own copy. Saved PNG and PDF output is
unaffected.

## See also

[`plot.hv_eda()`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hv_eda.md),
[`plot.hv_eda_pages()`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hv_eda_pages.md)

## Examples

``` r
if (requireNamespace("ggiraph", quietly = TRUE)) {
  dta <- sample_eda_data(n = 300, seed = 42)
  pages <- plot(hv_eda_pages(dta, section = "percent"),
                ncol = 2, nrow = 2, interactive = TRUE)
  widget <- hv_girafe(pages[[1]], width = 6.5, height = 6)
  class(widget)
}
#> [1] "girafe"     "htmlwidget"
```
