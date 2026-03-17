# hvtiPlotR 1.1.0

* Added `survival_curve()` — Kaplan-Meier and Nelson-Aalen survival analysis
  returning five plot types (survival, cumulative hazard, hazard, log-log,
  life/RMST) plus risk and report tables. Ports the SAS `%kaplan` and
  `%nelsont` macros from `tp.ac.dead.sas`.
* Added `sample_survival_data()` — realistic exponential survival simulation
  with administrative censoring and optional treatment strata.
* Added `goodness_followup()` — goodness-of-follow-up scatter plot showing
  actual vs. potential follow-up per operation year, with optional non-fatal
  event panel.
* Added `sample_goodness_followup_data()` — simulates an operative cohort
  with operation dates, follow-up times, competing events, and death.
* Added `covariate_balance()` — standardised mean difference dot-plot for
  propensity-score matching or weighting diagnostics.
* Added `sample_covariate_balance_data()` — patient-level logistic simulation
  with greedy 1:1 caliper matching; SMDs computed before and after matching.
* Added `stacked_histogram()` and `sample_stacked_histogram_data()` — stacked
  or filled histogram of a numeric variable by group.
* Improved `mirror_histogram()` sample data (`sample_mirror_histogram_data()`)
  to use a realistic logistic propensity-score model with greedy 1:1 caliper
  matching and optional ATE IPTW weights; extreme-PS patients naturally
  go unmatched.
* Added `hvti_plot()` dispatcher supporting `"mirror_histogram"`,
  `"stacked_histogram"`, and `"covariate_balance"` plot types.
* Added `hvti_theme()` dispatcher for `"manuscript"`, `"ppt"`, `"dark_ppt"`,
  and `"poster"` themes.
* Enabled roxygen Markdown (`Roxygen: list(markdown = TRUE)`) so `**bold**`,
  backtick code spans, and `[pkg::fn()]` cross-references render correctly
  in Rd help pages.
* Added `survival` to package `Imports`.
* Updated package-level documentation (`help.R`) to reflect all current
  exported functions and sample-data generators.

# hvtiPlotR 0.2.2

* Fixed deprecated ggplot2 syntax (`size` -> `linewidth` in `element_line`
  and `element_rect`).
* Removed empty `save.hvtiplotr` function.
* Fixed `theme_dark_ppt` to pass all parameters to `theme_grey`.
* Updated documentation for data objects.
* Updated README to reference `officer` package instead of deprecated
  `ReporteRs`.

# hvtiPlotR 0.2.0

* Initial CRAN submission.
