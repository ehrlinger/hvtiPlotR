# Nonparametric survival estimates

A dataset containing nonparametric competing-risk estimates used for
examples in the package vignettes: the empirical companion to
[parametric](https://ehrlinger.github.io/hvtiPlotR/reference/parametric.md),
over the same three states (event-free, death, and stroke). Originally
exported from SAS via `tp.hp.dead.sas` / `tp.np.*.sas`.

## Format

A data frame with 126 rows (one per event time) and 10 columns:

- iv_state:

  Follow-up time in years (0 to about 4.9); the x-axis in the vignette
  plots.

- sginit:

  Percent event-free (still in the initial state).

- stlinit:

  Lower confidence limit for `sginit`; all `NA` in this extract.

- stuinit:

  Upper confidence limit for `sginit`; all `NA` in this extract.

- sgdead1:

  Cumulative percent dead; `NA` at times with no death.

- sgstrk1:

  Cumulative percent with stroke; `NA` at times with no stroke.

- stldead1:

  Lower confidence limit for `sgdead1` (6 time points).

- studead1:

  Upper confidence limit for `sgdead1` (6 time points).

- stlstrk1:

  Lower confidence limit for `sgstrk1` (3 time points).

- stustrk1:

  Upper confidence limit for `sgstrk1` (3 time points).

## Details

Column prefixes follow the SAS naming: `sg*` is the estimate, `stl*` and
`stu*` its lower and upper confidence limits. The limits are filled only
at the handful of times where an error bar is drawn and are `NA`
elsewhere, which is how `plot.sas` thins error bars.

## See also

[parametric](https://ehrlinger.github.io/hvtiPlotR/reference/parametric.md),
[`hv_nonparametric()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_nonparametric.md)
