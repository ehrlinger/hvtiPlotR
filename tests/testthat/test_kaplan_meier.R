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
# hv_survival — return structure (S3 object)
# ===========================================================================

test_that("hv_survival returns an hv_data object", {
  dta <- sample_survival_data(n = 100, seed = 1)
  km  <- hv_survival(dta)
  expect_s3_class(km, "hv_data")
})

test_that("hv_survival returns an hv_survival subclass", {
  dta <- sample_survival_data(n = 100, seed = 1)
  km  <- hv_survival(dta)
  expect_s3_class(km, "hv_survival")
})

test_that("hv_survival $data slot is a data frame", {
  dta <- sample_survival_data(n = 200, seed = 2)
  km  <- hv_survival(dta)
  expect_true(is.data.frame(km$data))
})

test_that("hv_survival $tables$risk is not NULL", {
  dta <- sample_survival_data(n = 200, seed = 2)
  km  <- hv_survival(dta)
  expect_false(is.null(km$tables$risk))
})

test_that("hv_survival $tables$report is not NULL", {
  dta <- sample_survival_data(n = 200, seed = 2)
  km  <- hv_survival(dta)
  expect_false(is.null(km$tables$report))
})

test_that("plot(hv_survival) returns a ggplot", {
  dta <- sample_survival_data(n = 100, seed = 1)
  km  <- hv_survival(dta)
  expect_s3_class(plot(km), "ggplot")
})

test_that("plot(km, type='cumhaz') returns a ggplot", {
  dta <- sample_survival_data(n = 200, seed = 2)
  km  <- hv_survival(dta)
  expect_s3_class(plot(km, type = "cumhaz"), "ggplot")
})

test_that("plot(km, type='hazard') returns a ggplot", {
  dta <- sample_survival_data(n = 200, seed = 2)
  km  <- hv_survival(dta)
  expect_s3_class(plot(km, type = "hazard"), "ggplot")
})

test_that("plot(km, type='loglog') returns a ggplot", {
  dta <- sample_survival_data(n = 200, seed = 2)
  km  <- hv_survival(dta)
  expect_s3_class(plot(km, type = "loglog"), "ggplot")
})

test_that("plot(km, type='life') returns a ggplot", {
  dta <- sample_survival_data(n = 200, seed = 2)
  km  <- hv_survival(dta)
  expect_s3_class(plot(km, type = "life"), "ggplot")
})

test_that("km$data contains SAS-derived columns", {
  km <- hv_survival(sample_survival_data(n = 200, seed = 5))
  extra_cols <- c("hazard", "density", "mid_time", "life",
                  "proplife", "log_cumhaz", "log_time")
  expect_true(all(extra_cols %in% names(km$data)))
})

test_that("km$data life is non-decreasing within strata", {
  km        <- hv_survival(sample_survival_data(n = 300, seed = 6))
  life_vals <- km$data$life[!is.na(km$data$life)]
  expect_true(all(diff(life_vals) >= -1e-9))
})

test_that("km$data hazard is positive at event times", {
  km       <- hv_survival(sample_survival_data(n = 300, seed = 7))
  haz_vals <- km$data$hazard[!is.na(km$data$hazard)]
  expect_true(all(haz_vals >= 0))
})

test_that("km$data has expected columns", {
  km <- hv_survival(sample_survival_data(n = 200, seed = 3))
  expected_cols <- c("time", "surv", "lower", "upper",
                     "n.risk", "n.event", "n.censor", "cumhaz", "strata",
                     "hazard", "density", "mid_time", "life",
                     "proplife", "log_cumhaz", "log_time")
  expect_true(all(expected_cols %in% names(km$data)))
})

test_that("km$data starts at time 0", {
  km <- hv_survival(sample_survival_data(n = 200, seed = 4))
  expect_true(0 %in% km$data$time)
})

test_that("km$data surv at time 0 is 1", {
  km <- hv_survival(sample_survival_data(n = 200, seed = 4))
  expect_equal(km$data$surv[km$data$time == 0][1], 1)
})

test_that("km$tables$report has correct columns", {
  km <- hv_survival(sample_survival_data(n = 200, seed = 5))
  expected_cols <- c("strata", "report_time", "surv", "lower", "upper",
                     "n.risk", "n.event")
  expect_true(all(expected_cols %in% names(km$tables$report)))
})

test_that("km$tables$report rows == length(report_times) for single stratum", {
  dta          <- sample_survival_data(n = 200, seed = 5)
  report_times <- c(1, 5, 10, 20)
  km           <- hv_survival(dta, report_times = report_times)
  expect_equal(nrow(km$tables$report), length(report_times))
})

test_that("km$tables$report rows == length(report_times) * n_strata", {
  dta <- sample_survival_data(
    n = 300,
    strata_levels = c("A", "B"),
    seed = 6
  )
  report_times <- c(1, 5, 10)
  km <- hv_survival(dta, group_col = "valve_type",
                      report_times = report_times)
  expect_equal(nrow(km$tables$report), length(report_times) * 2L)
})

test_that("km$tables$risk has correct columns", {
  km <- hv_survival(sample_survival_data(n = 200, seed = 7))
  expect_true(all(c("strata", "report_time", "n.risk") %in%
                    names(km$tables$risk)))
})

test_that("km$tables$risk rows == length(report_times) for single stratum", {
  dta          <- sample_survival_data(n = 200, seed = 8)
  report_times <- c(1, 5, 10)
  km           <- hv_survival(dta, report_times = report_times)
  expect_equal(nrow(km$tables$risk), length(report_times))
})

# ===========================================================================
# hv_survival — strata
# ===========================================================================

test_that("hv_survival stratified mode has correct strata in km$data", {
  dta <- sample_survival_data(
    n = 300,
    strata_levels = c("Type A", "Type B"),
    seed = 9
  )
  km           <- hv_survival(dta, group_col = "valve_type")
  strata_found <- unique(km$data$strata)
  expect_true(all(c("Type A", "Type B") %in% strata_found))
})

test_that("hv_survival unstratified mode has strata == 'All'", {
  km <- hv_survival(sample_survival_data(n = 200, seed = 10))
  expect_true(all(km$data$strata == "All"))
})

test_that("hv_survival stratified km$tables$risk has rows == report_times * n_strata", {
  dta <- sample_survival_data(
    n = 300,
    strata_levels = c("A", "B", "C"),
    seed = 11
  )
  report_times <- c(5, 10, 15, 20)
  km <- hv_survival(dta, group_col = "valve_type",
                      report_times = report_times)
  expect_equal(nrow(km$tables$risk), length(report_times) * 3L)
})

# ===========================================================================
# plot.hv_survival — confidence interval
# ===========================================================================

test_that("plot(km, conf_int=FALSE) still returns ggplot", {
  km <- hv_survival(sample_survival_data(n = 200, seed = 12))
  expect_s3_class(plot(km, conf_int = FALSE), "ggplot")
})

test_that("plot(km, conf_int=TRUE) has more layers than conf_int=FALSE", {
  km    <- hv_survival(sample_survival_data(n = 200, seed = 13))
  p_on  <- plot(km, conf_int = TRUE)
  p_off <- plot(km, conf_int = FALSE)
  expect_gt(length(p_on$layers), length(p_off$layers))
})

# ===========================================================================
# hv_survival — custom report_times
# ===========================================================================

test_that("hv_survival respects custom report_times", {
  dta          <- sample_survival_data(n = 200, seed = 14)
  report_times <- c(2, 7, 12)
  km           <- hv_survival(dta, report_times = report_times)
  expect_equal(sort(unique(km$tables$report$report_time)),
               sort(report_times))
})

# ===========================================================================
# hv_survival — input validation
# ===========================================================================

test_that("hv_survival errors when data is not a data frame", {
  expect_error(
    hv_survival(list(iv_dead = 1:10, dead = rep(TRUE, 10))),
    "data.frame"
  )
})

test_that("hv_survival errors when time_col is missing from data", {
  dta         <- sample_survival_data(n = 50, seed = 1)
  dta$iv_dead <- NULL
  expect_error(hv_survival(dta), "column")
})

test_that("hv_survival errors when event_col is missing from data", {
  dta      <- sample_survival_data(n = 50, seed = 1)
  dta$dead <- NULL
  expect_error(hv_survival(dta), "column")
})

test_that("hv_survival errors when group_col is missing from data", {
  dta <- sample_survival_data(n = 50, seed = 1)
  expect_error(
    hv_survival(dta, group_col = "nonexistent_col"),
    "column"
  )
})

test_that("hv_survival errors when conf_level is out of (0,1)", {
  dta <- sample_survival_data(n = 50, seed = 1)
  expect_error(hv_survival(dta, conf_level = 0),    "conf_level")
  expect_error(hv_survival(dta, conf_level = 1),    "conf_level")
  expect_error(hv_survival(dta, conf_level = -0.5), "conf_level")
  expect_error(hv_survival(dta, conf_level = 1.1),  "conf_level")
})

test_that("hv_survival errors when report_times is empty", {
  dta <- sample_survival_data(n = 50, seed = 1)
  expect_error(hv_survival(dta, report_times = numeric(0)),
               "report_times")
})

test_that("hv_survival errors when report_times is non-numeric", {
  dta <- sample_survival_data(n = 50, seed = 1)
  expect_error(hv_survival(dta, report_times = c("1", "5")),
               "report_times")
})

test_that("hv_survival errors on invalid method", {
  dta <- sample_survival_data(n = 50, seed = 1)
  expect_error(hv_survival(dta, method = "breslow"),
               "kaplan-meier|nelson-aalen")
})

test_that("hv_survival errors when time_col is non-numeric", {
  dta           <- sample_survival_data(n = 50, seed = 1)
  dta$iv_dead   <- as.character(dta$iv_dead)
  expect_error(hv_survival(dta), "must be numeric")
})

test_that("hv_survival errors when event_col has invalid values", {
  dta       <- sample_survival_data(n = 50, seed = 1)
  dta$dead  <- sample(c("yes", "no"), 50, replace = TRUE)
  expect_error(hv_survival(dta), "0/1 or logical")
})

test_that("plot.hv_survival errors when alpha exceeds 1", {
  km <- hv_survival(sample_survival_data(n = 50, seed = 1))
  expect_error(plot(km, alpha = 1.5), "alpha")
})

test_that("plot.hv_survival errors when alpha is negative", {
  km <- hv_survival(sample_survival_data(n = 50, seed = 1))
  expect_error(plot(km, alpha = -0.1), "alpha")
})

# ===========================================================================
# hv_survival — method = "nelson-aalen"
# ===========================================================================

test_that("nelson-aalen method returns an hv_data object", {
  dta <- sample_survival_data(n = 200, seed = 10)
  km  <- hv_survival(dta, method = "nelson-aalen")
  expect_s3_class(km, "hv_data")
})

test_that("plot(km) with nelson-aalen returns a ggplot", {
  dta <- sample_survival_data(n = 200, seed = 10)
  km  <- hv_survival(dta, method = "nelson-aalen")
  expect_s3_class(plot(km), "ggplot")
})

test_that("nelson-aalen $data and $tables slots are present", {
  dta <- sample_survival_data(n = 200, seed = 11)
  km  <- hv_survival(dta, method = "nelson-aalen")
  expect_false(is.null(km$data))
  expect_false(is.null(km$tables$risk))
  expect_false(is.null(km$tables$report))
})

test_that("nelson-aalen surv differs from kaplan-meier", {
  dta   <- sample_survival_data(n = 500, seed = 12)
  km_km <- hv_survival(dta, method = "kaplan-meier")
  km_na <- hv_survival(dta, method = "nelson-aalen")
  expect_true(all(km_na$data$surv >= 0 & km_na$data$surv <= 1))
  expect_false(identical(km_km$data$surv, km_na$data$surv))
})

test_that("nelson-aalen cumhaz is non-decreasing", {
  km <- hv_survival(sample_survival_data(n = 300, seed = 13),
                      method = "nelson-aalen")
  ch <- km$data$cumhaz
  expect_true(all(diff(ch) >= -1e-9))
})

test_that("nelson-aalen works with stratification", {
  dta <- sample_survival_data(
    n = 200, strata_levels = c("A", "B"),
    hazard_ratios = c(1, 1.5), seed = 14
  )
  km <- hv_survival(dta, group_col = "valve_type",
                      method = "nelson-aalen")
  expect_s3_class(plot(km), "ggplot")
  expect_true(all(c("A", "B") %in% km$data$strata))
})

# ===========================================================================
# hv_survival — non-default column names
# ===========================================================================

test_that("hv_survival works with non-default column names", {
  dta <- sample_survival_data(n = 100, seed = 20)
  names(dta)[names(dta) == "iv_dead"] <- "follow_up"
  names(dta)[names(dta) == "dead"]    <- "event"
  km <- hv_survival(dta, time_col = "follow_up", event_col = "event")
  expect_s3_class(plot(km), "ggplot")
})

# ===========================================================================
# km$data internals
# ===========================================================================

test_that("km$data cumhaz is non-decreasing over time (single stratum)", {
  km        <- hv_survival(sample_survival_data(n = 300, seed = 21))
  km_sorted <- km$data[order(km$data$time), ]
  diffs     <- diff(km_sorted$cumhaz)
  expect_true(all(diffs >= -1e-10))
})

test_that("km$data surv is between 0 and 1", {
  km <- hv_survival(sample_survival_data(n = 300, seed = 22))
  expect_true(all(km$data$surv >= 0 & km$data$surv <= 1))
})

test_that("km$data lower <= surv and upper >= surv", {
  km <- hv_survival(sample_survival_data(n = 300, seed = 23))
  expect_true(all(km$data$lower <= km$data$surv + 1e-10, na.rm = TRUE))
  expect_true(all(km$data$upper >= km$data$surv - 1e-10, na.rm = TRUE))
})

# ===========================================================================
# hv_survival — edge cases
# ===========================================================================

test_that("hv_survival handles all-censored data (no events)", {
  dta      <- sample_survival_data(n = 100, seed = 1)
  dta$dead <- FALSE
  expect_s3_class(plot(hv_survival(dta)), "ggplot")
})

test_that("hv_survival handles single-observation data frame", {
  dta <- sample_survival_data(n = 1, seed = 1)
  expect_error(hv_survival(dta), NA)
})

# ===========================================================================
# hv_survival — snapshot (km$tables$report values at fixed seed)
# ===========================================================================

test_that("km$tables$report matches snapshot (fixed seed)", {
  km <- hv_survival(
    sample_survival_data(n = 500, seed = 42),
    report_times = c(1, 5, 10, 15, 20)
  )
  expect_snapshot(km$tables$report)
})

# ---------------------------------------------------------------------------
# print.hv_survival coverage
# ---------------------------------------------------------------------------

test_that("print.hv_survival produces <hv_survival> header", {
  km <- hv_survival(
    sample_survival_data(n = 200, seed = 1),
    report_times = c(1, 5, 10)
  )
  expect_output(print(km), "<hv_survival>")
})

test_that("print.hv_survival returns x invisibly", {
  km  <- hv_survival(
    sample_survival_data(n = 200, seed = 1),
    report_times = c(1, 5, 10)
  )
  ret <- withVisible(print(km))
  expect_false(ret$visible)
  expect_identical(ret$value, km)
})
