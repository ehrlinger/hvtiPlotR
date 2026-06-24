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
