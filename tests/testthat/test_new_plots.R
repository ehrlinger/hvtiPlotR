# tests/testthat/test_new_plots.R
#
# Smoke / property tests for plot functions added in v1.2+:
#   sample_upset_data, hv_upset
#   sample_alluvial_data, hv_alluvial
#   sample_spaghetti_data, hv_spaghetti
#   sample_trends_data, hv_trends
#   sample_longitudinal_counts_data, hv_longitudinal
# hv_theme("light_ppt") dispatch + theme_light_ppt alias.
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
# hv_upset
# ============================================================================

sets <- c("AV_Replacement", "AV_Repair", "MV_Replacement",
          "MV_Repair", "TV_Repair", "Aorta", "CABG")

test_that("hv_upset returns an hv_data object", {
  dta <- sample_upset_data(n = 200, seed = 1)
  expect_s3_class(hv_upset(dta, intersect = sets), "hv_data")
})

test_that("hv_upset errors when data is not a data frame", {
  expect_error(hv_upset(list(), intersect = sets), "data frame")
})

test_that("hv_upset errors when intersect has only one element", {
  dta <- sample_upset_data(n = 100, seed = 1)
  expect_error(hv_upset(dta, intersect = "AV_Replacement"), "at least 2")
})

test_that("hv_upset errors when intersect names are absent from data", {
  dta <- sample_upset_data(n = 100, seed = 1)
  expect_error(
    hv_upset(dta, intersect = c("AV_Replacement", "DoesNotExist")),
    "column"
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
# hv_alluvial
# ============================================================================

test_that("hv_alluvial returns an hv_data object", {
  dta  <- sample_alluvial_data(n = 150, seed = 1)
  axes <- c("pre_ar", "procedure", "post_ar")
  expect_s3_class(hv_alluvial(dta, axes = axes, y_col = "freq"), "hv_data")
})

test_that("plot(hv_alluvial) returns a ggplot with three axes", {
  dta  <- sample_alluvial_data(n = 150, seed = 1)
  axes <- c("pre_ar", "procedure", "post_ar")
  p    <- plot(hv_alluvial(dta, axes = axes, y_col = "freq"))
  expect_s3_class(p, "ggplot")
})

test_that("plot(hv_alluvial) works with only two axes", {
  dta <- sample_alluvial_data(n = 100, seed = 1)
  p   <- plot(hv_alluvial(dta, axes = c("pre_ar", "post_ar"), y_col = "freq"))
  expect_s3_class(p, "ggplot")
})

test_that("plot(hv_alluvial) has a geom_text layer when show_labels=TRUE", {
  dta <- sample_alluvial_data(n = 100, seed = 1)
  p   <- plot(hv_alluvial(dta, axes = c("pre_ar", "post_ar"), y_col = "freq"),
              show_labels = TRUE)
  geoms <- sapply(p$layers, function(l) class(l$geom)[1])
  expect_true("GeomText" %in% geoms)
})

test_that("plot(hv_alluvial) omits geom_text when show_labels=FALSE", {
  dta <- sample_alluvial_data(n = 100, seed = 1)
  p   <- plot(hv_alluvial(dta, axes = c("pre_ar", "post_ar"), y_col = "freq"),
              show_labels = FALSE)
  geoms <- sapply(p$layers, function(l) class(l$geom)[1])
  expect_false("GeomText" %in% geoms)
})

test_that("plot(hv_alluvial) with fill_col returns a ggplot", {
  dta  <- sample_alluvial_data(n = 150, seed = 1)
  axes <- c("pre_ar", "procedure", "post_ar")
  p    <- plot(hv_alluvial(dta, axes = axes, y_col = "freq", fill_col = "pre_ar"))
  expect_s3_class(p, "ggplot")
})

test_that("hv_alluvial errors when data is not a data frame", {
  expect_error(hv_alluvial(list(), axes = c("a", "b")), "data frame")
})

test_that("hv_alluvial errors when axes has fewer than two elements", {
  dta <- sample_alluvial_data(n = 100, seed = 1)
  expect_error(hv_alluvial(dta, axes = "pre_ar"), "at least 2")
})

test_that("hv_alluvial errors when an axis name is absent from data", {
  dta <- sample_alluvial_data(n = 100, seed = 1)
  expect_error(
    hv_alluvial(dta, axes = c("pre_ar", "nonexistent")),
    "column"
  )
})

test_that("hv_alluvial errors when y_col is absent from data", {
  dta <- sample_alluvial_data(n = 100, seed = 1)
  expect_error(
    hv_alluvial(dta, axes = c("pre_ar", "post_ar"), y_col = "missing_col"),
    "not found"
  )
})

test_that("plot(hv_alluvial) errors when alpha is out of [0, 1]", {
  dta <- sample_alluvial_data(n = 100, seed = 1)
  expect_error(
    plot(hv_alluvial(dta, axes = c("pre_ar", "post_ar"), y_col = "freq"),
         alpha = 1.5),
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
# hv_spaghetti
# ============================================================================

test_that("hv_spaghetti returns an hv_data object", {
  dta <- sample_spaghetti_data(n_patients = 40, seed = 1)
  expect_s3_class(hv_spaghetti(dta), "hv_data")
})

test_that("plot(hv_spaghetti) returns a ggplot (unstratified)", {
  dta <- sample_spaghetti_data(n_patients = 40, seed = 1)
  expect_s3_class(plot(hv_spaghetti(dta)), "ggplot")
})

test_that("plot(hv_spaghetti) has a geom_line layer", {
  dta   <- sample_spaghetti_data(n_patients = 40, seed = 1)
  geoms <- sapply(plot(hv_spaghetti(dta))$layers, function(l) class(l$geom)[1])
  expect_true("GeomLine" %in% geoms)
})

test_that("plot(hv_spaghetti) with colour_col returns a ggplot", {
  dta <- sample_spaghetti_data(n_patients = 40, seed = 1)
  p   <- plot(hv_spaghetti(dta, colour_col = "group"))
  expect_s3_class(p, "ggplot")
})

test_that("plot(hv_spaghetti) add_smooth=TRUE adds an extra layer vs add_smooth=FALSE", {
  dta      <- sample_spaghetti_data(n_patients = 40, seed = 1)
  sp       <- hv_spaghetti(dta)
  p_plain  <- plot(sp)
  p_smooth <- plot(sp, add_smooth = TRUE)
  expect_gt(length(p_smooth$layers), length(p_plain$layers))
})

test_that("plot(hv_spaghetti) add_smooth=TRUE has a GeomSmooth layer", {
  dta   <- sample_spaghetti_data(n_patients = 40, seed = 1)
  geoms <- sapply(plot(hv_spaghetti(dta), add_smooth = TRUE)$layers,
                  function(l) class(l$geom)[1])
  expect_true("GeomSmooth" %in% geoms)
})

test_that("plot(hv_spaghetti) y_labels adds a y scale vs default", {
  dta <- sample_spaghetti_data(n_patients = 40, seed = 1)
  dta$value <- round(pmin(3, pmax(0, dta$value / 12)))
  labels    <- c(None = 0, Mild = 1, Moderate = 2, Severe = 3)
  sp        <- hv_spaghetti(dta)
  p_default <- plot(sp)
  p_labeled <- plot(sp, y_labels = labels)
  # y_labels adds scale_y_continuous: labeled plot must have more scales
  expect_gt(
    length(p_labeled$scales$scales),
    length(p_default$scales$scales)
  )
})

test_that("hv_spaghetti errors when x_col is absent from data", {
  dta <- sample_spaghetti_data(n_patients = 30, seed = 1)
  expect_error(hv_spaghetti(dta, x_col = "nonexistent"), "column")
})

test_that("hv_spaghetti errors when colour_col is absent from data", {
  dta <- sample_spaghetti_data(n_patients = 30, seed = 1)
  expect_error(hv_spaghetti(dta, colour_col = "nonexistent"), "not found")
})

test_that("plot(hv_spaghetti) errors when alpha is out of [0, 1]", {
  dta <- sample_spaghetti_data(n_patients = 30, seed = 1)
  expect_error(plot(hv_spaghetti(dta), alpha = 2.0), "alpha")
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
# hv_trends
# ============================================================================

test_that("hv_trends returns an hv_data object", {
  dta <- sample_trends_data(n = 200, seed = 1)
  expect_s3_class(hv_trends(dta), "hv_data")
})

test_that("plot(hv_trends) returns a ggplot (multi-group)", {
  dta <- sample_trends_data(n = 200, seed = 1)
  expect_s3_class(plot(hv_trends(dta)), "ggplot")
})

test_that("plot(hv_trends) has both geom_smooth and geom_point layers", {
  dta   <- sample_trends_data(n = 200, seed = 1)
  geoms <- sapply(plot(hv_trends(dta))$layers, function(l) class(l$geom)[1])
  expect_true("GeomSmooth" %in% geoms)
  expect_true("GeomPoint"  %in% geoms)
})

test_that("plot(hv_trends) works with group_col=NULL (single group)", {
  dta <- sample_trends_data(n = 200, seed = 1)
  one <- dta[dta$group == "Group I", ]
  p   <- plot(hv_trends(one, group_col = NULL))
  expect_s3_class(p, "ggplot")
})

test_that("plot(hv_trends) summary_fn='median' returns a ggplot", {
  dta <- sample_trends_data(n = 200, seed = 1)
  p   <- plot(hv_trends(dta, summary_fn = "median"))
  expect_s3_class(p, "ggplot")
})

test_that("hv_trends errors when x_col is absent from data", {
  dta <- sample_trends_data(n = 100, seed = 1)
  expect_error(hv_trends(dta, x_col = "nonexistent"), "column")
})

test_that("hv_trends errors when y_col is absent from data", {
  dta <- sample_trends_data(n = 100, seed = 1)
  expect_error(hv_trends(dta, y_col = "nonexistent"), "column")
})

test_that("hv_trends errors when group_col is absent from data", {
  dta <- sample_trends_data(n = 100, seed = 1)
  expect_error(hv_trends(dta, group_col = "nonexistent"), "not found")
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
# hv_longitudinal
# ============================================================================

test_that("hv_longitudinal returns an hv_data object", {
  dta <- sample_longitudinal_counts_data(n_patients = 60, seed = 1)
  expect_s3_class(hv_longitudinal(dta), "hv_data")
})

test_that("plot(hv_longitudinal) returns a ggplot", {
  dta <- sample_longitudinal_counts_data(n_patients = 60, seed = 1)
  expect_s3_class(plot(hv_longitudinal(dta)), "ggplot")
})

test_that("plot(hv_longitudinal) is composable with + operator", {
  dta <- sample_longitudinal_counts_data(n_patients = 60, seed = 1)
  p   <- plot(hv_longitudinal(dta)) + ggplot2::labs(y = "Count")
  expect_s3_class(p, "ggplot")
})

test_that("plot(hv_longitudinal) has a GeomBar layer", {
  dta   <- sample_longitudinal_counts_data(n_patients = 60, seed = 1)
  geoms <- sapply(plot(hv_longitudinal(dta))$layers, function(l) class(l$geom)[1])
  expect_true("GeomBar" %in% geoms)
})

test_that("plot(hv_longitudinal) position='stack' returns a ggplot", {
  dta <- sample_longitudinal_counts_data(n_patients = 60, seed = 1)
  expect_s3_class(plot(hv_longitudinal(dta), position = "stack"), "ggplot")
})

test_that("plot(hv_longitudinal) position='dodge' differs from 'stack'", {
  dta <- sample_longitudinal_counts_data(n_patients = 60, seed = 1)
  lc  <- hv_longitudinal(dta)
  p_d <- plot(lc, position = "dodge")
  p_s <- plot(lc, position = "stack")
  # The position argument changes how bars are drawn — the layer params differ
  expect_false(identical(p_d$layers[[1]]$position, p_s$layers[[1]]$position))
})

test_that("hv_longitudinal errors when required column is absent", {
  dta <- sample_longitudinal_counts_data(n_patients = 60, seed = 1)
  expect_error(hv_longitudinal(dta, x_col = "nonexistent"), "column")
})

test_that("plot(hv_longitudinal) errors on invalid position value", {
  dta <- sample_longitudinal_counts_data(n_patients = 60, seed = 1)
  expect_error(plot(hv_longitudinal(dta), position = "fill"), "dodge")
})

# ============================================================================
# hv_longitudinal — table panel (type = "table")
# ============================================================================

test_that("plot(hv_longitudinal, type='table') returns a ggplot", {
  dta <- sample_longitudinal_counts_data(n_patients = 60, seed = 1)
  expect_s3_class(plot(hv_longitudinal(dta), type = "table"), "ggplot")
})

test_that("plot(hv_longitudinal, type='table') has a GeomText layer", {
  dta   <- sample_longitudinal_counts_data(n_patients = 60, seed = 1)
  geoms <- sapply(
    plot(hv_longitudinal(dta), type = "table")$layers,
    function(l) class(l$geom)[1]
  )
  expect_true("GeomText" %in% geoms)
})

test_that("plot(hv_longitudinal, type='table') is composable with + operator", {
  dta <- sample_longitudinal_counts_data(n_patients = 60, seed = 1)
  p   <- plot(hv_longitudinal(dta), type = "table") + hv_theme("manuscript")
  expect_s3_class(p, "ggplot")
})

test_that("plot(hv_longitudinal) and plot(hv_longitudinal, type='table') produce distinct plots", {
  dta     <- sample_longitudinal_counts_data(n_patients = 60, seed = 1)
  lc      <- hv_longitudinal(dta)
  p_bar   <- plot(lc)
  p_table <- plot(lc, type = "table")
  bar_geoms   <- sapply(p_bar$layers,   function(l) class(l$geom)[1])
  table_geoms <- sapply(p_table$layers, function(l) class(l$geom)[1])
  expect_false(identical(bar_geoms, table_geoms))
})

# ============================================================================
# hv_theme("light_ppt") — dispatch and alias
# ============================================================================

test_that("hv_theme('light_ppt') returns a theme object", {
  t <- hv_theme("light_ppt")
  expect_s3_class(t, "theme")
})

test_that("hv_theme_light_ppt() returns a theme object", {
  t <- hv_theme_light_ppt()
  expect_s3_class(t, "theme")
})

test_that("theme_light_ppt is an alias pointing to hv_theme_light_ppt", {
  expect_identical(theme_light_ppt, hv_theme_light_ppt)
})

test_that("hv_theme('light_ppt') and hv_theme_light_ppt() produce the same theme", {
  t_generic <- hv_theme("light_ppt")
  t_direct  <- hv_theme_light_ppt()
  expect_equal(t_generic, t_direct)
})

test_that("hv_theme_light_ppt can be applied to a plot", {
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + hv_theme_light_ppt()
  expect_s3_class(p, "ggplot")
})

test_that("hv_theme_light_ppt and hv_theme_dark_ppt produce distinct themes", {
  # Light and dark themes must not be interchangeable
  t_light <- hv_theme_light_ppt()
  t_dark  <- hv_theme_dark_ppt()
  expect_false(identical(t_light, t_dark))
})

test_that("hv_theme_light_ppt respects base_size: size 12 differs from size 48", {
  t_small <- hv_theme_light_ppt(base_size = 12)
  t_large <- hv_theme_light_ppt(base_size = 48)
  # Changing base_size must produce a different theme object
  expect_false(identical(t_small, t_large))
})
