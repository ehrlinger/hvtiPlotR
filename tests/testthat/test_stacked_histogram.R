# Test suite for stacked-histogram.R
#
library(testthat)

# ---------------------------------------------------------------------------
# sample_stacked_histogram_data
# ---------------------------------------------------------------------------

test_that("sample_stacked_histogram_data returns correct structure", {
  df <- sample_stacked_histogram_data()
  expect_true(is.data.frame(df))
  expect_true(all(c("year", "category") %in% names(df)))
})

test_that("sample_stacked_histogram_data years span the requested range", {
  df <- sample_stacked_histogram_data(n_years = 10, start_year = 2005)
  expect_true(all(df$year >= 2005))
  expect_true(all(df$year <= 2014))
  expect_equal(length(unique(df$year)), 10)
})

test_that("sample_stacked_histogram_data categories in 1:n_categories", {
  df <- sample_stacked_histogram_data(n_categories = 4)
  expect_true(all(df$category %in% 1:4))
})

test_that("sample_stacked_histogram_data is reproducible with same seed", {
  df1 <- sample_stacked_histogram_data(seed = 7)
  df2 <- sample_stacked_histogram_data(seed = 7)
  expect_identical(df1, df2)
})

test_that("sample_stacked_histogram_data differs with different seeds", {
  df1 <- sample_stacked_histogram_data(seed = 1)
  df2 <- sample_stacked_histogram_data(seed = 2)
  expect_false(identical(df1, df2))
})

test_that("sample_stacked_histogram_data errors on non-positive n_years", {
  expect_error(sample_stacked_histogram_data(n_years = 0), "positive integer")
})

test_that("sample_stacked_histogram_data errors on non-positive n_categories", {
  expect_error(
    sample_stacked_histogram_data(n_categories = 0),
    "positive integer"
  )
})

# ---------------------------------------------------------------------------
# hv_stacked — return type
# ---------------------------------------------------------------------------

test_that("hv_stacked returns an hv_data object", {
  df <- sample_stacked_histogram_data()
  sh <- hv_stacked(df)
  expect_s3_class(sh, "hv_data")
})

test_that("plot(hv_stacked) returns a ggplot object", {
  df <- sample_stacked_histogram_data()
  expect_s3_class(plot(hv_stacked(df)), "ggplot")
})

test_that("plot(hv_stacked, position='fill') returns a ggplot object", {
  df <- sample_stacked_histogram_data()
  expect_s3_class(plot(hv_stacked(df, position = "fill")), "ggplot")
})

# ---------------------------------------------------------------------------
# hv_stacked — input validation (errors in constructor)
# ---------------------------------------------------------------------------

test_that("hv_stacked errors when data is not a data frame", {
  expect_error(
    hv_stacked(list(year = 1:5, category = 1:5)),
    "data.frame"
  )
})

test_that("hv_stacked errors when x_col is missing", {
  df      <- sample_stacked_histogram_data()
  df$year <- NULL
  expect_error(
    hv_stacked(df, x_col = "year"),
    "Missing required column"
  )
})

test_that("hv_stacked errors when group_col is missing", {
  df          <- sample_stacked_histogram_data()
  df$category <- NULL
  expect_error(
    hv_stacked(df, group_col = "category"),
    "Missing required column"
  )
})

test_that("hv_stacked errors when x_col is not numeric", {
  df      <- sample_stacked_histogram_data()
  df$year <- as.character(df$year)
  expect_error(hv_stacked(df, x_col = "year"), "numeric")
})

test_that("hv_stacked errors on non-positive binwidth", {
  df <- sample_stacked_histogram_data()
  expect_error(hv_stacked(df, binwidth = 0),  "binwidth")
  expect_error(hv_stacked(df, binwidth = -1), "binwidth")
})

test_that("hv_stacked errors on invalid position", {
  df <- sample_stacked_histogram_data()
  expect_error(hv_stacked(df, position = "dodge"), "should be one of")
})

# ---------------------------------------------------------------------------
# plot(hv_stacked) — plot internals
# ---------------------------------------------------------------------------

test_that("plot(hv_stacked) maps x_col to the x aesthetic", {
  df <- sample_stacked_histogram_data()
  p  <- plot(hv_stacked(df, x_col = "year", group_col = "category"))
  expect_match(rlang::as_label(p$mapping$x), "year")
})

test_that("plot(hv_stacked) maps group_col to fill and colour aesthetics", {
  df <- sample_stacked_histogram_data()
  p  <- plot(hv_stacked(df, x_col = "year", group_col = "category"))
  expect_match(rlang::as_label(p$mapping$fill),   "category")
  expect_match(rlang::as_label(p$mapping$colour), "category")
})

test_that("plot(hv_stacked) uses a GeomBar layer", {
  df            <- sample_stacked_histogram_data()
  p             <- plot(hv_stacked(df))
  layer_classes <- vapply(p$layers, function(l) class(l$geom)[1], character(1))
  expect_true("GeomBar" %in% layer_classes)
})

test_that("hv_stacked respects custom binwidth", {
  df  <- sample_stacked_histogram_data()
  p2  <- plot(hv_stacked(df, binwidth = 2))
  p5  <- plot(hv_stacked(df, binwidth = 5))
  bw2 <- p2$layers[[1]]$stat_params$binwidth
  bw5 <- p5$layers[[1]]$stat_params$binwidth
  expect_equal(bw2, 2)
  expect_equal(bw5, 5)
})

test_that("hv_stacked position='fill' uses PositionFill", {
  df        <- sample_stacked_histogram_data()
  p         <- plot(hv_stacked(df, position = "fill"))
  pos_class <- class(p$layers[[1]]$position)[1]
  expect_equal(pos_class, "PositionFill")
})

test_that("hv_stacked position='stack' uses PositionStack", {
  df        <- sample_stacked_histogram_data()
  p         <- plot(hv_stacked(df, position = "stack"))
  pos_class <- class(p$layers[[1]]$position)[1]
  expect_equal(pos_class, "PositionStack")
})

# ---------------------------------------------------------------------------
# hv_stacked — custom column names
# ---------------------------------------------------------------------------

test_that("hv_stacked works with non-default column names", {
  df <- data.frame(
    surg_yr  = 1987:2020,
    group_id = sample(1:3, 34, replace = TRUE)
  )
  p <- plot(hv_stacked(df, x_col = "surg_yr", group_col = "group_id"))
  expect_s3_class(p, "ggplot")
  expect_match(rlang::as_label(p$mapping$x), "surg_yr")
})


# ---------------------------------------------------------------------------
# print.hv_stacked coverage
# ---------------------------------------------------------------------------

test_that("print.hv_stacked produces <hv_stacked> header", {
  df  <- sample_stacked_histogram_data(n = 200, seed = 1)
  obj <- hv_stacked(df, x_col = "surg_yr", group_col = "group_id")
  expect_output(print(obj), "<hv_stacked>")
})

test_that("print.hv_stacked returns x invisibly", {
  df  <- sample_stacked_histogram_data(n = 200, seed = 1)
  obj <- hv_stacked(df, x_col = "surg_yr", group_col = "group_id")
  ret <- withVisible(print(obj))
  expect_false(ret$visible)
  expect_identical(ret$value, obj)
})
