# Plot an hv_survival object

Builds a bare `ggplot2` object from an
[`hv_survival`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_survival.md)
data object. The plot contains the correct aesthetics and geometries but
no scale, label, or theme modifications; add those with `+` as you would
with any `ggplot2` object.

## Usage

``` r
# S3 method for class 'hv_survival'
plot(
  x,
  type = c("survival", "cumhaz", "hazard", "loglog", "life"),
  conf_int = TRUE,
  alpha = 0.8,
  curve = c("step", "line"),
  ...
)
```

## Arguments

- x:

  An `hv_survival` object.

- type:

  Which plot variant to produce. One of:

  `"survival"`

  :   (default, `PLOTS=1`) KM curve (see `curve`) with optional CI
      ribbon; y-axis on the 0–100 percent scale.

  `"cumhaz"`

  :   (`PLOTC=1`) Nelson-Aalen cumulative hazard \\H(t) = -\log S(t)\\.

  `"hazard"`

  :   (`PLOTH=1`) Instantaneous hazard \\h(t)\\; add
      `geom_smooth(method="loess")` for a smoothed publication curve.

  `"loglog"`

  :   Log-log diagnostic: \\\log H(t)\\ vs \\\log t\\. Parallel lines
      across strata support proportional hazards.

  `"life"`

  :   (`PLOTL=1`) Restricted mean survival time (integral of \\S(t)\\)
      vs time.

- conf_int:

  Logical; draw a CI ribbon on the `"survival"` plot. Default `TRUE`.
  Ignored for other `type` values.

- alpha:

  Line/point transparency in \\\[0,1\]\\. Default `0.8`.

- curve:

  How the `"survival"`, `"cumhaz"` and `"loglog"` curves join one event
  to the next. `"step"` (default) draws the Kaplan-Meier steps, flat
  between events. `"line"` joins the events with straight lines, as the
  SAS `%kaplan` figures do: it draws time zero, each event and each
  stratum's last row, and skips censored rows between, so a censoring
  time puts no corner in the line. The CI ribbon follows the same rows.
  Ignored for `"hazard"`, which draws points, and `"life"`.

- ...:

  Ignored; present for S3 consistency.

## Value

A bare [`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html)
object; compose with `+` to add scales, axis limits, labels, and
[`theme_hv_manuscript`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md).

## See also

[`hv_survival`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_survival.md)
to build the data object,
[`theme_hv_manuscript`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md)
for the publication theme.

Other Kaplan-Meier survival:
[`hv_survival()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_survival.md),
[`sample_survival_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_survival_data.md)

## Examples

``` r
dta <- sample_survival_data(n = 500, seed = 42)
km  <- hv_survival(dta)

# Default survival curve
plot(km) +
  ggplot2::labs(x = "Years after Operation", y = "Survival (%)") +
  theme_hv_poster()


# Events joined by straight lines, with a point at each event
plot(km, curve = "line") +
  ggplot2::geom_point(
    data = km$data[km$data$n.event > 0, ],
    ggplot2::aes(x = .data[["time"]], y = .data[["surv"]] * 100)
  ) +
  ggplot2::labs(x = "Years after Operation", y = "Survival (%)") +
  theme_hv_poster()


# Cumulative hazard
plot(km, type = "cumhaz") +
  ggplot2::labs(x = "Years", y = "Cumulative Hazard") +
  theme_hv_poster()


# Hazard rate with loess smoother
plot(km, type = "hazard") +
  ggplot2::geom_smooth(
    ggplot2::aes(x = .data[["mid_time"]], y = .data[["hazard"]]),
    method = "loess", se = FALSE, span = 0.5
  ) +
  ggplot2::labs(x = "Years", y = "Instantaneous Hazard") +
  theme_hv_poster()
#> `geom_smooth()` using formula = 'y ~ x'

```
