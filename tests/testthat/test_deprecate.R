# One-release deprecations: study-specific defaults (rubric T2-D4).

test_that("hv_followup warns once when the study dates are omitted", {
  local_fresh_deprecations()
  dta <- sample_goodness_followup_data(n = 40)
  expect_warning(hv_followup(dta), class = "hvtiPlotR_deprecated")
  expect_warning(hv_followup(dta), NA)
})

test_that("hv_followup names only the dates actually omitted", {
  local_fresh_deprecations()
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
  local_fresh_deprecations()
  dta <- sample_goodness_followup_data(n = 40)
  expect_no_warning(
    hv_followup(dta, origin_year = 1990, study_start = as.Date("1990-01-01"),
                study_end = as.Date("2019-12-31"),
                close_date = as.Date("2021-08-06"))
  )
})

test_that("hv_mirror_hist warns when the study's arm names are relied on", {
  local_fresh_deprecations()
  df <- sample_mirror_histogram_data(60)
  expect_warning(hv_mirror_hist(df), "group_labels", class = "hvtiPlotR_deprecated")
  .hv_deprecate_reset()
  expect_no_warning(hv_mirror_hist(df, group_col = "tavr",
                                   group_labels = c("Control", "Treated")))
})

# One-release renames (rubric: `_col`, `data` first, `file`, `linewidth`).

test_that("renamed arguments still work under their old names, once warned", {
  local_fresh_deprecations()
  dta <- data.frame(t = c(1, 2, 3, 4), e = c(1, 0, 1, 0), g = c("a", "a", "b", "b"))
  new <- hv_atrisk(dta, time_col = "t", event_col = "e", group_col = "g", report_times = 1:3)
  res <- collect_deprecations(hv_atrisk(x = dta, time = "t", status = "e", group = "g",
                                        report_times = 1:3))
  expect_length(res$warnings, 4L)
  expect_match(res$warnings[2], "`time` is renamed `time_col`")
  expect_equal(res$value$data, new$data)
  expect_error(hv_atrisk(dta, time_col = "t", time = "t"), "both were given")
})

test_that("hv_rmst_contrast and hv_rmst_curves accept the old column names", {
  local_fresh_deprecations()
  est <- data.frame(est = c("IPTW", "Overlap"), d = c(1, 2), l = c(0, 1), h = c(2, 3))
  res <- collect_deprecations(hv_rmst_contrast(est, estimator = "est", diff = "d", lo = "l", hi = "h"))
  expect_length(res$warnings, 4L)
  rc <- res$value
  expect_identical(rc$meta$estimator, "est")
  rc2 <- hv_rmst_contrast(est, estimator_col = "est", diff_col = "d", lo_col = "l", hi_col = "h")
  expect_equal(rc$data, rc2$data)

  cv <- data.frame(f = "IPTW", a = rep(c("treated", "control"), each = 2),
                   tt = c(0, 1, 0, 1), s = c(1, 0.8, 1, 0.7))
  res <- collect_deprecations(hv_rmst_curves(curves = cv, facet = "f", arm = "a", time = "tt",
                                             surv = "s"))
  expect_length(res$warnings, 5L)
  c1 <- res$value
  c2 <- hv_rmst_curves(cv, facet_col = "f", arm_col = "a", time_col = "tt", surv_col = "s")
  expect_equal(c1$data, c2$data)
})

test_that("rmst estimand labels pass through in either casing", {
  for (lab in list(c("ate", "att"), c("ATE", "ATT"))) {
    est <- data.frame(estimator = lab, diff_days = 1:2, lo_days = 0:1, hi_days = 2:3)
    expect_identical(hv_rmst_contrast(est)$meta$estimator_levels, lab)
  }
})

test_that("curve_data, diff_data, nnt_data and line_width are deprecated", {
  local_fresh_deprecations()
  hz <- sample_hazard_data(n = 50, seed = 1)
  expect_warning(h1 <- hv_hazard(curve_data = hz), class = "hvtiPlotR_deprecated")
  expect_equal(h1$data, hv_hazard(hz)$data)
  expect_warning(plot(h1, line_width = 2), class = "hvtiPlotR_deprecated")
  p <- plot(h1, linewidth = 2)
  expect_equal(ggplot2::ggplot_build(p)$data[[1]]$linewidth[1], 2)
  expect_warning(hv_nnt(nnt_data = sample_nnt_data(seed = 1)), class = "hvtiPlotR_deprecated")
  expect_warning(hv_survival_difference(diff_data = sample_survival_difference_data(seed = 1)),
                 class = "hvtiPlotR_deprecated")
})

test_that("save_ppt(powerpoint) is deprecated in favor of file", {
  local_fresh_deprecations()
  skip_if_not_installed("officer")
  skip_if_not_installed("rvg")
  out <- tempfile(fileext = ".pptx")
  on.exit(unlink(out), add = TRUE)
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
  expect_warning(res <- save_ppt(p, powerpoint = out), class = "hvtiPlotR_deprecated")
  expect_identical(res, out)
  expect_true(file.exists(out))
  expect_error(save_ppt(p, file = out, powerpoint = out), "both were given")
})

test_that("hv_followup refuses a time column where a status column belongs", {
  dta <- sample_goodness_followup_data(n = 40)
  expect_error(
    hv_followup(dta, death_time_col = "dead", death_col = "iv_dead", origin_year = 1990,
                study_start = "1990-01-01", study_end = "2019-12-31", close_date = "2021-08-06"),
    "must be logical, 0/1"
  )
  # Text that as.logical() reads is a valid status, as it was before the check.
  dta$dead <- as.character(as.logical(dta$dead))
  expect_s3_class(
    hv_followup(dta, origin_year = 1990, study_start = "1990-01-01",
                study_end = "2019-12-31", close_date = "2021-08-06"),
    "hv_data"
  )
})

# One-release renames for arguments that take one or more columns (`_cols`).

test_that("vars, axes, sets and intersect are deprecated in favor of _cols", {
  local_fresh_deprecations()
  num <- data.frame(a = c(1, 2, 3, 5), b = c(2, 1, 4, 3), c = c(9, 7, 8, 6))
  res <- collect_deprecations(hv_correlation_matrix(num, vars = c("a", "b")))
  expect_match(res$warnings, "`vars` is renamed `var_cols`")
  expect_equal(res$value$data, hv_correlation_matrix(num, var_cols = c("a", "b"))$data)
  expect_error(hv_correlation_matrix(num, var_cols = c("a", "b"), vars = c("a", "b")),
               "both were given")
  expect_warning(out <- eda_select_vars(num, vars = "a c"), class = "hvtiPlotR_deprecated")
  expect_identical(names(out), c("a", "c"))

  sets <- data.frame(s1 = c(1, 0, 1, 1), s2 = c(0, 1, 1, 1), s3 = c(1, 1, 0, 1))
  expect_warning(v <- hv_venn(sets, sets = c("s1", "s2")), class = "hvtiPlotR_deprecated")
  expect_equal(v$data, hv_venn(sets, set_cols = c("s1", "s2"))$data)
  expect_warning(u <- hv_upset(sets, intersect = c("s1", "s2", "s3")),
                 class = "hvtiPlotR_deprecated")
  expect_equal(u$data, hv_upset(sets, set_cols = c("s1", "s2", "s3"))$data)

  al <- data.frame(pre = c("A", "B"), post = c("B", "B"), freq = c(3, 4))
  expect_warning(a <- hv_alluvial(al, axes = c("pre", "post")), class = "hvtiPlotR_deprecated")
  expect_equal(a$data, hv_alluvial(al, axis_cols = c("pre", "post"))$data)
})

test_that("hv_followup's event_col and event_time_col become plural", {
  local_fresh_deprecations()
  dta <- sample_goodness_followup_data(n = 40)
  dates <- list(origin_year = 1990, study_start = "1990-01-01",
                study_end = "2019-12-31", close_date = "2021-08-06")
  res <- collect_deprecations(do.call(hv_followup, c(list(dta, event_col = "ev_event",
                                                         event_time_col = "iv_event"), dates)))
  expect_length(res$warnings, 2L)
  new <- do.call(hv_followup, c(list(dta, event_cols = "ev_event", event_time_cols = "iv_event"),
                                dates))
  expect_equal(res$value$tables$event_data, new$tables$event_data)
})
