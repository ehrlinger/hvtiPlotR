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
# covariate_balance — return type
# ---------------------------------------------------------------------------

test_that("covariate_balance returns a ggplot object", {
  dta <- sample_covariate_balance_data()
  p   <- covariate_balance(dta)
  expect_s3_class(p, "ggplot")
})

# ---------------------------------------------------------------------------
# covariate_balance — input validation
# ---------------------------------------------------------------------------

test_that("covariate_balance errors when data is not a data frame", {
  expect_error(
    covariate_balance(list(variable = "x", group = "y", std_diff = 1)),
    "data.frame"
  )
})

test_that("covariate_balance errors on missing variable_col", {
  dta <- sample_covariate_balance_data()
  dta$variable <- NULL
  expect_error(covariate_balance(dta), "Missing required column")
})

test_that("covariate_balance errors on missing group_col", {
  dta <- sample_covariate_balance_data()
  dta$group <- NULL
  expect_error(covariate_balance(dta), "Missing required column")
})

test_that("covariate_balance errors on missing std_diff_col", {
  dta <- sample_covariate_balance_data()
  dta$std_diff <- NULL
  expect_error(covariate_balance(dta), "Missing required column")
})

test_that("covariate_balance errors when std_diff_col is not numeric", {
  dta <- sample_covariate_balance_data()
  dta$std_diff <- as.character(dta$std_diff)
  expect_error(covariate_balance(dta), "numeric")
})

test_that("covariate_balance accepts non-default column names", {
  dta <- sample_covariate_balance_data()
  names(dta) <- c("cov", "grp", "smd")
  p <- covariate_balance(dta,
                         variable_col  = "cov",
                         group_col     = "grp",
                         std_diff_col  = "smd")
  expect_s3_class(p, "ggplot")
})

# ---------------------------------------------------------------------------
# covariate_balance — plot structure
# ---------------------------------------------------------------------------

test_that("covariate_balance has a geom_point layer", {
  dta <- sample_covariate_balance_data()
  p   <- covariate_balance(dta)
  geom_classes <- vapply(p$layers, function(l) class(l$geom)[1], character(1))
  expect_true("GeomPoint" %in% geom_classes)
})

test_that("covariate_balance has geom_vline layers", {
  dta <- sample_covariate_balance_data()
  p   <- covariate_balance(dta)
  geom_classes <- vapply(p$layers, function(l) class(l$geom)[1], character(1))
  expect_true("GeomVline" %in% geom_classes)
})

test_that("covariate_balance has geom_hline layers", {
  dta <- sample_covariate_balance_data()
  p   <- covariate_balance(dta)
  geom_classes <- vapply(p$layers, function(l) class(l$geom)[1], character(1))
  expect_true("GeomHline" %in% geom_classes)
})

test_that("covariate_balance y scale has n breaks equal to n_vars", {
  n   <- 8L
  dta <- sample_covariate_balance_data(n_vars = n)
  p   <- covariate_balance(dta)
  built  <- ggplot2::ggplot_build(p)
  breaks <- built$layout$panel_params[[1]]$y$breaks
  expect_equal(length(breaks), n)
})

test_that("covariate_balance y labels match var_levels order", {
  dta <- sample_covariate_balance_data(n_vars = 4)
  custom_order <- rev(unique(dta$variable))
  p  <- covariate_balance(dta, var_levels = custom_order)
  built  <- ggplot2::ggplot_build(p)
  labels <- built$layout$panel_params[[1]]$y$get_labels()
  expect_equal(labels, custom_order)
})

test_that("covariate_balance threshold vlines appear at correct x values", {
  dta   <- sample_covariate_balance_data()
  p     <- covariate_balance(dta, threshold = 15)
  built <- ggplot2::ggplot_build(p)
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
