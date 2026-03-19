# tests/testthat/test_plot_integration.R
#
# Smoke tests for every plot function / sample data pair.
# Each test:
#   1. Calls the sample_* function with small n and a fixed seed
#   2. Calls the corresponding plot function
#   3. Expects the result to be a ggplot object
#   Where relevant (mirror_histogram, survival_curve) also checks attributes.

library(testthat)
library(ggplot2)

# ============================================================================
# hazard_plot — sample_hazard_data and sample_hazard_empirical
# ============================================================================

test_that("hazard_plot returns a ggplot from sample_hazard_data", {
  dat <- sample_hazard_data(n = 50, time_max = 5, n_points = 50, seed = 1)
  p   <- hazard_plot(dat)
  expect_s3_class(p, "ggplot")
})

test_that("hazard_plot with empirical overlay returns a ggplot", {
  dat <- sample_hazard_data(n = 50, time_max = 5, n_points = 50, seed = 1)
  emp <- sample_hazard_empirical(n = 50, time_max = 5, n_bins = 4, seed = 1)
  p   <- hazard_plot(dat, empirical = emp)
  expect_s3_class(p, "ggplot")
})

# ============================================================================
# survival_curve — sample_survival_data
# ============================================================================

test_that("survival_curve returns a ggplot from sample_survival_data", {
  dta <- sample_survival_data(n = 50, seed = 1)
  p   <- survival_curve(dta)
  expect_s3_class(p, "ggplot")
})

test_that("survival_curve attaches km_data attribute", {
  dta <- sample_survival_data(n = 50, seed = 1)
  p   <- survival_curve(dta)
  expect_false(is.null(attr(p, "km_data")))
})

test_that("survival_curve attaches risk_table attribute", {
  dta <- sample_survival_data(n = 50, seed = 1)
  p   <- survival_curve(dta)
  expect_false(is.null(attr(p, "risk_table")))
})

test_that("survival_curve attaches report_table attribute", {
  dta <- sample_survival_data(n = 50, seed = 1)
  p   <- survival_curve(dta)
  expect_false(is.null(attr(p, "report_table")))
})

test_that("survival_curve plot_type='cumhaz' returns a ggplot", {
  dta <- sample_survival_data(n = 50, seed = 1)
  p   <- survival_curve(dta, plot_type = "cumhaz")
  expect_s3_class(p, "ggplot")
})

test_that("survival_curve plot_type='hazard' returns a ggplot", {
  dta <- sample_survival_data(n = 50, seed = 1)
  p   <- survival_curve(dta, plot_type = "hazard")
  expect_s3_class(p, "ggplot")
})

test_that("survival_curve plot_type='loglog' returns a ggplot", {
  dta <- sample_survival_data(n = 50, seed = 1)
  p   <- survival_curve(dta, plot_type = "loglog")
  expect_s3_class(p, "ggplot")
})

test_that("survival_curve plot_type='life' returns a ggplot", {
  dta <- sample_survival_data(n = 50, seed = 1)
  p   <- survival_curve(dta, plot_type = "life")
  expect_s3_class(p, "ggplot")
})

test_that("survival_curve strata_col deprecation warning is emitted", {
  dta <- sample_survival_data(
    n             = 50,
    strata_levels = c("A", "B"),
    seed          = 1
  )
  expect_warning(
    survival_curve(dta, strata_col = "valve_type"),
    "deprecated"
  )
})

# ============================================================================
# survival_difference_plot — sample_survival_difference_data
# ============================================================================

test_that("survival_difference_plot returns a ggplot", {
  dif <- sample_survival_difference_data(n = 50, time_max = 5, n_points = 50,
                                         seed = 1)
  p   <- survival_difference_plot(dif)
  expect_s3_class(p, "ggplot")
})

# ============================================================================
# nnt_plot — sample_nnt_data
# ============================================================================

test_that("nnt_plot returns a ggplot", {
  nnt <- sample_nnt_data(n = 50, time_max = 5, n_points = 50, seed = 1)
  p   <- nnt_plot(nnt)
  expect_s3_class(p, "ggplot")
})

# ============================================================================
# nonparametric_curve_plot — sample_nonparametric_curve_data
# ============================================================================

test_that("nonparametric_curve_plot returns a ggplot", {
  dat <- sample_nonparametric_curve_data(n = 50, time_max = 5,
                                         n_points = 50, seed = 1)
  p   <- nonparametric_curve_plot(dat)
  expect_s3_class(p, "ggplot")
})

# ============================================================================
# nonparametric_ordinal_plot — sample_nonparametric_ordinal_data
# ============================================================================

test_that("nonparametric_ordinal_plot returns a ggplot", {
  dat <- sample_nonparametric_ordinal_data(n = 100, time_max = 5,
                                           n_points = 50, seed = 1)
  p   <- nonparametric_ordinal_plot(dat)
  expect_s3_class(p, "ggplot")
})

# ============================================================================
# goodness_followup — sample_goodness_followup_data
# ============================================================================

test_that("goodness_followup returns a ggplot", {
  dta <- sample_goodness_followup_data(n = 50, seed = 1)
  p   <- goodness_followup(dta)
  expect_s3_class(p, "ggplot")
})

# ============================================================================
# goodness_event_plot — sample_goodness_followup_data
# ============================================================================

test_that("goodness_event_plot returns a ggplot", {
  dta <- sample_goodness_followup_data(n = 50, seed = 1)
  p   <- goodness_event_plot(
    dta,
    event_col      = "ev_event",
    event_time_col = "iv_event"
  )
  expect_s3_class(p, "ggplot")
})

# ============================================================================
# covariate_balance — sample_covariate_balance_data
# ============================================================================

test_that("covariate_balance returns a ggplot", {
  dta <- sample_covariate_balance_data(n_vars = 4, n = 100, seed = 1)
  p   <- covariate_balance(dta)
  expect_s3_class(p, "ggplot")
})

# ============================================================================
# mirror_histogram — sample_mirror_histogram_data
# ============================================================================

test_that("mirror_histogram returns a ggplot", {
  dta <- sample_mirror_histogram_data(n = 50, seed = 1)
  p   <- suppressMessages(mirror_histogram(dta))
  expect_s3_class(p, "ggplot")
})

test_that("mirror_histogram attaches diagnostics attribute", {
  dta <- sample_mirror_histogram_data(n = 50, seed = 1)
  p   <- suppressMessages(mirror_histogram(dta))
  expect_false(is.null(attr(p, "diagnostics")))
})

test_that("mirror_histogram attaches data attribute", {
  dta <- sample_mirror_histogram_data(n = 50, seed = 1)
  p   <- suppressMessages(mirror_histogram(dta))
  expect_false(is.null(attr(p, "data")))
})

test_that("mirror_histogram emits a diagnostics message", {
  dta <- sample_mirror_histogram_data(n = 50, seed = 1)
  expect_message(mirror_histogram(dta), "mirror_histogram diagnostics")
})

# ============================================================================
# spaghetti_plot — sample_spaghetti_data
# ============================================================================

test_that("spaghetti_plot returns a ggplot", {
  dta <- sample_spaghetti_data(n_patients = 20, seed = 1)
  p   <- spaghetti_plot(dta)
  expect_s3_class(p, "ggplot")
})

# ============================================================================
# trends_plot — sample_trends_data
# ============================================================================

test_that("trends_plot returns a ggplot", {
  dta <- sample_trends_data(n = 100, seed = 1)
  p   <- trends_plot(dta)
  expect_s3_class(p, "ggplot")
})

# ============================================================================
# longitudinal_counts_plot — sample_longitudinal_counts_data
# ============================================================================

test_that("longitudinal_counts_plot returns a ggplot", {
  dta <- sample_longitudinal_counts_data(n_patients = 30, seed = 1)
  p   <- longitudinal_counts_plot(dta)
  expect_s3_class(p, "ggplot")
})

# ============================================================================
# alluvial_plot — sample_alluvial_data
# ============================================================================

test_that("alluvial_plot returns a ggplot", {
  dta  <- sample_alluvial_data(n = 100, seed = 1)
  axes <- c("pre_ar", "procedure", "post_ar")
  p    <- alluvial_plot(dta, axes = axes, y_col = "freq")
  expect_s3_class(p, "ggplot")
})

# ============================================================================
# cluster_sankey_plot — sample_cluster_sankey_data
# ============================================================================

test_that("cluster_sankey_plot returns a ggplot", {
  skip_if_not_installed("ggsankey")
  dta <- sample_cluster_sankey_data(n = 50, seed = 1)
  p   <- cluster_sankey_plot(dta)
  expect_s3_class(p, "ggplot")
})

# ============================================================================
# stacked_histogram — sample_stacked_histogram_data
# ============================================================================

test_that("stacked_histogram returns a ggplot", {
  dta <- sample_stacked_histogram_data(seed = 1)
  p   <- stacked_histogram(dta)
  expect_s3_class(p, "ggplot")
})

# ============================================================================
# upset_plot — sample_upset_data
# ============================================================================

test_that("upset_plot returns without error from sample data", {
  sets <- c("AV_Replacement", "AV_Repair", "MV_Replacement",
            "MV_Repair", "TV_Repair", "Aorta", "CABG")
  dta  <- sample_upset_data(n = 100, seed = 1)
  result <- tryCatch(
    upset_plot(dta, intersect = sets),
    error = function(e) {
      msg <- conditionMessage(e)
      if (grepl("valid theme|S7|patchwork", msg, ignore.case = TRUE)) {
        skip(paste("ComplexUpset version incompatibility:", msg))
      }
      stop(e)
    }
  )
  expect_true(!is.null(result))
})

# ============================================================================
# eda_plot — sample_eda_data
# ============================================================================

test_that("eda_plot returns a ggplot", {
  dta <- sample_eda_data(n = 50, seed = 1)
  p   <- eda_plot(dta)
  expect_s3_class(p, "ggplot")
})
