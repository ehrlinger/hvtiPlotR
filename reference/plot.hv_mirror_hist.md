# Plot an hv_mirror_hist object

Builds a bare mirrored-histogram `ggplot2` object from an
[`hv_mirror_hist`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_mirror_hist.md)
data object. Bars for the treated group appear above the x-axis; bars
for the control group appear below. Matched or weighted patients are
shown in a contrasting shade. Compose with `+` to add color scales, axis
labels, and
[`theme_hv_manuscript`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md).

## Usage

``` r
# S3 method for class 'hv_mirror_hist'
plot(x, alpha = 0.8, split_tall = FALSE, split_mult = 1.5, ...)
```

## Arguments

- x:

  An `hv_mirror_hist` object from
  [`hv_mirror_hist`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_mirror_hist.md).
  The fill legend reads `"<group>, all"` and `"<group>, matched"` (or
  `", weighted"`) from `group_labels`. A
  [`scale_fill_manual()`](https://ggplot2.tidyverse.org/reference/scale_manual.html)
  you add replaces that scale; pass `labels = x$meta$fill_labels` to
  keep the readable labels.

  When one arm piles into a single bin (say 648 of 685 patients at a
  score of 95 to 100\\ arm and the matched bars cannot be read.
  `split_tall = TRUE` sizes the y-axis to the tallest bar of the matched
  (or weighted) layers or of the arm whose tallest bar is smaller, times
  `split_mult`. Any taller "all patients" bar is clipped at the panel
  edge, cut by a white gap, and labeled with its full count on a white
  label. The limits are set with
  [`coord_cartesian`](https://ggplot2.tidyverse.org/reference/coord_cartesian.html),
  which clips a bar instead of dropping it, so do not add
  [`ylim()`](https://ggplot2.tidyverse.org/reference/lims.html) or scale
  limits on top; a `scale_y_continuous(labels = abs)` without limits is
  safe.

- alpha:

  Bar transparency in \\\[0,1\]\\. Default `0.8`.

- split_tall:

  Logical. Split "all patients" bars too tall for an axis sized to the
  matched bars and the smaller arm. Default `FALSE`.

- split_mult:

  Number greater than 1: the axis cap as a multiple of the tallest
  matched bar or tallest bar of the smaller arm. Used only when
  `split_tall = TRUE`. Default `1.5`.

- ...:

  Ignored; present for S3 consistency.

## Value

A bare [`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html)
object; compose with `+` to add color scales, axis limits, labels, and
[`theme_hv_manuscript`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md).
With `split_tall = TRUE` it carries two extra layers after the bars: the
white gaps (`geom_rect`) and the count labels (`geom_label`).

## See also

[`hv_mirror_hist`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_mirror_hist.md)
to build the data object,
[`theme_hv_manuscript`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md)
for the publication theme,
[`sample_mirror_histogram_data`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_mirror_histogram_data.md)
for example data.

Other Propensity Score & Matching:
[`hv_mirror_hist()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_mirror_hist.md),
[`hv_rmst_contrast()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_rmst_contrast.md),
[`hv_rmst_curves()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_rmst_curves.md),
[`plot.hv_rmst_contrast()`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hv_rmst_contrast.md),
[`plot.hv_rmst_curves()`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hv_rmst_curves.md),
[`sample_covariate_balance_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_covariate_balance_data.md)

## Examples

``` r
dta <- sample_mirror_histogram_data(n = 500)
mh  <- hv_mirror_hist(dta)

plot(mh) +
  ggplot2::labs(x = "Propensity Score (%)", y = "Count") +
  theme_hv_poster()


# One tall bar: most treated patients pile into the top bin.
dta_tall <- dta
top <- dta_tall$tavr == 1 & dta_tall$match == 0
dta_tall$prob_t[top] <- 0.98
mh_tall <- hv_mirror_hist(dta_tall)
plot(mh_tall, split_tall = TRUE) +
  ggplot2::labs(x = "Propensity Score (%)", y = "Count") +
  theme_hv_poster()

```
