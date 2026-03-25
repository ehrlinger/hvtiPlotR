# Nonparametric survival estimates

A dataset containing nonparametric empirical survival estimates used for
examples in the package vignettes. The data represent follow-up outcomes
for patients stratified by initial valve state (`iv_state`) from an
aortic-valve surgery registry, originally exported from SAS via
`tp.hp.dead.sas` / `tp.np.*.sas`.

## Format

A data frame with one row per patient and 10 columns:

- iv_state:

  Initial valve state (character/factor); used as the x-axis grouping
  variable in nonparametric plots.

- sginit:

  Initial SG (St. Jude Medical Silzone) indicator (numeric).

- stlinit:

  Initial STL indicator (numeric).

- stuinit:

  Initial STU indicator (numeric).

- sgdead1:

  Death indicator for SG group (logical/integer; 1 = event).

- sgstrk1:

  Stroke indicator for SG group (logical/integer; 1 = event).

- stldead1:

  Death indicator for STL group (logical/integer; 1 = event).

- studead1:

  Death indicator for STU group (logical/integer; 1 = event).

- stlstrk1:

  Stroke indicator for STL group (logical/integer; 1 = event).

- stustrk1:

  Stroke indicator for STU group (logical/integer; 1 = event).

## See also

[parametric](https://ehrlinger.github.io/hvtiPlotR/reference/parametric.md),
[`nonparametric_curve_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/nonparametric_curve_plot.md)
