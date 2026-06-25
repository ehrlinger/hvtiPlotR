# Plot an hv_venn object

Draws a 2-3 set Venn diagram using
[`ggvenn::ggvenn()`](https://yanlinlin82.github.io/ggvenn/reference/ggvenn.html)
and returns a bare ggplot2 object you can finish with `+`.

## Usage

``` r
# S3 method for class 'hv_venn'
plot(
  x,
  show_percentage = TRUE,
  show_counts = TRUE,
  fill = NULL,
  text_size = 4,
  set_name_size = 6,
  ...
)
```

## Arguments

- x:

  An `hv_venn` object.

- show_percentage:

  Logical; show each region's percentage. Default `TRUE`.

- show_counts:

  Logical; show each region's count. Default `TRUE`.

- fill:

  Optional vector of fill colours, one per set. `NULL` (default) uses
  ggvenn's palette.

- text_size:

  Region label text size. Default `4`.

- set_name_size:

  Set name text size. Default `6`.

- ...:

  Forwarded to
  [`ggvenn::ggvenn()`](https://yanlinlin82.github.io/ggvenn/reference/ggvenn.html)
  for finer styling (unlike most `plot.hv_*` methods, which ignore
  `...`; ggvenn bakes labels into its geoms, so forwarding is the only
  way to reach them).

## Value

A [`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html)
object. Compose with
[`theme_hv_manuscript`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md),
[`labs()`](https://ggplot2.tidyverse.org/reference/labs.html), etc.

## See also

[`hv_venn`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_venn.md)

## Examples

``` r
dta <- sample_upset_data(n = 300, seed = 42)
v   <- hv_venn(dta, sets = c("AV_Replacement", "MV_Replacement", "CABG"))
plot(v) + theme_hv_manuscript()

```
