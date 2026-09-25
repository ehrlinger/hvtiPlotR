# tests/testthat/test_followup_panels.R
#
# Tests for followup-panels.R: hv_followup_panels(), print.hv_followup_panels(),
# plot.hv_followup_panels().
#
library(testthat)
library(ggplot2)

dta <- sample_goodness_followup_data(n = 150, seed = 7)
all_deaths <- list(all = list(status = "dead", time = "iv_dead", title = "All deaths"))
ev <- list(ev = list(event = "ev_event", time = "iv_event", death = "deads",
                     death_time = "iv_dead", label = "Non-fatal event"))

test_that("one hv_followup per panel, death panels first, with counts", {
  fp <- hv_followup_panels(dta, origin_year = 1990, panels = all_deaths, events = ev)
  expect_s3_class(fp, c("hv_followup_panels", "hv_data"))
  expect_identical(fp$data$panel, c("all", "ev"))
  expect_identical(fp$data$type, c("followup", "event"))
  expect_identical(fp$data$title, c("All deaths", "Non-fatal event"))
  expect_s3_class(fp$tables$panels$all, "hv_followup")
  expect_identical(fp$data$n_drawn[1], fp$tables$panels$all$meta$n_patients)
  expect_identical(fp$data$n_drawn[2], fp$tables$panels$ev$meta$n_event_patients)
})

test_that("the window starts on 1 January of the origin and ends at the last operation", {
  fp <- hv_followup_panels(dta, origin_year = 1990, panels = all_deaths)
  expect_identical(fp$meta$study_start, as.Date("1990-01-01"))
  expect_identical(fp$meta$study_end, as.Date("1990-01-01") + round(max(dta$iv_opyrs) * 365.2425))
  expect_identical(fp$tables$panels$all$meta$study_start, fp$meta$study_start)
})

test_that("a NULL close date is estimated and says so; a given one is used", {
  fp <- hv_followup_panels(dta, origin_year = 1990, panels = all_deaths)
  reach <- max(dta$iv_opyrs + dta$iv_dead, na.rm = TRUE)
  expect_identical(fp$meta$close_date, max(fp$meta$study_end, as.Date("1990-01-01") + round(reach * 365.2425)))
  expect_match(fp$meta$close_source, "estimated")
  fp <- hv_followup_panels(dta, origin_year = 1990, panels = all_deaths, close_date = "2023-01-01")
  expect_identical(fp$meta$close_date, as.Date("2023-01-01"))
  expect_match(fp$meta$close_source, "set in close_date")
  expect_error(hv_followup_panels(dta, origin_year = 1990, panels = all_deaths, close_date = "2000-01-01"),
               "before the last operation")
  expect_error(hv_followup_panels(dta, origin_year = 1990, panels = all_deaths, close_date = "not a date"),
               "one date")
})

test_that("every missing column is named in one error", {
  bad <- list(all = list(status = "nope1", time = "nope2"))
  expect_error(hv_followup_panels(dta, origin_year = 1990, panels = bad),
               "not in the data: nope1, nope2")
})

test_that("a name used twice across panels and events is an error", {
  twice <- list(all = ev$ev)
  expect_error(hv_followup_panels(dta, origin_year = 1990, panels = all_deaths, events = twice),
               "all is used twice")
})

test_that("the wrong-origin mistake stops rather than sliding the axis", {
  expect_error(hv_followup_panels(dta, origin_year = 85, panels = all_deaths), "Check `origin_year`")
  expect_error(hv_followup_panels(dta, origin_year = 2020, panels = all_deaths), "Check `origin_year`")
  neg <- transform(dta, iv_opyrs = iv_opyrs - 1)
  expect_error(hv_followup_panels(neg, origin_year = 1990, panels = all_deaths), "negative")
  expect_error(hv_followup_panels(dta, origin_year = 1990.5, panels = all_deaths), "whole calendar year")
})

test_that("panel and event entries and column types are validated", {
  expect_error(hv_followup_panels(dta, origin_year = 1990, panels = list()), "at least one")
  expect_error(hv_followup_panels(dta, origin_year = 1990, panels = list(all = list(status = "dead"))),
               "needs one `status` and one `time`")
  expect_error(hv_followup_panels(dta, origin_year = 1990, panels = all_deaths,
                                  events = list(ev = list(event = "ev_event"))), "needs one `event`")
  expect_error(hv_followup_panels(transform(dta, dead = as.integer(dead) * 2L), origin_year = 1990,
                                  panels = all_deaths), "1/0 or logical: dead")
  expect_error(hv_followup_panels(transform(dta, iv_dead = as.character(iv_dead)), origin_year = 1990,
                                  panels = all_deaths), "numeric years: iv_dead")
})

test_that("plot returns one named, bare ggplot per panel, each with data", {
  fp <- hv_followup_panels(dta, origin_year = 1990, panels = all_deaths, events = ev)
  plots <- plot(fp)
  expect_named(plots, c("all", "ev"))
  for (p in plots) expect_plot_has_data(p)
  built <- ggplot2::ggplot_build(plots$all)
  point_layer <- which(vapply(plots$all$layers, function(l) inherits(l$geom, "GeomPoint"), logical(1)))
  expect_true(all(built$data[[point_layer[1]]]$alpha == 0.5))
  expect_setequal(levels(plots$ev$data$state), c("No event", "Non-fatal event", "Death"))
  expect_error(plot(fp, alpha = 2))
})

test_that("print summarises the window and the close date", {
  fp <- hv_followup_panels(dta, origin_year = 1990, panels = all_deaths)
  expect_output(print(fp), "Close date  : .*estimated")
})
