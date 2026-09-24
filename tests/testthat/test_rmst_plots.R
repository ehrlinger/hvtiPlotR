# Test suite for rmst-plots.R

library(testthat)

rmst_estimates <- function() {
  data.frame(
    estimator    = factor(c("IPTW", "Overlap", "Matching"),
                          levels = c("Matching", "IPTW", "Overlap")),
    subset       = "all",
    weighting    = "ATE",
    n            = c(500L, 500L, 320L),
    diff         = c(41, 35, 28),
    diff_days    = c(41, 35, 28),
    lo_days      = c(-5, 2, -14),
    hi_days      = c(87, 68, 70),
    n_failed     = 0L
  )
}

rmst_curves <- function() {
  one <- function(est, arm, s) {
    data.frame(estimator = est, arm = arm, time = c(0, 100, 250, 500), surv = s)
  }
  rbind(
    one("IPTW", "treated", c(1, .9, .8, .6)), one("IPTW", "control", c(1, .8, .6, .4)),
    one("Overlap", "treated", c(1, .95, .85, .7)), one("Overlap", "control", c(1, .85, .7, .5))
  )
}

rmst_ps <- function() {
  structure(list(tables = list(estimates = rmst_estimates(), curves = rmst_curves())),
            class = "ps_rmst")
}

# ---------------------------------------------------------------------------
# hv_rmst_contrast
# ---------------------------------------------------------------------------

test_that("hv_rmst_contrast returns an hv_data object with meta", {
  rc <- hv_rmst_contrast(rmst_estimates())
  expect_s3_class(rc, "hv_rmst_contrast")
  expect_s3_class(rc, "hv_data")
  expect_equal(rc$meta$n_estimators, 3L)
  expect_output(print(rc), "hv_rmst_contrast")
})

test_that("plot.hv_rmst_contrast layers carry data and include the zero line", {
  p <- plot(hv_rmst_contrast(rmst_estimates()))
  expect_plot_has_data(p, geoms = c("GeomVline", "GeomPointrange"))
  built <- ggplot2::ggplot_build(p)
  vl <- built$data[[which(geom_classes(p) == "GeomVline")]]
  expect_equal(vl$xintercept, 0)
  pr <- built$data[[which(geom_classes(p) == "GeomPointrange")]]
  expect_equal(nrow(pr), 3L)
  expect_setequal(pr$x, c(41, 35, 28))
})

test_that("estimators are ordered as given, first at the top", {
  # factor levels respected
  p <- plot(hv_rmst_contrast(rmst_estimates()))
  expect_equal(p$scales$get_scales("y")$limits, rev(c("Matching", "IPTW", "Overlap")))
  # character: order of appearance
  d <- rmst_estimates()
  d$estimator <- as.character(d$estimator)
  p2 <- plot(hv_rmst_contrast(d))
  expect_equal(p2$scales$get_scales("y")$limits, rev(c("IPTW", "Overlap", "Matching")))
})

test_that("default x label is RMST difference (days) and can be overridden", {
  rc <- hv_rmst_contrast(rmst_estimates())
  expect_equal(plot(rc)$labels$x, "RMST difference (days)")
  expect_equal(plot(rc, x_label = "Days")$labels$x, "Days")
})

test_that("hv_rmst_contrast accepts custom column names and a ps_rmst object", {
  d <- rmst_estimates()
  names(d)[names(d) == "diff_days"] <- "d"
  expect_plot_has_data(plot(hv_rmst_contrast(d, diff = "d")))
  rc <- hv_rmst_contrast(rmst_ps())
  expect_equal(rc$meta$n_estimators, 3L)
  expect_plot_has_data(plot(rc))
})

test_that("hv_rmst_contrast errors on bad input", {
  expect_error(hv_rmst_contrast(1:3), "data frame")
  expect_error(hv_rmst_contrast(rmst_estimates()[, c("estimator", "diff_days")]),
               "Missing required column.*lo_days")
  expect_error(hv_rmst_contrast(rmst_estimates(), diff = "nope"), "nope")
  d <- rmst_estimates()
  d$diff_days <- as.character(d$diff_days)
  expect_error(hv_rmst_contrast(d), "numeric")
  d <- rmst_estimates()
  d$estimator[2] <- NA
  expect_error(hv_rmst_contrast(d), "missing values")
  expect_error(hv_rmst_contrast(list(tables = list())), "tables\\$estimates")
})

test_that("hv_rmst_contrast accounts for missing estimates", {
  d <- rmst_estimates()
  d$lo_days[1] <- NA
  expect_warning(rc <- hv_rmst_contrast(d), "will not be drawn")
  expect_equal(rc$meta$n_missing, 1L)
})

# ---------------------------------------------------------------------------
# hv_rmst_curves
# ---------------------------------------------------------------------------

test_that("hv_rmst_curves returns an hv_data object", {
  rc <- hv_rmst_curves(rmst_curves())
  expect_s3_class(rc, "hv_rmst_curves")
  expect_s3_class(rc, "hv_data")
  expect_equal(rc$meta$arm_levels, c("treated", "control"))
  expect_output(print(rc), "hv_rmst_curves")
})

test_that("plot.hv_rmst_curves draws steps, faceted by estimator", {
  p <- plot(hv_rmst_curves(rmst_curves()))
  expect_plot_has_data(p, geoms = "GeomStep", min_groups = 2)
  expect_s3_class(p$facet, "FacetWrap")
  built <- ggplot2::ggplot_build(p)
  expect_equal(length(unique(built$layout$layout$PANEL)), 2L)
  expect_false("GeomRibbon" %in% geom_classes(p))
  expect_false("GeomVline" %in% geom_classes(p))
})

test_that("facet order follows factor levels", {
  d <- rmst_curves()
  d$estimator <- factor(d$estimator, levels = c("Overlap", "IPTW"))
  built <- ggplot2::ggplot_build(plot(hv_rmst_curves(d)))
  expect_equal(as.character(built$layout$layout$estimator), c("Overlap", "IPTW"))
})

test_that("tau adds shaded area under each arm and a vertical tau line", {
  p <- plot(hv_rmst_curves(rmst_curves(), tau = 300))
  expect_plot_has_data(p, geoms = c("GeomStep", "GeomRibbon", "GeomVline"))
  built <- ggplot2::ggplot_build(p)
  rib <- built$data[[which(geom_classes(p) == "GeomRibbon")]]
  expect_true(all(rib$x <= 300))
  expect_equal(max(rib$x), 300)
  expect_equal(min(rib$ymin), 0)
  expect_length(unique(rib$fill), 2L)
  vl <- built$data[[which(geom_classes(p) == "GeomVline")]]
  expect_equal(unique(vl$xintercept), 300)
})

test_that("shaded area equals the RMST of the step curve", {
  d <- data.frame(estimator = "A", arm = "treated", time = c(0, 100, 250), surv = c(1, .5, .25))
  sh <- hv_rmst_curves(d, tau = 300)$tables$shade
  # trapezoid rule over the staircase polygon: 100*1 + 150*.5 + 50*.25 = 187.5
  area <- sum(diff(sh$time) * (head(sh$surv, -1L) + tail(sh$surv, -1L)) / 2)
  expect_equal(area, 187.5)
})

test_that("estimates annotate each facet with diff and interval", {
  p <- plot(hv_rmst_curves(rmst_curves(), estimates = rmst_estimates(), tau = 300))
  expect_plot_has_data(p, geoms = "GeomText")
  built <- ggplot2::ggplot_build(p)
  txt <- built$data[[which(geom_classes(p) == "GeomText")]]
  expect_equal(nrow(txt), 2L)
  expect_true(any(grepl("+41.0 [-5.0, 87.0] days", txt$label, fixed = TRUE)))
})

test_that("a ps_rmst-like list supplies curves, estimates and works end to end", {
  rc <- hv_rmst_curves(rmst_ps(), tau = 300)
  expect_equal(nrow(rc$tables$labels), 2L)
  expect_plot_has_data(plot(rc), geoms = c("GeomStep", "GeomRibbon", "GeomText"))
  expect_error(hv_rmst_curves(list(tables = list())), "tables\\$curves")
})

test_that("hv_rmst_curves supports a custom facet column", {
  d <- rmst_curves()
  names(d)[1] <- "method"
  expect_plot_has_data(plot(hv_rmst_curves(d, facet = "method", tau = 300)), geoms = "GeomRibbon")
})

test_that("hv_rmst_curves errors on bad input", {
  expect_error(hv_rmst_curves(1:3), "data frame")
  expect_error(hv_rmst_curves(rmst_curves()[, c("estimator", "arm", "time")]),
               "Missing required column.*surv")
  expect_error(hv_rmst_curves(rmst_curves(), tau = -1), "positive")
  expect_error(hv_rmst_curves(rmst_curves(), tau = c(1, 2)), "scalar")
  expect_error(hv_rmst_curves(rmst_curves(), estimates = rmst_estimates()[, "estimator", drop = FALSE]),
               "Missing required column.*diff_days")
  d <- rmst_curves()
  d$arm[1] <- NA
  expect_error(hv_rmst_curves(d), "missing values")
})

test_that("tau before every step shades nothing and does not error", {
  d <- rmst_curves()
  d <- d[d$time > 0, ]
  rc <- hv_rmst_curves(d, tau = 50)
  expect_equal(nrow(rc$tables$shade), 0L)
  expect_s3_class(plot(rc), "ggplot")
})
