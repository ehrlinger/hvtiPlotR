# Test suite for goodness-followup.R
library(testthat)
library(ggplot2)

# ---------------------------------------------------------------------------
# sample_goodness_followup_data
# ---------------------------------------------------------------------------

test_that("sample_goodness_followup_data returns a data frame", {
  expect_true(is.data.frame(sample_goodness_followup_data()))
})

test_that("sample_goodness_followup_data has required columns", {
  dta <- sample_goodness_followup_data()
  expect_true(all(c("iv_opyrs", "iv_dead", "dead",
                    "iv_event", "ev_event", "deads") %in% names(dta)))
})

test_that("sample_goodness_followup_data returns n rows", {
  expect_equal(nrow(sample_goodness_followup_data(n = 50)), 50L)
})

test_that("sample_goodness_followup_data is reproducible with same seed", {
  d1 <- sample_goodness_followup_data(seed = 7)
  d2 <- sample_goodness_followup_data(seed = 7)
  expect_identical(d1, d2)
})

test_that("sample_goodness_followup_data differs with different seeds", {
  d1 <- sample_goodness_followup_data(seed = 1)
  d2 <- sample_goodness_followup_data(seed = 2)
  expect_false(identical(d1, d2))
})

test_that("sample_goodness_followup_data iv_opyrs is non-negative", {
  expect_true(all(sample_goodness_followup_data()$iv_opyrs >= 0))
})

test_that("sample_goodness_followup_data iv_dead is non-negative", {
  expect_true(all(sample_goodness_followup_data()$iv_dead >= 0))
})

test_that("sample_goodness_followup_data dead and deads are logical", {
  dta <- sample_goodness_followup_data()
  expect_type(dta$dead,  "logical")
  expect_type(dta$deads, "logical")
})

test_that("sample_goodness_followup_data deads is a subset of dead", {
  dta <- sample_goodness_followup_data(n = 500)
  expect_true(all(dta$dead[dta$deads]))
})

test_that("sample_goodness_followup_data higher death_rate increases deaths", {
  d_low  <- sample_goodness_followup_data(n = 500, death_rate = 0.01, seed = 1)
  d_high <- sample_goodness_followup_data(n = 500, death_rate = 0.20, seed = 1)
  expect_lt(sum(d_low$dead), sum(d_high$dead))
})

test_that("sample_goodness_followup_data errors on non-positive n", {
  expect_error(sample_goodness_followup_data(n = 0),  "positive integer")
  expect_error(sample_goodness_followup_data(n = -1), "positive integer")
})

test_that("sample_goodness_followup_data errors on non-positive death_rate", {
  expect_error(sample_goodness_followup_data(death_rate = 0),  "positive number")
  expect_error(sample_goodness_followup_data(death_rate = -1), "positive number")
})

test_that("sample_goodness_followup_data errors on non-positive event_rate", {
  expect_error(sample_goodness_followup_data(event_rate = 0), "positive number")
})

test_that("sample_goodness_followup_data errors when study_start >= study_end", {
  expect_error(
    sample_goodness_followup_data(study_start = "2020-01-01",
                                  study_end   = "1990-01-01"),
    "before"
  )
})

test_that("sample_goodness_followup_data errors when close_date < study_end", {
  expect_error(
    sample_goodness_followup_data(study_end  = "2019-12-31",
                                  close_date = "2018-01-01"),
    "after"
  )
})

# ---------------------------------------------------------------------------
# Shared helper
# ---------------------------------------------------------------------------

make_gfup_data <- function(n = 80, seed = 42) {
  sample_goodness_followup_data(n = n, seed = seed)
}

# ---------------------------------------------------------------------------
# hv_followup — returns an hv_data object; plot() returns a ggplot
# ---------------------------------------------------------------------------

test_that("hv_followup returns an hv_data object", {
  expect_s3_class(hv_followup(make_gfup_data()), "hv_data")
})

test_that("plot(hv_followup) returns a ggplot", {
  expect_s3_class(plot(hv_followup(make_gfup_data())), "ggplot")
})

test_that("plot(hv_followup) is composable with + operator", {
  p <- plot(hv_followup(make_gfup_data())) +
    ggplot2::scale_color_manual(values = c("Alive" = "blue", "Dead" = "red"),
                                name = NULL)
  expect_s3_class(p, "ggplot")
})

test_that("hv_followup death_levels are respected in plot", {
  gf <- hv_followup(make_gfup_data(), death_levels = c("Alive", "Dead"))
  p  <- plot(gf)
  expect_true(all(levels(p$data$state) %in% c("Alive", "Dead")))
})

test_that("plot(hv_followup) contains geom_point, geom_segment, and geom_line", {
  p           <- plot(hv_followup(make_gfup_data()))
  layer_geoms <- vapply(p$layers, function(l) class(l$geom)[1], character(1))
  expect_true("GeomPoint"   %in% layer_geoms)
  expect_true("GeomSegment" %in% layer_geoms)
  expect_true("GeomLine"    %in% layer_geoms)
})

test_that("hv_followup origin_year is reflected in plot operation_year", {
  gf <- hv_followup(make_gfup_data(), origin_year = 2000)
  p  <- plot(gf)
  expect_true(all(p$data$operation_year >= 2000))
})

test_that("plot(hv_followup) state has exactly two levels", {
  p <- plot(hv_followup(make_gfup_data()))
  expect_equal(nlevels(p$data$state), 2L)
})

# ---------------------------------------------------------------------------
# hv_followup — input validation (errors fire in constructor)
# ---------------------------------------------------------------------------

test_that("hv_followup errors when death_levels is not length 2", {
  expect_error(
    hv_followup(make_gfup_data(), death_levels = c("A", "B", "C")),
    "exactly two labels"
  )
})

test_that("plot.hv_followup errors when alpha is out of range", {
  gf <- hv_followup(make_gfup_data())
  expect_error(plot(gf, alpha = -0.1), "alpha")
  expect_error(plot(gf, alpha = 1.1),  "alpha")
})

test_that("hv_followup errors when segment_drop is negative", {
  expect_error(hv_followup(make_gfup_data(), segment_drop = -1), "non-negative")
})

test_that("hv_followup errors when a required column is missing", {
  dta      <- make_gfup_data()
  dta$dead <- NULL
  expect_error(hv_followup(dta), "Missing required column")
})

test_that("hv_followup errors when study_start is after study_end", {
  expect_error(
    hv_followup(make_gfup_data(),
                  study_start = as.Date("2020-01-01"),
                  study_end   = as.Date("1990-01-01"),
                  close_date  = as.Date("2021-01-01")),
    "study_start"
  )
})

test_that("hv_followup errors when close_date is before study_end", {
  expect_error(
    hv_followup(make_gfup_data(),
                  study_start = as.Date("1990-01-01"),
                  study_end   = as.Date("2020-01-01"),
                  close_date  = as.Date("2019-01-01")),
    "close_date"
  )
})

# ---------------------------------------------------------------------------
# plot(hv_followup, type = "event") — event panel
# ---------------------------------------------------------------------------

make_gfup_event <- function(n = 80, seed = 42) {
  hv_followup(
    sample_goodness_followup_data(n = n, seed = seed),
    event_col      = "ev_event",
    event_time_col = "iv_event"
  )
}

test_that("plot(hv_followup, type='event') returns a ggplot", {
  p <- plot(make_gfup_event(), type = "event")
  expect_s3_class(p, "ggplot")
})

test_that("plot(hv_followup, type='event') is composable with + operator", {
  p <- plot(make_gfup_event(), type = "event") +
    ggplot2::scale_color_manual(
      values = c("No event" = "blue", "Non-fatal event" = "green3", "Death" = "red"),
      name   = NULL
    )
  expect_s3_class(p, "ggplot")
})

test_that("plot(hv_followup, type='event') state has exactly three levels", {
  p <- plot(make_gfup_event(), type = "event")
  expect_equal(nlevels(p$data$state), 3L)
})

test_that("hv_followup event_levels are respected in event plot", {
  lvls <- c("No event", "Relapse", "Death")
  gf   <- hv_followup(make_gfup_data(),
                         event_col      = "ev_event",
                         event_time_col = "iv_event",
                         event_levels   = lvls)
  p <- plot(gf, type = "event")
  expect_equal(levels(p$data$state), lvls)
})

test_that("hv_followup death_for_event_col is respected", {
  gf <- hv_followup(make_gfup_data(),
                       event_col           = "ev_event",
                       event_time_col      = "iv_event",
                       death_for_event_col = "deads")
  p <- plot(gf, type = "event")
  expect_s3_class(p, "ggplot")
  expect_equal(nlevels(p$data$state), 3L)
})

test_that("plot(hv_followup, type='event') contains geom_point, geom_segment, and geom_line", {
  p           <- plot(make_gfup_event(), type = "event")
  layer_geoms <- vapply(p$layers, function(l) class(l$geom)[1], character(1))
  expect_true("GeomPoint"   %in% layer_geoms)
  expect_true("GeomSegment" %in% layer_geoms)
  expect_true("GeomLine"    %in% layer_geoms)
})

test_that("followup and event plots both have a GeomLine (diagonal)", {
  dta <- make_gfup_data()
  gf  <- hv_followup(dta,
                        event_col      = "ev_event",
                        event_time_col = "iv_event")
  p_d <- plot(gf, type = "followup")
  p_e <- plot(gf, type = "event")
  has_line <- function(p) {
    any(vapply(p$layers, function(l) inherits(l$geom, "GeomLine"), logical(1)))
  }
  expect_true(has_line(p_d))
  expect_true(has_line(p_e))
})

test_that("event and followup plots produce distinct state factor structures", {
  gf  <- make_gfup_event()
  p_d <- plot(gf, type = "followup")
  p_e <- plot(gf, type = "event")
  expect_false(identical(nlevels(p_d$data$state), nlevels(p_e$data$state)))
})

# ---------------------------------------------------------------------------
# hv_followup — event panel input validation
# ---------------------------------------------------------------------------

test_that("plot.hv_followup type='event' errors when event_col not supplied", {
  gf <- hv_followup(make_gfup_data())   # no event_col
  expect_error(plot(gf, type = "event"), "event_col")
})

test_that("hv_followup errors when event_col supplied without event_time_col", {
  expect_error(
    hv_followup(make_gfup_data(), event_col = "ev_event"),
    "event_time_col"
  )
})

test_that("hv_followup errors when event_levels is not length 3", {
  expect_error(
    hv_followup(make_gfup_data(),
                  event_col      = "ev_event",
                  event_time_col = "iv_event",
                  event_levels   = c("A", "B")),
    "exactly three labels"
  )
})

test_that("hv_followup errors when event_col is absent from data", {
  expect_error(
    hv_followup(make_gfup_data(),
                  event_col      = "nonexistent",
                  event_time_col = "iv_event"),
    "Missing required column"
  )
})

test_that("plot.hv_followup type='event' errors when alpha is out of range", {
  gf <- make_gfup_event()
  expect_error(plot(gf, type = "event", alpha = -0.1), "alpha")
})
