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
