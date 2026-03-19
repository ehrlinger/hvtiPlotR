# Kaplan-Meier Survival Curve

Estimates a Kaplan-Meier survival function and returns a list containing
five bare `ggplot` objects (survival curve, cumulative hazard, hazard
rate, log-minus-log survival, and mean residual life), plus associated
data frames (tidy KM data, numbers-at-risk table, and a report table at
specified time points). The returned plots intentionally omit scale,
label, and theme modifications so the caller can layer on their own
choices with `+`.

## Usage

``` r
survival_curve(
  data,
  time_col = "iv_dead",
  event_col = "dead",
  strata_col = NULL,
  conf_int = TRUE,
  conf_level = 0.6827,
  report_times = c(1, 5, 10, 15, 20, 25),
  alpha = 0.8,
  method = c("kaplan-meier", "nelson-aalen")
)
```

## Arguments

- data:

  A data frame.

- time_col:

  Name of the numeric column holding follow-up time in years. Defaults
  to `"iv_dead"`.

- event_col:

  Name of the logical or 0/1 column indicating whether the event
  occurred. Defaults to `"dead"`.

- strata_col:

  Optional name of a character or factor column used to stratify the
  analysis. Pass `NULL` (the default) for an unstratified estimate.

- conf_int:

  Logical; draw a confidence-interval ribbon on the survival plot.
  Defaults to `TRUE`.

- conf_level:

  Confidence level for the CI band. Defaults to `0.6827` (one standard
  deviation), matching the SAS `%kaplan` macro default.

- report_times:

  Numeric vector of time points at which survival estimates and numbers
  at risk are reported. Defaults to `c(1, 5, 10, 15, 20, 25)`.

- alpha:

  Transparency of plot lines and points, in \[0, 1\]. Default `0.8`. The
  CI ribbon uses a fixed transparency of `0.2`.

- method:

  Estimator to use. `"kaplan-meier"` (default) computes the
  product-limit estimate with a logit CI — corresponding to the SAS
  `%kaplan` macro. `"nelson-aalen"` uses the Fleming-Harrington
  cumulative hazard \\H(t) = \sum d_i / n_i\\ with \\S(t) = \exp(-H)\\
  and a log CI on \\H(t)\\ — corresponding to the SAS `%nelsont` macro,
  which is preferred when \\S(t)\\ falls to or near zero.

## Value

A named list with elements mirroring the SAS `%kaplan` macro output
plots (`PLOTS`, `PLOTC`, `PLOTH`, `PLOTL`):

- `survival_plot`:

  (`PLOTS=1`) Bare `ggplot`: KM step function with optional CI ribbon,
  y-axis on 0–100 scale.

- `cumhaz_plot`:

  (`PLOTC=1`) Bare `ggplot`: Nelson-Aalen cumulative hazard H(t) = -log
  S(t).

- `hazard_plot`:

  (`PLOTH=1`) Bare `ggplot`: instantaneous hazard h(t) =
  log(S(t_prev)/S(t)) / delta_t, plotted at interval midpoints. Add
  `geom_smooth(method="loess")` for a smoothed hazard curve.

- `loglog_plot`:

  (`PLOTC=1`, log-log variant) Bare `ggplot`: log H(t) vs log t.
  Parallel lines across strata indicate proportional hazards.

- `life_plot`:

  (`PLOTL=1`) Bare `ggplot`: restricted mean survival time (integral of
  S(t)) vs time.

- `km_data`:

  Tidy data frame with columns `time`, `surv`, `lower`, `upper`,
  `n.risk`, `n.event`, `n.censor`, `cumhaz`, `strata`, `hazard`,
  `density`, `mid_time`, `life`, `proplife`, `log_cumhaz`, `log_time`.

- `risk_table`:

  Data frame: `strata`, `report_time`, `n.risk`.

- `report_table`:

  Data frame: `strata`, `report_time`, `surv`, `lower`, `upper`,
  `n.risk`, `n.event`.

## References

SAS template: `tp.ac.dead.sas` (calls `%kaplan` for product-limit
survival estimates and `%nelsont` for Nelson-Aalen cumulative event
estimates).

## Examples

``` r
# --- Unstratified ---
dta <- sample_survival_data(n = 500, seed = 42)
result <- survival_curve(dta, alpha = 0.8)

# Bare survival plot
result$survival_plot


# Add scales, labels, theme
result$survival_plot +
  ggplot2::scale_y_continuous(breaks = seq(0, 100, 20),
                              labels = function(x) paste0(x, "%")) +
  ggplot2::scale_x_continuous(breaks = seq(0, 20, 5)) +
  ggplot2::coord_cartesian(xlim = c(0, 20), ylim = c(0, 100)) +
  ggplot2::labs(x = "Years after Operation", y = "Survival (%)",
                title = "Freedom from Death") +
  hvti_theme("manuscript")
#> Scale for y is already present.
#> Adding another scale for y, which will replace the existing scale.


# Cumulative hazard
result$cumhaz_plot +
  ggplot2::scale_x_continuous(breaks = seq(0, 20, 5)) +
  ggplot2::labs(x = "Years after Operation", y = "Cumulative Hazard",
                title = "Nelson-Aalen Cumulative Hazard") +
  hvti_theme("manuscript")


# Numbers at risk
result$risk_table
#>   strata report_time n.risk
#> 1    All           1    478
#> 2    All           5    412
#> 3    All          10    322
#> 4    All          15    260
#> 5    All          20    207
#> 6    All          25    207

# Report table at 1, 5, 10, 15, 20 years
result$report_table
#>   strata report_time  surv     lower     upper n.risk n.event
#> 1    All           1 0.954 0.9436693 0.9625114    478       1
#> 2    All           5 0.822 0.8042449 0.8384681    412       1
#> 3    All          10 0.642 0.6202877 0.6631450    322       1
#> 4    All          15 0.518 0.4956322 0.5402959    260       1
#> 5    All          20 0.414 0.3921576 0.4361859    207       0
#> 6    All          25 0.414 0.3921576 0.4361859    207       0

# --- Stratified ---
# supply strata_levels to sample_survival_data() to generate the
# "valve_type" column used by strata_col below.
# dta_s <- sample_survival_data(
#   n = 500,
#   strata_levels  = c("Type A", "Type B"),  # adds valve_type column
#   hazard_ratios  = c(1, 1.4),
#   seed = 42
# )
# result_s <- survival_curve(dta_s, strata_col = "valve_type", alpha = 0.8)
#
# result_s$survival_plot +
#   ggplot2::scale_color_manual(
#     values = c("Type A" = "blue", "Type B" = "red"),
#     name   = "Valve Type"
#   ) +
#   ggplot2::scale_fill_manual(
#     values = c("Type A" = "blue", "Type B" = "red"),
#     name   = "Valve Type"
#   ) +
#   ggplot2::scale_x_continuous(breaks = seq(0, 20, 5)) +
#   ggplot2::coord_cartesian(xlim = c(0, 20), ylim = c(0, 100)) +
#   ggplot2::labs(x = "Years after Operation", y = "Survival (%)",
#                 title = "Freedom from Death by Valve Type") +
#   hvti_theme("manuscript")
#
# --- Hazard rate plot (PLOTH=1; add smoother for publication) ---
# result$hazard_plot +
#   ggplot2::geom_smooth(ggplot2::aes(x = mid_time, y = hazard,
#                                     color = strata),
#                        method = "loess", se = FALSE, span = 0.5) +
#   ggplot2::scale_x_continuous(breaks = seq(0, 20, 5)) +
#   ggplot2::labs(x = "Years after Operation",
#                 y = "Instantaneous Hazard") +
#   hvti_theme("manuscript")
#
# --- Log-log plot (PLOTC log-log; proportional-hazards check) ---
# result$loglog_plot +
#   ggplot2::labs(x = "log(Years)", y = "log(-log S(t))",
#                 title = "Log-Log Survival (PH Assumption Check)") +
#   hvti_theme("manuscript")
#
# --- Integrated survivorship / restricted mean survival (PLOTL=1) ---
# result$life_plot +
#   ggplot2::scale_x_continuous(breaks = seq(0, 20, 5)) +
#   ggplot2::labs(x = "Years after Operation",
#                 y = "Restricted Mean Survival (years)") +
#   hvti_theme("manuscript")
#
# --- Nelson-Aalen (use when S(t) falls to zero; mirrors SAS %nelsont) ---
# result_na <- survival_curve(dta, alpha = 0.8, method = "nelson-aalen")
# result_na$survival_plot +
#   ggplot2::scale_color_manual(values = c(All = "steelblue"), guide = "none") +
#   ggplot2::scale_fill_manual(values  = c(All = "steelblue"), guide = "none") +
#   ggplot2::scale_y_continuous(breaks = seq(0, 100, 20),
#                               labels = function(x) paste0(x, "%")) +
#   ggplot2::scale_x_continuous(breaks = seq(0, 20, 5)) +
#   ggplot2::coord_cartesian(xlim = c(0, 20), ylim = c(0, 100)) +
#   ggplot2::labs(x = "Years after Operation", y = "Survival (%)",
#                 title = "Freedom from Death (Nelson-Aalen)") +
#   hvti_theme("manuscript")
#
# --- Save ---
# ggplot2::ggsave("survival_curve.pdf", result$survival_plot,
#                 width = 8, height = 6)
```
