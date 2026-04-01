# Plot an hvti_mirror_hist object

Builds a bare mirrored-histogram `ggplot2` object from an
[`hvti_mirror_hist`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_mirror_hist.md)
data object. Bars for the treated group appear above the x-axis; bars
for the control group appear below. Matched or weighted patients are
shown in a contrasting shade. Compose with `+` to add colour scales,
axis labels, and
[`hvti_theme`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme.md).

## Usage

``` r
# S3 method for class 'hvti_mirror_hist'
plot(x, alpha = 0.8, ...)
```

## Arguments

- x:

  An `hvti_mirror_hist` object from
  [`hvti_mirror_hist`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_mirror_hist.md).

- alpha:

  Bar transparency in \\\[0,1\]\\. Default `0.8`.

- ...:

  Ignored; present for S3 consistency.

## Value

A bare [`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html)
object; compose with `+` to add colour scales, axis limits, labels, and
[`hvti_theme`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme.md).

## See also

[`hvti_mirror_hist`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_mirror_hist.md)
to build the data object,
[`hvti_theme`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme.md)
for the publication theme,
[`sample_mirror_histogram_data`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_mirror_histogram_data.md)
for example data.

Other Propensity Score & Matching:
[`hvti_mirror_hist`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_mirror_hist.md)

## Examples

``` r
dta <- sample_mirror_histogram_data(n = 500)
mh  <- hvti_mirror_hist(dta)
#> mirror_histogram diagnostics: n=1000  dropped=0  [see $tables$diagnostics]

plot(mh) +
  ggplot2::labs(x = "Propensity Score (%)", y = "Count") +
  hvti_theme("manuscript")

```
