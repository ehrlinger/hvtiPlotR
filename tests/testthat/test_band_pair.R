# A confidence band needs both bounds. Supplying only one used to drop the
# band silently; every constructor that takes a pair now refuses it.

band_df <- data.frame(time = 1:3, estimate = c(0.9, 0.8, 0.7),
                      lo = c(0.8, 0.7, 0.6), hi = c(1, 0.9, 0.8))

test_that("hv_hazard refuses a one-sided band", {
  expect_error(hv_hazard(band_df, lower_col = "lo"),
               "hv_hazard\\(\\): supply both `lower_col` and `upper_col`")
  expect_error(hv_hazard(band_df, upper_col = "hi"), "Only `upper_col` was given")
  expect_error(hv_hazard(band_df, empirical = band_df, emp_lower_col = "lo"),
               "`emp_lower_col` and `emp_upper_col`")
})

test_that("hv_survival_difference and hv_nnt refuse a one-sided band", {
  expect_error(hv_survival_difference(band_df, lower_col = "lo"), "supply both")
  expect_error(hv_nnt(band_df, upper_col = "hi"), "supply both")
})

test_that("hv_nonparametric refuses a one-sided band", {
  expect_error(hv_nonparametric(band_df, lower_col = "lo"),
               "hv_nonparametric\\(\\): supply both")
})

test_that("the ggplot-returning helpers refuse a one-sided band", {
  expect_error(hazard_plot(band_df, lower_col = "lo"), "hazard_plot\\(\\): supply both")
  expect_error(survival_difference_plot(band_df, upper_col = "hi"), "supply both")
  expect_error(nnt_plot(band_df, lower_col = "lo"), "supply both")
})
