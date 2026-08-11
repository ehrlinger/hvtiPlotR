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

test_that("plot(hv_followup) contains geom_point and geom_line", {
  p           <- plot(hv_followup(make_gfup_data()))
  layer_geoms <- vapply(p$layers, function(l) class(l$geom)[1], character(1))
  expect_true("GeomPoint" %in% layer_geoms)
  expect_true("GeomLine"  %in% layer_geoms)
})

test_that("plot(hv_followup) draws no stem segment by default", {
  p           <- plot(hv_followup(make_gfup_data()))
  layer_geoms <- vapply(p$layers, function(l) class(l$geom)[1], character(1))
  expect_false("GeomSegment" %in% layer_geoms)
})

test_that("plot(hv_followup) restores the stem when segment_drop > 0", {
  p           <- plot(hv_followup(make_gfup_data(), segment_drop = 0.2))
  layer_geoms <- vapply(p$layers, function(l) class(l$geom)[1], character(1))
  expect_true("GeomSegment" %in% layer_geoms)
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

test_that("plot(hv_followup, type='event') contains geom_point and geom_line", {
  p           <- plot(make_gfup_event(), type = "event")
  layer_geoms <- vapply(p$layers, function(l) class(l$geom)[1], character(1))
  expect_true("GeomPoint"   %in% layer_geoms)
  expect_false("GeomSegment" %in% layer_geoms)
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

# ---------------------------------------------------------------------------
# print.hv_followup coverage
# ---------------------------------------------------------------------------

test_that("print.hv_followup produces <hv_followup> header", {
  obj <- hv_followup(make_gfup_data())
  expect_output(print(obj), "<hv_followup>")
})

test_that("print.hv_followup returns x invisibly", {
  obj <- hv_followup(make_gfup_data())
  ret <- withVisible(print(obj))
  expect_false(ret$visible)
  expect_identical(ret$value, obj)
})

# ===========================================================================
# Event-panel ordering and the missing-data contract
# ===========================================================================

test_that("event panel labels death-before-event as Death, not Non-fatal event", {
  # Patient 1 dies at year 1 but carries an event flag recorded at year 2.
  # The event flag alone would label this "Non-fatal event", contradicting
  # the documented "death before non-fatal event" state.
  dta <- data.frame(
    iv_opyrs = c(5, 5, 5),
    iv_dead  = c(1, 1, 8),
    dead     = c(TRUE, TRUE, FALSE),
    iv_event = c(2, 1, 3),
    ev_event = c(TRUE, FALSE, TRUE)
  )
  gf <- hv_followup(dta, event_col = "ev_event", event_time_col = "iv_event",
                    death_for_event_col = "dead")
  state <- as.character(gf$tables$event_data$state)

  expect_equal(state[1], "Death")            # event flagged after death
  expect_equal(state[2], "Death")            # died, no event
  expect_equal(state[3], "Non-fatal event")  # event genuinely first
})

test_that("event panel keeps the event when it strictly precedes death", {
  dta <- data.frame(
    iv_opyrs = 5, iv_dead = 6, dead = TRUE,
    iv_event = 2, ev_event = TRUE
  )
  gf <- hv_followup(dta, event_col = "ev_event", event_time_col = "iv_event",
                    death_for_event_col = "dead")
  expect_equal(as.character(gf$tables$event_data$state), "Non-fatal event")
})

test_that("event panel gives ties to death", {
  dta <- data.frame(
    iv_opyrs = 5, iv_dead = 3, dead = TRUE,
    iv_event = 3, ev_event = TRUE
  )
  gf <- hv_followup(dta, event_col = "ev_event", event_time_col = "iv_event",
                    death_for_event_col = "dead")
  expect_equal(as.character(gf$tables$event_data$state), "Death")
})

test_that("hv_followup warns and reports the analyzed cohort", {
  dta <- data.frame(
    iv_opyrs = c(1, 2, 3),
    iv_dead  = c(1, 2, NA),
    dead     = c(TRUE, FALSE, TRUE)
  )
  expect_warning(gf <- hv_followup(dta), "1 of 3 row\\(s\\) excluded")
  expect_equal(gf$meta$n_patients, 2L)
  expect_equal(gf$meta$n_input, 3L)
  expect_equal(gf$meta$n_excluded, 1L)
  expect_equal(nrow(gf$data), gf$meta$n_patients)
  expect_output(print(gf), "2 analysed of 3 input")
})

test_that("hv_followup is silent when no rows are dropped", {
  expect_no_warning(gf <- hv_followup(make_gfup_data()))
  expect_equal(gf$meta$n_excluded, 0L)
  expect_equal(gf$meta$n_patients, nrow(gf$data))
})

test_that("event panel reports its own cohort when only event columns are missing", {
  # The event panel needs more columns than the death panel, so a complete
  # death record with a missing event time belongs in one panel but not the
  # other. Previously the event rows were dropped by gf_prepare_frame() with
  # no warning, and $meta described only the death panel's cohort.
  dta <- data.frame(
    iv_opyrs = c(1, 2, 3),
    iv_dead  = c(5, 6, 7),
    dead     = c(FALSE, FALSE, FALSE),
    iv_event = c(1, 2, NA),
    ev_event = c(TRUE, FALSE, TRUE)
  )
  expect_warning(
    gf <- hv_followup(dta, event_col = "ev_event", event_time_col = "iv_event"),
    "excluded from the event panel"
  )
  # Death panel keeps all three -- it does not need the event columns.
  expect_equal(gf$meta$n_patients, 3L)
  expect_equal(gf$meta$n_excluded, 0L)
  expect_equal(nrow(gf$data), 3L)
  # Event panel reports its own, smaller cohort.
  expect_equal(gf$meta$n_event_patients, 2L)
  expect_equal(gf$meta$n_event_excluded, 1L)
  expect_equal(nrow(gf$tables$event_data), gf$meta$n_event_patients)
  expect_output(print(gf), "Event panel : 2 analysed; 1 excluded")
})

test_that("each panel's exclusion warning names its own panel", {
  dta <- data.frame(
    iv_opyrs = c(1, 2, 3),
    iv_dead  = c(5, NA, 7),
    dead     = c(FALSE, FALSE, FALSE),
    iv_event = c(1, 2, NA),
    ev_event = c(TRUE, FALSE, TRUE)
  )
  w <- character()
  withCallingHandlers(
    hv_followup(dta, event_col = "ev_event", event_time_col = "iv_event"),
    warning = function(x) { w <<- c(w, conditionMessage(x))
                            invokeRestart("muffleWarning") }
  )
  expect_true(any(grepl("death panel", w)))
  expect_true(any(grepl("event panel", w)))
})

test_that("no event-panel counts are reported when there is no event panel", {
  gf <- hv_followup(make_gfup_data())
  expect_null(gf$meta$n_event_patients)
  expect_null(gf$meta$n_event_excluded)
})
