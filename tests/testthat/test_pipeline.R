# tests/testthat/test_pipeline.R
#
# End-to-end pipeline tests and built-in dataset usability.
#
# These tests exercise the primary production workflows:
#   1. Built-in datasets -> plot function
#   2. hvti_survival -> hvti_theme -> save_ppt (full pipeline)
#   3. eda_classify_var edge cases not covered elsewhere
#   4. Built-in parametric + nonparametric datasets with their plot functions
#
library(testthat)
library(ggplot2)

# ============================================================================
# Helper: minimal .pptx template for save_ppt tests
# ============================================================================

make_temp_pptx <- function() {
  skip_if_not_installed("officer")
  tmp <- tempfile(fileext = ".pptx")
  officer::read_pptx() |>
    officer::add_slide(layout = "Title and Content",
                       master = "Office Theme") |>
    print(target = tmp)
  tmp
}

# ============================================================================
# Built-in datasets — basic usability with their target plot functions
# ============================================================================

test_that("parametric dataset has required hazard_plot columns", {
  data(parametric, package = "hvtiPlotR", envir = environment())
  # The parametric dataset must have at least the default columns that
  # hazard_plot() expects: a time column and a survival (or estimate) column.
  # We accept either the SAS-era column names or the R equivalents.
  time_candidates  <- c("time", "years", "iv_dead", "YEARS")
  # Competing-risks column names used in the package vignettes:
  # noinit/nodeath/nostrk = point estimates; clinit/cldeath/clstrk = lower CI;
  # cuinit/cudeath/custrk = upper CI. Also accept generic names.
  surv_candidates  <- c("survival", "ssurviv", "SSURVIV", "estimate",
                        "noinit", "nodeath", "nostrk",
                        "clinit", "cuinit")
  has_time <- any(time_candidates %in% names(parametric))
  has_surv <- any(surv_candidates %in% names(parametric))
  expect_true(has_time,
    label = "parametric must have a recognisable time column")
  expect_true(has_surv,
    label = "parametric must have a recognisable survival/estimate column")
})

test_that("nonparametric dataset has documented columns", {
  data(nonparametric, package = "hvtiPlotR", envir = environment())
  # Documented columns from nonparametric.R
  expected <- c("iv_state", "sginit", "stlinit", "stuinit",
                "sgdead1", "sgstrk1")
  found <- expected[expected %in% names(nonparametric)]
  expect_true(length(found) >= 3L,
    label = "nonparametric must contain at least 3 of its 6 documented core columns")
})

test_that("nonparametric dataset produces a valid ggplot object via ggplot()", {
  data(nonparametric, package = "hvtiPlotR", envir = environment())
  expect_no_error(ggplot2::ggplot(nonparametric))
})

test_that("parametric dataset produces a valid ggplot object via ggplot()", {
  data(parametric, package = "hvtiPlotR", envir = environment())
  expect_no_error(ggplot2::ggplot(parametric))
})

# ============================================================================
# eda_classify_var — edge cases
# ============================================================================

test_that("eda_classify_var handles a logical vector", {
  # Logical TRUE/FALSE is binary (2 unique values) — should classify as Cat_Num
  result <- eda_classify_var(c(TRUE, FALSE, TRUE, NA))
  expect_true(result %in% c("Cat_Num", "Cat_Char"),
              label = "logical vector should be categorical")
})

test_that("eda_classify_var handles an all-NA vector", {
  # All-NA: 0 non-missing unique values; should not error
  expect_no_error(eda_classify_var(rep(NA_real_, 10)))
})

test_that("eda_classify_var handles a length-1 vector", {
  expect_no_error(eda_classify_var(42))
})

# ============================================================================
# End-to-end: hvti_survival → hvti_theme → save_ppt
# ============================================================================

test_that("full pipeline: hvti_survival + hvti_theme + save_ppt (single plot)", {
  skip_if_not_installed("officer")
  skip_if_not_installed("rvg")

  template <- make_temp_pptx()
  on.exit(unlink(template))

  km <- hvti_survival(
    sample_survival_data(
      n             = 200,
      strata_levels = c("SAVR", "TAVR"),
      seed          = 1
    ),
    group_col = "valve_type"
  )

  pptx_out <- tempfile(fileext = ".pptx")
  on.exit(unlink(pptx_out), add = TRUE)

  expect_no_error(
    save_ppt(
      object       = plot(km) + hvti_theme("ppt"),
      template     = template,
      powerpoint   = pptx_out,
      slide_titles = "KM: SAVR vs TAVR"
    )
  )
  expect_true(file.exists(pptx_out))
})

test_that("full pipeline: list of plots → save_ppt (multi-slide)", {
  skip_if_not_installed("officer")
  skip_if_not_installed("rvg")

  template <- make_temp_pptx()
  on.exit(unlink(template))

  km <- hvti_survival(sample_survival_data(n = 100, seed = 1))
  p2 <- plot(hvti_eda(sample_eda_data(n = 100, seed = 1), y_col = "ef",
                      x_col = "op_years"))

  pptx_out <- tempfile(fileext = ".pptx")
  on.exit(unlink(pptx_out), add = TRUE)

  expect_no_error(
    save_ppt(
      object       = list(plot(km) + hvti_theme("ppt"), p2 + hvti_theme("ppt")),
      template     = template,
      powerpoint   = pptx_out,
      slide_titles = c("Kaplan-Meier", "EF vs Follow-up Years")
    )
  )
  expect_true(file.exists(pptx_out))
})

# ============================================================================
# End-to-end: hazard_plot → hvti_theme (parametric pipeline)
# ============================================================================

test_that("hazard_plot with life table reference + theme composes cleanly", {
  dat <- sample_hazard_data(
    n = 200, time_max = 10,
    groups = c("<65" = 0.5, "\u226580" = 1.8),
    seed = 1
  )
  lt <- sample_life_table(
    age_groups = c("<65", "\u226580"),
    age_mids   = c(55, 85),
    time_max   = 10
  )
  p <- hazard_plot(
    dat,
    estimate_col     = "survival",
    lower_col        = "surv_lower",
    upper_col        = "surv_upper",
    group_col        = "group",
    reference        = lt,
    ref_estimate_col = "survival",
    ref_group_col    = "group"
  ) +
    hvti_theme("manuscript") +
    ggplot2::labs(x = "Years", y = "Survival (%)")

  expect_s3_class(p, "ggplot")
})

# ============================================================================
# End-to-end: hvti_nonparametric + data points + theme
# ============================================================================

test_that("hvti_nonparametric with CI + data points + theme composes cleanly", {
  dat <- sample_nonparametric_curve_data(
    n = 200, time_max = 12,
    groups = c("Ozaki" = 0.7, "CE-P" = 1.3)
  )
  pts <- sample_nonparametric_curve_points(
    n = 200, time_max = 12,
    groups = c("Ozaki" = 0.7, "CE-P" = 1.3)
  )
  p <- plot(
    hvti_nonparametric(
      dat,
      group_col   = "group",
      lower_col   = "lower",
      upper_col   = "upper",
      data_points = pts
    )
  ) +
    hvti_theme("manuscript") +
    ggplot2::labs(x = "Months", y = "Probability")

  expect_s3_class(p, "ggplot")
  geoms <- sapply(p$layers, function(l) class(l$geom)[1])
  expect_true("GeomLine"   %in% geoms)
  expect_true("GeomRibbon" %in% geoms)
  expect_true("GeomPoint"  %in% geoms)
})
