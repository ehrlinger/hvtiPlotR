# tests/testthat/test_nonparametric_plots.R
#
# Full test suite for nonparametric-curve-plot.R and
# nonparametric-ordinal-plot.R:
#   sample_nonparametric_curve_data, sample_nonparametric_curve_points,
#   nonparametric_curve_plot,
#   sample_nonparametric_ordinal_data, sample_nonparametric_ordinal_points,
#   nonparametric_ordinal_plot
#
library(testthat)
library(ggplot2)

# ============================================================================
# sample_nonparametric_curve_data
# ============================================================================

test_that("sample_nonparametric_curve_data returns a data frame", {
  df <- sample_nonparametric_curve_data(n = 100, seed = 1)
  expect_true(is.data.frame(df))
})

test_that("sample_nonparametric_curve_data has required columns (single-group)", {
  df <- sample_nonparametric_curve_data(n = 100, seed = 1)
  expect_true(all(c("time", "estimate", "lower", "upper") %in% names(df)))
})

test_that("sample_nonparametric_curve_data returns n_points rows (single)", {
  df <- sample_nonparametric_curve_data(n = 100, n_points = 200, seed = 1)
  expect_equal(nrow(df), 200L)
})

test_that("sample_nonparametric_curve_data probability estimate is in [0, 1]", {
  df <- sample_nonparametric_curve_data(
    n = 200, outcome_type = "probability", seed = 42
  )
  expect_true(all(df$estimate >= 0))
  expect_true(all(df$estimate <= 1))
})

test_that("sample_nonparametric_curve_data CI bounds straddle estimate", {
  df <- sample_nonparametric_curve_data(n = 200, seed = 42)
  expect_true(all(df$lower <= df$estimate + 1e-9))
  expect_true(all(df$upper >= df$estimate - 1e-9))
})

test_that("sample_nonparametric_curve_data is reproducible with same seed", {
  df1 <- sample_nonparametric_curve_data(n = 100, seed = 7)
  df2 <- sample_nonparametric_curve_data(n = 100, seed = 7)
  expect_identical(df1, df2)
})

test_that("sample_nonparametric_curve_data n_points controls row count", {
  # The smooth curve is deterministic math — seed does not introduce randomness.
  # Verify that changing n_points produces a different number of rows instead.
  df_s <- sample_nonparametric_curve_data(n = 100, n_points = 50,  seed = 1)
  df_l <- sample_nonparametric_curve_data(n = 100, n_points = 200, seed = 1)
  expect_false(identical(df_s, df_l))
})

test_that("sample_nonparametric_curve_data groups argument adds group factor", {
  df <- sample_nonparametric_curve_data(
    n = 100, groups = c("A" = 0.8, "B" = 1.2), seed = 1
  )
  expect_true("group" %in% names(df))
  expect_true(is.factor(df$group))
  expect_equal(levels(df$group), c("A", "B"))
})

test_that("sample_nonparametric_curve_data multi-group returns n_points per group", {
  df <- sample_nonparametric_curve_data(
    n = 100, n_points = 50,
    groups = c("Low" = 0.8, "High" = 1.3),
    seed = 1
  )
  expect_equal(nrow(df), 100L)   # 2 groups × 50 points
})

test_that("sample_nonparametric_curve_data continuous outcome has larger estimate scale than probability", {
  df_p <- sample_nonparametric_curve_data(n = 200, outcome_type = "probability", seed = 1)
  df_c <- sample_nonparametric_curve_data(n = 200, outcome_type = "continuous",  seed = 1)
  expect_gt(mean(df_c$estimate), mean(df_p$estimate))
})

# ============================================================================
# sample_nonparametric_curve_points
# ============================================================================

test_that("sample_nonparametric_curve_points returns a data frame", {
  df <- sample_nonparametric_curve_points(n = 100, seed = 1)
  expect_true(is.data.frame(df))
})

test_that("sample_nonparametric_curve_points has required columns (single-group)", {
  df <- sample_nonparametric_curve_points(n = 100, seed = 1)
  expect_true(all(c("time", "value") %in% names(df)))
})

test_that("sample_nonparametric_curve_points returns n_bins rows (single-group)", {
  df <- sample_nonparametric_curve_points(n = 200, n_bins = 8, seed = 1)
  expect_equal(nrow(df), 8L)
})

test_that("sample_nonparametric_curve_points multi-group has group factor", {
  df <- sample_nonparametric_curve_points(
    n = 200, groups = c("Ozaki" = 0.7, "CE-P" = 1.3), seed = 1
  )
  expect_true("group" %in% names(df))
  expect_equal(levels(df$group), c("Ozaki", "CE-P"))
})

test_that("sample_nonparametric_curve_points multi-group returns n_bins per group", {
  df <- sample_nonparametric_curve_points(
    n = 200, n_bins = 6,
    groups = c("A" = 0.8, "B" = 1.2),
    seed = 1
  )
  expect_equal(nrow(df), 12L)  # 2 groups × 6 bins
})

test_that("sample_nonparametric_curve_points is reproducible with same seed", {
  df1 <- sample_nonparametric_curve_points(n = 100, seed = 5)
  df2 <- sample_nonparametric_curve_points(n = 100, seed = 5)
  expect_identical(df1, df2)
})

# ============================================================================
# nonparametric_curve_plot — return type and composability
# ============================================================================

test_that("nonparametric_curve_plot returns a ggplot (single curve)", {
  dat <- sample_nonparametric_curve_data(n = 100, seed = 1)
  expect_s3_class(nonparametric_curve_plot(dat), "ggplot")
})

test_that("nonparametric_curve_plot is composable with + operator", {
  dat <- sample_nonparametric_curve_data(n = 100, seed = 1)
  p   <- nonparametric_curve_plot(dat) + ggplot2::labs(x = "Months")
  expect_s3_class(p, "ggplot")
  expect_equal(p$labels$x, "Months")
})

test_that("nonparametric_curve_plot is composable with hvti_theme()", {
  dat <- sample_nonparametric_curve_data(n = 100, seed = 1)
  p   <- nonparametric_curve_plot(dat) + hvti_theme("manuscript")
  expect_s3_class(p, "ggplot")
})

# ============================================================================
# nonparametric_curve_plot — layer structure
# ============================================================================

test_that("nonparametric_curve_plot has a GeomLine layer", {
  dat   <- sample_nonparametric_curve_data(n = 100, seed = 1)
  geoms <- sapply(nonparametric_curve_plot(dat)$layers, function(l) class(l$geom)[1])
  expect_true("GeomLine" %in% geoms)
})

test_that("nonparametric_curve_plot with CI adds a GeomRibbon layer", {
  dat   <- sample_nonparametric_curve_data(n = 100, seed = 1)
  geoms <- sapply(
    nonparametric_curve_plot(dat, lower_col = "lower", upper_col = "upper")$layers,
    function(l) class(l$geom)[1]
  )
  expect_true("GeomRibbon" %in% geoms)
})

test_that("nonparametric_curve_plot with CI has more layers than without CI", {
  dat    <- sample_nonparametric_curve_data(n = 100, seed = 1)
  p_no   <- nonparametric_curve_plot(dat)
  p_ci   <- nonparametric_curve_plot(dat, lower_col = "lower", upper_col = "upper")
  expect_gt(length(p_ci$layers), length(p_no$layers))
})

test_that("nonparametric_curve_plot with data_points adds a GeomPoint layer", {
  dat <- sample_nonparametric_curve_data(n = 200, seed = 1)
  pts <- sample_nonparametric_curve_points(n = 200, seed = 1)
  geoms_with <- sapply(
    nonparametric_curve_plot(dat, data_points = pts)$layers,
    function(l) class(l$geom)[1]
  )
  expect_true("GeomPoint" %in% geoms_with)
})

test_that("nonparametric_curve_plot multi-group returns a ggplot", {
  dat <- sample_nonparametric_curve_data(
    n = 100, groups = c("Ozaki" = 0.7, "CE-P" = 1.3), seed = 1
  )
  expect_s3_class(
    nonparametric_curve_plot(dat, group_col = "group"),
    "ggplot"
  )
})

# ============================================================================
# nonparametric_curve_plot — input validation
# ============================================================================

test_that("nonparametric_curve_plot errors when curve_data is not a data frame", {
  expect_error(
    nonparametric_curve_plot(list(time = 1:5, estimate = 1:5)),
    "data.frame|data frame"
  )
})

test_that("nonparametric_curve_plot errors when x_col is absent", {
  dat <- sample_nonparametric_curve_data(n = 50, seed = 1)
  expect_error(
    nonparametric_curve_plot(dat, x_col = "nonexistent"),
    "column"
  )
})

test_that("nonparametric_curve_plot errors when estimate_col is absent", {
  dat <- sample_nonparametric_curve_data(n = 50, seed = 1)
  expect_error(
    nonparametric_curve_plot(dat, estimate_col = "nonexistent"),
    "column"
  )
})

test_that("nonparametric_curve_plot errors when group_col is absent", {
  dat <- sample_nonparametric_curve_data(n = 50, seed = 1)
  expect_error(
    nonparametric_curve_plot(dat, group_col = "nonexistent"),
    "not found"
  )
})

# ============================================================================
# sample_nonparametric_ordinal_data
# ============================================================================

test_that("sample_nonparametric_ordinal_data returns a data frame", {
  df <- sample_nonparametric_ordinal_data(n = 200, seed = 1)
  expect_true(is.data.frame(df))
})

test_that("sample_nonparametric_ordinal_data has required columns", {
  df <- sample_nonparametric_ordinal_data(n = 200, seed = 1)
  expect_true(all(c("time", "estimate", "grade") %in% names(df)))
})

test_that("sample_nonparametric_ordinal_data grade is a factor", {
  df <- sample_nonparametric_ordinal_data(n = 200, seed = 1)
  expect_true(is.factor(df$grade))
})

test_that("sample_nonparametric_ordinal_data default has 4 grade levels", {
  df <- sample_nonparametric_ordinal_data(n = 200, seed = 1)
  expect_equal(nlevels(df$grade), 4L)
})

test_that("sample_nonparametric_ordinal_data grade_labels sets level names", {
  lbls <- c("None", "Mild", "Moderate", "Severe")
  df   <- sample_nonparametric_ordinal_data(
    n = 200, grade_labels = lbls, seed = 1
  )
  expect_equal(levels(df$grade), lbls)
})

test_that("sample_nonparametric_ordinal_data grade probabilities sum to 1 at each time", {
  df <- sample_nonparametric_ordinal_data(n = 500, n_points = 20, seed = 42)
  sums <- tapply(df$estimate, df$time, sum)
  expect_true(all(abs(sums - 1) < 1e-9))
})

test_that("sample_nonparametric_ordinal_data estimate is in [0, 1]", {
  df <- sample_nonparametric_ordinal_data(n = 200, seed = 1)
  expect_true(all(df$estimate >= 0 - 1e-9))
  expect_true(all(df$estimate <= 1 + 1e-9))
})

test_that("sample_nonparametric_ordinal_data is reproducible with same seed", {
  df1 <- sample_nonparametric_ordinal_data(n = 100, seed = 3)
  df2 <- sample_nonparametric_ordinal_data(n = 100, seed = 3)
  expect_identical(df1, df2)
})

test_that("sample_nonparametric_ordinal_data n_points controls row count", {
  # The smooth curve is deterministic — seed does not introduce randomness in
  # the returned data frame. Verify that n_points drives output size instead.
  df_s <- sample_nonparametric_ordinal_data(n = 100, n_points = 50,  seed = 1)
  df_l <- sample_nonparametric_ordinal_data(n = 100, n_points = 200, seed = 1)
  expect_false(identical(df_s, df_l))
})

# ============================================================================
# sample_nonparametric_ordinal_points
# ============================================================================

test_that("sample_nonparametric_ordinal_points returns a data frame", {
  df <- sample_nonparametric_ordinal_points(n = 200, seed = 1)
  expect_true(is.data.frame(df))
})

test_that("sample_nonparametric_ordinal_points has required columns", {
  df <- sample_nonparametric_ordinal_points(n = 200, seed = 1)
  expect_true(all(c("time", "value", "grade") %in% names(df)))
})

test_that("sample_nonparametric_ordinal_points returns n_bins * n_grades rows", {
  n_grades <- 4L
  n_bins   <- 8L
  df <- sample_nonparametric_ordinal_points(
    n = 200, n_bins = n_bins, seed = 1
  )
  expect_equal(nrow(df), n_bins * n_grades)
})

test_that("sample_nonparametric_ordinal_points grade_labels sets factor levels", {
  lbls <- c("0", "1", "2", "3+")
  df   <- sample_nonparametric_ordinal_points(
    n = 200, grade_labels = lbls, seed = 1
  )
  expect_equal(levels(df$grade), lbls)
})

test_that("sample_nonparametric_ordinal_points is reproducible with same seed", {
  df1 <- sample_nonparametric_ordinal_points(n = 100, seed = 7)
  df2 <- sample_nonparametric_ordinal_points(n = 100, seed = 7)
  expect_identical(df1, df2)
})

# ============================================================================
# nonparametric_ordinal_plot — return type
# ============================================================================

test_that("nonparametric_ordinal_plot returns a ggplot", {
  dat <- sample_nonparametric_ordinal_data(n = 200, seed = 1)
  expect_s3_class(nonparametric_ordinal_plot(dat), "ggplot")
})

test_that("nonparametric_ordinal_plot is composable with + operator", {
  dat <- sample_nonparametric_ordinal_data(n = 200, seed = 1)
  p   <- nonparametric_ordinal_plot(dat) + ggplot2::labs(x = "Years")
  expect_s3_class(p, "ggplot")
  expect_equal(p$labels$x, "Years")
})

test_that("nonparametric_ordinal_plot is composable with hvti_theme()", {
  dat <- sample_nonparametric_ordinal_data(n = 200, seed = 1)
  p   <- nonparametric_ordinal_plot(dat) + hvti_theme("manuscript")
  expect_s3_class(p, "ggplot")
})

# ============================================================================
# nonparametric_ordinal_plot — layer structure
# ============================================================================

test_that("nonparametric_ordinal_plot has a GeomLine layer", {
  # nonparametric_ordinal_plot renders one line per grade using geom_line.
  dat   <- sample_nonparametric_ordinal_data(n = 200, seed = 1)
  geoms <- sapply(
    nonparametric_ordinal_plot(dat)$layers,
    function(l) class(l$geom)[1]
  )
  expect_true("GeomLine" %in% geoms)
})

test_that("nonparametric_ordinal_plot with data_points adds a GeomPoint layer", {
  dat <- sample_nonparametric_ordinal_data(n = 500, seed = 1)
  pts <- sample_nonparametric_ordinal_points(n = 500, seed = 1)
  geoms <- sapply(
    nonparametric_ordinal_plot(dat, data_points = pts)$layers,
    function(l) class(l$geom)[1]
  )
  expect_true("GeomPoint" %in% geoms)
})

# ============================================================================
# nonparametric_ordinal_plot — input validation
# ============================================================================

test_that("nonparametric_ordinal_plot errors when curve_data is not a data frame", {
  expect_error(
    nonparametric_ordinal_plot(list(time = 1:5, estimate = 1:5, grade = 1:5)),
    "data.frame|data frame"
  )
})

test_that("nonparametric_ordinal_plot errors when x_col is absent", {
  dat <- sample_nonparametric_ordinal_data(n = 100, seed = 1)
  expect_error(
    nonparametric_ordinal_plot(dat, x_col = "nonexistent"),
    "column"
  )
})

test_that("nonparametric_ordinal_plot errors when estimate_col is absent", {
  dat <- sample_nonparametric_ordinal_data(n = 100, seed = 1)
  expect_error(
    nonparametric_ordinal_plot(dat, estimate_col = "nonexistent"),
    "column"
  )
})

test_that("nonparametric_ordinal_plot errors when grade_col is absent", {
  dat <- sample_nonparametric_ordinal_data(n = 100, seed = 1)
  expect_error(
    nonparametric_ordinal_plot(dat, grade_col = "nonexistent"),
    "column"
  )
})
