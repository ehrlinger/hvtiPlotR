# tests/testthat/test_at_risk.R
library(testthat)
library(ggplot2)

test_that(".atrisk_table counts subjects still at risk at each report time", {
  # 4 subjects, follow-up times 2, 4, 6, 8; report at 1, 5, 9
  tab <- .atrisk_table(time = c(2, 4, 6, 8), report_times = c(1, 5, 9))
  expect_equal(tab$strata, rep("Overall", 3))
  expect_equal(tab$report_time, c(1, 5, 9))
  expect_equal(tab$n.risk, c(4, 2, 0))   # >=1: all; >=5: {6,8}; >=9: none
})

test_that(".atrisk_table is non-increasing in time and splits by group", {
  tab <- .atrisk_table(
    time         = c(2, 8, 3, 9),
    group        = c("A", "A", "B", "B"),
    report_times = c(1, 5)
  )
  a <- tab$n.risk[tab$strata == "A"]
  b <- tab$n.risk[tab$strata == "B"]
  expect_equal(a, c(2, 1))   # A: >=1 {2,8}; >=5 {8}
  expect_equal(b, c(2, 1))   # B: >=1 {3,9}; >=5 {9}
  expect_true(all(diff(a) <= 0) && all(diff(b) <= 0))
})

test_that(".atrisk_table errors on bad input", {
  expect_error(.atrisk_table(time = numeric(0), report_times = 1),
               "non-empty numeric")
  expect_error(.atrisk_table(time = c(1, 2), report_times = NULL),
               "non-empty numeric")
  expect_error(.atrisk_table(time = c(1, 2), group = "A", report_times = 1),
               "same length")
  expect_error(
    .atrisk_table(time = c(1, 2, 3), group = c("A", NA, "B"),
                  report_times = 1),
    "missing values"
  )
})

test_that(".atrisk_table matches km_risk_table when no events fall between report times", {
  # Events exactly at the report times -> both conventions agree.
  dta <- data.frame(iv_dead = c(1, 1, 2, 2, 3, 3), dead = rep(TRUE, 6))
  km  <- hv_survival(dta, time_col = "iv_dead", event_col = "dead",
                     report_times = c(1, 2, 3))
  emp <- .atrisk_table(time = dta$iv_dead, report_times = c(1, 2, 3))
  # Compare n.risk per report time (km strata label is the single-cohort name).
  expect_equal(emp$n.risk, km$tables$risk$n.risk)
})

test_that("hv_atrisk renders a panel from an hv_survival object", {
  dta <- sample_survival_data(n = 200, strata_levels = c("A", "B"), seed = 1)
  km  <- hv_survival(dta, time_col = "iv_dead", event_col = "dead",
                     group_col = "valve_type")
  p   <- hv_atrisk(km)
  expect_s3_class(p, "ggplot")
  # one text label per (stratum x report time)
  n_expected <- nrow(km$tables$risk)
  built <- ggplot2::layer_data(p, 1)
  expect_equal(nrow(built), n_expected)
})

test_that("hv_atrisk renders a panel from a precomputed risk data frame", {
  rdf <- data.frame(strata = c("A", "A", "B", "B"),
                    report_time = c(0, 5, 0, 5),
                    n.risk = c(50, 30, 40, 20))
  p   <- hv_atrisk(rdf)
  expect_s3_class(p, "ggplot")
  expect_equal(nrow(ggplot2::layer_data(p, 1)), 4L)
})

test_that("hv_atrisk accepts `n` and `time` column aliases", {
  rdf <- data.frame(strata = c("A", "B"), time = c(0, 0), n = c(10, 8))
  p   <- hv_atrisk(rdf)
  expect_s3_class(p, "ggplot")
  expect_equal(nrow(ggplot2::layer_data(p, 1)), 2L)
})

test_that("hv_atrisk strata_labels overrides row labels", {
  rdf <- data.frame(strata = c("A", "B"), report_time = c(0, 0),
                    n.risk = c(10, 8))
  p   <- hv_atrisk(rdf, strata_labels = c(A = "Group A", B = "Group B"))
  blt <- ggplot2::ggplot_build(p)
  ylabs <- blt$layout$panel_params[[1]]$y$get_labels()
  expect_true(all(c("Group A", "Group B") %in% ylabs))
})

test_that("hv_atrisk renders a single-stratum (unstratified) object", {
  km <- hv_survival(sample_survival_data(n = 100, seed = 1))
  p  <- hv_atrisk(km)
  expect_s3_class(p, "ggplot")
  expect_equal(nrow(ggplot2::layer_data(p, 1)), nrow(km$tables$risk))
})

test_that("hv_atrisk computes from subject-level data via time/status/group", {
  dta <- sample_survival_data(n = 200, strata_levels = c("A", "B"), seed = 1)
  p   <- hv_atrisk(dta, time = "iv_dead", status = "dead",
                   group = "valve_type", report_times = c(0, 5, 10))
  expect_s3_class(p, "ggplot")
  expect_equal(nrow(ggplot2::layer_data(p, 1)), 6L)  # 2 strata x 3 times

  # Same as the equivalent precomputed table.
  ref <- .atrisk_table(time = dta$iv_dead, group = dta$valve_type,
                       report_times = c(0, 5, 10))
  got <- ggplot2::layer_data(p, 1)
  expect_equal(sort(as.numeric(as.character(got$label))), sort(ref$n.risk))
})

test_that("hv_atrisk derives report_times from the time range when NULL", {
  dta <- sample_survival_data(n = 100, seed = 1)
  p   <- hv_atrisk(dta, time = "iv_dead")
  built <- ggplot2::layer_data(p, 1)
  expect_gt(nrow(built), 0L)
  # derived points lie inside the observed follow-up range
  expect_true(all(built$x >= min(dta$iv_dead) & built$x <= max(dta$iv_dead)))
})

test_that("hv_atrisk errors on an unresolvable input", {
  expect_error(hv_atrisk(42), "hv_data object")
  expect_error(hv_atrisk(data.frame(foo = 1)), "Precomputed risk data frame")
})

test_that("hv_atrisk_compose stacks curve over table with shared x-range", {
  dta   <- sample_survival_data(n = 200, strata_levels = c("A", "B"), seed = 1)
  km    <- hv_survival(dta, time_col = "iv_dead", event_col = "dead",
                       group_col = "valve_type")
  curve <- plot(km)
  table <- hv_atrisk(km)
  comp  <- hv_atrisk_compose(curve, table)

  expect_s3_class(comp, "patchwork")
  # the two patches share x-axis limits after composition
  xr_curve <- ggplot2::ggplot_build(curve)$layout$panel_params[[1]]$x.range
  xr_table <- ggplot2::ggplot_build(comp[[2]])$layout$panel_params[[1]]$x.range
  expect_equal(xr_table, xr_curve, tolerance = 1e-6)
})

test_that("hv_atrisk_compose validates its inputs", {
  dta   <- sample_survival_data(n = 50, seed = 1)
  table <- hv_atrisk(hv_survival(dta))
  expect_error(hv_atrisk_compose("nope", table), "ggplot")
  expect_error(hv_atrisk_compose(table, "nope"), "ggplot")
})

test_that("hv_atrisk_compose validates heights", {
  dta   <- sample_survival_data(n = 50, seed = 1)
  km    <- hv_survival(dta)
  curve <- plot(km)
  table <- hv_atrisk(km)
  expect_error(hv_atrisk_compose(curve, table, heights = "tall"),
               "length-2 numeric")
  expect_error(hv_atrisk_compose(curve, table, heights = c(1, 2, 3)),
               "length-2 numeric")
})

# ---------------------------------------------------------------------------
# report_times selection + strata handling on the table-backed paths
# ---------------------------------------------------------------------------

test_that("report_times selects from an hv_survival object's existing times", {
  km <- hv_survival(sample_survival_data(n = 200, seed = 1),
                    report_times = c(0, 5, 10, 15, 20))
  p  <- hv_atrisk(km, report_times = c(0, 10, 20))
  built <- ggplot2::layer_data(p, 1)
  expect_equal(sort(unique(built$x)), c(0, 10, 20))
})

test_that("report_times not in the table warns and is dropped", {
  km <- hv_survival(sample_survival_data(n = 200, seed = 1),
                    report_times = c(0, 5, 10))
  expect_warning(hv_atrisk(km, report_times = c(0, 99)), "not in the risk table")
})

test_that("report_times matching nothing errors", {
  km <- hv_survival(sample_survival_data(n = 100, seed = 1),
                    report_times = c(0, 5, 10))
  expect_error(suppressWarnings(hv_atrisk(km, report_times = c(99))),
               "None of the requested")
})

test_that("precomputed strata factor order is preserved (not alphabetised)", {
  rdf <- data.frame(
    strata      = factor(c("Late", "Early"), levels = c("Late", "Early")),
    report_time = c(0, 0),
    n.risk      = c(10, 20)
  )
  p   <- hv_atrisk(rdf)
  # y is built with rev(levels) so the first level ("Late") sits on top
  blt <- ggplot2::ggplot_build(p)
  ylabs <- blt$layout$panel_params[[1]]$y$get_labels()
  expect_equal(ylabs, c("Early", "Late"))  # bottom-to-top => Late on top
})

test_that("hv_atrisk errors on NA strata in a precomputed table", {
  rdf <- data.frame(strata = c("A", NA), report_time = c(0, 0),
                    n.risk = c(10, 8))
  expect_error(hv_atrisk(rdf), "missing `strata`")
})

test_that("raw-data path errors when time has no finite values", {
  dta <- data.frame(t = c(NA_real_, NA_real_), g = c("A", "B"))
  expect_error(hv_atrisk(dta, time = "t", group = "g"), "no finite values")
})
