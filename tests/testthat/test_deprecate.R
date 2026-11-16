# One-release deprecations: study-specific defaults (rubric T2-D4).

test_that("hv_followup warns once when the study dates are omitted", {
  .hv_deprecate_reset()
  withr::defer(.hv_deprecate_reset())
  dta <- sample_goodness_followup_data(n = 40)
  expect_warning(hv_followup(dta), class = "hvtiPlotR_deprecated")
  expect_warning(hv_followup(dta), NA)
})

test_that("hv_followup names only the dates actually omitted", {
  .hv_deprecate_reset()
  withr::defer(.hv_deprecate_reset())
  dta <- sample_goodness_followup_data(n = 40)
  w <- tryCatch(
    hv_followup(dta, origin_year = 1990, study_start = as.Date("1990-01-01"),
                study_end = as.Date("2019-12-31")),
    hvtiPlotR_deprecated = function(w) conditionMessage(w)
  )
  expect_match(w, "^hv_followup\\(\\): `close_date` is study-specific")
  expect_no_match(w, "study_end")
})

test_that("hv_followup is silent when every study date is given", {
  .hv_deprecate_reset()
  withr::defer(.hv_deprecate_reset())
  dta <- sample_goodness_followup_data(n = 40)
  expect_no_warning(
    hv_followup(dta, origin_year = 1990, study_start = as.Date("1990-01-01"),
                study_end = as.Date("2019-12-31"),
                close_date = as.Date("2021-08-06"))
  )
})

test_that("hv_mirror_hist warns when the study's arm names are relied on", {
  .hv_deprecate_reset()
  withr::defer(.hv_deprecate_reset())
  df <- sample_mirror_histogram_data(60)
  expect_warning(hv_mirror_hist(df), "group_labels", class = "hvtiPlotR_deprecated")
  .hv_deprecate_reset()
  expect_no_warning(hv_mirror_hist(df, group_col = "tavr",
                                   group_labels = c("Control", "Treated")))
})
