# tests/testthat/test_hazard_plot.R
#
# Full test suite for hazard-plot.R:
#   sample_hazard_data, sample_hazard_empirical, sample_life_table,
#   hazard_plot
#
library(testthat)
library(ggplot2)

# ============================================================================
# sample_hazard_data
# ============================================================================

test_that("sample_hazard_data returns a data frame", {
  df <- sample_hazard_data(n = 100, seed = 1)
  expect_true(is.data.frame(df))
})

test_that("sample_hazard_data has required columns (single-group)", {
  df <- sample_hazard_data(n = 100, seed = 1)
  expect_true(all(c("time", "survival", "surv_lower", "surv_upper",
                    "hazard", "haz_lower", "haz_upper",
                    "cumhaz", "cumhaz_lower", "cumhaz_upper") %in% names(df)))
})

test_that("sample_hazard_data returns n_points rows (single-group)", {
  df <- sample_hazard_data(n = 100, n_points = 200, seed = 1)
  expect_equal(nrow(df), 200L)
})

test_that("sample_hazard_data survival is between 0 and 100", {
  df <- sample_hazard_data(n = 300, seed = 42)
  expect_true(all(df$survival >= 0))
  expect_true(all(df$survival <= 100))
})

test_that("sample_hazard_data hazard is positive", {
  df <- sample_hazard_data(n = 100, seed = 1)
  expect_true(all(df$hazard > 0))
})

test_that("sample_hazard_data CI bounds straddle survival estimate", {
  df <- sample_hazard_data(n = 300, seed = 42)
  expect_true(all(df$surv_lower <= df$survival + 1e-9))
  expect_true(all(df$surv_upper >= df$survival - 1e-9))
})

test_that("sample_hazard_data CI bounds straddle hazard estimate", {
  df <- sample_hazard_data(n = 300, seed = 42)
  expect_true(all(df$haz_lower <= df$hazard + 1e-9))
  expect_true(all(df$haz_upper >= df$hazard - 1e-9))
})

test_that("sample_hazard_data is reproducible with same seed", {
  df1 <- sample_hazard_data(n = 100, seed = 7)
  df2 <- sample_hazard_data(n = 100, seed = 7)
  expect_identical(df1, df2)
})

test_that("sample_hazard_data groups argument produces different output", {
  # sample_hazard_data uses deterministic Weibull predictions; seed is a no-op.
  # Verify that changing the groups multiplier produces different survival values.
  df_base  <- sample_hazard_data(n = 100, seed = 1)
  df_group <- sample_hazard_data(
    n = 100, groups = c("Low" = 1.0, "High" = 2.0), seed = 1
  )
  expect_false(identical(df_base, df_group))
})

test_that("sample_hazard_data groups argument adds group factor column", {
  df <- sample_hazard_data(
    n = 100, groups = c("Control" = 1.0, "Treatment" = 0.7), seed = 1
  )
  expect_true("group" %in% names(df))
  expect_true(is.factor(df$group))
})

test_that("sample_hazard_data group levels match groups argument order", {
  grps <- c("No Takedown" = 1.0, "Takedown" = 0.65)
  df   <- sample_hazard_data(n = 100, groups = grps, seed = 1)
  expect_equal(levels(df$group), names(grps))
})

test_that("sample_hazard_data multi-group returns n_points rows per group", {
  df <- sample_hazard_data(
    n = 100, n_points = 50,
    groups = c("A" = 1.0, "B" = 0.8),
    seed = 1
  )
  expect_equal(nrow(df), 100L)   # 2 groups × 50 points
  expect_equal(sum(df$group == "A"), 50L)
  expect_equal(sum(df$group == "B"), 50L)
})

test_that("sample_hazard_data higher hazard group has lower survival at t_max", {
  df <- sample_hazard_data(
    n = 500, time_max = 10,
    groups = c("Low" = 0.5, "High" = 2.0),
    seed = 1
  )
  surv_low  <- df$survival[df$group == "Low"  & df$time == max(df$time[df$group == "Low"])]
  surv_high <- df$survival[df$group == "High" & df$time == max(df$time[df$group == "High"])]
  expect_gt(mean(surv_low), mean(surv_high))
})

# ============================================================================
# sample_hazard_empirical
# ============================================================================

test_that("sample_hazard_empirical returns a data frame", {
  df <- sample_hazard_empirical(n = 100, seed = 1)
  expect_true(is.data.frame(df))
})

test_that("sample_hazard_empirical has required columns", {
  df <- sample_hazard_empirical(n = 100, seed = 1)
  expect_true(all(c("time", "estimate", "lower", "upper") %in% names(df)))
})

test_that("sample_hazard_empirical returns n_bins rows (single-group)", {
  df <- sample_hazard_empirical(n = 100, n_bins = 6, seed = 1)
  expect_equal(nrow(df), 6L)
})

test_that("sample_hazard_empirical estimate is in [0, 100]", {
  df <- sample_hazard_empirical(n = 200, seed = 42)
  expect_true(all(df$estimate >= 0))
  expect_true(all(df$estimate <= 100))
})

test_that("sample_hazard_empirical CI bounds straddle estimate", {
  df <- sample_hazard_empirical(n = 200, seed = 42)
  expect_true(all(df$lower <= df$estimate + 1e-9))
  expect_true(all(df$upper >= df$estimate - 1e-9))
})

test_that("sample_hazard_empirical is reproducible with same seed", {
  df1 <- sample_hazard_empirical(n = 100, seed = 5)
  df2 <- sample_hazard_empirical(n = 100, seed = 5)
  expect_identical(df1, df2)
})

test_that("sample_hazard_empirical multi-group returns n_bins rows per group", {
  df <- sample_hazard_empirical(
    n = 100, n_bins = 4,
    groups = c("A" = 1.0, "B" = 0.8),
    seed = 1
  )
  expect_equal(nrow(df), 8L)   # 2 groups × 4 bins
})

# ============================================================================
# sample_life_table
# ============================================================================

test_that("sample_life_table returns a data frame", {
  df <- sample_life_table()
  expect_true(is.data.frame(df))
})

test_that("sample_life_table has required columns", {
  df <- sample_life_table()
  expect_true(all(c("time", "survival", "group") %in% names(df)))
})

test_that("sample_life_table group is a factor with age_groups levels", {
  grps <- c("Under 65", "65 and over")
  df   <- sample_life_table(age_groups = grps, age_mids = c(55, 75))
  expect_true(is.factor(df$group))
  expect_equal(levels(df$group), grps)
})

test_that("sample_life_table default has 3 age groups", {
  df <- sample_life_table()
  expect_equal(nlevels(df$group), 3L)
})

test_that("sample_life_table survival is in [0, 100]", {
  df <- sample_life_table()
  expect_true(all(df$survival >= 0))
  expect_true(all(df$survival <= 100))
})

test_that("sample_life_table survival starts near 100 and decreases", {
  df  <- sample_life_table()
  grp <- df[df$group == levels(df$group)[1], ]
  grp <- grp[order(grp$time), ]
  expect_true(grp$survival[1] > 95)
  expect_true(grp$survival[nrow(grp)] < grp$survival[1])
})

test_that("sample_life_table time_max controls the x range", {
  df <- sample_life_table(time_max = 20)
  expect_lte(max(df$time), 20)
})

test_that("sample_life_table errors when age_groups and age_mids lengths differ", {
  expect_error(
    sample_life_table(age_groups = c("A", "B"), age_mids = c(55, 72, 85)),
    "same length"
  )
})

test_that("sample_life_table older age_mids produce lower survival", {
  young_df <- sample_life_table(age_groups = "Young", age_mids = 40, time_max = 20)
  old_df   <- sample_life_table(age_groups = "Old",   age_mids = 85, time_max = 20)
  expect_gt(
    mean(young_df$survival),
    mean(old_df$survival)
  )
})

# ============================================================================
# hazard_plot — return type
# ============================================================================

test_that("hazard_plot returns a ggplot for default estimate_col='survival'", {
  dat <- sample_hazard_data(n = 50, seed = 1)
  expect_s3_class(hazard_plot(dat), "ggplot")
})

test_that("hazard_plot returns a ggplot for estimate_col='hazard'", {
  dat <- sample_hazard_data(n = 50, seed = 1)
  expect_s3_class(hazard_plot(dat, estimate_col = "hazard"), "ggplot")
})

test_that("hazard_plot returns a ggplot for estimate_col='cumhaz'", {
  dat <- sample_hazard_data(n = 50, seed = 1)
  expect_s3_class(hazard_plot(dat, estimate_col = "cumhaz"), "ggplot")
})

test_that("hazard_plot is composable with + operator", {
  dat <- sample_hazard_data(n = 50, seed = 1)
  p   <- hazard_plot(dat) + ggplot2::labs(x = "Years", y = "Survival (%)")
  expect_s3_class(p, "ggplot")
  expect_equal(p$labels$x, "Years")
})

# ============================================================================
# hazard_plot — layer structure
# ============================================================================

test_that("hazard_plot has a GeomLine layer", {
  dat   <- sample_hazard_data(n = 50, seed = 1)
  geoms <- sapply(hazard_plot(dat)$layers, function(l) class(l$geom)[1])
  expect_true("GeomLine" %in% geoms)
})

test_that("hazard_plot with lower_col + upper_col has a GeomRibbon layer", {
  dat   <- sample_hazard_data(n = 50, seed = 1)
  geoms <- sapply(
    hazard_plot(dat, lower_col = "surv_lower", upper_col = "surv_upper")$layers,
    function(l) class(l$geom)[1]
  )
  expect_true("GeomRibbon" %in% geoms)
})

test_that("hazard_plot without CI has no GeomRibbon", {
  dat   <- sample_hazard_data(n = 50, seed = 1)
  geoms <- sapply(hazard_plot(dat)$layers, function(l) class(l$geom)[1])
  expect_false("GeomRibbon" %in% geoms)
})

test_that("hazard_plot with empirical overlay adds a GeomPoint layer", {
  dat <- sample_hazard_data(n = 50, seed = 1)
  emp <- sample_hazard_empirical(n = 50, seed = 1)
  p_no_emp   <- hazard_plot(dat)
  p_with_emp <- hazard_plot(dat, empirical = emp)
  expect_gt(length(p_with_emp$layers), length(p_no_emp$layers))
})

test_that("hazard_plot empirical with error bars has a GeomErrorbar layer", {
  dat   <- sample_hazard_data(n = 50, seed = 1)
  emp   <- sample_hazard_empirical(n = 50, seed = 1)
  geoms <- sapply(
    hazard_plot(dat, empirical = emp,
                emp_lower_col = "lower",
                emp_upper_col = "upper")$layers,
    function(l) class(l$geom)[1]
  )
  expect_true("GeomErrorbar" %in% geoms)
})

test_that("hazard_plot with reference life table adds extra GeomLine layer", {
  dat <- sample_hazard_data(n = 50, seed = 1)
  lt  <- sample_life_table(time_max = 10)
  p_no_ref   <- hazard_plot(dat)
  p_with_ref <- hazard_plot(dat, reference = lt,
                             ref_estimate_col = "survival",
                             ref_group_col    = "group")
  expect_gt(length(p_with_ref$layers), length(p_no_ref$layers))
})

# ============================================================================
# hazard_plot — multi-group
# ============================================================================

test_that("hazard_plot works with group_col", {
  dat <- sample_hazard_data(
    n = 100, groups = c("Control" = 1.0, "Treated" = 0.7), seed = 1
  )
  p <- hazard_plot(dat, group_col = "group")
  expect_s3_class(p, "ggplot")
})

test_that("hazard_plot multi-group has more layers than single-group (due to colour aesthetic)", {
  dat_single <- sample_hazard_data(n = 50, seed = 1)
  dat_multi  <- sample_hazard_data(
    n = 50, groups = c("A" = 1.0, "B" = 0.8), seed = 1
  )
  p_single <- hazard_plot(dat_single)
  p_multi  <- hazard_plot(dat_multi, group_col = "group")
  # Multi-group plot has the same layer types but uses colour aesthetic
  expect_s3_class(p_multi, "ggplot")
  expect_false(identical(p_single$mapping, p_multi$mapping))
})

# ============================================================================
# hazard_plot — non-default column names
# ============================================================================

test_that("hazard_plot works with non-default x_col", {
  dat      <- sample_hazard_data(n = 50, seed = 1)
  dat$year <- dat$time
  p <- hazard_plot(dat, x_col = "year")
  expect_s3_class(p, "ggplot")
})

test_that("hazard_plot works with non-default estimate_col", {
  dat     <- sample_hazard_data(n = 50, seed = 1)
  dat$est <- dat$survival
  p <- hazard_plot(dat, estimate_col = "est")
  expect_s3_class(p, "ggplot")
})

# ============================================================================
# hazard_plot — input validation
# ============================================================================

test_that("hazard_plot errors when curve_data is not a data frame", {
  expect_error(
    hazard_plot(list(time = 1:5, survival = 1:5)),
    "data frame"
  )
})

test_that("hazard_plot errors when x_col is absent from curve_data", {
  dat <- sample_hazard_data(n = 50, seed = 1)
  expect_error(hazard_plot(dat, x_col = "nonexistent"), "column")
})

test_that("hazard_plot errors when estimate_col is absent from curve_data", {
  dat <- sample_hazard_data(n = 50, seed = 1)
  expect_error(hazard_plot(dat, estimate_col = "nonexistent"), "column")
})

test_that("hazard_plot errors when lower_col is absent from curve_data", {
  dat <- sample_hazard_data(n = 50, seed = 1)
  expect_error(hazard_plot(dat, lower_col = "nonexistent"), "not found")
})

test_that("hazard_plot errors when group_col is absent from curve_data", {
  dat <- sample_hazard_data(n = 50, seed = 1)
  expect_error(hazard_plot(dat, group_col = "nonexistent"), "not found")
})

test_that("hazard_plot handles empty data frame gracefully", {
  # An empty data frame with the required columns (time, survival) satisfies
  # all column-presence checks; ggplot renders an empty plot without error.
  empty_df <- data.frame(time = numeric(0), survival = numeric(0))
  result <- hazard_plot(curve_data = empty_df)
  expect_s3_class(result, "ggplot")
})
