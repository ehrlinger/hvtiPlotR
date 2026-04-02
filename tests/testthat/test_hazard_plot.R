# tests/testthat/test_hazard_plot.R
#
# Full test suite for hazard-plot.R:
#   sample_hazard_data, sample_hazard_empirical, sample_life_table,
#   hv_hazard, hv_survival_difference, hv_nnt
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
# hv_hazard — constructor return type and slots
# ============================================================================

test_that("hv_hazard returns an hv_data object with correct class", {
  dat <- sample_hazard_data(n = 50, seed = 1)
  obj <- hv_hazard(dat)
  expect_true(is_hv_data(obj))
  expect_s3_class(obj, "hv_hazard")
  expect_s3_class(obj, "hv_data")
})

test_that("hv_hazard has $data, $meta, and $tables slots", {
  dat <- sample_hazard_data(n = 50, seed = 1)
  obj <- hv_hazard(dat)
  expect_true(!is.null(obj$data))
  expect_true(!is.null(obj$meta))
  expect_true(!is.null(obj$tables))
})

test_that("hv_hazard stores curve data in $data", {
  dat <- sample_hazard_data(n = 50, seed = 1)
  obj <- hv_hazard(dat)
  expect_identical(obj$data, dat)
})

test_that("hv_hazard stores column mappings in $meta", {
  dat <- sample_hazard_data(
    n = 50, groups = c("A" = 1.0, "B" = 0.8), seed = 1
  )
  obj <- hv_hazard(dat, x_col = "time", estimate_col = "survival",
                     lower_col = "surv_lower", upper_col = "surv_upper",
                     group_col = "group")
  expect_equal(obj$meta$x_col,        "time")
  expect_equal(obj$meta$estimate_col, "survival")
  expect_equal(obj$meta$lower_col,    "surv_lower")
  expect_equal(obj$meta$upper_col,    "surv_upper")
  expect_equal(obj$meta$group_col,    "group")
})

test_that("hv_hazard stores empirical data in $tables$empirical", {
  dat <- sample_hazard_data(n = 50, seed = 1)
  emp <- sample_hazard_empirical(n = 50, seed = 1)
  obj <- hv_hazard(dat, empirical = emp)
  expect_identical(obj$tables$empirical, emp)
})

test_that("hv_hazard stores reference data in $tables$reference", {
  dat <- sample_hazard_data(n = 50, seed = 1)
  lt  <- sample_life_table(time_max = 10)
  obj <- hv_hazard(dat, reference = lt)
  expect_identical(obj$tables$reference, lt)
})

test_that("hv_hazard $tables$empirical is NULL when not supplied", {
  dat <- sample_hazard_data(n = 50, seed = 1)
  obj <- hv_hazard(dat)
  expect_null(obj$tables$empirical)
  expect_null(obj$tables$reference)
})

# ============================================================================
# hv_hazard — plot() return type
# ============================================================================

test_that("plot.hv_hazard returns a ggplot", {
  dat <- sample_hazard_data(n = 50, seed = 1)
  p   <- plot(hv_hazard(dat))
  expect_s3_class(p, "ggplot")
})

test_that("plot.hv_hazard with estimate_col='hazard' returns a ggplot", {
  dat <- sample_hazard_data(n = 50, seed = 1)
  p   <- plot(hv_hazard(dat, estimate_col = "hazard"))
  expect_s3_class(p, "ggplot")
})

test_that("plot.hv_hazard with estimate_col='cumhaz' returns a ggplot", {
  dat <- sample_hazard_data(n = 50, seed = 1)
  p   <- plot(hv_hazard(dat, estimate_col = "cumhaz"))
  expect_s3_class(p, "ggplot")
})

test_that("plot.hv_hazard is composable with + operator", {
  dat <- sample_hazard_data(n = 50, seed = 1)
  p   <- plot(hv_hazard(dat)) + ggplot2::labs(x = "Years", y = "Survival (%)")
  expect_s3_class(p, "ggplot")
  expect_equal(p$labels$x, "Years")
})

# ============================================================================
# hv_hazard — layer structure
# ============================================================================

test_that("plot.hv_hazard has a GeomLine layer", {
  dat   <- sample_hazard_data(n = 50, seed = 1)
  geoms <- sapply(plot(hv_hazard(dat))$layers, function(l) class(l$geom)[1])
  expect_true("GeomLine" %in% geoms)
})

test_that("plot.hv_hazard with CI cols has a GeomRibbon layer", {
  dat   <- sample_hazard_data(n = 50, seed = 1)
  geoms <- sapply(
    plot(hv_hazard(dat, lower_col = "surv_lower",
                    upper_col = "surv_upper"))$layers,
    function(l) class(l$geom)[1]
  )
  expect_true("GeomRibbon" %in% geoms)
})

test_that("plot.hv_hazard without CI has no GeomRibbon", {
  dat   <- sample_hazard_data(n = 50, seed = 1)
  geoms <- sapply(plot(hv_hazard(dat))$layers, function(l) class(l$geom)[1])
  expect_false("GeomRibbon" %in% geoms)
})

test_that("plot.hv_hazard with empirical overlay adds a GeomPoint layer", {
  dat <- sample_hazard_data(n = 50, seed = 1)
  emp <- sample_hazard_empirical(n = 50, seed = 1)
  p_no_emp   <- plot(hv_hazard(dat))
  p_with_emp <- plot(hv_hazard(dat, empirical = emp))
  expect_gt(length(p_with_emp$layers), length(p_no_emp$layers))
})

test_that("plot.hv_hazard with empirical error bars has a GeomErrorbar layer", {
  dat   <- sample_hazard_data(n = 50, seed = 1)
  emp   <- sample_hazard_empirical(n = 50, seed = 1)
  geoms <- sapply(
    plot(hv_hazard(dat,
                     empirical     = emp,
                     emp_lower_col = "lower",
                     emp_upper_col = "upper"))$layers,
    function(l) class(l$geom)[1]
  )
  expect_true("GeomPoint"    %in% geoms)
  expect_true("GeomErrorbar" %in% geoms)
})

test_that("plot.hv_hazard with reference life table adds extra GeomLine layer", {
  dat <- sample_hazard_data(n = 50, seed = 1)
  lt  <- sample_life_table(time_max = 10)
  p_no_ref   <- plot(hv_hazard(dat))
  p_with_ref <- plot(hv_hazard(dat, reference = lt,
                                  ref_estimate_col = "survival",
                                  ref_group_col    = "group"))
  expect_gt(length(p_with_ref$layers), length(p_no_ref$layers))
})

# ============================================================================
# hv_hazard — multi-group
# ============================================================================

test_that("hv_hazard accepts group_col and plot() returns a ggplot", {
  dat <- sample_hazard_data(
    n = 100, groups = c("Control" = 1.0, "Treated" = 0.7), seed = 1
  )
  obj <- hv_hazard(dat, group_col = "group")
  expect_equal(obj$meta$group_col, "group")
  expect_s3_class(plot(obj), "ggplot")
})

test_that("plot.hv_hazard multi-group mapping differs from single-group", {
  dat_single <- sample_hazard_data(n = 50, seed = 1)
  dat_multi  <- sample_hazard_data(
    n = 50, groups = c("A" = 1.0, "B" = 0.8), seed = 1
  )
  p_single <- plot(hv_hazard(dat_single))
  p_multi  <- plot(hv_hazard(dat_multi, group_col = "group"))
  expect_false(identical(p_single$mapping, p_multi$mapping))
})

# ============================================================================
# hv_hazard — non-default column names
# ============================================================================

test_that("hv_hazard works with non-default x_col", {
  dat      <- sample_hazard_data(n = 50, seed = 1)
  dat$year <- dat$time
  expect_s3_class(plot(hv_hazard(dat, x_col = "year")), "ggplot")
})

test_that("hv_hazard works with non-default estimate_col", {
  dat     <- sample_hazard_data(n = 50, seed = 1)
  dat$est <- dat$survival
  expect_s3_class(plot(hv_hazard(dat, estimate_col = "est")), "ggplot")
})

# ============================================================================
# hv_hazard — input validation (errors thrown in constructor)
# ============================================================================

test_that("hv_hazard errors when curve_data is not a data frame", {
  expect_error(
    hv_hazard(list(time = 1:5, survival = 1:5)),
    "data frame"
  )
})

test_that("hv_hazard errors when x_col is absent from curve_data", {
  dat <- sample_hazard_data(n = 50, seed = 1)
  expect_error(hv_hazard(dat, x_col = "nonexistent"), "column")
})

test_that("hv_hazard errors when estimate_col is absent from curve_data", {
  dat <- sample_hazard_data(n = 50, seed = 1)
  expect_error(hv_hazard(dat, estimate_col = "nonexistent"), "column")
})

test_that("hv_hazard errors when lower_col is absent from curve_data", {
  dat <- sample_hazard_data(n = 50, seed = 1)
  expect_error(hv_hazard(dat, lower_col = "nonexistent"), "not found")
})

test_that("hv_hazard errors when group_col is absent from curve_data", {
  dat <- sample_hazard_data(n = 50, seed = 1)
  expect_error(hv_hazard(dat, group_col = "nonexistent"), "not found")
})

test_that("hv_hazard handles empty data frame gracefully", {
  # Column-presence checks pass; ggplot renders an empty plot without error.
  empty_df <- data.frame(time = numeric(0), survival = numeric(0))
  obj <- hv_hazard(empty_df)
  expect_s3_class(plot(obj), "ggplot")
})

# ============================================================================
# hv_survival_difference — constructor return type and slots
# ============================================================================

test_that("hv_survival_difference returns an hv_data object", {
  diff_dat <- sample_survival_difference_data(
    groups = c("Control" = 1.0, "Treatment" = 0.70), seed = 1
  )
  obj <- hv_survival_difference(diff_dat)
  expect_true(is_hv_data(obj))
  expect_s3_class(obj, "hv_survival_difference")
  expect_s3_class(obj, "hv_data")
})

test_that("hv_survival_difference stores data in $data and col names in $meta", {
  diff_dat <- sample_survival_difference_data(
    groups = c("Control" = 1.0, "Treatment" = 0.70), seed = 1
  )
  obj <- hv_survival_difference(diff_dat,
    lower_col = "diff_lower", upper_col = "diff_upper"
  )
  expect_identical(obj$data, diff_dat)
  expect_equal(obj$meta$estimate_col, "difference")
  expect_equal(obj$meta$lower_col,    "diff_lower")
  expect_equal(obj$meta$upper_col,    "diff_upper")
})

test_that("hv_survival_difference $tables is empty list", {
  diff_dat <- sample_survival_difference_data(seed = 1)
  obj <- hv_survival_difference(diff_dat)
  expect_identical(obj$tables, list())
})

# ============================================================================
# hv_survival_difference — plot() return type and layers
# ============================================================================

test_that("plot.hv_survival_difference returns a ggplot", {
  diff_dat <- sample_survival_difference_data(seed = 1)
  expect_s3_class(plot(hv_survival_difference(diff_dat)), "ggplot")
})

test_that("plot.hv_survival_difference has a GeomLine layer", {
  diff_dat <- sample_survival_difference_data(seed = 1)
  geoms <- sapply(
    plot(hv_survival_difference(diff_dat))$layers,
    function(l) class(l$geom)[1]
  )
  expect_true("GeomLine" %in% geoms)
})

test_that("plot.hv_survival_difference with CI cols has a GeomRibbon layer", {
  diff_dat <- sample_survival_difference_data(seed = 1)
  geoms <- sapply(
    plot(hv_survival_difference(diff_dat,
                                   lower_col = "diff_lower",
                                   upper_col = "diff_upper"))$layers,
    function(l) class(l$geom)[1]
  )
  expect_true("GeomRibbon" %in% geoms)
})

test_that("plot.hv_survival_difference without CI has no GeomRibbon", {
  diff_dat <- sample_survival_difference_data(seed = 1)
  geoms <- sapply(
    plot(hv_survival_difference(diff_dat))$layers,
    function(l) class(l$geom)[1]
  )
  expect_false("GeomRibbon" %in% geoms)
})

test_that("plot.hv_survival_difference is composable with + operator", {
  diff_dat <- sample_survival_difference_data(seed = 1)
  p <- plot(hv_survival_difference(diff_dat)) +
    ggplot2::labs(x = "Years", y = "Difference (%)")
  expect_equal(p$labels$x, "Years")
})

# ============================================================================
# hv_survival_difference — multi-group
# ============================================================================

test_that("hv_survival_difference accepts group_col", {
  d1 <- sample_survival_difference_data(
    groups = c("Medical Mgmt" = 1.0, "TF-TAVR" = 0.70), seed = 1
  )
  d1$comparison <- "TF-TAVR vs Medical"
  d2 <- sample_survival_difference_data(
    groups = c("TA-TAVR" = 0.90, "TF-TAVR" = 0.70), seed = 2
  )
  d2$comparison <- "TF-TAVR vs TA-TAVR"
  dall <- rbind(d1, d2)

  obj <- hv_survival_difference(dall, group_col = "comparison")
  expect_equal(obj$meta$group_col, "comparison")
  expect_s3_class(plot(obj), "ggplot")
})

# ============================================================================
# hv_survival_difference — input validation
# ============================================================================

test_that("hv_survival_difference errors when diff_data is not a data frame", {
  expect_error(
    hv_survival_difference(list(time = 1:5, difference = 1:5)),
    "data frame"
  )
})

test_that("hv_survival_difference errors when x_col is absent", {
  diff_dat <- sample_survival_difference_data(seed = 1)
  expect_error(
    hv_survival_difference(diff_dat, x_col = "nonexistent"),
    "not found"
  )
})

test_that("hv_survival_difference errors when estimate_col is absent", {
  diff_dat <- sample_survival_difference_data(seed = 1)
  expect_error(
    hv_survival_difference(diff_dat, estimate_col = "nonexistent"),
    "not found"
  )
})

test_that("hv_survival_difference errors when lower_col is absent", {
  diff_dat <- sample_survival_difference_data(seed = 1)
  expect_error(
    hv_survival_difference(diff_dat, lower_col = "nonexistent"),
    "not found"
  )
})

# ============================================================================
# hv_nnt — constructor return type and slots
# ============================================================================

test_that("hv_nnt returns an hv_data object", {
  nnt_dat <- sample_nnt_data(
    groups = c("SVG" = 1.0, "ITA" = 0.75), seed = 1
  )
  obj <- hv_nnt(nnt_dat)
  expect_true(is_hv_data(obj))
  expect_s3_class(obj, "hv_nnt")
  expect_s3_class(obj, "hv_data")
})

test_that("hv_nnt stores column mappings in $meta", {
  nnt_dat <- sample_nnt_data(seed = 1)
  obj <- hv_nnt(nnt_dat,
                  lower_col = "nnt_lower", upper_col = "nnt_upper")
  expect_equal(obj$meta$x_col,        "time")
  expect_equal(obj$meta$estimate_col, "nnt")
  expect_equal(obj$meta$lower_col,    "nnt_lower")
  expect_equal(obj$meta$upper_col,    "nnt_upper")
})

test_that("hv_nnt stores na_rm in $meta", {
  nnt_dat <- sample_nnt_data(seed = 1)
  obj_rm  <- hv_nnt(nnt_dat, na_rm = TRUE)
  obj_no  <- hv_nnt(nnt_dat, na_rm = FALSE)
  expect_true(obj_rm$meta$na_rm)
  expect_false(obj_no$meta$na_rm)
})

test_that("hv_nnt with na_rm=TRUE removes NA rows at construction time", {
  nnt_dat <- sample_nnt_data(seed = 1)
  nnt_dat$nnt[1:5] <- NA   # inject 5 NAs (some may already be NA)
  n_na <- sum(is.na(nnt_dat$nnt))
  obj_rm <- hv_nnt(nnt_dat, na_rm = TRUE)
  obj_no <- hv_nnt(nnt_dat, na_rm = FALSE)
  expect_equal(nrow(obj_rm$data), nrow(nnt_dat) - n_na)
  expect_equal(nrow(obj_no$data), nrow(nnt_dat))
})

test_that("hv_nnt $tables is empty list", {
  nnt_dat <- sample_nnt_data(seed = 1)
  obj <- hv_nnt(nnt_dat)
  expect_identical(obj$tables, list())
})

# ============================================================================
# hv_nnt — plot() return type and layers
# ============================================================================

test_that("plot.hv_nnt returns a ggplot", {
  nnt_dat <- sample_nnt_data(seed = 1)
  expect_s3_class(plot(hv_nnt(nnt_dat)), "ggplot")
})

test_that("plot.hv_nnt has a GeomLine layer", {
  nnt_dat <- sample_nnt_data(seed = 1)
  geoms <- sapply(
    plot(hv_nnt(nnt_dat))$layers,
    function(l) class(l$geom)[1]
  )
  expect_true("GeomLine" %in% geoms)
})

test_that("plot.hv_nnt with CI cols has a GeomRibbon layer", {
  nnt_dat <- sample_nnt_data(seed = 1)
  geoms <- sapply(
    plot(hv_nnt(nnt_dat,
                  lower_col = "nnt_lower",
                  upper_col = "nnt_upper"))$layers,
    function(l) class(l$geom)[1]
  )
  expect_true("GeomRibbon" %in% geoms)
})

test_that("plot.hv_nnt without CI has no GeomRibbon", {
  nnt_dat <- sample_nnt_data(seed = 1)
  geoms <- sapply(
    plot(hv_nnt(nnt_dat))$layers,
    function(l) class(l$geom)[1]
  )
  expect_false("GeomRibbon" %in% geoms)
})

test_that("plot.hv_nnt with arr estimate_col returns a ggplot", {
  nnt_dat <- sample_nnt_data(seed = 1)
  p <- plot(hv_nnt(nnt_dat, estimate_col = "arr", na_rm = FALSE))
  expect_s3_class(p, "ggplot")
})

# ============================================================================
# hv_nnt — group_col support
# ============================================================================

test_that("hv_nnt accepts group_col and plot() renders correctly", {
  d1 <- sample_nnt_data(groups = c("SVG" = 1.0, "ITA" = 0.75), seed = 1)
  d1$comparison <- "ITA vs SVG"
  d2 <- sample_nnt_data(groups = c("SVG" = 1.0, "ITA2" = 0.80), seed = 2)
  d2$comparison <- "ITA2 vs SVG"
  dall <- rbind(d1, d2)

  obj <- hv_nnt(dall, group_col = "comparison")
  expect_equal(obj$meta$group_col, "comparison")
  expect_s3_class(plot(obj), "ggplot")
})

test_that("plot.hv_nnt multi-group mapping differs from single-group", {
  nnt_single <- sample_nnt_data(seed = 1)
  d1 <- sample_nnt_data(groups = c("SVG" = 1.0, "ITA" = 0.75), seed = 1)
  d1$comparison <- "A"
  d2 <- sample_nnt_data(groups = c("SVG" = 1.0, "ITA" = 0.80), seed = 2)
  d2$comparison <- "B"
  dall <- rbind(d1, d2)

  p_single <- plot(hv_nnt(nnt_single))
  p_multi  <- plot(hv_nnt(dall, group_col = "comparison"))
  expect_false(identical(p_single$mapping, p_multi$mapping))
})

# ============================================================================
# hv_nnt — input validation
# ============================================================================

test_that("hv_nnt errors when nnt_data is not a data frame", {
  expect_error(
    hv_nnt(list(time = 1:5, nnt = 1:5)),
    "data frame"
  )
})

test_that("hv_nnt errors when x_col is absent", {
  nnt_dat <- sample_nnt_data(seed = 1)
  expect_error(hv_nnt(nnt_dat, x_col = "nonexistent"), "not found")
})

test_that("hv_nnt errors when estimate_col is absent", {
  nnt_dat <- sample_nnt_data(seed = 1)
  expect_error(hv_nnt(nnt_dat, estimate_col = "nonexistent"), "not found")
})

test_that("hv_nnt errors when lower_col is absent", {
  nnt_dat <- sample_nnt_data(seed = 1)
  expect_error(hv_nnt(nnt_dat, lower_col = "nonexistent"), "not found")
})

test_that("hv_nnt errors when group_col is absent", {
  nnt_dat <- sample_nnt_data(seed = 1)
  expect_error(hv_nnt(nnt_dat, group_col = "nonexistent"), "not found")
})

# ============================================================================
# hv_hazard — empirical / reference validation (fix #13)
# ============================================================================

test_that("hv_hazard errors when empirical is not a data frame", {
  dat <- sample_hazard_data(n = 50, seed = 1)
  expect_error(hv_hazard(dat, empirical = "not_a_df"), "data frame")
})

test_that("hv_hazard errors when empirical is missing emp_x_col", {
  dat <- sample_hazard_data(n = 50, seed = 1)
  bad_emp <- data.frame(wrong = 1:3, estimate = runif(3))
  expect_error(hv_hazard(dat, empirical = bad_emp), "not found|Missing")
})

test_that("hv_hazard errors when empirical is missing emp_estimate_col", {
  dat <- sample_hazard_data(n = 50, seed = 1)
  bad_emp <- data.frame(time = 1:3, wrong = runif(3))
  expect_error(hv_hazard(dat, empirical = bad_emp), "not found|Missing")
})

test_that("hv_hazard errors when reference is not a data frame", {
  dat <- sample_hazard_data(n = 50, seed = 1)
  expect_error(hv_hazard(dat, reference = "not_a_df"), "data frame")
})

test_that("hv_hazard errors when reference is missing ref_x_col", {
  dat <- sample_hazard_data(n = 50, seed = 1)
  bad_ref <- data.frame(wrong = 1:3, survival = runif(3))
  expect_error(hv_hazard(dat, reference = bad_ref), "not found|Missing")
})

test_that("hv_hazard errors when reference is missing ref_estimate_col", {
  dat <- sample_hazard_data(n = 50, seed = 1)
  bad_ref <- data.frame(time = 1:3, wrong = runif(3))
  expect_error(
    hv_hazard(dat, reference = bad_ref, ref_estimate_col = "nonexistent"),
    "not found|Missing"
  )
})

# ============================================================================
# print() output tests (fix #14)
# ============================================================================

test_that("print.hv_hazard produces expected output", {
  dat <- sample_hazard_data(n = 50, seed = 1)
  obj <- hv_hazard(dat)
  expect_output(print(obj), "hv_hazard")
})

test_that("print.hv_survival_difference produces expected output", {
  diff_dat <- sample_survival_difference_data(seed = 1)
  obj <- hv_survival_difference(diff_dat)
  expect_output(print(obj), "hv_survival_difference")
})

test_that("print.hv_nnt produces expected output", {
  nnt_dat <- sample_nnt_data(seed = 1)
  obj <- hv_nnt(nnt_dat)
  expect_output(print(obj), "hv_nnt")
})

test_that("print.hv_hazard shows CI info when present", {
  dat <- sample_hazard_data(n = 50, seed = 1)
  obj <- hv_hazard(dat, lower_col = "surv_lower", upper_col = "surv_upper")
  expect_output(print(obj), "CI")
})

test_that("print.hv_nnt shows na_rm in output", {
  nnt_dat <- sample_nnt_data(seed = 1)
  obj <- hv_nnt(nnt_dat, na_rm = TRUE)
  expect_output(print(obj), "na_rm")
})

# ============================================================================
# as.data.frame and meta consistency (fix #11 / #15 verification)
# ============================================================================

test_that("hv_hazard stores $data as plain data.frame", {
  dat <- sample_hazard_data(n = 50, seed = 1)
  obj <- hv_hazard(dat)
  expect_true(is.data.frame(obj$data))
  expect_true(inherits(obj$data, "data.frame"))
})

test_that("hv_hazard $meta includes has_ci and n_obs", {
  dat <- sample_hazard_data(n = 50, seed = 1)
  obj <- hv_hazard(dat, lower_col = "surv_lower", upper_col = "surv_upper")
  expect_true(obj$meta$has_ci)
  expect_equal(obj$meta$n_obs, nrow(dat))
})

test_that("hv_survival_difference $meta includes has_ci and n_obs", {
  diff_dat <- sample_survival_difference_data(seed = 1)
  obj <- hv_survival_difference(diff_dat,
    lower_col = "diff_lower", upper_col = "diff_upper"
  )
  expect_true(obj$meta$has_ci)
  expect_equal(obj$meta$n_obs, nrow(diff_dat))
})

test_that("hv_nnt $meta includes has_ci and n_obs", {
  nnt_dat <- sample_nnt_data(seed = 1)
  obj <- hv_nnt(nnt_dat,
    lower_col = "nnt_lower", upper_col = "nnt_upper"
  )
  expect_true(obj$meta$has_ci)
  # n_obs reflects pre-na_rm count
  expect_true(obj$meta$n_obs > 0)
})
