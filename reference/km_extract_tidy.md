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

  Cumulative integral of the survival function, by the SAS `%kaplan`
  formula, kept for SAS parity: \\LIFE \mathrel{+}= \Delta t (3 S(t) -
  S(t\_{prev})) / 2\\. This is **not** a trapezoid. The Kaplan-Meier
  curve is a right-continuous step, constant at \\S(t\_{prev})\\ across
  \\\[t\_{prev}, t)\\, so the exact area of an interval is \\\Delta t \\
  S(t\_{prev})\\; the trapezoid would be \\\Delta t (S(t) +
  S(t\_{prev})) / 2\\. The SAS formula falls short of the exact area by
  \\\frac{3}{2} \Delta t (S(t\_{prev}) - S(t))\\ at each event (and
  equals it across a censoring-only interval), so `life` understates the
  restricted mean survival time. For the exact RMST use
  [`hvtiRpropensity::ps_rmst()`](https://ehrlinger.github.io/hvtiRpropensity/reference/ps_rmst.html).

- `proplife`:

  LIFE / t, the proportionate life length.
