# Test suite for covariate-balance.R

library(testthat)

# ---------------------------------------------------------------------------
# sample_covariate_balance_data
# ---------------------------------------------------------------------------

test_that("sample_covariate_balance_data returns a data frame", {
  dta <- sample_covariate_balance_data()
  expect_true(is.data.frame(dta))
})

test_that("sample_covariate_balance_data has required columns", {
  dta <- sample_covariate_balance_data()
  expect_true(all(c("variable", "group", "std_diff") %in% names(dta)))
})

test_that("sample_covariate_balance_data has 2 * n_vars rows", {
  dta <- sample_covariate_balance_data(n_vars = 8)
  expect_equal(nrow(dta), 16L)
})

test_that("sample_covariate_balance_data uses supplied group_levels", {
  dta <- sample_covariate_balance_data(group_levels = c("Unweighted", "IPTW"))
  expect_setequal(unique(dta$group), c("Unweighted", "IPTW"))
})

test_that("sample_covariate_balance_data is reproducible with same seed", {
  d1 <- sample_covariate_balance_data(seed = 7)
  d2 <- sample_covariate_balance_data(seed = 7)
  expect_identical(d1, d2)
})

test_that("sample_covariate_balance_data differs with different seeds", {
  d1 <- sample_covariate_balance_data(seed = 1)
  d2 <- sample_covariate_balance_data(seed = 2)
  expect_false(identical(d1, d2))
})

test_that("sample_covariate_balance_data errors on non-positive n_vars", {
  expect_error(sample_covariate_balance_data(n_vars = 0),  "positive integer")
  expect_error(sample_covariate_balance_data(n_vars = -1), "positive integer")
})

test_that("sample_covariate_balance_data errors when group_levels != 2", {
  expect_error(
    sample_covariate_balance_data(group_levels = c("A", "B", "C")),
    "length-2"
  )
})

test_that("sample_covariate_balance_data errors on non-positive n", {
  expect_error(sample_covariate_balance_data(n = 0),  "positive integer")
  expect_error(sample_covariate_balance_data(n = -1), "positive integer")
})

test_that("sample_covariate_balance_data errors on non-positive separation", {
  expect_error(sample_covariate_balance_data(separation = 0),  "positive number")
  expect_error(sample_covariate_balance_data(separation = -1), "positive number")
})

test_that("sample_covariate_balance_data errors on out-of-range caliper", {
  expect_error(sample_covariate_balance_data(caliper = 0),   "\\(0, 1\\]")
  expect_error(sample_covariate_balance_data(caliper = 1.1), "\\(0, 1\\]")
})

test_that("sample_covariate_balance_data extends past default names", {
  dta <- sample_covariate_balance_data(n_vars = 15)
  expect_equal(length(unique(dta$variable)), 15L)
})

test_that("sample_covariate_balance_data before-match SMDs are larger than after-match", {
  dta <- sample_covariate_balance_data(seed = 1)
  before <- dta$std_diff[dta$group == "Before match"]
  after  <- dta$std_diff[dta$group == "After match"]
  # Matching should reduce |SMD| on average
  expect_gt(mean(abs(before)), mean(abs(after)))
})

test_that("sample_covariate_balance_data higher separation increases before-match imbalance", {
  d_low  <- sample_covariate_balance_data(separation = 0.5, seed = 1)
  d_high <- sample_covariate_balance_data(separation = 3.0, seed = 1)
  before_low  <- mean(abs(d_low$std_diff[d_low$group  == "Before match"]))
  before_high <- mean(abs(d_high$std_diff[d_high$group == "Before match"]))
  expect_gt(before_high, before_low)
})

# ---------------------------------------------------------------------------
# hv_balance — return type
# ---------------------------------------------------------------------------

test_that("hv_balance returns an hv_data object", {
  dta <- sample_covariate_balance_data()
  cb  <- hv_balance(dta)
  expect_s3_class(cb, "hv_data")
})

test_that("plot(hv_balance) returns a ggplot object", {
  dta <- sample_covariate_balance_data()
  expect_s3_class(plot(hv_balance(dta)), "ggplot")
})

# ---------------------------------------------------------------------------
# hv_balance — input validation (errors in constructor)
# ---------------------------------------------------------------------------

test_that("hv_balance errors when data is not a data frame", {
  expect_error(
    hv_balance(list(variable = "x", group = "y", std_diff = 1)),
    "data.frame"
  )
})

test_that("hv_balance errors on missing variable_col", {
  dta <- sample_covariate_balance_data()
  dta$variable <- NULL
  expect_error(hv_balance(dta), "Missing required column")
})

test_that("hv_balance errors on missing group_col", {
  dta <- sample_covariate_balance_data()
  dta$group <- NULL
  expect_error(hv_balance(dta), "Missing required column")
})

test_that("hv_balance errors on missing std_diff_col", {
  dta <- sample_covariate_balance_data()
  dta$std_diff <- NULL
  expect_error(hv_balance(dta), "Missing required column")
})

test_that("hv_balance errors when std_diff_col is not numeric", {
  dta <- sample_covariate_balance_data()
  dta$std_diff <- as.character(dta$std_diff)
  expect_error(hv_balance(dta), "numeric")
})

test_that("hv_balance accepts non-default column names", {
  dta <- sample_covariate_balance_data()
  names(dta) <- c("cov", "grp", "smd")
  cb <- hv_balance(dta,
                     variable_col  = "cov",
                     group_col     = "grp",
                     std_diff_col  = "smd")
  expect_s3_class(plot(cb), "ggplot")
})

# ---------------------------------------------------------------------------
# plot(hv_balance) — plot structure
# ---------------------------------------------------------------------------

test_that("plot(hv_balance) has a geom_point layer", {
  p            <- plot(hv_balance(sample_covariate_balance_data()))
  geom_classes <- vapply(p$layers, function(l) class(l$geom)[1], character(1))
  expect_true("GeomPoint" %in% geom_classes)
})

test_that("plot(hv_balance) has geom_vline layers", {
  p            <- plot(hv_balance(sample_covariate_balance_data()))
  geom_classes <- vapply(p$layers, function(l) class(l$geom)[1], character(1))
  expect_true("GeomVline" %in% geom_classes)
})

test_that("plot(hv_balance) has geom_hline layers", {
  p            <- plot(hv_balance(sample_covariate_balance_data()))
  geom_classes <- vapply(p$layers, function(l) class(l$geom)[1], character(1))
  expect_true("GeomHline" %in% geom_classes)
})

test_that("plot(hv_balance) y scale has n breaks equal to n_vars", {
  n      <- 8L
  dta    <- sample_covariate_balance_data(n_vars = n)
  p      <- plot(hv_balance(dta))
  built  <- ggplot2::ggplot_build(p)
  breaks <- built$layout$panel_params[[1]]$y$breaks
  expect_equal(length(breaks), n)
})

test_that("hv_balance var_levels is respected in plot y labels", {
  dta          <- sample_covariate_balance_data(n_vars = 4)
  custom_order <- rev(unique(dta$variable))
  cb           <- hv_balance(dta, var_levels = custom_order)
  p            <- plot(cb)
  built        <- ggplot2::ggplot_build(p)
  labels       <- built$layout$panel_params[[1]]$y$get_labels()
  expect_equal(labels, custom_order)
})

test_that("hv_balance threshold vlines appear at correct x values", {
  dta       <- sample_covariate_balance_data()
  p         <- plot(hv_balance(dta, threshold = 15))
  built     <- ggplot2::ggplot_build(p)
  vline_idx <- which(vapply(
    p$layers,
    function(l) inherits(l$geom, "GeomVline"),
    logical(1)
  ))
  intercepts <- unlist(lapply(
    vline_idx, function(i) built$data[[i]]$xintercept
  ))
  expect_true(15 %in% intercepts)
  expect_true(-15 %in% intercepts)
})

# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# print.hv_balance coverage
# ---------------------------------------------------------------------------

test_that("print.hv_balance produces <hv_balance> header", {
  df  <- sample_covariate_balance_data(n = 200, seed = 1)
  bal <- hv_balance(df, group_col = "group")
  expect_output(print(bal), "<hv_balance>")
})

test_that("print.hv_balance returns x invisibly", {
  df  <- sample_covariate_balance_data(n = 200, seed = 1)
  bal <- hv_balance(df, group_col = "group")
  ret <- withVisible(print(bal))
  expect_false(ret$visible)
  expect_identical(ret$value, bal)
})

# ---------------------------------------------------------------------------
# hv_balance_height
# ---------------------------------------------------------------------------

test_that("hv_balance_height gives about 8 in for 38 rows at 12 pt", {
  expect_equal(hv_balance_height(38), 0.17 * 38 + 1.5)
  expect_equal(round(hv_balance_height(38), 2), 7.96)
})

test_that("hv_balance_height scales with base_size", {
  expect_equal(hv_balance_height(38, base_size = 18), 1.5 * hv_balance_height(38))
})

test_that("hv_balance_height adds rows and strip space per pair", {
  expect_equal(hv_balance_height(10, n_pairs = 3), 0.17 * 30 + 0.3 * 2 + 1.5)
})

test_that("hv_balance_height rejects non-positive input", {
  expect_error(hv_balance_height(0), "n_rows")
  expect_error(hv_balance_height(10, base_size = -1), "base_size")
  expect_error(hv_balance_height(10, n_pairs = 0), "n_pairs")
})

# ---------------------------------------------------------------------------
# hv_balance: stat / pair data model
# ---------------------------------------------------------------------------

cb_long_df <- function() {
  base <- sample_covariate_balance_data(n_vars = 4)
  ks <- transform(base, stat = "ks")
  ks$std_diff <- abs(ks$std_diff) / 100
  rbind(transform(base, stat = "smd"), ks)
}

test_that("hv_balance adds stat = smd and pair = NA for plain input", {
  cb <- hv_balance(sample_covariate_balance_data())
  expect_true(all(cb$data$stat == "smd"))
  expect_true(all(is.na(cb$data$pair)))
  expect_equal(cb$meta$stats, "smd")
  expect_identical(cb$meta$pairs, character(0))
  expect_equal(cb$meta$n_imputations, 1L)
})

test_that("hv_balance stores suggested_height from hv_balance_height", {
  cb <- hv_balance(sample_covariate_balance_data(n_vars = 12))
  expect_equal(cb$meta$suggested_height, hv_balance_height(12))
})

test_that("hv_balance keeps only the requested stats from stat_col", {
  cb <- hv_balance(cb_long_df(), stat_col = "stat")
  expect_equal(levels(cb$data$stat), "smd")
  expect_equal(nrow(cb$data), 8L)
  cb2 <- hv_balance(cb_long_df(), stat_col = "stat", stats = c("smd", "ks"))
  expect_equal(levels(cb2$data$stat), c("smd", "ks"))
  expect_equal(nrow(cb2$data), 16L)
})

test_that("hv_balance reads pair_col and records pairs in order", {
  d <- sample_covariate_balance_data(n_vars = 3)
  d <- rbind(transform(d, cmp = "B vs. A"), transform(d, cmp = "C vs. A"))
  cb <- hv_balance(d, pair_col = "cmp")
  expect_equal(cb$meta$pairs, c("B vs. A", "C vs. A"))
  expect_equal(levels(cb$data$pair), c("B vs. A", "C vs. A"))
  expect_equal(cb$meta$suggested_height, hv_balance_height(3, n_pairs = 2))
})

test_that("hv_balance errors when stats names a stat with no rows", {
  expect_error(
    hv_balance(sample_covariate_balance_data(), stats = c("smd", "ks")),
    "no rows"
  )
})

test_that("hv_balance errors on an unknown stats value", {
  expect_error(hv_balance(sample_covariate_balance_data(), stats = "mean"), "should be one of")
})

test_that("hv_balance errors on unknown values in stat_col", {
  d <- transform(sample_covariate_balance_data(), stat = "ovl")
  expect_error(hv_balance(d, stat_col = "stat"), "unknown statistic")
})

test_that("hv_balance refuses to overwrite an unnamed stat or pair column", {
  d <- transform(sample_covariate_balance_data(), stat = "x")
  expect_error(hv_balance(d), "already has a column named `stat`")
})

test_that("hv_balance validates vr_threshold, ks_threshold and group_labels", {
  d <- sample_covariate_balance_data()
  expect_error(hv_balance(d, vr_threshold = c(0.5, 2, 3)), "vr_threshold")
  expect_error(hv_balance(d, vr_threshold = -1), "vr_threshold")
  expect_error(hv_balance(d, ks_threshold = 1.5), "ks_threshold")
  expect_error(hv_balance(d, group_labels = "x"), "group_labels")
})

test_that("print.hv_balance reports stats, pairs and height", {
  d <- sample_covariate_balance_data(n_vars = 3)
  d <- rbind(transform(d, cmp = "B vs. A"), transform(d, cmp = "C vs. A"))
  out <- capture.output(print(hv_balance(d, pair_col = "cmp")))
  expect_true(any(grepl("Stats", out)))
  expect_true(any(grepl("B vs. A, C vs. A", out)))
  expect_true(any(grepl("Height", out)))
})
