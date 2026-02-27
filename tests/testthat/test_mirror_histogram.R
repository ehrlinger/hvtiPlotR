# Test suite for mirror-histogram.R
#
library(testthat)

# Test sample data generation
test_that("sample_mirror_histogram_data generates correct structure", {
  df <- sample_mirror_histogram_data(50)
  expect_true(is.data.frame(df))
  expect_equal(nrow(df), 100)
  expect_true(all(c("prob_t", "tavr", "match") %in% names(df)))
  expect_true(is.numeric(df$prob_t))
  expect_true(is.numeric(df$tavr))
  expect_true(is.numeric(df$match))
})

test_that("sample_mirror_histogram_data validates positive n", {
  expect_error(sample_mirror_histogram_data(0), "positive integer")
})

# Test calc_smd function
test_that("calc_smd computes SMD correctly", {
  df <- sample_mirror_histogram_data(50)
  smd <- calc_smd(df$prob_t, df$tavr, c(0, 1))
  expect_true(is.numeric(smd))
  expect_false(is.na(smd))
})

# Test build_hist_counts function
test_that("build_hist_counts returns correct output", {
  x <- rnorm(100)
  breaks <- seq(-5, 5, by = 1)
  hist_df <- build_hist_counts(x, breaks)
  expect_true(is.data.frame(hist_df))
  expect_true(all(c("x", "count") %in% names(hist_df)))
})

# Test mirror_histogram function
test_that("mirror_histogram returns expected list structure", {
  df <- sample_mirror_histogram_data(50)
  result <- mirror_histogram(
    data = df,
    score_col = "prob_t",
    group_col = "tavr",
    match_col = "match",
    group_levels = c(0, 1),
    group_labels = c("SAVR", "TF-TAVR"),
    matched_value = 1,
    score_multiplier = 100,
    binwidth = 5
  )
  expect_true(is.list(result))
  expect_true("plot" %in% names(result))
  expect_true("diagnostics" %in% names(result))
  expect_true("data" %in% names(result))
})

test_that("mirror_histogram errors when required columns are missing", {
  df <- sample_mirror_histogram_data(25)
  df$match <- NULL
  expect_error(
    mirror_histogram(data = df),
    "Missing required columns"
  )
})

test_that("mirror_histogram errors for non-positive binwidth", {
  df <- sample_mirror_histogram_data(25)
  expect_error(
    mirror_histogram(data = df, binwidth = 0),
    "binwidth"
  )
})

test_that("mirror_histogram errors when output directory is missing", {
  df <- sample_mirror_histogram_data(10)
  bad_dir <- file.path(tempdir(), "nonexistent_dir")
  bad_file <- file.path(bad_dir, "mirror.pdf")
  expect_error(
    mirror_histogram(data = df, output_file = bad_file),
    "does not exist"
  )
})

test_that("hvti_plot dispatches mirror histogram plot", {
  df <- sample_mirror_histogram_data(40)
  result <- hvti_plot("mirror_histogram", data = df)
  expect_true(is.list(result))
  expect_true("plot" %in% names(result))
})

test_that("hvti_plot errors on unsupported types", {
  expect_error(hvti_plot("unknown"))
})
