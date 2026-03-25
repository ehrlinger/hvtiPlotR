# Changelog

## hvtiPlotR 2.0.0.9001

### Tests

- Added `tests/testthat/test_hazard_plot.R` — full validation suite for
  `sample_hazard_data`, `sample_hazard_empirical`, `sample_life_table`,
  and `hazard_plot` (column checks, CI bounds, layer structure,
  multi-group, non-default column names, input validation).
- Added `tests/testthat/test_nonparametric_plots.R` — full suite for
  `sample_nonparametric_curve_data`,
  `sample_nonparametric_curve_points`, `nonparametric_curve_plot`,
  `sample_nonparametric_ordinal_data`,
  `sample_nonparametric_ordinal_points`, and
  `nonparametric_ordinal_plot`. Includes probability-sum-to-1 invariant
  test for ordinal grades.
- Added `tests/testthat/test_survival_derived.R` — full suite for
  `sample_survival_difference_data`, `survival_difference_plot`,
  `sample_nnt_data`, and `nnt_plot`. Covers NA-NNT at t≈0 edge case and
  cross-function time-grid consistency.
- Added `tests/testthat/test_cluster_sankey.R` — full suite for
  `sample_cluster_sankey_data` and `cluster_sankey_plot`. Validates the
  hierarchical merge tree (C9=A → C2=A) and that each Ck has exactly k
  levels.
- Added `tests/testthat/test_pipeline.R` — end-to-end pipeline tests
  covering `survival_curve → hvti_theme → save_ppt`, multi-slide list
  pipelines, built-in dataset usability, `eda_classify_var` edge cases
  (logical vector, all-NA, length-1), and composed multi-layer plots.
- Added snapshot test to `test_kaplan_meier.R` for `survival_curve`
  `report_table` at fixed seed; added all-censored and
  single-observation edge-case tests.
- Added snapshot test to `test_mirror_histogram.R` for diagnostics at
  fixed seed.
- Added `slide_titles` length-mismatch test to `test_save_ppt.R`.
- Added `make_footnote` prefix-parameter tests to `test_footnote.R`.

### Documentation

- Fixed
  [`save_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/save_ppt.md)
  argument names throughout all vignettes: `plot =` → `object =`,
  `filename =` → `powerpoint =`. Also added correct `template =` and
  `slide_titles =` arguments where missing.
- Fixed critical roxygen bug in
  [`sample_mirror_histogram_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_mirror_histogram_data.md):
  doc block used `##'` (silently ignored by roxygen2) instead of `#'`,
  so the function had no generated `.Rd` file. Converted all `##'` →
  `#'`, modernised `\code{}` → backtick syntax, and added `@examples`.
- Added `@examples` to all five theme functions:
  [`hvti_theme()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme.md),
  [`hvti_theme_manuscript()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme_manuscript.md),
  [`hvti_theme_dark_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme_dark_ppt.md),
  [`hvti_theme_light_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme_light_ppt.md),
  and
  [`hvti_theme_poster()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme_poster.md).
- Expanded thin (2-line) `@examples` blocks for four sample-data
  helpers:
  [`sample_life_table()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_life_table.md),
  [`sample_nonparametric_curve_points()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_nonparametric_curve_points.md),
  [`sample_nonparametric_ordinal_points()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_nonparametric_ordinal_points.md),
  and
  [`sample_longitudinal_counts_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_longitudinal_counts_data.md).
- Fixed `km$survival_plot` and `km$risk_table` accessor patterns in
  `vignettes/plot-decorators.qmd`:
  [`survival_curve()`](https://ehrlinger.github.io/hvtiPlotR/reference/survival_curve.md)
  returns a ggplot with *attributes*, not a named list. Replaced with
  `km` (the returned object IS the survival plot) and
  `attr(km, "risk_table")`.
- Fixed patchwork operator-precedence bug in
  `vignettes/plot-decorators.qmd`: `p_ms | p_km_ms + plot_layout(...)` →
  `(p_ms | p_km_ms) + plot_layout(...)`.
- Added `patchwork` to `Suggests` in `DESCRIPTION` (required by
  `vignettes/plot-decorators.qmd`).
- Rewrote package-level help page (`help.R` /
  [`?hvtiPlotR`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-package.md))
  to document all 57 exported functions, organised by category.
- Expanded “Saving figures” section in
  `vignettes/sas-migration-guide.qmd` with correct
  [`save_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/save_ppt.md)
  single- and multi-slide examples.
- Added `ggplot2::geom_line(..., linewidth = 1.5)` (replacing deprecated
  `size =`) and updated
  [`remotes::install_github()`](https://remotes.r-lib.org/reference/install_github.html)
  (replacing
  [`devtools::install_github()`](https://devtools.r-lib.org/reference/install-deprecated.html))
  in `vignettes/hvtiPlotR.qmd`.

### Input validation improvements

- **[`upset_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/upset_plot.md)**
  — added binary-column type check. ComplexUpset silently produces
  broken plots when `intersect` columns contain non-binary values; the
  function now errors with a clear message listing the offending columns
  before handing off to ComplexUpset.
- **[`sample_stacked_histogram_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_stacked_histogram_data.md)**
  — added `start_year` validation (previously `n_years` and
  `n_categories` were checked but `start_year` was not; a non-integer or
  non-finite value produced silently nonsensical output).
- **[`trends_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/trends_plot.md)**
  — moved `match.arg(summary_fn)` to after the data-frame and column
  checks, so users see a clear `data` / column error rather than an
  opaque `'arg' should be one of...` message when both `data` and
  `summary_fn` are wrong.
- **`validators.R`** — added two scalar-parameter helpers:
  `.check_scalar_positive()` (finite, positive) and
  `.check_scalar_nonneg()` (finite, non-negative).
  `cb_validate_params()` in `covariate-balance.R` now delegates all four
  parameter checks to these helpers, eliminating 28 lines of bespoke
  validation code.

### Architecture

- **`.NP_SIM` constant list** (`nonparametric-curve-plot.R`) — lifted
  the seven simulation tuning constants (`eta_intercept`, `logit_shift`,
  `cont_baseline`, `cont_scale`, `cont_sigma`, `eff_frac_prob`,
  `eff_frac_cont`) from local variables in
  [`sample_nonparametric_curve_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_nonparametric_curve_data.md)
  and from hard-coded defaults in `.np_sample_bins()` into a single
  file-level private list. Both functions now reference `.NP_SIM$*` —
  change once, updates all simulation paths.

### Bug fixes / API consistency

- **Standardised `alpha` range to `[0, 1]`** across all plot functions.
  Previously
  [`survival_curve()`](https://ehrlinger.github.io/hvtiPlotR/reference/survival_curve.md),
  [`covariate_balance()`](https://ehrlinger.github.io/hvtiPlotR/reference/covariate_balance.md),
  [`mirror_histogram()`](https://ehrlinger.github.io/hvtiPlotR/reference/mirror_histogram.md),
  [`spaghetti_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/spaghetti_plot.md),
  and `goodness_followup_death_plot()` /
  `goodness_followup_event_plot()` used `(0, 1]` (rejecting
  `alpha = 0`), while
  [`alluvial_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/alluvial_plot.md)
  used `[0, 1]`. All functions now accept `[0, 1]` — `alpha = 0` (fully
  transparent) is a valid ggplot2 value and should not be an error.
- **Added `.check_alpha()` shared validator** in `R/validators.R`.
  Enforces `alpha ∈ [0, 1]` with `call. = FALSE` and is called from
  every plot function that accepts an `alpha` argument.
- **`call. = FALSE` sweep** — every
  [`stop()`](https://rdrr.io/r/base/stop.html) call in the package now
  includes `call. = FALSE` so error messages never expose internal
  function names to callers.
- **Expanded shared validators** (`R/validators.R`) to 11 files (up from
  3). All of `alluvial-plot.R`, `covariate-balance.R`, `eda-plots.R`,
  `goodness-followup.R`, `hazard-plot.R`, `kaplan-meier.R`,
  `longitudinal-counts-plot.R`, `mirror-histogram.R`,
  `nonparametric-curve-plot.R`, `nonparametric-ordinal-plot.R`,
  `spaghetti-plot.R`, `stacked-histogram.R`, `trends-plot.R`, and
  `upset-plot.R` now delegate `data.frame`, column-presence,
  numeric-column, and alpha checks to `.check_df()`, `.check_cols()`,
  `.check_col()`, `.check_numeric_col()`, and `.check_alpha()`. Error
  wording is now consistent across all entry points.

### Code quality

- Named all simulation tuning constants in
  [`sample_nonparametric_curve_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_nonparametric_curve_data.md)
  and the internal helper `.np_sample_bins()`: `eta_intercept`,
  `logit_shift`, `cont_baseline`, `cont_scale`, `cont_sigma`,
  `eff_frac_prob`, `eff_frac_cont`. Magic numbers replaced throughout
  single-curve, multi-group, and binned-data-summary code paths.
- Named all simulation tuning constants in
  [`sample_nonparametric_ordinal_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_nonparametric_ordinal_data.md)
  and
  [`sample_nonparametric_ordinal_points()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_nonparametric_ordinal_points.md):
  `a_first`, `a_step`, `eta_intercept`. Every occurrence of `-0.2`,
  `0.5`, and `1.2` replaced by the named constant.
- Extended edge-case test coverage:
  - `test_kaplan_meier.R`: added five `survival_curve` error tests for
    non-numeric `time_col`, invalid `event_col` values (character
    instead of 0/1/logical), and `alpha` at 0, \> 1, and \< 0.
  - `test_hazard_plot.R`: added graceful-handling test for an empty data
    frame (correct columns, zero rows) — confirms ggplot renders without
    error.
  - `test_mirror_histogram.R`: added error test for non-numeric
    `score_col`.

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
