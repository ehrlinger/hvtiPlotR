# Plot an hvti_sankey object

Draws a cluster stability Sankey diagram using ggsankey geoms.
**Requires the ggsankey package.** Install with:

    remotes::install_github("davidsjoberg/ggsankey")

## Usage

``` r
# S3 method for class 'hvti_sankey'
plot(x, alpha = 0.8, label_size = 8, label_hjust = -0.05, ...)
```

## Arguments

- x:

  An `hvti_sankey` object.

- alpha:

  Transparency applied to flow bands and node labels. Default `0.8`.

- label_size:

  Font size for node labels in points. Default `8`.

- label_hjust:

  Horizontal justification offset for node labels. Default `-0.05`.

- ...:

  Ignored; present for S3 consistency.

## Value

A [`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html) object
using ggsankey geoms. Compose with
[`scale_fill_manual()`](https://ggplot2.tidyverse.org/reference/scale_manual.html),
[`labs()`](https://ggplot2.tidyverse.org/reference/labs.html),
[`theme()`](https://ggplot2.tidyverse.org/reference/theme.html), and
[`hvti_theme`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme.md).

## See also

[`hvti_sankey`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_sankey.md),
[`hvti_theme`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme.md)

## Examples

``` r
dta <- sample_cluster_sankey_data(n = 300, seed = 42)

if (requireNamespace("ggsankey", quietly = TRUE)) {
  plot(hvti_sankey(dta)) +
    ggplot2::labs(x = NULL, title = "Cluster Stability: K = 2 to 9") +
    hvti_theme("manuscript")

  # Subset to K = 2 to 6
  plot(hvti_sankey(dta, cluster_cols = paste0("C", 2:6))) +
    ggplot2::labs(x = NULL) +
    hvti_theme("manuscript")
}

```
