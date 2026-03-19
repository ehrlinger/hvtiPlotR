# Changelog

## hvtiPlotR 2.0.0.9000

- Added
  [`eda_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/eda_plot.md)
  — exploratory barplot/scatterplot for a single variable. Auto-detects
  variable type (`"Cont"`, `"Cat_Num"`, `"Cat_Char"`) and dispatches to
  scatter + LOESS + rug (continuous) or stacked/filled bar
  (categorical). `NA` values are shown as an explicit `"(Missing)"` fill
  level. Returns a bare ggplot object for composition with
  `scale_fill_*`, `scale_colour_*`,
  [`labs()`](https://ggplot2.tidyverse.org/reference/labs.html),
  [`annotate()`](https://ggplot2.tidyverse.org/reference/annotate.html),
  and \[hvti_theme()\]. Ports `Function_DataPlotting()` from
  `tp.dp.EDA_barplots_scatterplots.R`.
- Added
  [`eda_classify_var()`](https://ehrlinger.github.io/hvtiPlotR/reference/eda_classify_var.md)
  — replicates the `UniqueLimit` type-detection logic from
  `Barplot_Scatterplot_Function.R`: classifies a vector as `"Cont"`,
  `"Cat_Num"`, or `"Cat_Char"`.
- Added
  [`eda_select_vars()`](https://ehrlinger.github.io/hvtiPlotR/reference/eda_select_vars.md)
  — subsets and reorders a data frame by a character vector or
  space-separated string of column names. Replaces `Order_Variables()`
  and the `Mod_Data <- dta[, Order_Var]` pattern from
  `tp.dp.EDA_barplots_scatterplots_varnames.R`.
- Added
  [`sample_eda_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_eda_data.md)
  — mixed-type cardiac-surgery registry simulation (binary, ordinal,
  character-categorical, and continuous variables) for demonstrating
  [`eda_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/eda_plot.md)
  and
  [`eda_select_vars()`](https://ehrlinger.github.io/hvtiPlotR/reference/eda_select_vars.md).
- Reorganised `inst/`: moved `par_cst.xpt` and `npar_cst.xpt` to
  `inst/extdata/` (standard R package location for bundled data files);
  removed unreferenced presentation and test artefacts (`*.pptx`,
  `*.pdf`, `*.sas` scratch files).
- Extended
  [`nonparametric_curve_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/nonparametric_curve_plot.md)
  examples: added dual-Y-axis example (Example 10, `\dontrun`) using
  `scale_y_continuous(sec.axis = ...)`; noted `cll_p95`/`clu_p95` column
  availability for 95 % CI (Example 2) and per-group shape mapping via
  [`scale_shape_manual()`](https://ggplot2.tidyverse.org/reference/scale_manual.html)
  (Example 4).
- Extended
  [`nonparametric_ordinal_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/nonparametric_ordinal_plot.md)
  examples: added pre-operative severity comparison example grouping
  combined Mild/Moderate/Severe cohorts through
  [`nonparametric_curve_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/nonparametric_curve_plot.md).
- Split vignette into three: `hvtiPlotR.qmd` (SAS migration guide),
  `plot-functions.qmd` (per-function reference with worked examples),
  `plot-decorators.qmd` (composition grammar: `scale_*`,
  [`labs()`](https://ggplot2.tidyverse.org/reference/labs.html), themes,
  and saving to manuscript PDF, poster PDF, and editable PowerPoint via
  [`save_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/save_ppt.md)).

## hvtiPlotR 1.1.0

- Added
  [`survival_curve()`](https://ehrlinger.github.io/hvtiPlotR/reference/survival_curve.md)
  — Kaplan-Meier and Nelson-Aalen survival analysis returning five plot
  types (survival, cumulative hazard, hazard, log-log, life/RMST) plus
  risk and report tables. Ports the SAS `%kaplan` and `%nelsont` macros
  from `tp.ac.dead.sas`.
- Added
  [`sample_survival_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_survival_data.md)
  — realistic exponential survival simulation with administrative
  censoring and optional treatment strata.
- Added
  [`goodness_followup()`](https://ehrlinger.github.io/hvtiPlotR/reference/goodness_followup.md)
  — goodness-of-follow-up scatter plot showing actual vs. potential
  follow-up per operation year, with optional non-fatal event panel.
- Added
  [`sample_goodness_followup_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_goodness_followup_data.md)
  — simulates an operative cohort with operation dates, follow-up times,
  competing events, and death.
- Added
  [`covariate_balance()`](https://ehrlinger.github.io/hvtiPlotR/reference/covariate_balance.md)
  — standardised mean difference dot-plot for propensity-score matching
  or weighting diagnostics.
- Added
  [`sample_covariate_balance_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_covariate_balance_data.md)
  — patient-level logistic simulation with greedy 1:1 caliper matching;
  SMDs computed before and after matching.
- Added
  [`stacked_histogram()`](https://ehrlinger.github.io/hvtiPlotR/reference/stacked_histogram.md)
  and
  [`sample_stacked_histogram_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_stacked_histogram_data.md)
  — stacked or filled histogram of a numeric variable by group.
- Improved
  [`mirror_histogram()`](https://ehrlinger.github.io/hvtiPlotR/reference/mirror_histogram.md)
  sample data
  ([`sample_mirror_histogram_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_mirror_histogram_data.md))
  to use a realistic logistic propensity-score model with greedy 1:1
  caliper matching and optional ATE IPTW weights; extreme-PS patients
  naturally go unmatched.
- Added `hvti_plot()` dispatcher supporting `"mirror_histogram"`,
  `"stacked_histogram"`, and `"covariate_balance"` plot types.
- Added
  [`hvti_theme()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme.md)
  dispatcher for `"manuscript"`, `"ppt"`, `"dark_ppt"`, and `"poster"`
  themes.
- Enabled roxygen Markdown (`Roxygen: list(markdown = TRUE)`) so
  `**bold**`, backtick code spans, and `[pkg::fn()]` cross-references
  render correctly in Rd help pages.
- Added `survival` to package `Imports`.
- Updated package-level documentation (`help.R`) to reflect all current
  exported functions and sample-data generators.

## hvtiPlotR 0.2.2

- Fixed deprecated ggplot2 syntax (`size` -\> `linewidth` in
  `element_line` and `element_rect`).
- Removed empty `save.hvtiplotr` function.
- Fixed `theme_dark_ppt` to pass all parameters to `theme_grey`.
- Updated documentation for data objects.
- Updated README to reference `officer` package instead of deprecated
  `ReporteRs`.

## hvtiPlotR 0.2.0

- Initial CRAN submission.
