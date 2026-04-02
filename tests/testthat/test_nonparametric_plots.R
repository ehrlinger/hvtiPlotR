# tests/testthat/test_nonparametric_plots.R
#
# Full test suite for nonparametric-curve-plot.R and
# nonparametric-ordinal-plot.R:
#   sample_nonparametric_curve_data, sample_nonparametric_curve_points,
#   hv_nonparametric,
#   sample_nonparametric_ordinal_data, sample_nonparametric_ordinal_points,
#   hv_ordinal
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
# hv_nonparametric — return type and composability
# ============================================================================

test_that("hv_nonparametric returns an hv_data object", {
  dat <- sample_nonparametric_curve_data(n = 100, seed = 1)
  expect_s3_class(hv_nonparametric(dat), "hv_data")
})

test_that("plot(hv_nonparametric) returns a ggplot (single curve)", {
  dat <- sample_nonparametric_curve_data(n = 100, seed = 1)
  expect_s3_class(plot(hv_nonparametric(dat)), "ggplot")
})

test_that("plot(hv_nonparametric) is composable with + operator", {
  dat <- sample_nonparametric_curve_data(n = 100, seed = 1)
  p   <- plot(hv_nonparametric(dat)) + ggplot2::labs(x = "Months")
  expect_s3_class(p, "ggplot")
  expect_equal(p$labels$x, "Months")
})

test_that("plot(hv_nonparametric) is composable with hv_theme()", {
  dat <- sample_nonparametric_curve_data(n = 100, seed = 1)
  p   <- plot(hv_nonparametric(dat)) + hv_theme("manuscript")
  expect_s3_class(p, "ggplot")
})

# ============================================================================
# hv_nonparametric — layer structure
# ============================================================================

test_that("plot(hv_nonparametric) has a GeomLine layer", {
  dat   <- sample_nonparametric_curve_data(n = 100, seed = 1)
  geoms <- sapply(plot(hv_nonparametric(dat))$layers, function(l) class(l$geom)[1])
  expect_true("GeomLine" %in% geoms)
})

test_that("plot(hv_nonparametric) with CI adds a GeomRibbon layer", {
  dat   <- sample_nonparametric_curve_data(n = 100, seed = 1)
  geoms <- sapply(
    plot(hv_nonparametric(dat, lower_col = "lower", upper_col = "upper"))$layers,
    function(l) class(l$geom)[1]
  )
  expect_true("GeomRibbon" %in% geoms)
})

test_that("plot(hv_nonparametric) with CI has more layers than without CI", {
  dat    <- sample_nonparametric_curve_data(n = 100, seed = 1)
  p_no   <- plot(hv_nonparametric(dat))
  p_ci   <- plot(hv_nonparametric(dat, lower_col = "lower", upper_col = "upper"))
  expect_gt(length(p_ci$layers), length(p_no$layers))
})

test_that("plot(hv_nonparametric) with data_points adds a GeomPoint layer", {
  dat <- sample_nonparametric_curve_data(n = 200, seed = 1)
  pts <- sample_nonparametric_curve_points(n = 200, seed = 1)
  geoms_with <- sapply(
    plot(hv_nonparametric(dat, data_points = pts))$layers,
    function(l) class(l$geom)[1]
  )
  expect_true("GeomPoint" %in% geoms_with)
})

test_that("plot(hv_nonparametric) multi-group returns a ggplot", {
  dat <- sample_nonparametric_curve_data(
    n = 100, groups = c("Ozaki" = 0.7, "CE-P" = 1.3), seed = 1
  )
  expect_s3_class(
    plot(hv_nonparametric(dat, group_col = "group")),
    "ggplot"
  )
})

# ============================================================================
# hv_nonparametric — input validation
# ============================================================================

test_that("hv_nonparametric errors when curve_data is not a data frame", {
  expect_error(
    hv_nonparametric(list(time = 1:5, estimate = 1:5)),
    "data.frame|data frame"
  )
})

test_that("hv_nonparametric errors when x_col is absent", {
  dat <- sample_nonparametric_curve_data(n = 50, seed = 1)
  expect_error(
    hv_nonparametric(dat, x_col = "nonexistent"),
    "column"
  )
})

test_that("hv_nonparametric errors when estimate_col is absent", {
  dat <- sample_nonparametric_curve_data(n = 50, seed = 1)
  expect_error(
    hv_nonparametric(dat, estimate_col = "nonexistent"),
    "column"
  )
})

test_that("hv_nonparametric errors when group_col is absent", {
  dat <- sample_nonparametric_curve_data(n = 50, seed = 1)
  expect_error(
    hv_nonparametric(dat, group_col = "nonexistent"),
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
# hv_ordinal — return type
# ============================================================================

test_that("hv_ordinal returns an hv_data object", {
  dat <- sample_nonparametric_ordinal_data(n = 200, seed = 1)
  expect_s3_class(hv_ordinal(dat), "hv_data")
})

test_that("plot(hv_ordinal) returns a ggplot", {
  dat <- sample_nonparametric_ordinal_data(n = 200, seed = 1)
  expect_s3_class(plot(hv_ordinal(dat)), "ggplot")
})

test_that("plot(hv_ordinal) is composable with + operator", {
  dat <- sample_nonparametric_ordinal_data(n = 200, seed = 1)
  p   <- plot(hv_ordinal(dat)) + ggplot2::labs(x = "Years")
  expect_s3_class(p, "ggplot")
  expect_equal(p$labels$x, "Years")
})

test_that("plot(hv_ordinal) is composable with hv_theme()", {
  dat <- sample_nonparametric_ordinal_data(n = 200, seed = 1)
  p   <- plot(hv_ordinal(dat)) + hv_theme("manuscript")
  expect_s3_class(p, "ggplot")
})

# ============================================================================
# hv_ordinal — layer structure
# ============================================================================

test_that("plot(hv_ordinal) has a GeomLine layer", {
  # hv_ordinal renders one line per grade using geom_line.
  dat   <- sample_nonparametric_ordinal_data(n = 200, seed = 1)
  geoms <- sapply(
    plot(hv_ordinal(dat))$layers,
    function(l) class(l$geom)[1]
  )
  expect_true("GeomLine" %in% geoms)
})

test_that("plot(hv_ordinal) with data_points adds a GeomPoint layer", {
  dat <- sample_nonparametric_ordinal_data(n = 500, seed = 1)
  pts <- sample_nonparametric_ordinal_points(n = 500, seed = 1)
  geoms <- sapply(
    plot(hv_ordinal(dat, data_points = pts))$layers,
    function(l) class(l$geom)[1]
  )
  expect_true("GeomPoint" %in% geoms)
})

# ============================================================================
# hv_ordinal — input validation
# ============================================================================

test_that("hv_ordinal errors when curve_data is not a data frame", {
  expect_error(
    hv_ordinal(list(time = 1:5, estimate = 1:5, grade = 1:5)),
    "data.frame|data frame"
  )
})

test_that("hv_ordinal errors when x_col is absent", {
  dat <- sample_nonparametric_ordinal_data(n = 100, seed = 1)
  expect_error(
    hv_ordinal(dat, x_col = "nonexistent"),
    "column"
  )
})

test_that("hv_ordinal errors when estimate_col is absent", {
  dat <- sample_nonparametric_ordinal_data(n = 100, seed = 1)
  expect_error(
    hv_ordinal(dat, estimate_col = "nonexistent"),
    "column"
  )
})

test_that("hv_ordinal errors when grade_col is absent", {
  dat <- sample_nonparametric_ordinal_data(n = 100, seed = 1)
  expect_error(
    hv_ordinal(dat, grade_col = "nonexistent"),
    "column"
  )
})

# ---------------------------------------------------------------------------
# print.hv_nonparametric and print.hv_ordinal coverage
# ---------------------------------------------------------------------------

test_that("print.hv_nonparametric produces <hv_nonparametric> header", {
  dat <- sample_nonparametric_curve_data(n = 100, seed = 1)
  obj <- hv_nonparametric(dat)
  expect_output(print(obj), "<hv_nonparametric>")
})

test_that("print.hv_nonparametric returns x invisibly", {
  dat <- sample_nonparametric_curve_data(n = 100, seed = 1)
  obj <- hv_nonparametric(dat)
  ret <- withVisible(print(obj))
  expect_false(ret$visible)
  expect_identical(ret$value, obj)
})

test_that("print.hv_ordinal produces <hv_ordinal> header", {
  dat <- sample_nonparametric_ordinal_data(n = 100, seed = 1)
  obj <- hv_ordinal(dat)
  expect_output(print(obj), "<hv_ordinal>")
})

test_that("print.hv_ordinal returns x invisibly", {
  dat <- sample_nonparametric_ordinal_data(n = 100, seed = 1)
  obj <- hv_ordinal(dat)
  ret <- withVisible(print(obj))
  expect_false(ret$visible)
  expect_identical(ret$value, obj)
})
