# tests/testthat/test_new_plots.R
#
# Smoke / property tests for plot functions added in v1.2+:
#   sample_upset_data, upset_plot
#   sample_alluvial_data, alluvial_plot
#   sample_spaghetti_data, spaghetti_plot
#   sample_trends_data, trends_plot
#   sample_longitudinal_counts_data, longitudinal_counts_plot
# hvti_theme("light_ppt") dispatch + theme_light_ppt alias.
#
# Every assertion tests a distinct property of a distinct object.
# No test compares a variable to itself (assert A == A).

library(testthat)
library(ggplot2)

# ============================================================================
# sample_upset_data
# ============================================================================

test_that("sample_upset_data returns a data frame", {
  df <- sample_upset_data(n = 100, seed = 1)
  expect_true(is.data.frame(df))
})

test_that("sample_upset_data returns exactly n rows", {
  df <- sample_upset_data(n = 200, seed = 1)
  expect_equal(nrow(df), 200)
})

test_that("sample_upset_data has all required logical columns", {
  expected_cols <- c("AV_Replacement", "AV_Repair", "MV_Replacement",
                     "MV_Repair", "TV_Repair", "Aorta", "CABG")
  df <- sample_upset_data(n = 100, seed = 1)
  expect_true(all(expected_cols %in% names(df)))
  # All set columns must be logical — a type change would break ComplexUpset
  are_logical <- sapply(df[expected_cols], is.logical)
  expect_true(all(are_logical))
})

test_that("sample_upset_data columns contain no missing values", {
  df <- sample_upset_data(n = 300, seed = 42)
  has_na <- sapply(df, anyNA)
  expect_false(any(has_na))
})

test_that("sample_upset_data CABG has both TRUE and FALSE values", {
  # CABG is primary (~30%) or concomitant (~12%); should not be all-TRUE or all-FALSE
  df <- sample_upset_data(n = 500, seed = 42)
  expect_gt(sum(df$CABG), 0)
  expect_gt(sum(!df$CABG), 0)
})

test_that("sample_upset_data is reproducible with same seed", {
  df1 <- sample_upset_data(n = 150, seed = 7)
  df2 <- sample_upset_data(n = 150, seed = 7)
  expect_identical(df1, df2)
})

test_that("sample_upset_data differs across seeds", {
  df1 <- sample_upset_data(n = 200, seed = 1)
  df2 <- sample_upset_data(n = 200, seed = 2)
  expect_false(identical(df1, df2))
})

# ============================================================================
# upset_plot
# ============================================================================

sets <- c("AV_Replacement", "AV_Repair", "MV_Replacement",
          "MV_Repair", "TV_Repair", "Aorta", "CABG")

test_that("upset_plot returns without error", {
  dta <- sample_upset_data(n = 200, seed = 1)
  expect_no_error(upset_plot(dta, intersect = sets))
})

test_that("upset_plot errors when data is not a data frame", {
  expect_error(upset_plot(list(), intersect = sets), "data frame")
})

test_that("upset_plot errors when intersect has only one element", {
  dta <- sample_upset_data(n = 100, seed = 1)
  expect_error(upset_plot(dta, intersect = "AV_Replacement"), "at least 2")
})

test_that("upset_plot errors when intersect names are absent from data", {
  dta <- sample_upset_data(n = 100, seed = 1)
  expect_error(
    upset_plot(dta, intersect = c("AV_Replacement", "DoesNotExist")),
    "not columns"
  )
})


# ============================================================================
# sample_alluvial_data
# ============================================================================

test_that("sample_alluvial_data returns a data frame", {
  df <- sample_alluvial_data(n = 100, seed = 1)
  expect_true(is.data.frame(df))
})

test_that("sample_alluvial_data has required columns", {
  df <- sample_alluvial_data()
  expect_true(all(c("pre_ar", "procedure", "post_ar", "freq") %in% names(df)))
})

test_that("sample_alluvial_data freq is a positive integer", {
  df <- sample_alluvial_data(n = 300, seed = 1)
  expect_true(is.integer(df$freq))
  expect_true(all(df$freq > 0L))
})

test_that("sample_alluvial_data freq sums to n (no zero rows retained)", {
  df <- sample_alluvial_data(n = 300, seed = 42)
  expect_equal(sum(df$freq), 300L)
})

test_that("sample_alluvial_data pre_ar is a factor with correct levels", {
  df <- sample_alluvial_data()
  expect_true(is.factor(df$pre_ar))
  expect_equal(levels(df$pre_ar), c("None", "Mild", "Moderate", "Severe"))
})

test_that("sample_alluvial_data procedure is a factor with correct levels", {
  df <- sample_alluvial_data()
  expect_true(is.factor(df$procedure))
  expect_equal(levels(df$procedure), c("TAVR", "Repair", "Replacement"))
})

test_that("sample_alluvial_data is reproducible with same seed", {
  df1 <- sample_alluvial_data(n = 200, seed = 5)
  df2 <- sample_alluvial_data(n = 200, seed = 5)
  expect_identical(df1, df2)
})

test_that("sample_alluvial_data differs across seeds", {
  df1 <- sample_alluvial_data(n = 200, seed = 1)
  df2 <- sample_alluvial_data(n = 200, seed = 2)
  expect_false(identical(df1, df2))
})

# ============================================================================
# alluvial_plot
# ============================================================================

test_that("alluvial_plot returns a ggplot with three axes", {
  dta  <- sample_alluvial_data(n = 150, seed = 1)
  axes <- c("pre_ar", "procedure", "post_ar")
  p    <- alluvial_plot(dta, axes = axes, y_col = "freq")
  expect_s3_class(p, "ggplot")
})

test_that("alluvial_plot works with only two axes", {
  dta <- sample_alluvial_data(n = 100, seed = 1)
  p   <- alluvial_plot(dta, axes = c("pre_ar", "post_ar"), y_col = "freq")
  expect_s3_class(p, "ggplot")
})

test_that("alluvial_plot has a geom_text layer when show_labels=TRUE", {
  dta <- sample_alluvial_data(n = 100, seed = 1)
  p   <- alluvial_plot(dta, axes = c("pre_ar", "post_ar"),
                     y_col = "freq", show_labels = TRUE)
  geoms <- sapply(p$layers, function(l) class(l$geom)[1])
  expect_true("GeomText" %in% geoms)
})

test_that("alluvial_plot omits geom_text when show_labels=FALSE", {
  dta <- sample_alluvial_data(n = 100, seed = 1)
  p   <- alluvial_plot(dta, axes = c("pre_ar", "post_ar"),
                     y_col = "freq", show_labels = FALSE)
  geoms <- sapply(p$layers, function(l) class(l$geom)[1])
  expect_false("GeomText" %in% geoms)
})

test_that("alluvial_plot with fill_col returns a ggplot", {
  dta  <- sample_alluvial_data(n = 150, seed = 1)
  axes <- c("pre_ar", "procedure", "post_ar")
  p    <- alluvial_plot(dta, axes = axes, y_col = "freq", fill_col = "pre_ar")
  expect_s3_class(p, "ggplot")
})

test_that("alluvial_plot errors when data is not a data frame", {
  expect_error(alluvial_plot(list(), axes = c("a", "b")), "data frame")
})

test_that("alluvial_plot errors when axes has fewer than two elements", {
  dta <- sample_alluvial_data(n = 100, seed = 1)
  expect_error(alluvial_plot(dta, axes = "pre_ar"), "at least 2")
})

test_that("alluvial_plot errors when an axis name is absent from data", {
  dta <- sample_alluvial_data(n = 100, seed = 1)
  expect_error(
    alluvial_plot(dta, axes = c("pre_ar", "nonexistent")),
    "not columns"
  )
})

test_that("alluvial_plot errors when y_col is absent from data", {
  dta <- sample_alluvial_data(n = 100, seed = 1)
  expect_error(
    alluvial_plot(dta, axes = c("pre_ar", "post_ar"), y_col = "missing_col"),
    "not a column"
  )
})

test_that("alluvial_plot errors when alpha is out of [0, 1]", {
  dta <- sample_alluvial_data(n = 100, seed = 1)
  expect_error(
    alluvial_plot(dta, axes = c("pre_ar", "post_ar"), y_col = "freq", alpha = 1.5),
    "alpha"
  )
})


# ============================================================================
# sample_spaghetti_data
# ============================================================================

test_that("sample_spaghetti_data returns a data frame", {
  df <- sample_spaghetti_data(n_patients = 30, seed = 1)
  expect_true(is.data.frame(df))
})

test_that("sample_spaghetti_data has required columns", {
  df <- sample_spaghetti_data(n_patients = 30, seed = 1)
  expect_true(all(c("id", "time", "value", "group") %in% names(df)))
})

test_that("sample_spaghetti_data has exactly n_patients unique ids", {
  df <- sample_spaghetti_data(n_patients = 50, seed = 1)
  expect_equal(length(unique(df$id)), 50L)
})

test_that("sample_spaghetti_data time is non-negative", {
  df <- sample_spaghetti_data(n_patients = 100, seed = 5)
  expect_true(all(df$time >= 0))
})

test_that("sample_spaghetti_data value is non-negative (pmax clamp)", {
  df <- sample_spaghetti_data(n_patients = 200, seed = 7)
  expect_true(all(df$value >= 0))
})

test_that("sample_spaghetti_data group is a factor", {
  df <- sample_spaghetti_data(n_patients = 50, seed = 1)
  expect_true(is.factor(df$group))
})

test_that("sample_spaghetti_data group levels match groups argument", {
  df <- sample_spaghetti_data(groups = c(A = 0.4, B = 0.6), seed = 1)
  expect_equal(levels(df$group), c("A", "B"))
})

test_that("sample_spaghetti_data each patient has at least 2 observations", {
  df <- sample_spaghetti_data(n_patients = 30, seed = 1)
  obs_per_patient <- tapply(df$id, df$id, length)
  expect_true(all(obs_per_patient >= 2L))
})

test_that("sample_spaghetti_data is reproducible with same seed", {
  df1 <- sample_spaghetti_data(n_patients = 50, seed = 3)
  df2 <- sample_spaghetti_data(n_patients = 50, seed = 3)
  expect_identical(df1, df2)
})

test_that("sample_spaghetti_data differs across seeds", {
  df1 <- sample_spaghetti_data(n_patients = 100, seed = 1)
  df2 <- sample_spaghetti_data(n_patients = 100, seed = 2)
  expect_false(identical(df1, df2))
})

# ============================================================================
# spaghetti_plot
# ============================================================================

test_that("spaghetti_plot returns a ggplot (unstratified)", {
  dta <- sample_spaghetti_data(n_patients = 40, seed = 1)
  p   <- spaghetti_plot(dta)
  expect_s3_class(p, "ggplot")
})

test_that("spaghetti_plot has a geom_line layer", {
  dta   <- sample_spaghetti_data(n_patients = 40, seed = 1)
  p     <- spaghetti_plot(dta)
  geoms <- sapply(p$layers, function(l) class(l$geom)[1])
  expect_true("GeomLine" %in% geoms)
})

test_that("spaghetti_plot with colour_col returns a ggplot", {
  dta <- sample_spaghetti_data(n_patients = 40, seed = 1)
  p   <- spaghetti_plot(dta, colour_col = "group")
  expect_s3_class(p, "ggplot")
})

test_that("spaghetti_plot add_smooth=TRUE adds an extra layer vs add_smooth=FALSE", {
  dta      <- sample_spaghetti_data(n_patients = 40, seed = 1)
  p_plain  <- spaghetti_plot(dta)
  p_smooth <- spaghetti_plot(dta, add_smooth = TRUE)
  expect_gt(length(p_smooth$layers), length(p_plain$layers))
})

test_that("spaghetti_plot add_smooth=TRUE has a GeomSmooth layer", {
  dta   <- sample_spaghetti_data(n_patients = 40, seed = 1)
  p     <- spaghetti_plot(dta, add_smooth = TRUE)
  geoms <- sapply(p$layers, function(l) class(l$geom)[1])
  expect_true("GeomSmooth" %in% geoms)
})

test_that("spaghetti_plot y_labels adds a y scale vs default", {
  dta <- sample_spaghetti_data(n_patients = 40, seed = 1)
  dta$value <- round(pmin(3, pmax(0, dta$value / 12)))
  labels    <- c(None = 0, Mild = 1, Moderate = 2, Severe = 3)
  p_default <- spaghetti_plot(dta)
  p_labeled <- spaghetti_plot(dta, y_labels = labels)
  # y_labels adds scale_y_continuous: labeled plot must have more scales
  expect_gt(
    length(p_labeled$scales$scales),
    length(p_default$scales$scales)
  )
})

test_that("spaghetti_plot errors when x_col is absent from data", {
  dta <- sample_spaghetti_data(n_patients = 30, seed = 1)
  expect_error(spaghetti_plot(dta, x_col = "nonexistent"), "not found")
})

test_that("spaghetti_plot errors when colour_col is absent from data", {
  dta <- sample_spaghetti_data(n_patients = 30, seed = 1)
  expect_error(spaghetti_plot(dta, colour_col = "nonexistent"), "not found")
})

test_that("spaghetti_plot errors when alpha is out of [0, 1]", {
  dta <- sample_spaghetti_data(n_patients = 30, seed = 1)
  expect_error(spaghetti_plot(dta, alpha = 2.0), "alpha")
})


# ============================================================================
# sample_trends_data
# ============================================================================

test_that("sample_trends_data returns a data frame", {
  df <- sample_trends_data(n = 100, seed = 1)
  expect_true(is.data.frame(df))
})

test_that("sample_trends_data has required columns", {
  df <- sample_trends_data(n = 100, seed = 1)
  expect_true(all(c("year", "value", "group") %in% names(df)))
})

test_that("sample_trends_data returns exactly n rows", {
  df <- sample_trends_data(n = 250, seed = 1)
  expect_equal(nrow(df), 250L)
})

test_that("sample_trends_data year falls within year_range", {
  df <- sample_trends_data(n = 200, year_range = c(2000L, 2015L), seed = 1)
  expect_true(all(df$year >= 2000L))
  expect_true(all(df$year <= 2015L))
})

test_that("sample_trends_data group is a factor", {
  df <- sample_trends_data(n = 100, seed = 1)
  expect_true(is.factor(df$group))
})

test_that("sample_trends_data group levels match the groups argument", {
  grps <- c("Low", "High")
  df   <- sample_trends_data(n = 200, groups = grps, seed = 1)
  expect_equal(levels(df$group), grps)
})

test_that("sample_trends_data is reproducible with same seed", {
  df1 <- sample_trends_data(n = 100, seed = 9)
  df2 <- sample_trends_data(n = 100, seed = 9)
  expect_identical(df1, df2)
})

test_that("sample_trends_data differs across seeds", {
  df1 <- sample_trends_data(n = 100, seed = 1)
  df2 <- sample_trends_data(n = 100, seed = 2)
  expect_false(identical(df1, df2))
})

# ============================================================================
# trends_plot
# ============================================================================

test_that("trends_plot returns a ggplot (multi-group)", {
  dta <- sample_trends_data(n = 200, seed = 1)
  p   <- trends_plot(dta)
  expect_s3_class(p, "ggplot")
})

test_that("trends_plot has both geom_smooth and geom_point layers", {
  dta   <- sample_trends_data(n = 200, seed = 1)
  p     <- trends_plot(dta)
  geoms <- sapply(p$layers, function(l) class(l$geom)[1])
  expect_true("GeomSmooth" %in% geoms)
  expect_true("GeomPoint"  %in% geoms)
})

test_that("trends_plot works with group_col=NULL (single group)", {
  dta <- sample_trends_data(n = 200, seed = 1)
  one <- dta[dta$group == "Group I", ]
  p   <- trends_plot(one, group_col = NULL)
  expect_s3_class(p, "ggplot")
})

test_that("trends_plot summary_fn='median' returns a ggplot", {
  dta <- sample_trends_data(n = 200, seed = 1)
  p   <- trends_plot(dta, summary_fn = "median")
  expect_s3_class(p, "ggplot")
})

test_that("trends_plot errors when x_col is absent from data", {
  dta <- sample_trends_data(n = 100, seed = 1)
  expect_error(trends_plot(dta, x_col = "nonexistent"), "not found")
})

test_that("trends_plot errors when y_col is absent from data", {
  dta <- sample_trends_data(n = 100, seed = 1)
  expect_error(trends_plot(dta, y_col = "nonexistent"), "not found")
})

test_that("trends_plot errors when group_col is absent from data", {
  dta <- sample_trends_data(n = 100, seed = 1)
  expect_error(trends_plot(dta, group_col = "nonexistent"), "not found")
})


# ============================================================================
# sample_longitudinal_counts_data
# ============================================================================

test_that("sample_longitudinal_counts_data returns a data frame", {
  df <- sample_longitudinal_counts_data(n_patients = 50, seed = 1)
  expect_true(is.data.frame(df))
})

test_that("sample_longitudinal_counts_data has required columns", {
  df <- sample_longitudinal_counts_data(n_patients = 50, seed = 1)
  expect_true(all(c("time_label", "series", "count") %in% names(df)))
})

test_that("sample_longitudinal_counts_data has 14 rows (7 windows x 2 series)", {
  df <- sample_longitudinal_counts_data(n_patients = 100, seed = 1)
  expect_equal(nrow(df), 14L)
})

test_that("sample_longitudinal_counts_data series contains Patients and Measurements", {
  df <- sample_longitudinal_counts_data(n_patients = 50, seed = 1)
  expect_setequal(unique(df$series), c("Patients", "Measurements"))
})

test_that("sample_longitudinal_counts_data count is a non-negative integer", {
  df <- sample_longitudinal_counts_data(n_patients = 100, seed = 1)
  expect_true(is.integer(df$count))
  # Empty time windows produce NA; non-NA counts must be non-negative
  non_na <- df$count[!is.na(df$count)]
  expect_true(all(non_na >= 0L))
})

test_that("sample_longitudinal_counts_data Patients count <= n_patients", {
  n  <- 75L
  df <- sample_longitudinal_counts_data(n_patients = n, seed = 1)
  pat_rows <- df[df$series == "Patients", ]
  # NA entries are empty windows — only check non-missing values
  non_na <- pat_rows$count[!is.na(pat_rows$count)]
  expect_true(all(non_na <= n))
})

test_that("sample_longitudinal_counts_data is reproducible with same seed", {
  df1 <- sample_longitudinal_counts_data(n_patients = 100, seed = 1)
  df2 <- sample_longitudinal_counts_data(n_patients = 100, seed = 1)
  expect_identical(df1, df2)
})

test_that("sample_longitudinal_counts_data differs across seeds", {
  df1 <- sample_longitudinal_counts_data(n_patients = 100, seed = 1)
  df2 <- sample_longitudinal_counts_data(n_patients = 100, seed = 99)
  expect_false(identical(df1, df2))
})

# ============================================================================
# longitudinal_counts_plot
# ============================================================================

test_that("longitudinal_counts_plot returns a ggplot", {
  dta <- sample_longitudinal_counts_data(n_patients = 60, seed = 1)
  expect_s3_class(longitudinal_counts_plot(dta), "ggplot")
})

test_that("longitudinal_counts_plot is composable with + operator", {
  dta <- sample_longitudinal_counts_data(n_patients = 60, seed = 1)
  p   <- longitudinal_counts_plot(dta) + ggplot2::labs(y = "Count")
  expect_s3_class(p, "ggplot")
})

test_that("longitudinal_counts_plot has a GeomBar layer", {
  dta   <- sample_longitudinal_counts_data(n_patients = 60, seed = 1)
  geoms <- sapply(longitudinal_counts_plot(dta)$layers, function(l) class(l$geom)[1])
  expect_true("GeomBar" %in% geoms)
})

test_that("longitudinal_counts_plot position='stack' returns a ggplot", {
  dta <- sample_longitudinal_counts_data(n_patients = 60, seed = 1)
  expect_s3_class(longitudinal_counts_plot(dta, position = "stack"), "ggplot")
})

test_that("longitudinal_counts_plot position='dodge' differs from 'stack'", {
  dta    <- sample_longitudinal_counts_data(n_patients = 60, seed = 1)
  p_d    <- longitudinal_counts_plot(dta, position = "dodge")
  p_s    <- longitudinal_counts_plot(dta, position = "stack")
  # The position argument changes how bars are drawn — the layer params differ
  expect_false(identical(p_d$layers[[1]]$position, p_s$layers[[1]]$position))
})

test_that("longitudinal_counts_plot errors when required column is absent", {
  dta <- sample_longitudinal_counts_data(n_patients = 60, seed = 1)
  expect_error(longitudinal_counts_plot(dta, x_col = "nonexistent"), "not found")
})

test_that("longitudinal_counts_plot errors on invalid position value", {
  dta <- sample_longitudinal_counts_data(n_patients = 60, seed = 1)
  expect_error(longitudinal_counts_plot(dta, position = "fill"), "dodge")
})


# ============================================================================
# longitudinal_counts_table
# ============================================================================

test_that("longitudinal_counts_table returns a ggplot", {
  dta <- sample_longitudinal_counts_data(n_patients = 60, seed = 1)
  expect_s3_class(longitudinal_counts_table(dta), "ggplot")
})

test_that("longitudinal_counts_table has a GeomText layer", {
  dta   <- sample_longitudinal_counts_data(n_patients = 60, seed = 1)
  geoms <- sapply(longitudinal_counts_table(dta)$layers, function(l) class(l$geom)[1])
  expect_true("GeomText" %in% geoms)
})

test_that("longitudinal_counts_table is composable with + operator", {
  dta <- sample_longitudinal_counts_data(n_patients = 60, seed = 1)
  p   <- longitudinal_counts_table(dta) + hvti_theme("manuscript")
  expect_s3_class(p, "ggplot")
})

test_that("longitudinal_counts_table errors when required column is absent", {
  dta <- sample_longitudinal_counts_data(n_patients = 60, seed = 1)
  expect_error(longitudinal_counts_table(dta, x_col = "nonexistent"), "not found")
})

test_that("longitudinal_counts_plot and longitudinal_counts_table produce distinct plots", {
  dta <- sample_longitudinal_counts_data(n_patients = 60, seed = 1)
  p_bar   <- longitudinal_counts_plot(dta)
  p_table <- longitudinal_counts_table(dta)
  bar_geoms   <- sapply(p_bar$layers,   function(l) class(l$geom)[1])
  table_geoms <- sapply(p_table$layers, function(l) class(l$geom)[1])
  expect_false(identical(bar_geoms, table_geoms))
})

# ============================================================================
# hvti_theme("light_ppt") — dispatch and alias
# ============================================================================

test_that("hvti_theme('light_ppt') returns a theme object", {
  t <- hvti_theme("light_ppt")
  expect_s3_class(t, "theme")
})

test_that("hvti_theme_light_ppt() returns a theme object", {
  t <- hvti_theme_light_ppt()
  expect_s3_class(t, "theme")
})

test_that("theme_light_ppt is an alias pointing to hvti_theme_light_ppt", {
  expect_identical(theme_light_ppt, hvti_theme_light_ppt)
})

test_that("hvti_theme('light_ppt') and hvti_theme_light_ppt() produce the same theme", {
  t_generic <- hvti_theme("light_ppt")
  t_direct  <- hvti_theme_light_ppt()
  expect_equal(t_generic, t_direct)
})

test_that("hvti_theme_light_ppt can be applied to a plot", {
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + hvti_theme_light_ppt()
  expect_s3_class(p, "ggplot")
})

test_that("hvti_theme_light_ppt and hvti_theme_dark_ppt produce distinct themes", {
  # Light and dark themes must not be interchangeable
  t_light <- hvti_theme_light_ppt()
  t_dark  <- hvti_theme_dark_ppt()
  expect_false(identical(t_light, t_dark))
})

test_that("hvti_theme_light_ppt respects base_size: size 12 differs from size 48", {
  t_small <- hvti_theme_light_ppt(base_size = 12)
  t_large <- hvti_theme_light_ppt(base_size = 48)
  # Changing base_size must produce a different theme object
  expect_false(identical(t_small, t_large))
})
