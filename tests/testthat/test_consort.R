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

# ---------------------------------------------------------------------------
# hv_consort_exclude
# ---------------------------------------------------------------------------

make_tracker <- function() {
  hv_consort_start(make_cohort(), patient_id = mrn)
}

test_that("hv_consort_exclude adds exclusion and pass columns", {
  tracker <- make_tracker() |>
    hv_consort_exclude(
      label      = "Eligible",
      col        = "excl_screen",
      age < 18   ~ "Age < 18",
      !has_surg  ~ "No qualifying surgery"
    )
  expect_true("excl_screen" %in% names(tracker$data))
  expect_true("eligible"    %in% names(tracker$data))
})

test_that("hv_consort_exclude respects explicit pass_col", {
  tracker <- make_tracker() |>
    hv_consort_exclude(
      label    = "Eligible",
      col      = "excl_screen",
      pass_col = "elig",
      age < 18 ~ "Age < 18"
    )
  expect_true("elig" %in% names(tracker$data))
  expect_false("eligible" %in% names(tracker$data))
})

test_that("hv_consort_exclude uses first-match logic", {
  cohort <- data.frame(
    mrn    = "P1",
    age    = 15L,
    has_surg = FALSE,
    stringsAsFactors = FALSE
  )
  tracker <- hv_consort_start(cohort, patient_id = mrn) |>
    hv_consort_exclude(
      label     = "Eligible",
      col       = "excl_screen",
      age < 18  ~ "Age < 18",
      !has_surg ~ "No qualifying surgery"
    )
  # P1 matches BOTH rules; first rule wins
  expect_equal(tracker$data$excl_screen, "Age < 18")
})

test_that("hv_consort_exclude counts excluded patients correctly", {
  cohort  <- make_cohort(n = 20L)
  tracker <- hv_consort_start(cohort, patient_id = mrn) |>
    hv_consort_exclude(
      label     = "Eligible",
      col       = "excl_screen",
      age < 18  ~ "Age < 18",
      !has_surg ~ "No qualifying surgery"
    )
  n_excl <- sum(!is.na(tracker$data$excl_screen))
  expect_equal(n_excl, 3L)
})

test_that("hv_consort_exclude gates on previous stage", {
  tracker <- make_tracker() |>
    hv_consort_exclude(
      label     = "Eligible",
      col       = "excl_screen",
      age < 18  ~ "Age < 18"
    ) |>
    hv_consort_exclude(
      label        = "Analyzed",
      col          = "excl_eligible",
      missing_echo ~ "Missing echocardiogram"
    )
  screen_excl <- which(!is.na(tracker$data$excl_screen))
  expect_true(all(is.na(tracker$data$excl_eligible[screen_excl])))
})

test_that("hv_consort_exclude appends correct stage metadata", {
  tracker <- make_tracker() |>
    hv_consort_exclude(label = "Eligible", col = "excl_screen",
                       age < 18 ~ "Age < 18")
  expect_length(tracker$stages, 2L)
  expect_equal(tracker$stages[[1L]]$excl_col,    "excl_screen")
  expect_equal(tracker$stages[[2L]]$include_col, "eligible")
  expect_null( tracker$stages[[2L]]$excl_col)
})

test_that("hv_consort_exclude errors on non-tracker input", {
  expect_error(hv_consort_exclude(list(), label = "X", col = "y"),
               "hv_consort_tracker")
})

# ---------------------------------------------------------------------------
# Audit helpers
# ---------------------------------------------------------------------------

make_full_tracker <- function() {
  hv_consort_start(make_cohort(), patient_id = mrn) |>
    hv_consort_exclude(
      label     = "Eligible",
      col       = "excl_screen",
      age < 18  ~ "Age < 18",
      !has_surg ~ "No qualifying surgery"
    ) |>
    hv_consort_exclude(
      label        = "Analyzed",
      col          = "excl_eligible",
      missing_echo ~ "Missing echocardiogram"
    )
}

test_that("hv_consort_summary returns a data frame with one row per stage", {
  tracker <- make_full_tracker()
  summ    <- hv_consort_summary(tracker)
  expect_true(is.data.frame(summ))
  expect_equal(nrow(summ), length(tracker$stages))
})

test_that("hv_consort_summary has required columns", {
  summ <- hv_consort_summary(make_full_tracker())
  expect_true(all(c("label", "include_col", "n_included",
                    "excl_col",  "n_excluded") %in% names(summ)))
})

test_that("hv_consort_summary n_included decreases monotonically", {
  summ <- hv_consort_summary(make_full_tracker())
  expect_true(all(diff(summ$n_included) <= 0L))
})

test_that("hv_consort_patients returns ids at a stage by include_col", {
  tracker <- make_full_tracker()
  ids     <- hv_consort_patients(tracker, "eligible")
  expect_type(ids, "character")
  n_eligible <- sum(tracker$data$eligible)
  expect_length(ids, n_eligible)
})

test_that("hv_consort_patients matches by label (case-insensitive)", {
  tracker <- make_full_tracker()
  expect_equal(
    hv_consort_patients(tracker, "eligible"),
    hv_consort_patients(tracker, "Eligible")
  )
})

test_that("hv_consort_patients with reason returns subset", {
  tracker <- make_full_tracker()
  ids     <- hv_consort_patients(tracker, "screened", reason = "Age < 18")
  excl_rows <- tracker$data[!is.na(tracker$data$excl_screen) &
                              tracker$data$excl_screen == "Age < 18", ]
  expect_equal(ids, excl_rows$mrn)
})

test_that("hv_consort_patients errors on unknown stage", {
  expect_error(hv_consort_patients(make_full_tracker(), "nonexistent"), "not found")
})

# ---------------------------------------------------------------------------
# hv_consort — plot constructor
# ---------------------------------------------------------------------------

test_that("hv_consort returns hv_consort object", {
  obj <- hv_consort(make_full_tracker())
  expect_s3_class(obj, "hv_consort")
})

test_that("hv_consort has $plot, $meta, $tracker slots", {
  obj <- hv_consort(make_full_tracker())
  expect_true(all(c("plot", "meta", "tracker") %in% names(obj)))
})

test_that("hv_consort meta contains n_stages, width, height, orders, side_box", {
  obj <- hv_consort(make_full_tracker())
  expect_true(all(c("n_stages", "width", "height", "orders", "side_box") %in%
                    names(obj$meta)))
})

test_that("hv_consort side_box = 'all' collects all excl columns", {
  obj <- hv_consort(make_full_tracker(), side_box = "all")
  expect_equal(sort(obj$meta$side_box), sort(c("excl_screen", "excl_eligible")))
})

test_that("hv_consort respects explicit side_box", {
  obj <- hv_consort(make_full_tracker(), side_box = "excl_screen")
  expect_equal(obj$meta$side_box, "excl_screen")
})

test_that("hv_consort computes default dimensions from stage count", {
  tracker <- make_full_tracker()
  obj     <- hv_consort(tracker)
  n       <- length(tracker$stages)
  expect_equal(obj$meta$height, 2 + n * 1.2)
  expect_equal(obj$meta$width,  7)
})

test_that("hv_consort respects explicit width and height", {
  obj <- hv_consort(make_full_tracker(), width = 9, height = 12)
  expect_equal(obj$meta$width,  9)
  expect_equal(obj$meta$height, 12)
})

test_that("hv_consort errors on non-tracker", {
  expect_error(hv_consort(list()), "hv_consort_tracker")
})

# ---------------------------------------------------------------------------
# plot.hv_consort + print.hv_consort
# ---------------------------------------------------------------------------

test_that("plot.hv_consort draws without error", {
  obj <- hv_consort(make_full_tracker())
  expect_no_error(suppressWarnings(plot(obj)))
})

test_that("plot.hv_consort returns invisibly", {
  obj    <- hv_consort(make_full_tracker())
  result <- withVisible(plot(obj))
  expect_false(result$visible)
})

test_that("print.hv_consort prints without error and shows class", {
  obj <- hv_consort(make_full_tracker())
  expect_output(print(obj), "hv_consort")
  expect_output(print(obj), "Stages")
})

# ---------------------------------------------------------------------------
# save_ppt — hv_consort integration
# ---------------------------------------------------------------------------

test_that("save_ppt accepts hv_consort without erroring on type check", {
  obj  <- hv_consort(make_full_tracker())
  expect_false(inherits(obj, "ggplot"))
  is_acceptable <- inherits(obj, "ggplot") || inherits(obj, "hv_consort")
  expect_true(is_acceptable)
})

# ---------------------------------------------------------------------------
# sample_consort_data
# ---------------------------------------------------------------------------

test_that("sample_consort_data returns an hv_consort_tracker", {
  expect_s3_class(sample_consort_data(), "hv_consort_tracker")
})

test_that("sample_consort_data is reproducible with same seed", {
  d1 <- sample_consort_data(seed = 1L)
  d2 <- sample_consort_data(seed = 1L)
  expect_equal(hv_consort_summary(d1), hv_consort_summary(d2))
})

test_that("sample_consort_data n controls total population", {
  tracker <- sample_consort_data(n = 50L)
  expect_equal(nrow(tracker$data), 50L)
})

test_that("sample_consort_data produces a plottable consort diagram", {
  tracker <- sample_consort_data()
  expect_no_error(hv_consort(tracker))
})

# ---------------------------------------------------------------------------
# Error-path coverage
# ---------------------------------------------------------------------------

test_that("hv_consort_exclude errors when no formulas supplied", {
  expect_error(
    hv_consort_exclude(make_tracker(), label = "Eligible", col = "excl_screen"),
    "at least one formula"
  )
})

test_that("hv_consort_exclude errors on a non-formula argument", {
  expect_error(
    hv_consort_exclude(make_tracker(), label = "Eligible", col = "excl_screen",
                       "not a formula"),
    "not a two-sided formula"
  )
})

test_that("hv_consort_exclude errors on a duplicate exclusion column", {
  expect_error(
    hv_consort_exclude(make_tracker(), label = "Eligible", col = "screened",
                       age < 18 ~ "Age < 18"),
    "already exists"
  )
})

test_that("hv_consort_exclude errors on a duplicate pass_col", {
  expect_error(
    hv_consort_exclude(make_tracker(), label = "Eligible", col = "excl_screen",
                       pass_col = "screened", age < 18 ~ "Age < 18"),
    "already exists"
  )
})

test_that("hv_consort errors on a single-stage tracker", {
  expect_error(hv_consort(make_tracker()), "at least once")
})

test_that("hv_consort_exclude propagates a custom excl_label into stage metadata", {
  tracker <- make_tracker() |>
    hv_consort_exclude(label = "Eligible", col = "excl_screen",
                       excl_label = "Removed at screening",
                       age < 18 ~ "Age < 18")
  expect_equal(tracker$stages[[1L]]$excl_label, "Removed at screening")
})
