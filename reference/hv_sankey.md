# Prepare cluster stability Sankey data for plotting

Validates a wide cluster-assignment data frame, resolves node level
ordering, computes default node colours if not supplied, and
pre-computes the long-format Sankey data. Call
[`plot.hv_sankey`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hv_sankey.md)
on the result to obtain a bare `ggplot2` Sankey diagram using ggsankey
geoms.

## Usage

``` r
hv_sankey(
  data,
  cluster_cols = paste0("C", 2:9),
  node_levels = NULL,
  node_colours = NULL
)
```

## Arguments

- data:

  Data frame; one row per patient. Must contain all columns named in
  `cluster_cols`.

- cluster_cols:

  Character vector of column names giving the cluster assignments at
  each value of K, in ascending K order. Default `paste0("C", 2:9)`.

- node_levels:

  Character vector giving the display order of node labels (bottom to
  top within each column). If `NULL` (default), a lineage-preserving
  order is derived from the data so each child cluster sits next to its
  parent and flows stay uncrossed (see Details). If supplied, it is used
  verbatim but must cover every observed cluster label.

- node_colours:

  Named character vector mapping node labels to fill colours. If `NULL`
  (default), labels are mapped to an inline ColorBrewer `Set1` hex
  palette in `node_levels` order (no dependency on RColorBrewer). When
  there are more labels than palette colours the palette is recycled
  with a warning.

## Value

An object of class `c("hv_sankey", "hv_data")`:

- `$data`:

  The long-format Sankey data frame (four columns: `x`, `node`,
  `next_x`, `next_node`).

- `$meta`:

  Named list: `cluster_cols`, `node_levels`, `node_colours`,
  `n_patients`, `n_k`.

- `$tables`:

  Empty list.

## Details

By default (`node_levels = NULL`) the node order is read from the data,
not from one column's factor levels. We take every label that appears in
any `cluster_cols` column, so no finer-K cluster is dropped to `NA`, and
place each child next to its parent: the coarser-K cluster that
contributes most of its members. Siblings end up together, the way
leaves sit in a dendrogram, and the flows stay short and uncrossed. Pass
`node_levels` yourself to override this; it is then used as given, but
it must name every label in the data.

## See also

[`plot.hv_sankey`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hv_sankey.md),
[`sample_cluster_sankey_data`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_cluster_sankey_data.md)

## Examples

``` r
dta <- sample_cluster_sankey_data(n = 300, seed = 42)

if (requireNamespace("ggsankey", quietly = TRUE)) {
  # 1. Build data object
  sn <- hv_sankey(dta)
  sn  # prints cluster cols and node count

  # 2. Bare plot -- undecorated ggplot returned by plot.hv_sankey
  p <- plot(sn)

  # 3. Decorate: axis labels and theme
  p +
    ggplot2::labs(x = NULL, title = "Cluster Stability: K = 2 to 9") +
    theme_hv_poster()
}
#> Warning: The `size` argument of `element_rect()` is deprecated as of ggplot2 3.4.0.
#> ℹ Please use the `linewidth` argument instead.
#> ℹ The deprecated feature was likely used in the ggsankey package.
#>   Please report the issue at <https://github.com/davidsjoberg/ggsankey/issues>.

```
