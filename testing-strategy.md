# hvtiPlotR Testing Strategy

*Generated from full audit of the test suite — March 2026*

------------------------------------------------------------------------

## Current State

The package ships 12 test files containing roughly 500 individual
[`test_that()`](https://testthat.r-lib.org/reference/test_that.html)
blocks. Every exported function has at least one test. The overall suite
is strong in several areas but has important gaps in coverage depth,
snapshot testing, and a handful of plot families that received only a
single smoke test during early integration work.

### Test file inventory

| File                       | What it covers                                                                                                                        | Depth |
|----------------------------|---------------------------------------------------------------------------------------------------------------------------------------|-------|
| `test_themes.R`            | All 5 `hvti_theme_*` functions + [`hvti_theme()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme.md) dispatcher + aliases | ★★★★★ |
| `test_kaplan_meier.R`      | `sample_survival_data` + `survival_curve` (all plot types, strata, CI, methods, validation)                                           | ★★★★★ |
| `test_mirror_histogram.R`  | `mirror_histogram` + `sample_mirror_histogram_data` (binary and IPTW-weighted modes, internal helpers)                                | ★★★★★ |
| `test_covariate_balance.R` | `covariate_balance` + `sample_covariate_balance_data` (structure, plot geometry, rendered labels)                                     | ★★★★★ |
| `test_goodness_followup.R` | `goodness_followup` + `goodness_event_plot` + `sample_goodness_followup_data`                                                         | ★★★★★ |
| `test_save_ppt.R`          | `save_ppt` (single/list, layouts, validation)                                                                                         | ★★★★★ |
| `test_new_plots.R`         | `alluvial_plot`, `spaghetti_plot`, `trends_plot`, `longitudinal_counts_plot/table`, `upset_plot` + all sample\_\* generators          | ★★★★☆ |
| `test_eda_plots.R`         | `eda_classify_var`, `eda_select_vars`, `sample_eda_data`, `eda_plot` (all three variable type paths)                                  | ★★★★☆ |
| `test_stacked_histogram.R` | `stacked_histogram` + `sample_stacked_histogram_data` (position, binwidth, aesthetics)                                                | ★★★★☆ |
| `test_footnote.R`          | `makeFootnote` + `make_footnote` (both renderers, parameter validation)                                                               | ★★★☆☆ |
| `test_plot_integration.R`  | Smoke test for every plot function / sample\_\* pair                                                                                  | ★★☆☆☆ |
| `test_data.R`              | `parametric` + `nonparametric` built-in datasets (structure only)                                                                     | ★★☆☆☆ |

------------------------------------------------------------------------

## Coverage Gaps

### 1. Plot functions with smoke-test-only coverage

Six plot families live entirely in `test_plot_integration.R` with 1–2
tests each. They have no input-validation tests, no column-name
flexibility tests, and no layer-structure assertions.

| Function                     | Current tests                | Missing                                                                                                    |
|------------------------------|------------------------------|------------------------------------------------------------------------------------------------------------|
| `hazard_plot`                | 2 (smoke, empirical overlay) | Validation: missing `time_col`, wrong `n.groups`; layer: `GeomRibbon`, `GeomLine`; parametric model args   |
| `survival_difference_plot`   | 1 (smoke)                    | Validation: missing columns, out-of-range confidence; structure: reference group rendering, ribbon vs line |
| `nnt_plot`                   | 1 (smoke)                    | Validation: data frame check, column presence; structure: `GeomLine`, `GeomRibbon`, inf-NNT handling       |
| `nonparametric_curve_plot`   | 1 (smoke)                    | Validation, group-col tests, conf_int flag, layer structure                                                |
| `nonparametric_ordinal_plot` | 1 (smoke)                    | Validation, grade-level ordering, cumulative vs non-cumulative mode                                        |
| `cluster_sankey_plot`        | 1 (ggsankey skip)            | Everything — always skipped when `ggsankey` is absent                                                      |

### 2. Sample-data generators with no validation tests

These generators are exported and documented but have no dedicated tests
beyond being passed to their plot function.

| Generator                             | What to test                                                                                      |
|---------------------------------------|---------------------------------------------------------------------------------------------------|
| `sample_hazard_data`                  | Column names, `n_groups` creates group column, time range, `seed` reproducibility, error on `n=0` |
| `sample_hazard_empirical`             | Column names, `n_bins` controls row count, midpoint computation                                   |
| `sample_life_table`                   | Column names, `survival` in \[0, 100\], group factor levels, `time_max` respected                 |
| `sample_survival_difference_data`     | Column names, confidence bounds straddle point estimate, seed reproducibility                     |
| `sample_nnt_data`                     | Column names, NNT positive, `Inf` values when difference ≈ 0, seed reproducibility                |
| `sample_nonparametric_curve_points`   | Column names, `nrow` matches expected, group levels, confidence bounds ordering                   |
| `sample_nonparametric_ordinal_points` | Column names, ordinal level ordering, cumulative sum ≤ 1, seed reproducibility                    |
| `sample_cluster_sankey_data`          | Column names, `k` range respected, `n` rows, seed reproducibility                                 |

### 3. No snapshot / visual regression tests

The entire suite asserts on *structure* (class, layer types, attribute
names) but never on *values*. Drift in estimated survival probabilities,
computed SMDs, or rendered label text would go completely undetected.

Targets for
[`expect_snapshot()`](https://testthat.r-lib.org/reference/expect_snapshot.html)
(testthat 3.x):

- Rendered label text from `covariate_balance` y-axis
- `survival_curve` report table for a fixed seed
- `mirror_histogram` diagnostics list for a fixed seed
- `eda_plot` plot title derived from `y_label`

### 4. Missing edge-case tests

| Function                     | Untested edge case                                                                                                                                                                                                                                                                                                                                 |
|------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `make_footnote`              | `prefix` parameter (the new snake_case API has a `prefix` arg that `makeFootnote` does not expose; no test verifies prefix is prepended to rendered text)                                                                                                                                                                                          |
| `eda_classify_var`           | Logical vector input (neither `Cat_Char` nor `Cont` — what does it return?)                                                                                                                                                                                                                                                                        |
| `survival_curve`             | All-censored data (no events); single observation per stratum                                                                                                                                                                                                                                                                                      |
| `nnt_plot`                   | Divide-by-zero / `Inf` NNT values (survival difference of zero at some time points)                                                                                                                                                                                                                                                                |
| `nonparametric_ordinal_plot` | Fewer grade levels than expected (e.g., a stratum where only 2 of 4 grades appear)                                                                                                                                                                                                                                                                 |
| `save_ppt`                   | `slide_titles` length mismatch vs list length (should error with a useful message)                                                                                                                                                                                                                                                                 |
| `stacked_histogram`          | Zero-row data frame after filtering                                                                                                                                                                                                                                                                                                                |
| Built-in datasets            | Using `parametric` with [`hazard_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/hazard_plot.md) and `nonparametric` with [`nonparametric_curve_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/nonparametric_curve_plot.md) — these represent the primary production use case but are only checked for structure, not usability |

### 5. No cross-function integration tests

The package’s value proposition involves *composing* outputs: a
`survival_curve` result styled with
[`hvti_theme()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme.md)
and exported via
[`save_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/save_ppt.md).
No test exercises this full pipeline.

------------------------------------------------------------------------

## Recommended Test Plan

### Priority 1 — Fill gaps in existing thin-coverage files (high ROI, low effort)

Create `tests/testthat/test_hazard_plot.R` and
`tests/testthat/test_nonparametric_plots.R` using the established
patterns from `test_kaplan_meier.R`. Each file should cover:

1.  Sample-data generator validation (columns, ranges, seed
    reproducibility, error paths)
2.  Plot function return type (`expect_s3_class(p, "ggplot")`)
3.  Layer structure (`GeomLine`, `GeomRibbon`, `GeomPoint` as
    appropriate)
4.  Confidence interval flag changes layer count
5.  Column-name flexibility (non-default column names)
6.  Input validation (missing columns, non-data-frame input,
    out-of-range parameters)

Example — `test_hazard_plot.R`:

``` r
# tests/testthat/test_hazard_plot.R
library(testthat)

# ============================================================================
# sample_hazard_data
# ============================================================================

test_that("sample_hazard_data returns a data frame", {
  df <- sample_hazard_data(n = 100, seed = 1)
  expect_true(is.data.frame(df))
})

test_that("sample_hazard_data has required columns", {
  df <- sample_hazard_data(n = 100, seed = 1)
  expect_true(all(c("time", "hazard", "lower", "upper") %in% names(df)))
})

test_that("sample_hazard_data hazard is positive", {
  df <- sample_hazard_data(n = 100, seed = 1)
  expect_true(all(df$hazard > 0))
})

test_that("sample_hazard_data confidence bounds straddle hazard estimate", {
  df <- sample_hazard_data(n = 200, seed = 42)
  expect_true(all(df$lower <= df$hazard + 1e-9))
  expect_true(all(df$upper >= df$hazard - 1e-9))
})

test_that("sample_hazard_data is reproducible with same seed", {
  df1 <- sample_hazard_data(n = 100, seed = 7)
  df2 <- sample_hazard_data(n = 100, seed = 7)
  expect_identical(df1, df2)
})

test_that("sample_hazard_data differs across seeds", {
  df1 <- sample_hazard_data(n = 100, seed = 1)
  df2 <- sample_hazard_data(n = 100, seed = 2)
  expect_false(identical(df1, df2))
})

# ============================================================================
# hazard_plot — structure
# ============================================================================

test_that("hazard_plot has a GeomLine layer", {
  dat   <- sample_hazard_data(n = 50, seed = 1)
  geoms <- sapply(hazard_plot(dat)$layers, function(l) class(l$geom)[1])
  expect_true("GeomLine" %in% geoms)
})

test_that("hazard_plot has a GeomRibbon layer (confidence interval)", {
  dat   <- sample_hazard_data(n = 50, seed = 1)
  geoms <- sapply(hazard_plot(dat)$layers, function(l) class(l$geom)[1])
  expect_true("GeomRibbon" %in% geoms)
})

test_that("hazard_plot with empirical overlay adds a GeomPoint layer", {
  dat <- sample_hazard_data(n = 50, seed = 1)
  emp <- sample_hazard_empirical(n = 50, seed = 1)
  p_no_emp   <- hazard_plot(dat)
  p_with_emp <- hazard_plot(dat, empirical = emp)
  expect_gt(length(p_with_emp$layers), length(p_no_emp$layers))
})

# ============================================================================
# hazard_plot — input validation
# ============================================================================

test_that("hazard_plot errors when data is not a data frame", {
  expect_error(hazard_plot(list(time = 1:5, hazard = 1:5)), "data.frame")
})

test_that("hazard_plot errors when time_col is absent from data", {
  dat <- sample_hazard_data(n = 50, seed = 1)
  expect_error(hazard_plot(dat, time_col = "nonexistent"), "not found")
})

test_that("hazard_plot errors when hazard_col is absent from data", {
  dat <- sample_hazard_data(n = 50, seed = 1)
  expect_error(hazard_plot(dat, hazard_col = "nonexistent"), "not found")
})
```

### Priority 2 — Snapshot tests for value-sensitive outputs

Add a `tests/testthat/_snaps/` directory and snapshot the most
clinically important numeric outputs. Run
[`testthat::snapshot_accept()`](https://testthat.r-lib.org/reference/snapshot_accept.html)
once to establish the baseline.

``` r
# In test_kaplan_meier.R — add near the bottom:

test_that("survival_curve report_table matches snapshot (fixed seed)", {
  result <- survival_curve(
    sample_survival_data(n = 500, seed = 42),
    report_times = c(1, 5, 10, 15, 20)
  )
  expect_snapshot(attr(result, "report_table"))
})

# In test_mirror_histogram.R:

test_that("mirror_histogram diagnostics match snapshot (fixed seed)", {
  df     <- sample_mirror_histogram_data(200, seed = 42)
  result <- suppressMessages(mirror_histogram(df))
  expect_snapshot(attr(result, "diagnostics"))
})
```

### Priority 3 — Edge-case and boundary tests

Add these to the most relevant existing test files:

``` r
# In test_kaplan_meier.R — all-censored data:
test_that("survival_curve handles all-censored data gracefully", {
  dta <- sample_survival_data(n = 100, seed = 1)
  dta$dead <- FALSE          # override: no events
  expect_s3_class(survival_curve(dta), "ggplot")
})

# In test_footnote.R — make_footnote prefix:
test_that("make_footnote prepends prefix to text", {
  pdf(NULL)
  plot(1:10)
  expect_no_error(make_footnote("analysis.R", prefix = "Source: "))
  dev.off()
})

# In test_eda_plots.R — logical vector:
test_that("eda_classify_var handles a logical vector", {
  result <- eda_classify_var(c(TRUE, FALSE, TRUE, NA))
  expect_true(result %in% c("Cat_Num", "Cat_Char"))
})

# In test_save_ppt.R — mismatched slide_titles:
test_that("save_ppt errors when slide_titles length mismatches list length", {
  skip_if_not_installed("officer")
  skip_if_not_installed("rvg")
  template <- make_temp_template()
  on.exit(unlink(template))
  plots <- list(create_test_plot(), create_test_plot())
  expect_error(
    save_ppt(plots, template = template,
             powerpoint = tempfile(fileext = ".pptx"),
             slide_titles = c("A", "B", "C")),   # 3 titles for 2 plots
    "slide_titles"
  )
})
```

### Priority 4 — End-to-end pipeline test

``` r
# tests/testthat/test_pipeline.R
library(testthat)
library(ggplot2)

test_that("full pipeline: survival_curve -> theme -> save_ppt", {
  skip_if_not_installed("officer")
  skip_if_not_installed("rvg")

  template <- tempfile(fileext = ".pptx")
  officer::read_pptx() |>
    officer::add_slide(layout = "Title and Content") |>
    print(target = template)
  on.exit(unlink(template))

  km <- survival_curve(
    sample_survival_data(
      n = 100,
      strata_levels = c("SAVR", "TAVR"),
      seed = 1
    ),
    group_col = "valve_type"
  )

  pptx_out <- tempfile(fileext = ".pptx")
  on.exit(unlink(pptx_out), add = TRUE)

  expect_no_error(
    save_ppt(
      object       = km + hvti_theme("ppt"),
      template     = template,
      powerpoint   = pptx_out,
      slide_titles = "KM: SAVR vs TAVR"
    )
  )
  expect_true(file.exists(pptx_out))
})
```

### Priority 5 — Built-in dataset usability

``` r
# In test_data.R — add after existing tests:

test_that("parametric dataset works with hazard_plot()", {
  data(parametric, package = "hvtiPlotR", envir = environment())
  # identify the expected column names from the docs
  expect_s3_class(
    hazard_plot(parametric),
    "ggplot"
  )
})

test_that("nonparametric dataset works with nonparametric_curve_plot()", {
  data(nonparametric, package = "hvtiPlotR", envir = environment())
  expect_s3_class(
    nonparametric_curve_plot(nonparametric),
    "ggplot"
  )
})
```

------------------------------------------------------------------------

## Coverage Targets

| Category                                  | Current estimate | Target                                  |
|-------------------------------------------|------------------|-----------------------------------------|
| Theme functions                           | ~100% structure  | ~100% — already sufficient              |
| `survival_curve` + `sample_survival_data` | ~95%             | ~95% — add snapshot + all-censored      |
| `mirror_histogram`                        | ~95%             | ~95% — add snapshot                     |
| `covariate_balance`                       | ~90%             | ~90% — already good                     |
| `save_ppt`                                | ~85%             | ~90% — add `slide_titles` mismatch test |
| `hazard_plot` + 5 thin-coverage plots     | ~15%             | ~70% — priority 1 above                 |
| Sample-data generators (thin coverage)    | ~20%             | ~70% — add validation suite             |
| Snapshot / value regression               | 0%               | Add for top 4 functions                 |
| End-to-end pipeline                       | 0%               | Add 1 test for each major workflow      |

------------------------------------------------------------------------

## What to Skip

These categories are not worth testing:

- **`theme_man` / `theme_manuscript` / `theme_ppt` identical-function
  tests** — already covered via
  `expect_identical(theme_man, theme_manuscript)`; no need to duplicate
- **ggplot2 internal rendering** — whether a geom actually *draws*
  correctly is ggplot2’s responsibility, not hvtiPlotR’s
- **Font availability** — testing that “Outfit” renders correctly on
  every contributor’s machine is not worthwhile; the existing
  `base_family = "nonexistent"` no-error tests are sufficient
- **[`dev.off()`](https://rdrr.io/r/grDevices/dev.html) behavior** —
  `makeFootnote` already tests this adequately

------------------------------------------------------------------------

## Running the Tests

``` r
# All tests
devtools::test()

# A single file
testthat::test_file("tests/testthat/test_kaplan_meier.R")

# Update snapshots after intentional changes
testthat::snapshot_accept()

# Full R CMD check (runs tests + examples + vignettes)
devtools::check()
```

Coverage report (requires `covr`):

``` r
covr::package_coverage() |> covr::report()
```
