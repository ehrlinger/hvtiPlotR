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
test_that("mirror_histogram returns a ggplot with expected attributes", {
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
  expect_s3_class(result, "ggplot")
  expect_false(is.null(attr(result, "diagnostics")))
  expect_false(is.null(attr(result, "data")))
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

test_that("mirror_histogram returns a bare ggplot", {
  df     <- sample_mirror_histogram_data(40)
  result <- mirror_histogram(data = df)
  expect_s3_class(result, "ggplot")
})

# ---------------------------------------------------------------------------
# sample_mirror_histogram_data — add_weights
# ---------------------------------------------------------------------------

test_that("sample_mirror_histogram_data add_weights appends mt_wt", {
  df <- sample_mirror_histogram_data(50, add_weights = TRUE)
  expect_true("mt_wt" %in% names(df))
  expect_true(is.numeric(df$mt_wt))
  expect_true(all(df$mt_wt > 0))
})

test_that("sample_mirror_histogram_data add_weights FALSE omits mt_wt", {
  df <- sample_mirror_histogram_data(50, add_weights = FALSE)
  expect_false("mt_wt" %in% names(df))
})

test_that("sample_mirror_histogram_data errors on non-flag add_weights", {
  expect_error(sample_mirror_histogram_data(10, add_weights = "yes"))
})

# ---------------------------------------------------------------------------
# build_weighted_hist_counts
# ---------------------------------------------------------------------------

test_that("build_weighted_hist_counts returns correct structure", {
  breaks <- seq(0, 100, 10)
  result <- build_weighted_hist_counts(c(15, 25, 55), c(2, 3, 1), breaks)
  expect_true(is.data.frame(result))
  expect_true(all(c("x", "count") %in% names(result)))
  expect_equal(nrow(result), length(breaks) - 1)
})

test_that("build_weighted_hist_counts sums weights per bin correctly", {
  # Both observations fall in [10, 20)
  breaks <- seq(0, 100, 10)
  result <- build_weighted_hist_counts(c(11, 15), c(4, 6), breaks)
  bin_idx <- which(result$x == 15)   # midpoint of [10, 20)
  expect_equal(result$count[bin_idx], 10)
})

test_that("build_weighted_hist_counts produces zero for empty bins", {
  breaks <- seq(0, 100, 10)
  result <- build_weighted_hist_counts(c(5), c(3), breaks)
  expect_equal(result$count[nrow(result)], 0)
})

# ---------------------------------------------------------------------------
# calc_weighted_smd
# ---------------------------------------------------------------------------

test_that("calc_weighted_smd returns a numeric scalar", {
  set.seed(1)
  score  <- c(rnorm(50, 0.3), rnorm(50, 0.6))
  group  <- c(rep(0, 50), rep(1, 50))
  weights <- rep(1, 100)
  result <- calc_weighted_smd(score, weights, group, c(0, 1))
  expect_true(is.numeric(result))
  expect_length(result, 1)
  expect_false(is.na(result))
})

test_that("calc_weighted_smd with equal distributions is near zero", {
  set.seed(42)
  x <- rnorm(200, mean = 0.5)
  result <- calc_weighted_smd(x, rep(1, 200), c(rep(0, 100), rep(1, 100)),
                              c(0, 1))
  expect_true(abs(result) < 0.5)
})

test_that("calc_weighted_smd returns NA when a group has zero weight", {
  score   <- c(0.2, 0.3, 0.7, 0.8)
  weights <- c(0,   0,   1,   1)
  group   <- c(0,   0,   1,   1)
  result  <- calc_weighted_smd(score, weights, group, c(0, 1))
  expect_true(is.na(result))
})

# ---------------------------------------------------------------------------
# validate — weighted mode
# ---------------------------------------------------------------------------

test_that("validate errors when weight_col is absent from data", {
  df <- sample_mirror_histogram_data(25)
  expect_error(
    validate_mirror_histogram_input(df, "prob_t", "tavr", "match",
                                    c(0, 1), c("A", "B"), 5,
                                    weight_col = "mt_wt"),
    "Missing required columns"
  )
})

test_that("validate errors when weight_col is non-numeric", {
  df <- sample_mirror_histogram_data(25, add_weights = TRUE)
  df$mt_wt <- as.character(df$mt_wt)
  expect_error(
    validate_mirror_histogram_input(df, "prob_t", "tavr", "match",
                                    c(0, 1), c("A", "B"), 5,
                                    weight_col = "mt_wt"),
    "numeric"
  )
})

test_that("validate errors when weight_col contains negative values", {
  df <- sample_mirror_histogram_data(25, add_weights = TRUE)
  df$mt_wt[1] <- -1
  expect_error(
    validate_mirror_histogram_input(df, "prob_t", "tavr", "match",
                                    c(0, 1), c("A", "B"), 5,
                                    weight_col = "mt_wt"),
    "non-negative"
  )
})

test_that("validate skips match_col check when weight_col is provided", {
  df <- sample_mirror_histogram_data(25, add_weights = TRUE)
  df$match <- NULL   # remove match column
  expect_no_error(
    validate_mirror_histogram_input(df, "prob_t", "tavr", "match",
                                    c(0, 1), c("A", "B"), 5,
                                    weight_col = "mt_wt")
  )
})

# ---------------------------------------------------------------------------
# mirror_histogram — weighted mode integration
# ---------------------------------------------------------------------------

test_that("mirror_histogram weighted mode returns a ggplot with attributes", {
  df <- sample_mirror_histogram_data(100, add_weights = TRUE)
  result <- mirror_histogram(df, weight_col = "mt_wt")
  expect_s3_class(result, "ggplot")
  expect_false(is.null(attr(result, "diagnostics")))
  expect_false(is.null(attr(result, "data")))
})

test_that("mirror_histogram weighted mode returns a ggplot object", {
  df <- sample_mirror_histogram_data(100, add_weights = TRUE)
  result <- mirror_histogram(df, weight_col = "mt_wt")
  expect_s3_class(result, "ggplot")
})

test_that("mirror_histogram weighted diagnostics has weighted fields", {
  df <- sample_mirror_histogram_data(100, add_weights = TRUE)
  diag <- attr(mirror_histogram(df, weight_col = "mt_wt"), "diagnostics")
  expect_true("effective_n_by_group" %in% names(diag))
  expect_true("smd_weighted" %in% names(diag))
})

test_that("mirror_histogram weighted diagnostics omits binary-match fields", {
  df <- sample_mirror_histogram_data(100, add_weights = TRUE)
  diag <- attr(mirror_histogram(df, weight_col = "mt_wt"), "diagnostics")
  expect_false("smd_matched" %in% names(diag))
  expect_false("group_counts_matched" %in% names(diag))
})

test_that("mirror_histogram weighted effective_n_by_group sums weights", {
  df <- sample_mirror_histogram_data(50, add_weights = TRUE)
  result <- mirror_histogram(df, weight_col = "mt_wt")
  expected_total <- sum(df$mt_wt)
  observed_total <- sum(attr(result, "diagnostics")$effective_n_by_group)
  expect_equal(observed_total, expected_total, tolerance = 1e-6)
})

test_that("mirror_histogram weighted mode does not require match_col", {
  df <- sample_mirror_histogram_data(50, add_weights = TRUE)
  df$match <- NULL
  expect_no_error(mirror_histogram(df, weight_col = "mt_wt"))
})

test_that("mirror_histogram weighted fill_keys contain weighted layers", {
  df     <- sample_mirror_histogram_data(100, add_weights = TRUE)
  result <- mirror_histogram(df, weight_col = "mt_wt")
  # layers: [[1]] geom_hline, [[2]] Before geom_col, [[3]] overlay geom_col
  keys <- unique(result$layers[[3]]$data$fill_key)
  expect_true(any(grepl("weighted", keys)))
})

test_that("mirror_histogram weighted bars reflect weight sums not counts", {
  # Group 0: 20 rows all with score 0.05 (5% after x100), weight = 10 each
  # Group 1: 20 rows all with score 0.95 (95% after x100), weight = 1 each
  df <- data.frame(
    prob_t = c(rep(0.05, 20), rep(0.95, 20)),
    tavr   = c(rep(0, 20),    rep(1, 20)),
    match  = rep(1, 40),
    mt_wt  = c(rep(10, 20),   rep(1, 20))
  )
  result   <- mirror_histogram(df, weight_col = "mt_wt", binwidth = 5)
  # layers: [[1]] geom_hline, [[2]] Before, [[3]] Weighted
  wt_layer <- result$layers[[3]]$data
  g0_bar   <- wt_layer[wt_layer$fill_key == "weighted_g0", ]
  # weight sum = 20 * 10 = 200; raw count would be 20
  expect_true(any(g0_bar$y > 20))
})

test_that("mirror_histogram binary mode unchanged when weight_col is NULL", {
  df     <- sample_mirror_histogram_data(50)
  result <- mirror_histogram(df, weight_col = NULL)
  diag   <- attr(result, "diagnostics")
  expect_true("smd_matched" %in% names(diag))
  expect_true("group_counts_matched" %in% names(diag))
  expect_false("smd_weighted" %in% names(diag))
})

test_that("mirror_histogram errors when weight_col column is absent", {
  df <- sample_mirror_histogram_data(25)
  expect_error(
    mirror_histogram(df, weight_col = "nonexistent"),
    "Missing required columns"
  )
})

# ============================================================================
# Snapshot — diagnostics list (fixed seed)
# ============================================================================

test_that("mirror_histogram diagnostics match snapshot (fixed seed)", {
  df     <- sample_mirror_histogram_data(200, seed = 42)
  result <- suppressMessages(mirror_histogram(df))
  expect_snapshot(attr(result, "diagnostics"))
})
