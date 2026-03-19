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

  Cumulative hazard H(t) = -log S(t).

- `log_cumhaz`:

  log H(t) — y-axis of the log-log survival plot used to assess the
  proportional-hazards assumption.

- `log_time`:

  log(t) — x-axis of log-scale PLOTC plots.

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

  Cumulative integral of the survival function (restricted mean survival
  time) using the SAS trapezoidal rule: LIFE += delta_t \* (3\*S(t) -
  S(t_prev)) / 2.

- `proplife`:

  LIFE / t — proportionate life length.
