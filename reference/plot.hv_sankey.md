# Plot an hv_sankey object

Draws a cluster stability Sankey diagram using ggsankey geoms.
**Requires the ggsankey package.** Install with:

    remotes::install_github("davidsjoberg/ggsankey")

## Usage

``` r
# S3 method for class 'hv_sankey'
plot(
  x,
  flow_alpha = 0.5,
  label_alpha = 0.3,
  label_size = 8,
  label_hjust = -0.05,
  group_labels = NULL,
  alpha = NULL,
  ...
)
```

## Arguments

- x:

  An `hv_sankey` object.

- flow_alpha:

  Transparency of the flow bands and the dashed column guides, \\\[0,
  1\]\\. Default `0.5`.

- label_alpha:

  Transparency of the node-label fill, \\\[0, 1\]\\. Default `0.3` (a
  light tint behind black text).

- label_size:

  Font size for node labels in points. Default `8`.

- label_hjust:

  Horizontal justification offset for node labels. Default `-0.05`.

- group_labels:

  Optional named character vector mapping a `cluster_cols` value to a
  milestone label. When supplied, that column's x-axis tick shows
  `"<col>\n<label>"`; unlisted columns show the bare column name.
  Default `NULL` (bare column names).

- alpha:

  **Deprecated.** If supplied, sets both `flow_alpha` and `label_alpha`
  (back-compatibility) and emits a message steering you to the two new
  arguments. Default `NULL`.

- ...:

  Ignored; present for S3 consistency.

## Value

A [`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html) object
using ggsankey geoms. Compose with
[`scale_fill_manual()`](https://ggplot2.tidyverse.org/reference/scale_manual.html),
[`labs()`](https://ggplot2.tidyverse.org/reference/labs.html),
[`theme()`](https://ggplot2.tidyverse.org/reference/theme.html), and
[`theme_hv_manuscript`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md).

## See also

[`hv_sankey`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_sankey.md),
[`theme_hv_manuscript`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md)

## Examples

``` r
dta <- sample_cluster_sankey_data(n = 300, seed = 42)

if (requireNamespace("ggsankey", quietly = TRUE)) {
  plot(hv_sankey(dta)) +
    ggplot2::labs(x = NULL, title = "Cluster Stability: K = 2 to 9") +
    theme_hv_poster()

  # Subset to K = 2 to 6
  plot(hv_sankey(dta, cluster_cols = paste0("C", 2:6))) +
    ggplot2::labs(x = NULL) +
    theme_hv_poster()
}

```
