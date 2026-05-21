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

# ---------------------------------------------------------------------------
# hv_consort_start
# ---------------------------------------------------------------------------

test_that("hv_consort_start returns hv_consort_tracker", {
  cohort  <- make_cohort()
  tracker <- hv_consort_start(cohort, patient_id = mrn)
  expect_s3_class(tracker, "hv_consort_tracker")
})

test_that("hv_consort_start stores patient_id_col correctly", {
  cohort  <- make_cohort()
  tracker <- hv_consort_start(cohort, patient_id = mrn)
  expect_equal(tracker$patient_id_col, "mrn")
})

test_that("hv_consort_start adds screened = TRUE for all rows", {
  cohort  <- make_cohort()
  tracker <- hv_consort_start(cohort, patient_id = mrn)
  expect_true(all(tracker$data$screened))
  expect_equal(nrow(tracker$data), nrow(cohort))
})

test_that("hv_consort_start respects explicit pass_col", {
  cohort  <- make_cohort()
  tracker <- hv_consort_start(cohort, patient_id = mrn,
                               label    = "All Patients",
                               pass_col = "all_pts")
  expect_true("all_pts" %in% names(tracker$data))
  expect_equal(tracker$stages[[1L]]$include_col, "all_pts")
})

test_that("hv_consort_start registers one stage with correct label", {
  cohort  <- make_cohort()
  tracker <- hv_consort_start(cohort, patient_id = mrn, label = "Screened")
  expect_length(tracker$stages, 1L)
  expect_equal(tracker$stages[[1L]]$label, "Screened")
  expect_null(tracker$stages[[1L]]$excl_col)
})

test_that("print.hv_consort_tracker prints without error", {
  tracker <- hv_consort_start(make_cohort(), patient_id = mrn)
  expect_output(print(tracker), "hv_consort_tracker")
  expect_output(print(tracker), "Screened")
})
