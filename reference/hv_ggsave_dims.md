# Compute `ggsave()` dimensions for a fixed panel content area

Given a fitted ggplot, returns `width` and `height` values such that,
when passed to
[`ggplot2::ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html),
the resulting file has a panel content area matching `width` / `height`.
The "panel content area" is the rectangular bounding box of the gtable
cells tagged `panel` — i.e., the smallest rectangle that encloses every
plotting panel. Whatever grobs fall inside that rectangle (e.g.,
inter-panel gutters and strip rows that sit between facet rows) are
counted as part of the target; everything outside it (axes, axis titles,
plot title, caption, legend, plot margins, and any strips that sit
above/below or beside the panel block such as `facet_grid` side strips)
is counted as chrome.

## Usage

``` r
hv_ggsave_dims(plot, width, height, units = c("in", "cm", "mm"))
```

## Arguments

- plot:

  A ggplot (or patchwork) object.

- width:

  Target panel content area width, in `units`.

- height:

  Target panel content area height, in `units`.

- units:

  One of `"in"`, `"cm"`, `"mm"`. Default `"in"`.

## Value

A named list with elements `width`, `height`, `units` — shaped to splat
directly into
[`ggplot2::ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html)
via [`do.call()`](https://rdrr.io/r/base/do.call.html) (see examples).

## Details

Useful for multi-panel figure sets where a constant data region is
required across PDFs regardless of label length or legend placement.
Always measured with a PDF sizing device, which is why `units` is
limited to length (inches, cm, mm) — DPI is irrelevant for vector
output.

## Examples

``` r
if (FALSE) { # \dontrun{
p <- ggplot2::ggplot(mtcars, ggplot2::aes(hp, mpg)) +
  ggplot2::geom_point() +
  ggplot2::labs(title = "Long title that eats vertical space",
                x = "Horsepower", y = "Miles per gallon")

dims <- hv_ggsave_dims(p, width = 4, height = 3)
do.call(
  ggplot2::ggsave,
  c(list(filename = "fig.pdf", plot = p), dims)
)
} # }
```
