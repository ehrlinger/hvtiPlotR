# tests/testthat/test_survival_derived.R
#
# Full test suite for survival_difference_plot and nnt_plot:
#   sample_survival_difference_data, survival_difference_plot,
#   sample_nnt_data, nnt_plot
#
library(testthat)
library(ggplot2)

# ============================================================================
# sample_survival_difference_data
# ============================================================================

test_that("sample_survival_difference_data returns a data frame", {
  df <- sample_survival_difference_data(n = 100, seed = 1)
  expect_true(is.data.frame(df))
})

test_that("sample_survival_difference_data has required columns", {
  df <- sample_survival_difference_data(n = 100, seed = 1)
  expected <- c("time", "difference", "diff_lower", "diff_upper",
                "group1_surv", "group2_surv")
  expect_true(all(expected %in% names(df)))
})

test_that("sample_survival_difference_data returns n_points rows", {
  df <- sample_survival_difference_data(n = 100, n_points = 200, seed = 1)
  expect_equal(nrow(df), 200L)
})

test_that("sample_survival_difference_data CI bounds straddle difference estimate", {
  df <- sample_survival_difference_data(n = 300, seed = 42)
  expect_true(all(df$diff_lower <= df$difference + 1e-9))
  expect_true(all(df$diff_upper >= df$difference - 1e-9))
})

test_that("sample_survival_difference_data group1_surv and group2_surv are in [0, 100]", {
  df <- sample_survival_difference_data(n = 300, seed = 42)
  expect_true(all(df$group1_surv >= 0 & df$group1_surv <= 100))
  expect_true(all(df$group2_surv >= 0 & df$group2_surv <= 100))
})

test_that("sample_survival_difference_data treatment group has higher mean survival (default groups)", {
  # Default: Control (multiplier=1) vs Treatment (multiplier=0.7) -> treatment survives better
  df <- sample_survival_difference_data(n = 500, seed = 42)
  expect_gt(mean(df$group2_surv), mean(df$group1_surv))
})

test_that("sample_survival_difference_data difference is positive when group2 survives better", {
  df <- sample_survival_difference_data(n = 500, seed = 42)
  # At late time points the difference should be positive (treatment benefit)
  late <- df[df$time > max(df$time) * 0.5, ]
  expect_true(mean(late$difference) > 0)
})

test_that("sample_survival_difference_data is reproducible with same seed", {
  df1 <- sample_survival_difference_data(n = 100, seed = 7)
  df2 <- sample_survival_difference_data(n = 100, seed = 7)
  expect_identical(df1, df2)
})

test_that("sample_survival_difference_data errors when groups is not length 2", {
  expect_error(
    sample_survival_difference_data(
      groups = c("A" = 1.0, "B" = 0.8, "C" = 0.6)
    ),
    "length 2"
  )
})

# ============================================================================
# survival_difference_plot — return type and composability
# ============================================================================

test_that("survival_difference_plot returns a ggplot", {
  dif <- sample_survival_difference_data(n = 100, seed = 1)
  expect_s3_class(survival_difference_plot(dif), "ggplot")
})

test_that("survival_difference_plot is composable with + operator", {
  dif <- sample_survival_difference_data(n = 100, seed = 1)
  p   <- survival_difference_plot(dif) + ggplot2::labs(x = "Years")
  expect_s3_class(p, "ggplot")
  expect_equal(p$labels$x, "Years")
})

test_that("survival_difference_plot is composable with theme_hv_manuscript()", {
  dif <- sample_survival_difference_data(n = 100, seed = 1)
  p   <- survival_difference_plot(dif) + theme_hv_manuscript()
  expect_s3_class(p, "ggplot")
})

# ============================================================================
# survival_difference_plot — layer structure
# ============================================================================

test_that("survival_difference_plot has a GeomLine layer", {
  dif   <- sample_survival_difference_data(n = 100, seed = 1)
  geoms <- sapply(survival_difference_plot(dif)$layers, function(l) class(l$geom)[1])
  expect_true("GeomLine" %in% geoms)
})

test_that("survival_difference_plot has a GeomRibbon layer when CI cols supplied", {
  # GeomRibbon is only added when lower_col + upper_col are non-NULL.
  dif   <- sample_survival_difference_data(n = 100, seed = 1)
  geoms <- sapply(
    survival_difference_plot(
      dif,
      lower_col = "diff_lower",
      upper_col = "diff_upper"
    )$layers,
    function(l) class(l$geom)[1]
  )
  expect_true("GeomRibbon" %in% geoms)
})

# ============================================================================
# survival_difference_plot — input validation
# ============================================================================

test_that("survival_difference_plot errors when data is not a data frame", {
  expect_error(
    survival_difference_plot(list(time = 1:5, difference = 1:5)),
    "data.frame|data frame"
  )
})

test_that("survival_difference_plot errors when x_col is absent", {
  dif <- sample_survival_difference_data(n = 50, seed = 1)
  expect_error(
    survival_difference_plot(dif, x_col = "nonexistent"),
    "not found|not a column"
  )
})

test_that("survival_difference_plot errors when estimate_col is absent", {
  dif <- sample_survival_difference_data(n = 50, seed = 1)
  expect_error(
    survival_difference_plot(dif, estimate_col = "nonexistent"),
    "not found|not a column"
  )
})

# ============================================================================
# sample_nnt_data
# ============================================================================

test_that("sample_nnt_data returns a data frame", {
  df <- sample_nnt_data(n = 100, seed = 1)
  expect_true(is.data.frame(df))
})

test_that("sample_nnt_data has required columns", {
  df <- sample_nnt_data(n = 100, seed = 1)
  expected <- c("time", "arr", "arr_lower", "arr_upper",
                "nnt", "nnt_lower", "nnt_upper")
  expect_true(all(expected %in% names(df)))
})

test_that("sample_nnt_data returns n_points rows", {
  df <- sample_nnt_data(n = 100, n_points = 150, seed = 1)
  expect_equal(nrow(df), 150L)
})

test_that("sample_nnt_data arr CI bounds straddle arr estimate", {
  df <- sample_nnt_data(n = 300, seed = 42)
  expect_true(all(df$arr_lower <= df$arr + 1e-9))
  expect_true(all(df$arr_upper >= df$arr - 1e-9))
})

test_that("sample_nnt_data nnt is positive where arr > 0 (or NA)", {
  df <- sample_nnt_data(n = 300, seed = 42)
  valid <- df[!is.na(df$nnt), ]
  expect_true(all(valid$nnt > 0))
})

test_that("sample_nnt_data nnt is NA where arr is near zero", {
  # At very early time points the absolute risk reduction is near zero
  df <- sample_nnt_data(n = 500, seed = 42)
  earliest <- df[df$time == min(df$time), ]
  # Near t=0 the difference is ~0 so nnt should be NA
  expect_true(is.na(earliest$nnt))
})

test_that("sample_nnt_data is reproducible with same seed", {
  df1 <- sample_nnt_data(n = 100, seed = 9)
  df2 <- sample_nnt_data(n = 100, seed = 9)
  expect_identical(df1, df2)
})

test_that("sample_nnt_data errors when groups is not length 2", {
  expect_error(
    sample_nnt_data(groups = c("A" = 1.0, "B" = 0.8, "C" = 0.6)),
    "length 2"
  )
})

# ============================================================================
# nnt_plot — return type and composability
# ============================================================================

test_that("nnt_plot returns a ggplot", {
  nnt <- sample_nnt_data(n = 100, seed = 1)
  expect_s3_class(nnt_plot(nnt), "ggplot")
})

test_that("nnt_plot is composable with + operator", {
  nnt <- sample_nnt_data(n = 100, seed = 1)
  p   <- nnt_plot(nnt) + ggplot2::labs(x = "Years")
  expect_s3_class(p, "ggplot")
  expect_equal(p$labels$x, "Years")
})

test_that("nnt_plot is composable with theme_hv_manuscript()", {
  nnt <- sample_nnt_data(n = 100, seed = 1)
  p   <- nnt_plot(nnt) + theme_hv_manuscript()
  expect_s3_class(p, "ggplot")
})

# ============================================================================
# nnt_plot — layer structure
# ============================================================================

test_that("nnt_plot has a GeomLine layer", {
  nnt   <- sample_nnt_data(n = 100, seed = 1)
  geoms <- sapply(nnt_plot(nnt)$layers, function(l) class(l$geom)[1])
  expect_true("GeomLine" %in% geoms)
})

test_that("nnt_plot has a GeomRibbon layer when CI cols supplied", {
  # GeomRibbon is only added when lower_col + upper_col are non-NULL.
  nnt   <- sample_nnt_data(n = 100, seed = 1)
  geoms <- sapply(
    nnt_plot(nnt, lower_col = "nnt_lower", upper_col = "nnt_upper")$layers,
    function(l) class(l$geom)[1]
  )
  expect_true("GeomRibbon" %in% geoms)
})

# ============================================================================
# nnt_plot — input validation
# ============================================================================

test_that("nnt_plot errors when data is not a data frame", {
  expect_error(
    nnt_plot(list(time = 1:5, nnt = 1:5)),
    "data.frame|data frame"
  )
})

test_that("nnt_plot errors when x_col is absent", {
  nnt <- sample_nnt_data(n = 50, seed = 1)
  expect_error(
    nnt_plot(nnt, x_col = "nonexistent"),
    "not found|not a column"
  )
})

test_that("nnt_plot errors when estimate_col is absent", {
  nnt <- sample_nnt_data(n = 50, seed = 1)
  expect_error(
    nnt_plot(nnt, estimate_col = "nonexistent"),
    "not found|not a column"
  )
})

# ============================================================================
# Cross-function consistency
# ============================================================================

test_that("survival_difference_plot and nnt_plot use the same time grid (same inputs)", {
  dif <- sample_survival_difference_data(n = 200, seed = 42)
  nnt <- sample_nnt_data(n = 200, seed = 42)
  # Both are derived from the same underlying Weibull predictions,
  # so the time vectors should be identical
  expect_identical(dif$time, nnt$time)
})
