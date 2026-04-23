# tests/testthat/test_plot_integration.R
#
# Smoke tests for every hv_*() constructor / sample data pair.
# Each test:
#   1. Calls the sample_* function with small n and a fixed seed
#   2. Calls the hv_*() constructor to build the S3 data object
#   3. Calls plot() on the object and expects a ggplot result
#   Where relevant (hv_mirror_hist, hv_survival) also checks $tables slots.

library(testthat)
library(ggplot2)

# ============================================================================
# hazard_plot — sample_hazard_data and sample_hazard_empirical
# (retained single-call API — no hv_* constructor)
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
# hv_survival — sample_survival_data
# ============================================================================

test_that("hv_survival returns an hv_data object", {
  dta <- sample_survival_data(n = 50, seed = 1)
  km  <- hv_survival(dta)
  expect_s3_class(km, "hv_data")
})

test_that("plot(hv_survival) returns a ggplot", {
  dta <- sample_survival_data(n = 50, seed = 1)
  km  <- hv_survival(dta)
  expect_s3_class(plot(km), "ggplot")
})

test_that("hv_survival $tables$risk is not NULL", {
  dta <- sample_survival_data(n = 50, seed = 1)
  km  <- hv_survival(dta)
  expect_false(is.null(km$tables$risk))
})

test_that("hv_survival $tables$report is not NULL", {
  dta <- sample_survival_data(n = 50, seed = 1)
  km  <- hv_survival(dta)
  expect_false(is.null(km$tables$report))
})

test_that("plot(km, type='cumhaz') returns a ggplot", {
  dta <- sample_survival_data(n = 50, seed = 1)
  km  <- hv_survival(dta)
  expect_s3_class(plot(km, type = "cumhaz"), "ggplot")
})

test_that("plot(km, type='hazard') returns a ggplot", {
  dta <- sample_survival_data(n = 50, seed = 1)
  km  <- hv_survival(dta)
  expect_s3_class(plot(km, type = "hazard"), "ggplot")
})

test_that("plot(km, type='loglog') returns a ggplot", {
  dta <- sample_survival_data(n = 50, seed = 1)
  km  <- hv_survival(dta)
  expect_s3_class(plot(km, type = "loglog"), "ggplot")
})

test_that("plot(km, type='life') returns a ggplot", {
  dta <- sample_survival_data(n = 50, seed = 1)
  km  <- hv_survival(dta)
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
# hv_nonparametric — sample_nonparametric_curve_data
# ============================================================================

test_that("hv_nonparametric returns an hv_data object", {
  dat <- sample_nonparametric_curve_data(n = 50, time_max = 5,
                                         n_points = 50, seed = 1)
  np  <- hv_nonparametric(dat)
  expect_s3_class(np, "hv_data")
})

test_that("plot(hv_nonparametric) returns a ggplot", {
  dat <- sample_nonparametric_curve_data(n = 50, time_max = 5,
                                         n_points = 50, seed = 1)
  expect_s3_class(plot(hv_nonparametric(dat)), "ggplot")
})

# ============================================================================
# hv_ordinal — sample_nonparametric_ordinal_data
# ============================================================================

test_that("hv_ordinal returns an hv_data object", {
  dat <- sample_nonparametric_ordinal_data(n = 100, time_max = 5,
                                           n_points = 50, seed = 1)
  ord <- hv_ordinal(dat)
  expect_s3_class(ord, "hv_data")
})

test_that("plot(hv_ordinal) returns a ggplot", {
  dat <- sample_nonparametric_ordinal_data(n = 100, time_max = 5,
                                           n_points = 50, seed = 1)
  expect_s3_class(plot(hv_ordinal(dat)), "ggplot")
})

# ============================================================================
# hv_followup — sample_goodness_followup_data
# ============================================================================

test_that("hv_followup returns an hv_data object", {
  dta <- sample_goodness_followup_data(n = 50, seed = 1)
  gf  <- hv_followup(dta)
  expect_s3_class(gf, "hv_data")
})

test_that("plot(hv_followup) returns a ggplot", {
  dta <- sample_goodness_followup_data(n = 50, seed = 1)
  expect_s3_class(plot(hv_followup(dta)), "ggplot")
})

test_that("plot(hv_followup, type='event') returns a ggplot", {
  dta <- sample_goodness_followup_data(n = 50, seed = 1)
  gf  <- hv_followup(dta,
                        event_col      = "ev_event",
                        event_time_col = "iv_event")
  expect_s3_class(plot(gf, type = "event"), "ggplot")
})

# ============================================================================
# hv_balance — sample_covariate_balance_data
# ============================================================================

test_that("hv_balance returns an hv_data object", {
  dta <- sample_covariate_balance_data(n_vars = 4, n = 100, seed = 1)
  cb  <- hv_balance(dta)
  expect_s3_class(cb, "hv_data")
})

test_that("plot(hv_balance) returns a ggplot", {
  dta <- sample_covariate_balance_data(n_vars = 4, n = 100, seed = 1)
  expect_s3_class(plot(hv_balance(dta)), "ggplot")
})

# ============================================================================
# hv_mirror_hist — sample_mirror_histogram_data
# ============================================================================

test_that("hv_mirror_hist returns an hv_data object", {
  dta <- sample_mirror_histogram_data(n = 50, seed = 1)
  mh  <- suppressMessages(hv_mirror_hist(dta))
  expect_s3_class(mh, "hv_data")
})

test_that("plot(hv_mirror_hist) returns a ggplot", {
  dta <- sample_mirror_histogram_data(n = 50, seed = 1)
  mh  <- suppressMessages(hv_mirror_hist(dta))
  expect_s3_class(plot(mh), "ggplot")
})

test_that("hv_mirror_hist $tables$diagnostics is not NULL", {
  dta <- sample_mirror_histogram_data(n = 50, seed = 1)
  mh  <- suppressMessages(hv_mirror_hist(dta))
  expect_false(is.null(mh$tables$diagnostics))
})

test_that("hv_mirror_hist $tables$working is not NULL", {
  dta <- sample_mirror_histogram_data(n = 50, seed = 1)
  mh  <- suppressMessages(hv_mirror_hist(dta))
  expect_false(is.null(mh$tables$working))
})

test_that("hv_mirror_hist emits a diagnostics message", {
  dta <- sample_mirror_histogram_data(n = 50, seed = 1)
  expect_message(hv_mirror_hist(dta), "mirror_histogram diagnostics")
})

# ============================================================================
# hv_spaghetti — sample_spaghetti_data
# ============================================================================

test_that("hv_spaghetti returns an hv_data object", {
  dta <- sample_spaghetti_data(n_patients = 20, seed = 1)
  sp  <- hv_spaghetti(dta)
  expect_s3_class(sp, "hv_data")
})

test_that("plot(hv_spaghetti) returns a ggplot", {
  dta <- sample_spaghetti_data(n_patients = 20, seed = 1)
  expect_s3_class(plot(hv_spaghetti(dta)), "ggplot")
})

# ============================================================================
# hv_trends — sample_trends_data
# ============================================================================

test_that("hv_trends returns an hv_data object", {
  dta <- sample_trends_data(n = 100, seed = 1)
  tr  <- hv_trends(dta)
  expect_s3_class(tr, "hv_data")
})

test_that("plot(hv_trends) returns a ggplot", {
  dta <- sample_trends_data(n = 100, seed = 1)
  expect_s3_class(plot(hv_trends(dta)), "ggplot")
})

# ============================================================================
# hv_longitudinal — sample_longitudinal_counts_data
# ============================================================================

test_that("hv_longitudinal returns an hv_data object", {
  dta <- sample_longitudinal_counts_data(n_patients = 30, seed = 1)
  lc  <- hv_longitudinal(dta)
  expect_s3_class(lc, "hv_data")
})

test_that("plot(hv_longitudinal) returns a ggplot", {
  dta <- sample_longitudinal_counts_data(n_patients = 30, seed = 1)
  expect_s3_class(plot(hv_longitudinal(dta)), "ggplot")
})

# ============================================================================
# hv_alluvial — sample_alluvial_data
# ============================================================================

test_that("hv_alluvial returns an hv_data object", {
  dta  <- sample_alluvial_data(n = 100, seed = 1)
  axes <- c("pre_ar", "procedure", "post_ar")
  al   <- hv_alluvial(dta, axes = axes, y_col = "freq")
  expect_s3_class(al, "hv_data")
})

test_that("plot(hv_alluvial) returns a ggplot", {
  dta  <- sample_alluvial_data(n = 100, seed = 1)
  axes <- c("pre_ar", "procedure", "post_ar")
  expect_s3_class(plot(hv_alluvial(dta, axes = axes, y_col = "freq")),
                  "ggplot")
})

# ============================================================================
# hv_sankey — sample_cluster_sankey_data
# ============================================================================

test_that("hv_sankey returns an hv_data object", {
  skip_if_not_installed("ggsankey")
  dta <- sample_cluster_sankey_data(n = 50, seed = 1)
  sk  <- hv_sankey(dta)
  expect_s3_class(sk, "hv_data")
})

test_that("plot(hv_sankey) returns a ggplot", {
  skip_if_not_installed("ggsankey")
  dta <- sample_cluster_sankey_data(n = 50, seed = 1)
  p <- hv_muffle_known_plot_warnings(plot(hv_sankey(dta)))
  expect_s3_class(p, "ggplot")
})

# ============================================================================
# hv_stacked — sample_stacked_histogram_data
# ============================================================================

test_that("hv_stacked returns an hv_data object", {
  dta <- sample_stacked_histogram_data(seed = 1)
  sh  <- hv_stacked(dta)
  expect_s3_class(sh, "hv_data")
})

test_that("plot(hv_stacked) returns a ggplot", {
  dta <- sample_stacked_histogram_data(seed = 1)
  expect_s3_class(plot(hv_stacked(dta)), "ggplot")
})

# ============================================================================
# hv_upset — sample_upset_data
# ============================================================================

test_that("plot(hv_upset) returns without error from sample data", {
  sets <- c("AV_Replacement", "AV_Repair", "MV_Replacement",
            "MV_Repair", "TV_Repair", "Aorta", "CABG")
  dta  <- sample_upset_data(n = 100, seed = 1)
  result <- tryCatch(
    hv_muffle_known_plot_warnings(plot(hv_upset(dta, intersect = sets))),
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
# hv_eda — sample_eda_data
# ============================================================================

test_that("hv_eda returns an hv_data object", {
  dta <- sample_eda_data(n = 50, seed = 1)
  ed  <- hv_eda(dta)
  expect_s3_class(ed, "hv_data")
})

test_that("plot(hv_eda) returns a ggplot", {
  dta <- sample_eda_data(n = 50, seed = 1)
  expect_s3_class(plot(hv_eda(dta)), "ggplot")
})
