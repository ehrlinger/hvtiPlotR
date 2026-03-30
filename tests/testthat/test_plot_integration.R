# tests/testthat/test_plot_integration.R
#
# Smoke tests for every hvti_*() constructor / sample data pair.
# Each test:
#   1. Calls the sample_* function with small n and a fixed seed
#   2. Calls the hvti_*() constructor to build the S3 data object
#   3. Calls plot() on the object and expects a ggplot result
#   Where relevant (hvti_mirror, hvti_survival) also checks $tables slots.

library(testthat)
library(ggplot2)

# ============================================================================
# hazard_plot — sample_hazard_data and sample_hazard_empirical
# (retained single-call API — no hvti_* constructor)
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
# hvti_survival — sample_survival_data
# ============================================================================

test_that("hvti_survival returns an hvti_data object", {
  dta <- sample_survival_data(n = 50, seed = 1)
  km  <- hvti_survival(dta)
  expect_s3_class(km, "hvti_data")
})

test_that("plot(hvti_survival) returns a ggplot", {
  dta <- sample_survival_data(n = 50, seed = 1)
  km  <- hvti_survival(dta)
  expect_s3_class(plot(km), "ggplot")
})

test_that("hvti_survival $tables$risk is not NULL", {
  dta <- sample_survival_data(n = 50, seed = 1)
  km  <- hvti_survival(dta)
  expect_false(is.null(km$tables$risk))
})

test_that("hvti_survival $tables$report is not NULL", {
  dta <- sample_survival_data(n = 50, seed = 1)
  km  <- hvti_survival(dta)
  expect_false(is.null(km$tables$report))
})

test_that("plot(km, type='cumhaz') returns a ggplot", {
  dta <- sample_survival_data(n = 50, seed = 1)
  km  <- hvti_survival(dta)
  expect_s3_class(plot(km, type = "cumhaz"), "ggplot")
})

test_that("plot(km, type='hazard') returns a ggplot", {
  dta <- sample_survival_data(n = 50, seed = 1)
  km  <- hvti_survival(dta)
  expect_s3_class(plot(km, type = "hazard"), "ggplot")
})

test_that("plot(km, type='loglog') returns a ggplot", {
  dta <- sample_survival_data(n = 50, seed = 1)
  km  <- hvti_survival(dta)
  expect_s3_class(plot(km, type = "loglog"), "ggplot")
})

test_that("plot(km, type='life') returns a ggplot", {
  dta <- sample_survival_data(n = 50, seed = 1)
  km  <- hvti_survival(dta)
  expect_s3_class(plot(km, type = "life"), "ggplot")
})

# ============================================================================
# survival_difference_plot — sample_survival_difference_data
# (retained single-call API)
# ============================================================================

test_that("survival_difference_plot returns a ggplot", {
  dif <- sample_survival_difference_data(n = 50, time_max = 5, n_points = 50,
                                         seed = 1)
  p   <- survival_difference_plot(dif)
  expect_s3_class(p, "ggplot")
})

# ============================================================================
# nnt_plot — sample_nnt_data
# (retained single-call API)
# ============================================================================

test_that("nnt_plot returns a ggplot", {
  nnt <- sample_nnt_data(n = 50, time_max = 5, n_points = 50, seed = 1)
  p   <- nnt_plot(nnt)
  expect_s3_class(p, "ggplot")
})

# ============================================================================
# hvti_nonparametric — sample_nonparametric_curve_data
# ============================================================================

test_that("hvti_nonparametric returns an hvti_data object", {
  dat <- sample_nonparametric_curve_data(n = 50, time_max = 5,
                                         n_points = 50, seed = 1)
  np  <- hvti_nonparametric(dat)
  expect_s3_class(np, "hvti_data")
})

test_that("plot(hvti_nonparametric) returns a ggplot", {
  dat <- sample_nonparametric_curve_data(n = 50, time_max = 5,
                                         n_points = 50, seed = 1)
  expect_s3_class(plot(hvti_nonparametric(dat)), "ggplot")
})

# ============================================================================
# hvti_ordinal — sample_nonparametric_ordinal_data
# ============================================================================

test_that("hvti_ordinal returns an hvti_data object", {
  dat <- sample_nonparametric_ordinal_data(n = 100, time_max = 5,
                                           n_points = 50, seed = 1)
  ord <- hvti_ordinal(dat)
  expect_s3_class(ord, "hvti_data")
})

test_that("plot(hvti_ordinal) returns a ggplot", {
  dat <- sample_nonparametric_ordinal_data(n = 100, time_max = 5,
                                           n_points = 50, seed = 1)
  expect_s3_class(plot(hvti_ordinal(dat)), "ggplot")
})

# ============================================================================
# hvti_followup — sample_goodness_followup_data
# ============================================================================

test_that("hvti_followup returns an hvti_data object", {
  dta <- sample_goodness_followup_data(n = 50, seed = 1)
  gf  <- hvti_followup(dta)
  expect_s3_class(gf, "hvti_data")
})

test_that("plot(hvti_followup) returns a ggplot", {
  dta <- sample_goodness_followup_data(n = 50, seed = 1)
  expect_s3_class(plot(hvti_followup(dta)), "ggplot")
})

test_that("plot(hvti_followup, type='event') returns a ggplot", {
  dta <- sample_goodness_followup_data(n = 50, seed = 1)
  gf  <- hvti_followup(dta,
                        event_col      = "ev_event",
                        event_time_col = "iv_event")
  expect_s3_class(plot(gf, type = "event"), "ggplot")
})

# ============================================================================
# hvti_balance — sample_covariate_balance_data
# ============================================================================

test_that("hvti_balance returns an hvti_data object", {
  dta <- sample_covariate_balance_data(n_vars = 4, n = 100, seed = 1)
  cb  <- hvti_balance(dta)
  expect_s3_class(cb, "hvti_data")
})

test_that("plot(hvti_balance) returns a ggplot", {
  dta <- sample_covariate_balance_data(n_vars = 4, n = 100, seed = 1)
  expect_s3_class(plot(hvti_balance(dta)), "ggplot")
})

# ============================================================================
# hvti_mirror — sample_mirror_histogram_data
# ============================================================================

test_that("hvti_mirror returns an hvti_data object", {
  dta <- sample_mirror_histogram_data(n = 50, seed = 1)
  mh  <- suppressMessages(hvti_mirror(dta))
  expect_s3_class(mh, "hvti_data")
})

test_that("plot(hvti_mirror) returns a ggplot", {
  dta <- sample_mirror_histogram_data(n = 50, seed = 1)
  mh  <- suppressMessages(hvti_mirror(dta))
  expect_s3_class(plot(mh), "ggplot")
})

test_that("hvti_mirror $tables$diagnostics is not NULL", {
  dta <- sample_mirror_histogram_data(n = 50, seed = 1)
  mh  <- suppressMessages(hvti_mirror(dta))
  expect_false(is.null(mh$tables$diagnostics))
})

test_that("hvti_mirror $tables$working is not NULL", {
  dta <- sample_mirror_histogram_data(n = 50, seed = 1)
  mh  <- suppressMessages(hvti_mirror(dta))
  expect_false(is.null(mh$tables$working))
})

test_that("hvti_mirror emits a diagnostics message", {
  dta <- sample_mirror_histogram_data(n = 50, seed = 1)
  expect_message(hvti_mirror(dta), "mirror_histogram diagnostics")
})

# ============================================================================
# hvti_spaghetti — sample_spaghetti_data
# ============================================================================

test_that("hvti_spaghetti returns an hvti_data object", {
  dta <- sample_spaghetti_data(n_patients = 20, seed = 1)
  sp  <- hvti_spaghetti(dta)
  expect_s3_class(sp, "hvti_data")
})

test_that("plot(hvti_spaghetti) returns a ggplot", {
  dta <- sample_spaghetti_data(n_patients = 20, seed = 1)
  expect_s3_class(plot(hvti_spaghetti(dta)), "ggplot")
})

# ============================================================================
# hvti_trends — sample_trends_data
# ============================================================================

test_that("hvti_trends returns an hvti_data object", {
  dta <- sample_trends_data(n = 100, seed = 1)
  tr  <- hvti_trends(dta)
  expect_s3_class(tr, "hvti_data")
})

test_that("plot(hvti_trends) returns a ggplot", {
  dta <- sample_trends_data(n = 100, seed = 1)
  expect_s3_class(plot(hvti_trends(dta)), "ggplot")
})

# ============================================================================
# hvti_longitudinal — sample_longitudinal_counts_data
# ============================================================================

test_that("hvti_longitudinal returns an hvti_data object", {
  dta <- sample_longitudinal_counts_data(n_patients = 30, seed = 1)
  lc  <- hvti_longitudinal(dta)
  expect_s3_class(lc, "hvti_data")
})

test_that("plot(hvti_longitudinal) returns a ggplot", {
  dta <- sample_longitudinal_counts_data(n_patients = 30, seed = 1)
  expect_s3_class(plot(hvti_longitudinal(dta)), "ggplot")
})

# ============================================================================
# hvti_alluvial — sample_alluvial_data
# ============================================================================

test_that("hvti_alluvial returns an hvti_data object", {
  dta  <- sample_alluvial_data(n = 100, seed = 1)
  axes <- c("pre_ar", "procedure", "post_ar")
  al   <- hvti_alluvial(dta, axes = axes, y_col = "freq")
  expect_s3_class(al, "hvti_data")
})

test_that("plot(hvti_alluvial) returns a ggplot", {
  dta  <- sample_alluvial_data(n = 100, seed = 1)
  axes <- c("pre_ar", "procedure", "post_ar")
  expect_s3_class(plot(hvti_alluvial(dta, axes = axes, y_col = "freq")),
                  "ggplot")
})

# ============================================================================
# hvti_sankey — sample_cluster_sankey_data
# ============================================================================

test_that("hvti_sankey returns an hvti_data object", {
  skip_if_not_installed("ggsankey")
  dta <- sample_cluster_sankey_data(n = 50, seed = 1)
  sk  <- hvti_sankey(dta)
  expect_s3_class(sk, "hvti_data")
})

test_that("plot(hvti_sankey) returns a ggplot", {
  skip_if_not_installed("ggsankey")
  dta <- sample_cluster_sankey_data(n = 50, seed = 1)
  expect_s3_class(plot(hvti_sankey(dta)), "ggplot")
})

# ============================================================================
# hvti_stacked — sample_stacked_histogram_data
# ============================================================================

test_that("hvti_stacked returns an hvti_data object", {
  dta <- sample_stacked_histogram_data(seed = 1)
  sh  <- hvti_stacked(dta)
  expect_s3_class(sh, "hvti_data")
})

test_that("plot(hvti_stacked) returns a ggplot", {
  dta <- sample_stacked_histogram_data(seed = 1)
  expect_s3_class(plot(hvti_stacked(dta)), "ggplot")
})

# ============================================================================
# hvti_upset — sample_upset_data
# ============================================================================

test_that("plot(hvti_upset) returns without error from sample data", {
  sets <- c("AV_Replacement", "AV_Repair", "MV_Replacement",
            "MV_Repair", "TV_Repair", "Aorta", "CABG")
  dta  <- sample_upset_data(n = 100, seed = 1)
  result <- tryCatch(
    plot(hvti_upset(dta, intersect = sets)),
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
# hvti_eda — sample_eda_data
# ============================================================================

test_that("hvti_eda returns an hvti_data object", {
  dta <- sample_eda_data(n = 50, seed = 1)
  ed  <- hvti_eda(dta)
  expect_s3_class(ed, "hvti_data")
})

test_that("plot(hvti_eda) returns a ggplot", {
  dta <- sample_eda_data(n = 50, seed = 1)
  expect_s3_class(plot(hvti_eda(dta)), "ggplot")
})
