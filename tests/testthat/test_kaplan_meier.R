# Test suite for kaplan-meier.R
#
library(testthat)

# ===========================================================================
# sample_survival_data
# ===========================================================================

test_that("sample_survival_data returns a data frame", {
  df <- sample_survival_data()
  expect_true(is.data.frame(df))
})

test_that("sample_survival_data has required columns (unstratified)", {
  df <- sample_survival_data()
  expect_true(all(c("iv_dead", "dead", "iv_opyrs", "age_at_op") %in% names(df)))
})

test_that("sample_survival_data returns n rows", {
  df <- sample_survival_data(n = 200)
  expect_equal(nrow(df), 200)
})

test_that("sample_survival_data iv_dead is non-negative", {
  df <- sample_survival_data(n = 300, seed = 1)
  expect_true(all(df$iv_dead >= 0))
})

test_that("sample_survival_data iv_dead does not exceed study_years", {
  df <- sample_survival_data(n = 300, study_years = 15, seed = 7)
  expect_true(all(df$iv_dead <= 15))
})

test_that("sample_survival_data dead is logical", {
  df <- sample_survival_data()
  expect_true(is.logical(df$dead))
})

test_that("sample_survival_data age_at_op is capped to [30, 90]", {
  df <- sample_survival_data(n = 1000, seed = 99)
  expect_true(all(df$age_at_op >= 30))
  expect_true(all(df$age_at_op <= 90))
})

test_that("sample_survival_data iv_opyrs falls in [1990, 1990+study_years]", {
  df <- sample_survival_data(n = 500, study_years = 20, seed = 5)
  expect_true(all(df$iv_opyrs >= 1990))
  expect_true(all(df$iv_opyrs <= 2010))
})

test_that("sample_survival_data is reproducible with the same seed", {
  df1 <- sample_survival_data(n = 100, seed = 42)
  df2 <- sample_survival_data(n = 100, seed = 42)
  expect_identical(df1, df2)
})

test_that("sample_survival_data differs with different seeds", {
  df1 <- sample_survival_data(n = 100, seed = 1)
  df2 <- sample_survival_data(n = 100, seed = 2)
  expect_false(identical(df1, df2))
})

test_that("sample_survival_data adds valve_type when strata_levels supplied", {
  df <- sample_survival_data(
    n = 200,
    strata_levels = c("Type A", "Type B"),
    seed = 42
  )
  expect_true("valve_type" %in% names(df))
  expect_true(all(df$valve_type %in% c("Type A", "Type B")))
})

test_that("sample_survival_data splits n approximately evenly across strata", {
  df <- sample_survival_data(
    n = 200,
    strata_levels = c("A", "B"),
    seed = 10
  )
  counts <- table(df$valve_type)
  expect_equal(sum(counts), 200)
  # Each group gets exactly n/2 when n is even
  expect_equal(as.integer(counts["A"]), 100)
  expect_equal(as.integer(counts["B"]), 100)
})

test_that("sample_survival_data no valve_type column when strata_levels is NULL", {
  df <- sample_survival_data(n = 50)
  expect_false("valve_type" %in% names(df))
})

test_that("sample_survival_data higher hazard_ratio increases event proportion", {
  df_low <- sample_survival_data(
    n = 2000, strata_levels = c("Low", "High"),
    hazard_ratios = c(1, 3), seed = 7
  )
  prop_low  <- mean(df_low$dead[df_low$valve_type == "Low"])
  prop_high <- mean(df_low$dead[df_low$valve_type == "High"])
  expect_gt(prop_high, prop_low)
})

test_that("sample_survival_data errors on non-positive n", {
  expect_error(sample_survival_data(n = 0), "positive integer")
})

test_that("sample_survival_data errors on negative hazard_rate", {
  expect_error(sample_survival_data(hazard_rate = -0.1), "positive number")
})

test_that("sample_survival_data errors on zero hazard_rate", {
  expect_error(sample_survival_data(hazard_rate = 0), "positive number")
})

test_that("sample_survival_data errors on non-positive study_years", {
  expect_error(sample_survival_data(study_years = 0), "positive number")
})

test_that("sample_survival_data errors when hazard_ratios length mismatches strata", {
  expect_error(
    sample_survival_data(
      n = 100,
      strata_levels = c("A", "B"),
      hazard_ratios = c(1, 1.5, 2)
    ),
    "same length"
  )
})

test_that("sample_survival_data accepts NULL hazard_ratios with strata_levels", {
  df <- sample_survival_data(
    n = 100,
    strata_levels = c("A", "B"),
    hazard_ratios = NULL,
    seed = 42
  )
  expect_true(is.data.frame(df))
  expect_true("valve_type" %in% names(df))
})

# ===========================================================================
# survival_curve — return structure
# ===========================================================================

test_that("survival_curve returns a ggplot", {
  dta    <- sample_survival_data(n = 100, seed = 1)
  result <- survival_curve(dta)
  expect_s3_class(result, "ggplot")
})

test_that("survival_curve result has correct attribute names", {
  dta    <- sample_survival_data(n = 100, seed = 1)
  result <- survival_curve(dta)
  attr_names <- c("survival_plot", "cumhaz_plot", "hazard_plot",
                  "loglog_plot", "life_plot",
                  "km_data", "risk_table", "report_table")
  for (nm in attr_names) {
    expect_false(is.null(attr(result, nm)),
                 label = paste0("attr(result, '", nm, "') should not be NULL"))
  }
})

test_that("survival_curve returns a ggplot (survival_plot)", {
  dta    <- sample_survival_data(n = 200, seed = 2)
  result <- survival_curve(dta)
  expect_s3_class(result, "ggplot")
})

test_that("survival_curve cumhaz_plot is a ggplot", {
  dta <- sample_survival_data(n = 200, seed = 2)
  expect_s3_class(survival_curve(dta, plot_type = "cumhaz"), "ggplot")
})

test_that("survival_curve hazard_plot is a ggplot", {
  dta <- sample_survival_data(n = 200, seed = 2)
  expect_s3_class(survival_curve(dta, plot_type = "hazard"), "ggplot")
})

test_that("survival_curve loglog_plot is a ggplot", {
  dta <- sample_survival_data(n = 200, seed = 2)
  expect_s3_class(survival_curve(dta, plot_type = "loglog"), "ggplot")
})

test_that("survival_curve life_plot is a ggplot", {
  dta <- sample_survival_data(n = 200, seed = 2)
  expect_s3_class(survival_curve(dta, plot_type = "life"), "ggplot")
})

test_that("km_data contains SAS-derived columns", {
  result <- survival_curve(sample_survival_data(n = 200, seed = 5))
  extra_cols <- c("hazard", "density", "mid_time", "life",
                  "proplife", "log_cumhaz", "log_time")
  expect_true(all(extra_cols %in% names(attr(result, "km_data"))))
})

test_that("km_data life is non-decreasing within strata", {
  result    <- survival_curve(sample_survival_data(n = 300, seed = 6))
  km_data   <- attr(result, "km_data")
  life_vals <- km_data$life[!is.na(km_data$life)]
  expect_true(all(diff(life_vals) >= -1e-9))
})

test_that("km_data hazard is positive at event times", {
  result   <- survival_curve(sample_survival_data(n = 300, seed = 7))
  km_data  <- attr(result, "km_data")
  haz_vals <- km_data$hazard[!is.na(km_data$hazard)]
  expect_true(all(haz_vals >= 0))
})

test_that("survival_curve km_data is a data frame", {
  dta    <- sample_survival_data(n = 200, seed = 3)
  result <- survival_curve(dta)
  expect_true(is.data.frame(attr(result, "km_data")))
})

test_that("survival_curve km_data has expected columns", {
  dta    <- sample_survival_data(n = 200, seed = 3)
  result <- survival_curve(dta)
  expected_cols <- c("time", "surv", "lower", "upper",
                     "n.risk", "n.event", "n.censor", "cumhaz", "strata",
                     "hazard", "density", "mid_time", "life",
                     "proplife", "log_cumhaz", "log_time")
  expect_true(all(expected_cols %in% names(attr(result, "km_data"))))
})

test_that("survival_curve km_data starts at time 0", {
  dta    <- sample_survival_data(n = 200, seed = 4)
  result <- survival_curve(dta)
  expect_true(0 %in% attr(result, "km_data")$time)
})

test_that("survival_curve km_data surv at time 0 is 1", {
  dta    <- sample_survival_data(n = 200, seed = 4)
  result <- survival_curve(dta)
  km     <- attr(result, "km_data")
  expect_equal(km$surv[km$time == 0][1], 1)
})

test_that("survival_curve report_table has correct columns", {
  dta    <- sample_survival_data(n = 200, seed = 5)
  result <- survival_curve(dta)
  expected_cols <- c("strata", "report_time", "surv", "lower", "upper",
                     "n.risk", "n.event")
  expect_true(all(expected_cols %in% names(attr(result, "report_table"))))
})

test_that("survival_curve report_table rows == length(report_times) for single stratum", {
  dta          <- sample_survival_data(n = 200, seed = 5)
  report_times <- c(1, 5, 10, 20)
  result       <- survival_curve(dta, report_times = report_times)
  expect_equal(nrow(attr(result, "report_table")), length(report_times))
})

test_that("survival_curve report_table rows == length(report_times) * n_strata", {
  dta <- sample_survival_data(
    n = 300,
    strata_levels = c("A", "B"),
    seed = 6
  )
  report_times <- c(1, 5, 10)
  # In testthat 3, expect_warning() returns the condition, not the expression
  # value.  Verify the deprecation fires separately, then capture the result.
  expect_warning(
    survival_curve(dta, strata_col = "valve_type", report_times = report_times),
    "deprecated"
  )
  result <- suppressWarnings(
    survival_curve(dta, strata_col = "valve_type", report_times = report_times)
  )
  expect_equal(nrow(attr(result, "report_table")), length(report_times) * 2L)
})

test_that("survival_curve risk_table has correct columns", {
  dta    <- sample_survival_data(n = 200, seed = 7)
  result <- survival_curve(dta)
  expect_true(all(c("strata", "report_time", "n.risk") %in%
                    names(attr(result, "risk_table"))))
})

test_that("survival_curve risk_table rows == length(report_times) for single stratum", {
  dta          <- sample_survival_data(n = 200, seed = 8)
  report_times <- c(1, 5, 10)
  result       <- survival_curve(dta, report_times = report_times)
  expect_equal(nrow(attr(result, "risk_table")), length(report_times))
})

# ===========================================================================
# survival_curve — strata
# ===========================================================================

test_that("survival_curve stratified mode has correct strata in km_data", {
  dta <- sample_survival_data(
    n = 300,
    strata_levels = c("Type A", "Type B"),
    seed = 9
  )
  expect_warning(
    survival_curve(dta, strata_col = "valve_type"),
    "deprecated"
  )
  result        <- suppressWarnings(survival_curve(dta, strata_col = "valve_type"))
  strata_found  <- unique(attr(result, "km_data")$strata)
  expect_true(all(c("Type A", "Type B") %in% strata_found))
})

test_that("survival_curve unstratified mode has strata == 'All'", {
  dta    <- sample_survival_data(n = 200, seed = 10)
  result <- survival_curve(dta)
  expect_true(all(attr(result, "km_data")$strata == "All"))
})

test_that("survival_curve stratified risk_table has rows == report_times * n_strata", {
  dta <- sample_survival_data(
    n = 300,
    strata_levels = c("A", "B", "C"),
    seed = 11
  )
  report_times <- c(5, 10, 15, 20)
  expect_warning(
    survival_curve(dta, strata_col = "valve_type", report_times = report_times),
    "deprecated"
  )
  result <- suppressWarnings(
    survival_curve(dta, strata_col = "valve_type", report_times = report_times)
  )
  expect_equal(nrow(attr(result, "risk_table")), length(report_times) * 3L)
})

# ===========================================================================
# survival_curve — confidence interval
# ===========================================================================

test_that("survival_curve with conf_int=FALSE still returns ggplot", {
  dta    <- sample_survival_data(n = 200, seed = 12)
  result <- survival_curve(dta, conf_int = FALSE)
  expect_s3_class(result, "ggplot")
})

test_that("survival_curve conf_int=TRUE has more layers than conf_int=FALSE", {
  dta   <- sample_survival_data(n = 200, seed = 13)
  r_on  <- survival_curve(dta, conf_int = TRUE)
  r_off <- survival_curve(dta, conf_int = FALSE)
  surv_on  <- attr(r_on,  "survival_plot")
  surv_off <- attr(r_off, "survival_plot")
  expect_gt(length(surv_on$layers), length(surv_off$layers))
})

# ===========================================================================
# survival_curve — custom report_times
# ===========================================================================

test_that("survival_curve respects custom report_times", {
  dta          <- sample_survival_data(n = 200, seed = 14)
  report_times <- c(2, 7, 12)
  result       <- survival_curve(dta, report_times = report_times)
  expect_equal(sort(unique(attr(result, "report_table")$report_time)),
               sort(report_times))
})

# ===========================================================================
# survival_curve — input validation
# ===========================================================================

test_that("survival_curve errors when data is not a data frame", {
  expect_error(
    survival_curve(list(iv_dead = 1:10, dead = rep(TRUE, 10))),
    "data.frame"
  )
})

test_that("survival_curve errors when time_col is missing from data", {
  dta      <- sample_survival_data(n = 50, seed = 1)
  dta$iv_dead <- NULL
  expect_error(survival_curve(dta), "column")
})

test_that("survival_curve errors when event_col is missing from data", {
  dta      <- sample_survival_data(n = 50, seed = 1)
  dta$dead <- NULL
  expect_error(survival_curve(dta), "column")
})

test_that("survival_curve errors when strata_col is missing from data", {
  dta <- sample_survival_data(n = 50, seed = 1)
  expect_error(
    survival_curve(dta, group_col = "nonexistent_col"),
    "column"
  )
})

test_that("survival_curve errors when conf_level is out of (0,1)", {
  dta <- sample_survival_data(n = 50, seed = 1)
  expect_error(survival_curve(dta, conf_level = 0),   "conf_level")
  expect_error(survival_curve(dta, conf_level = 1),   "conf_level")
  expect_error(survival_curve(dta, conf_level = -0.5), "conf_level")
  expect_error(survival_curve(dta, conf_level = 1.1),  "conf_level")
})

test_that("survival_curve errors when report_times is empty", {
  dta <- sample_survival_data(n = 50, seed = 1)
  expect_error(survival_curve(dta, report_times = numeric(0)),
               "report_times")
})

test_that("survival_curve errors when report_times is non-numeric", {
  dta <- sample_survival_data(n = 50, seed = 1)
  expect_error(survival_curve(dta, report_times = c("1", "5")),
               "report_times")
})

test_that("survival_curve errors on invalid method", {
  dta <- sample_survival_data(n = 50, seed = 1)
  expect_error(survival_curve(dta, method = "breslow"),
               "kaplan-meier|nelson-aalen")
})

test_that("survival_curve errors when time_col is non-numeric", {
  dta           <- sample_survival_data(n = 50, seed = 1)
  dta$iv_dead   <- as.character(dta$iv_dead)   # convert to character
  expect_error(survival_curve(dta), "must be numeric")
})

test_that("survival_curve errors when event_col has invalid values", {
  dta       <- sample_survival_data(n = 50, seed = 1)
  dta$dead  <- sample(c("yes", "no"), 50, replace = TRUE)
  expect_error(survival_curve(dta), "0/1 or logical")
})

test_that("survival_curve errors when alpha exceeds 1", {
  dta <- sample_survival_data(n = 50, seed = 1)
  expect_error(survival_curve(dta, alpha = 1.5), "alpha")
})

test_that("survival_curve errors when alpha is negative", {
  dta <- sample_survival_data(n = 50, seed = 1)
  expect_error(survival_curve(dta, alpha = -0.1), "alpha")
})

# ===========================================================================
# survival_curve — method = "nelson-aalen"
# ===========================================================================

test_that("nelson-aalen method returns a ggplot", {
  dta    <- sample_survival_data(n = 200, seed = 10)
  result <- survival_curve(dta, method = "nelson-aalen")
  expect_s3_class(result, "ggplot")
})

test_that("nelson-aalen method result has expected attribute names", {
  dta    <- sample_survival_data(n = 200, seed = 11)
  result <- survival_curve(dta, method = "nelson-aalen")
  attr_names <- c("survival_plot", "cumhaz_plot", "hazard_plot",
                  "loglog_plot", "life_plot",
                  "km_data", "risk_table", "report_table")
  for (nm in attr_names) {
    expect_false(is.null(attr(result, nm)),
                 label = paste0("attr(result, '", nm, "') should not be NULL"))
  }
})

test_that("nelson-aalen surv differs from kaplan-meier", {
  dta  <- sample_survival_data(n = 500, seed = 12)
  km   <- survival_curve(dta, method = "kaplan-meier")
  na   <- survival_curve(dta, method = "nelson-aalen")
  km_data_na <- attr(na, "km_data")
  km_data_km <- attr(km, "km_data")
  # Both methods should produce surv in (0, 1]; they need not be identical
  expect_true(all(km_data_na$surv >= 0 & km_data_na$surv <= 1))
  expect_false(identical(km_data_km$surv, km_data_na$surv))
})

test_that("nelson-aalen cumhaz is non-decreasing", {
  result <- survival_curve(sample_survival_data(n = 300, seed = 13),
                           method = "nelson-aalen")
  ch <- attr(result, "km_data")$cumhaz
  expect_true(all(diff(ch) >= -1e-9))
})

test_that("nelson-aalen works with stratification", {
  dta <- sample_survival_data(
    n = 200, strata_levels = c("A", "B"),
    hazard_ratios = c(1, 1.5), seed = 14
  )
  result <- survival_curve(dta, group_col = "valve_type",
                           method = "nelson-aalen")
  expect_s3_class(result, "ggplot")
  expect_true(all(c("A", "B") %in% attr(result, "km_data")$strata))
})

# ===========================================================================
# survival_curve — non-default column names
# ===========================================================================

test_that("survival_curve works with non-default column names", {
  dta <- sample_survival_data(n = 100, seed = 20)
  names(dta)[names(dta) == "iv_dead"] <- "follow_up"
  names(dta)[names(dta) == "dead"]    <- "event"
  result <- survival_curve(dta, time_col = "follow_up", event_col = "event")
  expect_s3_class(result, "ggplot")
})

# ===========================================================================
# km helper internals (via survival_curve)
# ===========================================================================

test_that("km_data cumhaz is non-decreasing over time (single stratum)", {
  dta    <- sample_survival_data(n = 300, seed = 21)
  result <- survival_curve(dta)
  km     <- attr(result, "km_data")
  km_sorted <- km[order(km$time), ]
  diffs  <- diff(km_sorted$cumhaz)
  expect_true(all(diffs >= -1e-10))   # allow tiny floating-point noise
})

test_that("km_data surv is between 0 and 1", {
  dta    <- sample_survival_data(n = 300, seed = 22)
  result <- survival_curve(dta)
  expect_true(all(attr(result, "km_data")$surv >= 0 & attr(result, "km_data")$surv <= 1))
})

test_that("km_data lower <= surv and upper >= surv", {
  dta    <- sample_survival_data(n = 300, seed = 23)
  result <- survival_curve(dta)
  km     <- attr(result, "km_data")
  expect_true(all(km$lower <= km$surv + 1e-10, na.rm = TRUE))
  expect_true(all(km$upper >= km$surv - 1e-10, na.rm = TRUE))
})

# ===========================================================================
# survival_curve — edge cases
# ===========================================================================

test_that("survival_curve handles all-censored data (no events)", {
  dta      <- sample_survival_data(n = 100, seed = 1)
  dta$dead <- FALSE    # override: zero events
  expect_s3_class(survival_curve(dta), "ggplot")
})

test_that("survival_curve handles single-observation data frame", {
  dta <- sample_survival_data(n = 1, seed = 1)
  # May produce a degenerate KM but must not hard-error
  expect_error(survival_curve(dta), NA)
})

# ===========================================================================
# survival_curve — snapshot (report_table values at fixed seed)
# ===========================================================================

test_that("survival_curve report_table matches snapshot (fixed seed)", {
  result <- survival_curve(
    sample_survival_data(n = 500, seed = 42),
    report_times = c(1, 5, 10, 15, 20)
  )
  expect_snapshot(attr(result, "report_table"))
})
