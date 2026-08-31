# Sample Subject-Level Cohort Behind the Hazard Examples

Returns the subject-level survival data that
[`sample_hazard_empirical()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_hazard_empirical.md)
simulates internally and then discards. Use it when a hazard figure
needs a numbers-at-risk table:
[`hv_atrisk()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_atrisk.md)
counts subjects still under observation and therefore cannot work from
[`sample_hazard_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_hazard_data.md),
which is a prediction grid with no subjects in it.

## Usage

``` r
sample_hazard_cohort(
  n = 500,
  time_max = 10,
  groups = NULL,
  shape = 1.5,
  scale = 8,
  seed = 42L
)
```

## Arguments

- n:

  Number of simulated subjects **per group**. Default `500`.

- time_max:

  Scale of the follow-up window (years). Default `10`. Note that this is
  **not** a hard maximum on the returned `time`: follow-up is
  administratively truncated at `1.2 * time_max`, matching the cohort
  [`sample_hazard_empirical()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_hazard_empirical.md)
  fits to, so returned times run up to `12` at the default. It *is* the
  upper end of the grid in
  [`sample_hazard_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_hazard_data.md)
  and of the bins in
  [`sample_hazard_empirical()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_hazard_empirical.md).

- groups:

  `NULL` for a single group, or a named numeric vector of hazard
  multipliers matching those passed to
  [`sample_hazard_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_hazard_data.md).
  Names must be present, non-empty and distinct; multipliers must be
  finite and greater than zero.

- shape:

  Weibull shape parameter. Default `1.5`.

- scale:

  Weibull scale parameter (years). Default `8.0`.

- seed:

  Random seed. Default `42`.

## Value

A data frame with one row per subject and columns `time` (follow-up
time, years) and `status` (`1` event, `0` censored), plus a factor
`group` column when `groups` is not `NULL`.

## Details

For a given `n`, `time_max`, `groups`, `shape`, `scale` and `seed` this
draws the *same* cohort that
[`sample_hazard_empirical()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_hazard_empirical.md)
fits its Kaplan-Meier overlay to, so the counts and the overlay describe
the same subjects. Event times are Weibull, censoring is uniform on
`[0.2, 1.5] * time_max`, and follow-up is administratively truncated at
`1.2 * time_max`. When `groups` is supplied each level is an independent
draw of `n` subjects, matching
[`sample_hazard_empirical()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_hazard_empirical.md)'s
balanced-arms convention.

Note that
[`sample_hazard_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_hazard_data.md)
is an *analytic* Weibull curve evaluated at the same parameters — it is
not fitted to this cohort. The two share a generative model, not an
estimation step, so a figure combining them should not be captioned as a
model fit to these subjects.

## See also

[`hv_atrisk()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_atrisk.md),
[`hv_atrisk_compose()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_atrisk_compose.md),
[`sample_hazard_empirical()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_hazard_empirical.md),
[`sample_hazard_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_hazard_data.md)

## Examples

``` r
coh <- sample_hazard_cohort(n = 500, time_max = 10)
nrow(coh)
#> [1] 500
mean(coh$status)
#> [1] 0.58

# Numbers at risk under a parametric hazard figure. The cohort and the
# curve share n / shape / scale / seed, so the counts belong under it.
arms <- c("No Takedown" = 1.0, "Takedown" = 0.65)
coh2 <- sample_hazard_cohort(n = 400, time_max = 10, groups = arms)
haz  <- hv_hazard(
  sample_hazard_data(n = 400, time_max = 10, groups = arms),
  group_col = "group"
)
hv_atrisk_compose(
  plot(haz),
  hv_atrisk(coh2, time = "time", status = "status", group = "group",
            report_times = c(0, 2, 4, 6, 8, 10))
)
```
