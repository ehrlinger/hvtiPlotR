# Generate Sample Goodness-of-Follow-Up Data

Produces a reproducible data frame suitable for testing and
demonstrating
[`hv_followup()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_followup.md).
Operation dates are drawn uniformly over the study period; death and
non-fatal event times are simulated from exponential distributions and
censored at each patient's potential follow-up. The `deads` column
approximates active/systematic death ascertainment by restricting to
deaths within 90% of the potential follow-up window, mirroring the
distinction between `dead` and `deads` in the legacy `tp.dp.gfup.R`
template.

## Usage

``` r
sample_goodness_followup_data(
  n = 300,
  origin_year = 1990,
  study_start = as.Date("1990-01-01"),
  study_end = as.Date("2019-12-31"),
  close_date = as.Date("2021-08-06"),
  death_rate = 0.05,
  event_rate = 0.08,
  seed = 42L,
  loss_rate = 0.03
)
```

## Arguments

- n:

  Integer number of patients to simulate. Default `300`.

- origin_year:

  Integer calendar year corresponding to zero in `iv_opyrs`. Default
  `1990`.

- study_start, study_end:

  Date (or coercible string) defining the operation date window.

- close_date:

  Date (or coercible string) for the follow-up closing date. Must be \>=
  `study_end`.

- death_rate:

  Annual hazard for death (exponential model). Default `0.05` (median
  survival ~14 years).

- event_rate:

  Annual hazard for the non-fatal event (exponential model). Default
  `0.08` (median time-to-event ~9 years).

- seed:

  Integer random seed for reproducibility. Default `42`.

- loss_rate:

  Annual hazard of loss to active follow-up (exponential model). Default
  `0.03`. `0` means nobody is lost.

## Value

A data frame with columns:

- `iv_opyrs`:

  Years from `origin_year` to operation date.

- `iv_dead`:

  Follow-up years to death or censoring.

- `dead`:

  Logical all-source death indicator.

- `iv_event`:

  Follow-up years to non-fatal event or censoring.

- `ev_event`:

  Logical non-fatal event indicator.

- `deads`:

  Logical active/systematic death indicator (subset of `dead`).

## Details

Follow-up is deliberately imperfect, so the plot shows what real data
look like rather than the ideal. Patients lost to follow-up are censored
before `close_date`, the date the dataset was frozen, and fall below the
diagonal. No patient has follow-up past `close_date`. Set
`loss_rate = 0` for complete follow-up, with every survivor censored at
`close_date`.

The column names match the defaults of
[`hv_followup()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_followup.md):
`iv_opyrs`, `iv_dead`, `dead`. The event-panel columns (`iv_event`,
`ev_event`, `deads`) are included so callers can pass `event_col`,
`event_time_col`, and `death_for_event_col` directly.

## See also

[`hv_followup()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_followup.md)

## Examples

``` r
dta <- sample_goodness_followup_data()
head(dta)
#>   iv_opyrs iv_dead  dead iv_event ev_event deads
#> 1  29.5694  2.0261 FALSE   2.0261    FALSE FALSE
#> 2   6.4834  6.9027  TRUE   4.0813     TRUE  TRUE
#> 3  14.4342  2.8045 FALSE   2.8045    FALSE FALSE
#> 4  25.4324  4.2037 FALSE   0.6137     TRUE FALSE
#> 5   3.4251 13.1369  TRUE   6.9232     TRUE  TRUE
#> 6  24.1620  0.2802 FALSE   0.2802    FALSE FALSE

# Death panel
gf <- hv_followup(dta)
plot(gf) +
  ggplot2::scale_color_manual(
    values = c("Alive" = "blue", "Dead" = "red"), name = NULL
  ) +
  ggplot2::scale_shape_manual(values = c(1, 4), name = NULL) +
  ggplot2::labs(x = "Operation Date", y = "Follow-up (years)")


# Event panel
gf2 <- hv_followup(dta, event_col = "ev_event",
                      event_time_col = "iv_event",
                      death_for_event_col = "deads")
plot(gf2, type = "event") +
  ggplot2::scale_color_manual(
    values = c("No event" = "blue", "Non-fatal event" = "green3",
               "Death" = "red"),
    name   = NULL
  ) +
  ggplot2::scale_shape_manual(values = c(1, 2, 4), name = NULL) +
  ggplot2::labs(x = "Operation Date", y = "Follow-up (years)")

```
