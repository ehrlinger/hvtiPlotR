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
