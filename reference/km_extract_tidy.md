# Extract tidy data frame from a survfit object

Converts the survfit object to a tidy data frame, prepends a time=0 row
per stratum, strips the `"s_="` prefix from stratum names, and computes
derived columns that match the SAS `%kaplan` macro outputs:

## Usage

``` r
km_extract_tidy(fit, group_col)
```

## Arguments

- fit:

  A `survfit` object.

- group_col:

  Name of the original stratification column, or `NULL`.

## Value

A data frame.

## Details

- `cumhaz`:

  Nelson-Aalen cumulative hazard \\H(t) = \sum\_{t_j \le t} d_j / n_j\\,
  as `survfit()` reports it. Under `method = "kaplan-meier"` this is
  *not* \\-\log S(t)\\ of the product-limit curve; the two agree only
  approximately, and diverge in the tail where \\S(t)\\ is small. Only a
  `survfit` summary without a `cumhaz` component falls back to \\-\log
  S(t)\\.

- `log_cumhaz`:

  log H(t) of the Nelson-Aalen H above, the y-axis of the log-log
  survival plot used to assess the proportional-hazards assumption.

- `log_time`:

  log(t), the x-axis of log-scale PLOTC plots.

- `hazard`:

  Instantaneous hazard estimate: log(S(t_prev) / S(t)) / (t - t_prev).
  Only defined at event times with `delta_t > 0`; `NA` at censoring
  times.

- `density`:

  Probability density: (S(t_prev) - S(t)) / delta_t.

- `mid_time`:

  Midpoint of the interval (t_prev, t\], used as the x-axis of
  hazard-rate plots.

- `life`:

  Cumulative integral of the survival function, the restricted mean
  survival time to \\t\\. The Kaplan-Meier curve is a right-continuous
  step, constant at \\S(t\_{prev})\\ across \\\[t\_{prev}, t)\\, so each
  interval adds its exact area \\\Delta t \\ S(t\_{prev})\\. This
  matches
  [`hvtiRpropensity::ps_rmst()`](https://ehrlinger.github.io/hvtiRpropensity/reference/ps_rmst.html)
  and the `rmean` of `summary.survfit()`. It does **not** reproduce the
  SAS `%kaplan` `LIFE` column, which accumulates \\\Delta t (3 S(t) -
  S(t\_{prev})) / 2\\ between events and so understates the area.

- `proplife`:

  LIFE / t, the proportionate life length.
