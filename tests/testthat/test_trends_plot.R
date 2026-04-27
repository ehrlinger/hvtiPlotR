# Full test suite for trends-plot.R:
#   sample_trends_data, hv_trends, print.hv_trends, plot.hv_trends
#
# The smoke tests in test_new_plots.R verify basic constructor/plot return
# types.  This file adds depth: $meta / $tables slot contents, print output,
# all plot.hv_trends parameters, and edge cases.

library(hvtiPlotR)

# ---------------------------------------------------------------------------
# Shared fixtures
# ---------------------------------------------------------------------------

dta_grp <- sample_trends_data(
  n          = 400,
  year_range = c(1990L, 2010L),
  groups     = c("A", "B", "C"),
  seed       = 1L
)

dta_one <- sample_trends_data(
  n          = 300,
  year_range = c(2000L, 2015L),
  groups     = NULL,
  seed       = 2L
)

# ---------------------------------------------------------------------------
# hv_trends — $meta slot
# ---------------------------------------------------------------------------

test_that("hv_trends $meta contains all expected keys", {
  tr  <- hv_trends(dta_grp)
  expect_named(tr$meta,
    c("x_col", "y_col", "group_col", "summary_fn", "n_obs", "n_groups"),
    ignore.order = TRUE
  )
})

test_that("hv_trends $meta$n_obs equals nrow(data)", {
  tr <- hv_trends(dta_grp)
  expect_equal(tr$meta$n_obs, nrow(dta_grp))
})

test_that("hv_trends $meta$n_groups equals number of unique groups", {
  tr <- hv_trends(dta_grp)
  expect_equal(tr$meta$n_groups, length(unique(dta_grp$group)))
})

test_that("hv_trends $meta$n_groups is 1 when group_col = NULL", {
  tr <- hv_trends(dta_one, group_col = NULL)
  expect_equal(tr$meta$n_groups, 1L)
})

test_that("hv_trends $meta$summary_fn is 'mean' by default", {
  tr <- hv_trends(dta_grp)
  expect_equal(tr$meta$summary_fn, "mean")
})

test_that("hv_trends $meta$summary_fn is 'median' when requested", {
  tr <- hv_trends(dta_grp, summary_fn = "median")
  expect_equal(tr$meta$summary_fn, "median")
})

test_that("hv_trends $meta$group_col is NULL when group_col = NULL", {
  tr <- hv_trends(dta_one, group_col = NULL)
  expect_null(tr$meta$group_col)
})

test_that("hv_trends $meta respects custom x_col / y_col names", {
  df <- dta_grp
  names(df)[names(df) == "year"]  <- "time"
  names(df)[names(df) == "value"] <- "score"
  tr <- hv_trends(df, x_col = "time", y_col = "score")
  expect_equal(tr$meta$x_col, "time")
  expect_equal(tr$meta$y_col, "score")
})

# ---------------------------------------------------------------------------
# hv_trends — $tables slot
# ---------------------------------------------------------------------------

test_that("hv_trends $tables contains 'summary' element", {
  tr <- hv_trends(dta_grp)
  expect_true("summary" %in% names(tr$tables))
})

test_that("hv_trends $tables$summary is a data frame", {
  tr <- hv_trends(dta_grp)
  expect_s3_class(tr$tables$summary, "data.frame")
})

test_that("hv_trends $tables$summary has one row per x-value per group", {
  tr  <- hv_trends(dta_grp)
  n_x <- length(unique(dta_grp$year))
  n_g <- length(unique(dta_grp$group))
  expect_equal(nrow(tr$tables$summary), n_x * n_g)
})

test_that("hv_trends $tables$summary (single group) has one row per x-value", {
  tr  <- hv_trends(dta_one, group_col = NULL)
  n_x <- length(unique(dta_one$year))
  expect_equal(nrow(tr$tables$summary), n_x)
})

test_that("hv_trends mean and median summaries differ", {
  tr_mean   <- hv_trends(dta_grp, summary_fn = "mean")
  tr_median <- hv_trends(dta_grp, summary_fn = "median")
  expect_false(identical(tr_mean$tables$summary, tr_median$tables$summary))
})

# ---------------------------------------------------------------------------
# hv_trends — factor group levels preserved
# ---------------------------------------------------------------------------

test_that("hv_trends preserves factor level order in summary", {
  df          <- dta_grp
  df$group    <- factor(df$group, levels = c("C", "A", "B"))
  tr          <- hv_trends(df)
  sum_levels  <- levels(tr$tables$summary$group)
  expect_equal(sum_levels, c("C", "A", "B"))
})

# ---------------------------------------------------------------------------
# print.hv_trends
# ---------------------------------------------------------------------------

test_that("print.hv_trends produces output starting with <hv_trends>", {
  tr <- hv_trends(dta_grp)
  expect_output(print(tr), "<hv_trends>")
})

test_that("print.hv_trends shows n_obs", {
  tr <- hv_trends(dta_grp)
  expect_output(print(tr), as.character(nrow(dta_grp)))
})

test_that("print.hv_trends shows group_col when set", {
  tr <- hv_trends(dta_grp)
  expect_output(print(tr), "group")
})

test_that("print.hv_trends does not show Group col line when group_col = NULL", {
  tr  <- hv_trends(dta_one, group_col = NULL)
  out <- capture.output(print(tr))
  expect_false(any(grepl("Group col", out)))
})

test_that("print.hv_trends shows summary_fn", {
  tr <- hv_trends(dta_grp, summary_fn = "median")
  expect_output(print(tr), "median")
})

test_that("print.hv_trends returns x invisibly", {
  tr  <- hv_trends(dta_grp)
  ret <- withVisible(print(tr))
  expect_false(ret$visible)
  expect_identical(ret$value, tr)
})

# ---------------------------------------------------------------------------
# plot.hv_trends — parameter coverage
# ---------------------------------------------------------------------------

test_that("plot.hv_trends se=TRUE is accepted without error", {
  tr <- hv_trends(dta_grp)
  expect_s3_class(plot(tr, se = TRUE), "ggplot")
})

test_that("plot.hv_trends span parameter is accepted without error", {
  tr <- hv_trends(dta_grp)
  expect_s3_class(plot(tr, span = 0.5), "ggplot")
})

test_that("plot.hv_trends custom point_size is accepted", {
  tr <- hv_trends(dta_grp)
  expect_s3_class(plot(tr, point_size = 4), "ggplot")
})

test_that("plot.hv_trends custom point_shape is accepted (single group)", {
  tr <- hv_trends(dta_one, group_col = NULL)
  expect_s3_class(plot(tr, point_shape = 15L), "ggplot")
})

test_that("plot.hv_trends alpha parameter is accepted", {
  tr <- hv_trends(dta_grp)
  expect_s3_class(plot(tr, alpha = 0.5), "ggplot")
})

test_that("plot.hv_trends smoother='lm' is accepted", {
  tr <- hv_trends(dta_grp)
  expect_s3_class(plot(tr, smoother = "lm"), "ggplot")
})

test_that("plot.hv_trends grouped and ungrouped plots are distinct", {
  p_grp <- plot(hv_trends(dta_grp))
  p_one <- plot(hv_trends(dta_one, group_col = NULL))
  expect_false(identical(p_grp$mapping, p_one$mapping))
})

test_that("plot.hv_trends is composable with theme_hv_*", {
  tr <- hv_trends(dta_grp)
  expect_s3_class(plot(tr) + theme_hv_manuscript(), "ggplot")
})
