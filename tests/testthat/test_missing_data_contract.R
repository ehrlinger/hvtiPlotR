# Package-wide missing-data contract.
#
# Two shapes, deliberately different:
#   * analysis constructors EXCLUDE incomplete rows (the fit already has, so
#     reporting a cohort the fit never saw would be wrong) -- covered in
#     test_kaplan_meier.R / test_goodness_followup.R;
#   * plot constructors ACCOUNT for them (warn + record the count) but do not
#     filter, leaving ggplot2's own draw-time drop in place -- covered here.
library(testthat)

plot_constructors <- list(
  hv_trends = function(na) {
    d <- sample_trends_data(n = 60, seed = 1)
    if (na) d$value[1:3] <- NA
    hv_trends(d)
  },
  hv_spaghetti = function(na) {
    d <- sample_spaghetti_data(n_patients = 20, seed = 1)
    if (na) d$value[1:3] <- NA
    hv_spaghetti(d)
  },
  hv_stacked = function(na) {
    d <- sample_stacked_histogram_data(seed = 1)
    if (na) d$year[1:3] <- NA
    hv_stacked(d)
  },
  hv_balance = function(na) {
    d <- sample_covariate_balance_data(seed = 1)
    if (na) d$std_diff[1:3] <- NA
    hv_balance(d)
  },
  hv_longitudinal = function(na) {
    d <- sample_longitudinal_counts_data(n_patients = 30, seed = 1)
    if (na) d$count[1:3] <- NA
    hv_longitudinal(d)
  }
)

for (nm in names(plot_constructors)) {
  local({
    label <- nm
    build <- plot_constructors[[nm]]

    test_that(paste(label, "warns and records n_missing when rows are incomplete"), {
      expect_warning(obj <- build(TRUE), "have missing values")
      expect_equal(obj$meta$n_missing, 3L)
    })

    test_that(paste(label, "does NOT filter -- the rows stay in $data"), {
      complete   <- build(FALSE)
      incomplete <- suppressWarnings(build(TRUE))
      # Accounting, not filtering: row count is unchanged.
      expect_equal(nrow(incomplete$data), nrow(complete$data))
    })

    test_that(paste(label, "is silent and reports n_missing = 0 when complete"), {
      expect_no_warning(obj <- build(FALSE))
      expect_equal(obj$meta$n_missing, 0L)
    })

    test_that(paste(label, "print() surfaces the count only when non-zero"), {
      expect_output(print(suppressWarnings(build(TRUE))), "not drawn")
      expect_false(any(grepl("not drawn",
                             capture.output(print(build(FALSE))))))
    })
  })
}

# ---------------------------------------------------------------------------
# Label / grouping columns are a different failure mode: a missing value there
# does NOT drop the row, it silently merges it into an "NA" group. So those
# error rather than being counted as "not drawn".
# ---------------------------------------------------------------------------

test_that("hv_spaghetti rejects a missing subject id", {
  d <- data.frame(time = c(0, 1, 0, 1), value = c(1, 2, 3, 4),
                  id = c("p1", "p1", "p2", NA))
  # Previously counted as n_missing, but all four rows still rendered -- the
  # NA-id row was drawn, fused with any other id-less rows into one line.
  expect_error(hv_spaghetti(d), "must not contain missing values")
})

test_that("hv_spaghetti rejects a missing colour label", {
  d <- data.frame(time = c(0, 1), value = c(1, 2), id = c("p1", "p1"),
                  grp = c("A", NA))
  expect_error(hv_spaghetti(d, colour_col = "grp"),
               "must not contain missing values")
})

test_that("hv_trends rejects a missing group label", {
  d <- data.frame(year = c(2020, 2021), value = c(1, 2), group = c("A", NA))
  expect_error(hv_trends(d), "must not contain missing values")
})

test_that("hv_stacked rejects a missing group label", {
  d <- data.frame(year = c(2020, 2021), category = c("A", NA))
  expect_error(hv_stacked(d), "must not contain missing values")
})

test_that("hv_balance rejects a missing variable or group label", {
  d <- data.frame(variable = c("Age", NA), group = c("Before", "Before"),
                  std_diff = c(1, 2))
  expect_error(hv_balance(d), "must not contain missing values")
  d2 <- data.frame(variable = c("Age", "BMI"), group = c("Before", NA),
                   std_diff = c(1, 2))
  expect_error(hv_balance(d2), "must not contain missing values")
})

test_that("a NULL grouping column is not treated as missing", {
  d <- data.frame(year = c(2020, 2020, 2021), value = c(1, 2, 3))
  expect_no_error(hv_trends(d, group_col = NULL))
  d2 <- data.frame(time = c(0, 1), value = c(1, 2), id = c("p1", "p1"))
  expect_no_error(hv_spaghetti(d2, colour_col = NULL))
})
