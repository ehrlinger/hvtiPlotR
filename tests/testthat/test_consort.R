# tests/testthat/test_consort.R
library(testthat)

# Shared minimal cohort used across tests
make_cohort <- function(n = 20L) {
  set.seed(42L)
  data.frame(
    mrn        = paste0("P", seq_len(n)),
    age        = c(rep(15L, 3L), rep(25L, n - 3L)),   # 3 under 18
    has_surg   = c(rep(FALSE, 2L), rep(TRUE, n - 2L)), # 2 no surgery
    missing_echo = c(rep(TRUE, 4L), rep(FALSE, n - 4L)), # 4 missing echo
    lost_fu    = c(rep(TRUE, 1L), rep(FALSE, n - 1L)), # 1 lost to FU
    stringsAsFactors = FALSE
  )
}

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

test_that("ct_snakify lowercases and replaces non-alphanumeric with underscore", {
  expect_equal(hvtiPlotR:::ct_snakify("Screened"),          "screened")
  expect_equal(hvtiPlotR:::ct_snakify("Eligible Patients"), "eligible_patients")
  expect_equal(hvtiPlotR:::ct_snakify("  Foo--Bar  "),      "foo_bar")
})

test_that("ct_validate_tracker errors on non-tracker", {
  expect_error(hvtiPlotR:::ct_validate_tracker(list()), "hv_consort_tracker")
  expect_error(hvtiPlotR:::ct_validate_tracker(NULL),   "hv_consort_tracker")
})
