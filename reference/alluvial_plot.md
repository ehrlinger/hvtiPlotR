# Sankey / Alluvial Plot

Produces a Sankey (alluvial) diagram using
[`ggalluvial::geom_alluvium()`](http://corybrunson.github.io/ggalluvial/reference/geom_alluvium.md)
and
[`ggalluvial::geom_stratum()`](http://corybrunson.github.io/ggalluvial/reference/geom_stratum.md).
Axes are specified as a character vector so the number of stages is not
hard-coded. Returns a bare ggplot object for composition with `scale_*`,
[`labs()`](https://ggplot2.tidyverse.org/reference/labs.html), and
[`hvti_theme()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme.md).

## Usage

``` r
alluvial_plot(
  data,
  axes,
  y_col = "freq",
  fill_col = NULL,
  axis_labels = NULL,
  stratum_fill = "grey80",
  stratum_width = 1/4,
  flow_width = 1/6,
  alpha = 0.8,
  knot_pos = 0.4,
  show_labels = TRUE
)
```

## Arguments

- data:

  A data frame in wide alluvial format: one row per axis-value
  combination, a numeric weight column, and one column per axis.

- axes:

  Character vector of column names to use as axes, in left-to-right
  display order. Minimum two columns.

- y_col:

  Name of the numeric weight column (counts or proportions). Default
  `"freq"`.

- fill_col:

  Name of the column to map to the flow fill and colour aesthetics, or
  `NULL` for a single fill. Default `NULL`.

- axis_labels:

  Character vector of axis labels for the x-axis, the same length as
  `axes`. Defaults to `axes` (column names).

- stratum_fill:

  Fill colour for the stratum bars. Default `"grey80"`.

- stratum_width:

  Width of the stratum bars as a fraction of axis spacing. Default
  `1/4`.

- flow_width:

  Width of the alluvium flows. Default `1/6`.

- alpha:

  Transparency of the flows, `[0, 1]`. Default `0.8`.

- knot_pos:

  Curvature of the flow ribbons, `[0, 1]`. Default `0.4`.

- show_labels:

  Logical; whether to label each stratum with its value. Default `TRUE`.

## Value

A
[`ggplot2::ggplot()`](https://ggplot2.tidyverse.org/reference/ggplot.html)
object. Compose with `scale_fill_*`, `scale_colour_*`,
[`labs()`](https://ggplot2.tidyverse.org/reference/labs.html),
[`annotate()`](https://ggplot2.tidyverse.org/reference/annotate.html),
and
[`hvti_theme()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme.md).

## Details

**Data format:** one row per unique combination of axis values, with a
numeric weight column (`y_col`). This matches the frequency / summary
table format used in the SAS template (`ardat` with `percent` as `y`).

**Colours:** flows are unfilled by default. Map a column to `fill_col`
and add
[`scale_fill_manual()`](https://ggplot2.tidyverse.org/reference/scale_manual.html)
or
[`scale_fill_brewer()`](https://ggplot2.tidyverse.org/reference/scale_brewer.html)
to the returned object. Stratum bars use `stratum_fill` (default
`"grey80"`) and are independent of the flow fill scale.

## See also

[`ggalluvial::geom_alluvium()`](http://corybrunson.github.io/ggalluvial/reference/geom_alluvium.md),
[`ggalluvial::geom_stratum()`](http://corybrunson.github.io/ggalluvial/reference/geom_stratum.md),
[`sample_alluvial_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_alluvial_data.md),
[`hvti_theme()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme.md)

## Examples

``` r
dta  <- sample_alluvial_data(n = 300, seed = 42)
axes <- c("pre_ar", "procedure", "post_ar")

# --- Bare plot -----------------------------------------------------------
alluvial_plot(dta, axes = axes, y_col = "freq")
#> Warning: Some strata appear at multiple axes.
#> Warning: Some strata appear at multiple axes.
#> Warning: Some strata appear at multiple axes.


# --- Fill flows by pre-operative AR grade + manuscript theme -------------
alluvial_plot(dta, axes = axes, y_col = "freq", fill_col = "pre_ar") +
  ggplot2::scale_fill_manual(
    values = c(None     = "steelblue",
               Mild     = "goldenrod",
               Moderate = "darkorange",
               Severe   = "firebrick"),
    name = "Pre-op AR"
  ) +
  ggplot2::scale_colour_manual(
    values = c(None     = "steelblue",
               Mild     = "goldenrod",
               Moderate = "darkorange",
               Severe   = "firebrick"),
    guide = "none"
  ) +
  ggplot2::scale_x_continuous(
    breaks = 1:3,
    labels = c("Pre-op AR", "Procedure", "Post-op AR"),
    expand = c(0.05, 0.05)
  ) +
  ggplot2::labs(y = "Patients (n)",
                title = "AV Regurgitation: Pre- to Post-operative") +
  hvti_theme("manuscript")
#> Scale for x is already present.
#> Adding another scale for x, which will replace the existing scale.
#> Warning: Some strata appear at multiple axes.
#> Warning: Some strata appear at multiple axes.
#> Warning: Some strata appear at multiple axes.


# --- Fill flows by procedure with RColorBrewer palette -------------------
alluvial_plot(dta, axes = axes, y_col = "freq", fill_col = "procedure") +
  ggplot2::scale_fill_brewer(palette = "Set2", name = "Procedure") +
  ggplot2::scale_colour_brewer(palette = "Set2", guide = "none") +
  ggplot2::scale_x_continuous(
    breaks = 1:3,
    labels = c("Pre-op AR", "Procedure", "Post-op AR"),
    expand = c(0.05, 0.05)
  ) +
  ggplot2::labs(y = "Patients (n)") +
  hvti_theme("manuscript")
#> Scale for x is already present.
#> Adding another scale for x, which will replace the existing scale.
#> Warning: Some strata appear at multiple axes.
#> Warning: Some strata appear at multiple axes.
#> Warning: Some strata appear at multiple axes.


# --- Two-axis (before / after) with annotation ---------------------------
alluvial_plot(
  dta, axes = c("pre_ar", "post_ar"), y_col = "freq",
  fill_col = "pre_ar", axis_labels = c("Pre-operative", "Post-operative")
) +
  ggplot2::scale_fill_brewer(palette = "RdYlGn", direction = -1,
                             name = "AR Grade") +
  ggplot2::scale_colour_brewer(palette = "RdYlGn", direction = -1,
                               guide = "none") +
  ggplot2::annotate("text", x = 1.5, y = 250,
                    label = "Improvement after surgery",
                    size = 3.5, fontface = "italic") +
  ggplot2::labs(y = "Patients (n)",
                title = "AV Regurgitation Before and After Surgery") +
  hvti_theme("manuscript")
#> Warning: Some strata appear at multiple axes.
#> Warning: Some strata appear at multiple axes.
#> Warning: Some strata appear at multiple axes.


# --- Save ----------------------------------------------------------------
if (FALSE) { # \dontrun{
p <- alluvial_plot(dta, axes = axes, y_col = "freq", fill_col = "pre_ar") +
  ggplot2::scale_fill_brewer(palette = "RdYlGn", direction = -1) +
  ggplot2::scale_colour_brewer(palette = "RdYlGn", direction = -1,
                               guide = "none") +
  hvti_theme("manuscript")
ggplot2::ggsave("sankey.pdf", p, width = 8, height = 6)
} # }
```
