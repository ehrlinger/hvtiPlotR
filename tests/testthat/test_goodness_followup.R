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
# goodness_followup — returns a ggplot (death panel)
# ---------------------------------------------------------------------------

test_that("goodness_followup returns a ggplot", {
  expect_s3_class(goodness_followup(make_gfup_data()), "ggplot")
})

test_that("goodness_followup is composable with + operator", {
  p <- goodness_followup(make_gfup_data()) +
    ggplot2::scale_color_manual(values = c("Alive" = "blue", "Dead" = "red"),
                                name = NULL)
  expect_s3_class(p, "ggplot")
})

test_that("goodness_followup death_levels are respected", {
  p     <- goodness_followup(make_gfup_data(), death_levels = c("Alive", "Dead"))
  layer <- p$layers[[1]]
  # The state factor was built with the requested levels; they should appear in plot data
  expect_true(all(levels(p$data$state) %in% c("Alive", "Dead")))
})

test_that("goodness_followup contains geom_point, geom_segment, and geom_line", {
  p           <- goodness_followup(make_gfup_data())
  layer_geoms <- vapply(p$layers, function(l) class(l$geom)[1], character(1))
  expect_true("GeomPoint"   %in% layer_geoms)
  expect_true("GeomSegment" %in% layer_geoms)
  expect_true("GeomLine"    %in% layer_geoms)
})

test_that("goodness_followup operation_year reflects origin_year", {
  p <- goodness_followup(make_gfup_data(), origin_year = 2000)
  expect_true(all(p$data$operation_year >= 2000))
})

test_that("goodness_followup state has exactly two levels", {
  p <- goodness_followup(make_gfup_data())
  expect_equal(nlevels(p$data$state), 2L)
})

# ---------------------------------------------------------------------------
# goodness_followup — input validation
# ---------------------------------------------------------------------------

test_that("goodness_followup errors when death_levels is not length 2", {
  expect_error(
    goodness_followup(make_gfup_data(), death_levels = c("A", "B", "C")),
    "exactly two labels"
  )
})

test_that("goodness_followup errors when alpha is out of range", {
  expect_error(goodness_followup(make_gfup_data(), alpha = 0),   "alpha")
  expect_error(goodness_followup(make_gfup_data(), alpha = 1.1), "alpha")
})

test_that("goodness_followup errors when segment_drop is negative", {
  expect_error(goodness_followup(make_gfup_data(), segment_drop = -1), "non-negative")
})

test_that("goodness_followup errors when a required column is missing", {
  dta      <- make_gfup_data()
  dta$dead <- NULL
  expect_error(goodness_followup(dta), "Missing required column")
})

test_that("goodness_followup errors when study_start is after study_end", {
  expect_error(
    goodness_followup(make_gfup_data(),
                      study_start = as.Date("2020-01-01"),
                      study_end   = as.Date("1990-01-01"),
                      close_date  = as.Date("2021-01-01")),
    "study_start"
  )
})

test_that("goodness_followup errors when close_date is before study_end", {
  expect_error(
    goodness_followup(make_gfup_data(),
                      study_start = as.Date("1990-01-01"),
                      study_end   = as.Date("2020-01-01"),
                      close_date  = as.Date("2019-01-01")),
    "close_date"
  )
})

# ---------------------------------------------------------------------------
# goodness_event_plot — returns a ggplot (event panel)
# ---------------------------------------------------------------------------

test_that("goodness_event_plot returns a ggplot", {
  p <- goodness_event_plot(make_gfup_data(),
                           event_col      = "ev_event",
                           event_time_col = "iv_event")
  expect_s3_class(p, "ggplot")
})

test_that("goodness_event_plot is composable with + operator", {
  p <- goodness_event_plot(make_gfup_data(),
                           event_col      = "ev_event",
                           event_time_col = "iv_event") +
    ggplot2::scale_color_manual(
      values = c("No event" = "blue", "Non-fatal event" = "green3", "Death" = "red"),
      name   = NULL
    )
  expect_s3_class(p, "ggplot")
})

test_that("goodness_event_plot state has exactly three levels", {
  p <- goodness_event_plot(make_gfup_data(),
                           event_col      = "ev_event",
                           event_time_col = "iv_event")
  expect_equal(nlevels(p$data$state), 3L)
})

test_that("goodness_event_plot event_levels are respected", {
  lvls <- c("No event", "Relapse", "Death")
  p    <- goodness_event_plot(make_gfup_data(),
                              event_col      = "ev_event",
                              event_time_col = "iv_event",
                              event_levels   = lvls)
  expect_equal(levels(p$data$state), lvls)
})

test_that("goodness_event_plot uses death_for_event_col", {
  p <- goodness_event_plot(make_gfup_data(),
                           event_col           = "ev_event",
                           event_time_col      = "iv_event",
                           death_for_event_col = "deads")
  expect_s3_class(p, "ggplot")
  expect_equal(nlevels(p$data$state), 3L)
})

test_that("goodness_event_plot contains geom_point, geom_segment, and geom_line", {
  p           <- goodness_event_plot(make_gfup_data(),
                                     event_col      = "ev_event",
                                     event_time_col = "iv_event")
  layer_geoms <- vapply(p$layers, function(l) class(l$geom)[1], character(1))
  expect_true("GeomPoint"   %in% layer_geoms)
  expect_true("GeomSegment" %in% layer_geoms)
  expect_true("GeomLine"    %in% layer_geoms)
})

test_that("goodness_followup and goodness_event_plot use the same diagonal geometry", {
  dta  <- make_gfup_data()
  p_d  <- goodness_followup(dta)
  p_e  <- goodness_event_plot(dta, event_col = "ev_event", event_time_col = "iv_event")
  # Both plots should have a GeomLine layer (the diagonal)
  has_line <- function(p) {
    any(vapply(p$layers, function(l) inherits(l$geom, "GeomLine"), logical(1)))
  }
  expect_true(has_line(p_d))
  expect_true(has_line(p_e))
})

test_that("goodness_event_plot and goodness_followup produce distinct plots", {
  dta <- make_gfup_data()
  p_d <- goodness_followup(dta)
  p_e <- goodness_event_plot(dta, event_col = "ev_event", event_time_col = "iv_event")
  # Event panel has 3-level state; death panel has 2-level state
  expect_false(identical(nlevels(p_d$data$state), nlevels(p_e$data$state)))
})

# ---------------------------------------------------------------------------
# goodness_event_plot — input validation
# ---------------------------------------------------------------------------

test_that("goodness_event_plot errors when event_col is not supplied", {
  expect_error(
    goodness_event_plot(make_gfup_data(), event_time_col = "iv_event"),
    "event_col"
  )
})

test_that("goodness_event_plot errors when event_time_col is not supplied", {
  expect_error(
    goodness_event_plot(make_gfup_data(), event_col = "ev_event"),
    "event_time_col"
  )
})

test_that("goodness_event_plot errors when event_levels is not length 3", {
  expect_error(
    goodness_event_plot(make_gfup_data(),
                        event_col      = "ev_event",
                        event_time_col = "iv_event",
                        event_levels   = c("A", "B")),
    "exactly three labels"
  )
})

test_that("goodness_event_plot errors when a required column is missing", {
  expect_error(
    goodness_event_plot(make_gfup_data(),
                        event_col      = "nonexistent",
                        event_time_col = "iv_event"),
    "Missing required column"
  )
})

test_that("goodness_event_plot errors when alpha is out of range", {
  expect_error(
    goodness_event_plot(make_gfup_data(),
                        event_col = "ev_event", event_time_col = "iv_event",
                        alpha = 0),
    "alpha"
  )
})
