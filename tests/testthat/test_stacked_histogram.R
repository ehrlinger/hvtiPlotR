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
# stacked_histogram — return type
# ---------------------------------------------------------------------------

test_that("stacked_histogram returns a ggplot object", {
  df <- sample_stacked_histogram_data()
  p <- stacked_histogram(df)
  expect_s3_class(p, "ggplot")
})

test_that("stacked_histogram with position fill returns a ggplot object", {
  df <- sample_stacked_histogram_data()
  p <- stacked_histogram(df, position = "fill")
  expect_s3_class(p, "ggplot")
})

# ---------------------------------------------------------------------------
# stacked_histogram — input validation
# ---------------------------------------------------------------------------

test_that("stacked_histogram errors when data is not a data frame", {
  expect_error(
    stacked_histogram(list(year = 1:5, category = 1:5)),
    "data.frame"
  )
})

test_that("stacked_histogram errors when x_col is missing", {
  df <- sample_stacked_histogram_data()
  df$year <- NULL
  expect_error(
    stacked_histogram(df, x_col = "year"),
    "Missing required columns"
  )
})

test_that("stacked_histogram errors when group_col is missing", {
  df <- sample_stacked_histogram_data()
  df$category <- NULL
  expect_error(
    stacked_histogram(df, group_col = "category"),
    "Missing required columns"
  )
})

test_that("stacked_histogram errors when x_col is not numeric", {
  df <- sample_stacked_histogram_data()
  df$year <- as.character(df$year)
  expect_error(stacked_histogram(df, x_col = "year"), "numeric")
})

test_that("stacked_histogram errors on non-positive binwidth", {
  df <- sample_stacked_histogram_data()
  expect_error(stacked_histogram(df, binwidth = 0), "binwidth")
  expect_error(stacked_histogram(df, binwidth = -1), "binwidth")
})

test_that("stacked_histogram errors on invalid position", {
  df <- sample_stacked_histogram_data()
  expect_error(stacked_histogram(df, position = "dodge"), "should be one of")
})

# ---------------------------------------------------------------------------
# stacked_histogram — plot internals
# ---------------------------------------------------------------------------

test_that("stacked_histogram maps x_col to the x aesthetic", {
  df <- sample_stacked_histogram_data()
  p <- stacked_histogram(df, x_col = "year", group_col = "category")
  expect_match(rlang::as_label(p$mapping$x), "year")
})

test_that("stacked_histogram maps group_col to fill and colour aesthetics", {
  df <- sample_stacked_histogram_data()
  p <- stacked_histogram(df, x_col = "year", group_col = "category")
  # Both fill and colour should reference the group column via factor(category)
  expect_match(rlang::as_label(p$mapping$fill),   "category")
  expect_match(rlang::as_label(p$mapping$colour), "category")
})

test_that("stacked_histogram uses geom_histogram layer", {
  df <- sample_stacked_histogram_data()
  p <- stacked_histogram(df)
  layer_classes <- vapply(p$layers, function(l) class(l$geom)[1], character(1))
  expect_true("GeomBar" %in% layer_classes)
})

test_that("stacked_histogram respects custom binwidth", {
  df <- sample_stacked_histogram_data()
  p2 <- stacked_histogram(df, binwidth = 2)
  p5 <- stacked_histogram(df, binwidth = 5)
  bw2 <- p2$layers[[1]]$stat_params$binwidth
  bw5 <- p5$layers[[1]]$stat_params$binwidth
  expect_equal(bw2, 2)
  expect_equal(bw5, 5)
})

test_that("stacked_histogram position fill uses StatBin with fill position", {
  df <- sample_stacked_histogram_data()
  p <- stacked_histogram(df, position = "fill")
  pos_class <- class(p$layers[[1]]$position)[1]
  expect_equal(pos_class, "PositionFill")
})

test_that("stacked_histogram position stack uses stack position", {
  df <- sample_stacked_histogram_data()
  p <- stacked_histogram(df, position = "stack")
  pos_class <- class(p$layers[[1]]$position)[1]
  expect_equal(pos_class, "PositionStack")
})

# ---------------------------------------------------------------------------
# stacked_histogram — custom column names
# ---------------------------------------------------------------------------

test_that("stacked_histogram works with non-default column names", {
  df <- data.frame(
    surg_yr  = 1987:2020,
    group_id = sample(1:3, 34, replace = TRUE)
  )
  p <- stacked_histogram(df, x_col = "surg_yr", group_col = "group_id")
  expect_s3_class(p, "ggplot")
  expect_match(rlang::as_label(p$mapping$x), "surg_yr")
})

