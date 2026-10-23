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

# Potential follow-up (years to close_date) recovered from iv_opyrs
gfup_pfup <- function(dta, origin_year = 1990, close_date = "2021-08-06") {
  op <- as.Date(paste0(origin_year, "-01-01")) + round(dta$iv_opyrs * 365.2425)
  as.numeric(as.Date(close_date) - op) / 365.2425
}

test_that("sample_goodness_followup_data has survivors lost below the diagonal", {
  dta   <- sample_goodness_followup_data(n = 300, seed = 42)
  alive <- !dta$dead
  expect_gt(sum(dta$iv_dead[alive] < gfup_pfup(dta)[alive] - 0.01), 0)
})

test_that("sample_goodness_followup_data has no follow-up past close_date", {
  dta <- sample_goodness_followup_data(n = 500)
  expect_true(all(dta$iv_dead  <= gfup_pfup(dta) + 0.01))
  expect_true(all(dta$iv_event <= gfup_pfup(dta) + 0.01))
})

test_that("sample_goodness_followup_data with no loss censors at close_date", {
  dta   <- sample_goodness_followup_data(n = 300, loss_rate = 0)
  alive <- !dta$dead
  expect_equal(dta$iv_dead[alive], gfup_pfup(dta)[alive], tolerance = 0.01)
})

test_that("sample_goodness_followup_data errors on negative loss_rate", {
  expect_error(sample_goodness_followup_data(loss_rate = -1), "non-negative")
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
  expect_output(print(gf), "2 analyzed of 3 input")
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
  expect_output(print(gf), "Event panel : 2 analyzed; 1 excluded")
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
    warning = function(x) {
      w <<- c(w, conditionMessage(x))
      invokeRestart("muffleWarning")
    }
  )
  expect_true(any(grepl("death panel", w)))
  expect_true(any(grepl("event panel", w)))
})

test_that("no event-panel counts are reported when there is no event panel", {
  gf <- hv_followup(make_gfup_data())
  expect_null(gf$meta$n_event_patients)
  expect_null(gf$meta$n_event_excluded)
})

# ===========================================================================
# Competing non-fatal events
# ===========================================================================

# One patient per case: A first, B first, an A/B tie, an event tied with death,
# death first, and neither.
make_competing_data <- function() {
  data.frame(
    iv_opyrs = rep(5, 6),
    iv_dead  = c(9, 9, 9, 3, 1, 8),
    dead     = c(FALSE, FALSE, FALSE, TRUE, TRUE, FALSE),
    iv_a     = c(2, 6, 4, 3, 1, 8),
    ev_a     = c(TRUE, TRUE, TRUE, FALSE, FALSE, FALSE),
    iv_b     = c(5, 3, 4, 3, 2, 8),
    ev_b     = c(TRUE, TRUE, TRUE, TRUE, TRUE, FALSE)
  )
}

competing_levels <- c("No event", "Reop", "Stroke", "Death")

test_that("competing events: the first qualifying event sets the state", {
  gf <- hv_followup(make_competing_data(),
                    event_col = c("ev_a", "ev_b"), event_time_col = c("iv_a", "iv_b"),
                    event_levels = competing_levels)
  ed <- gf$tables$event_data
  expect_identical(levels(ed$state), competing_levels)
  expect_identical(as.character(ed$state),
                   c("Reop", "Stroke", "Reop", "Death", "Death", "No event"))
})

test_that("competing events: y is the winning event's time, else the first event's", {
  gf <- hv_followup(make_competing_data(),
                    event_col = c("ev_a", "ev_b"), event_time_col = c("iv_a", "iv_b"),
                    event_levels = competing_levels)
  expect_identical(gf$tables$event_data$follow_up, c(2, 3, 4, 3, 1, 8))
})

test_that("competing events: one event in a vector matches the scalar call", {
  d <- make_competing_data()
  scalar <- hv_followup(d, event_col = "ev_a", event_time_col = "iv_a")
  expect_identical(scalar$tables$event_data,
                   hv_followup(d, event_col = c(ev_a = "ev_a"), event_time_col = "iv_a")$tables$event_data)
})

test_that("competing events: the panel plots every patient", {
  gf <- hv_followup(make_competing_data(),
                    event_col = c("ev_a", "ev_b"), event_time_col = c("iv_a", "iv_b"),
                    event_levels = competing_levels)
  p <- plot(gf, type = "event")
  expect_plot_has_data(p, min_groups = 4L)
  expect_identical(layer_row_counts(p)[[1L]], 6L)
})

test_that("competing events: mismatched vectors and levels stop", {
  d <- make_competing_data()
  expect_error(hv_followup(d, event_col = c("ev_a", "ev_b"), event_time_col = "iv_a",
                           event_levels = competing_levels),
               "same length")
  expect_error(hv_followup(d, event_col = c("ev_a", "ev_b"), event_time_col = c("iv_a", "iv_b")),
               "four labels")
  expect_error(hv_followup(d, event_col = c("ev_a", "ev_b"), event_time_col = c("iv_a", "iv_b"),
                           event_levels = c("No event", "Reop", "Reop", "Death")),
               "distinct")
})

# ===========================================================================
# Echo layer
# ===========================================================================

test_that("no echo layer by default", {
  gf <- hv_followup(make_gfup_data())
  expect_null(gf$tables$echo_data)
  expect_false("GeomPoint" %in% geom_classes(plot(gf))[-1])
})

test_that("one echo per patient: a tick per patient with an echo, NA is no echo", {
  d <- make_gfup_data()
  d$iv_echo <- d$iv_dead / 2
  d$iv_echo[1:3] <- NA
  gf <- expect_silent(hv_followup(d, echo_time_col = "iv_echo"))
  expect_identical(gf$meta$n_patients, nrow(d))
  expect_identical(gf$meta$n_echo, nrow(d) - 3L)
  expect_identical(gf$meta$n_no_echo, 3L)
  expect_identical(names(gf$tables$echo_data), c("operation_year", "follow_up"))
  expect_equal(gf$tables$echo_data$follow_up, d$iv_echo[-(1:3)])
  p <- plot(gf)
  expect_plot_has_data(p)
  expect_identical(layer_row_counts(p)[[1L]], nrow(d))
  expect_identical(layer_row_counts(p)[[length(p$layers)]], nrow(d) - 3L)
})

test_that("every echo: one tick per complete echo row; incomplete rows warn", {
  d <- make_gfup_data()
  echo <- data.frame(iv_opyrs = rep(d$iv_opyrs[1:4], each = 3),
                     iv_echo  = rep(c(0.1, 1, 2), 4))
  echo$iv_echo[2] <- NA
  expect_warning(gf <- hv_followup(d, echo = echo, echo_time_col = "iv_echo"), "echo")
  expect_identical(gf$meta$n_echo, 11L)
  expect_identical(gf$meta$n_echo_excluded, 1L)
  expect_equal(gf$tables$echo_data$operation_year, 1990 + echo$iv_opyrs[-2])
  p <- plot(gf)
  expect_identical(layer_row_counts(p)[[length(p$layers)]], 11L)
  expect_identical(length(plot(gf, echo = FALSE)$layers), length(p$layers) - 1L)
})

test_that("echo reaches the event panel and errors name missing columns", {
  d <- make_gfup_data()
  d$iv_echo <- d$iv_dead / 2
  gf <- hv_followup(d, event_col = "ev_event", event_time_col = "iv_event", echo_time_col = "iv_echo")
  p <- plot(gf, type = "event")
  expect_identical(layer_row_counts(p)[[length(p$layers)]], nrow(d))
  expect_error(hv_followup(d, echo_time_col = "nope"), "nope")
  expect_error(hv_followup(d, echo = data.frame(x = 1), echo_time_col = "iv_echo"), "iv_echo")
  expect_error(hv_followup(d, echo = data.frame(iv_echo = 1)), "echo_time_col")
})

test_that("print names the echo column and its source", {
  d <- make_gfup_data()
  d$iv_echo <- d$iv_dead / 2
  expect_output(print(hv_followup(d, echo_time_col = "iv_echo")),
                "iv_echo, 80 echo\\(es\\) drawn \\(one per patient\\)")
  echo <- data.frame(iv_opyrs = d$iv_opyrs[1:4], iv_echo = 1)
  expect_output(print(hv_followup(d, echo = echo, echo_time_col = "iv_echo")), "4 echo\\(es\\) drawn \\(every echo\\)")
  expect_output(print(hv_followup(d, event_col = c("ev_event", "ev_event"),
                                  event_time_col = c("iv_event", "iv_event"),
                                  event_levels = c("No event", "A", "B", "Death"))),
                "ev_event / iv_event, ev_event / iv_event")
})

test_that("the event_levels count is spelled out to ten, then given as a number", {
  d <- make_gfup_data()
  expect_error(hv_followup(d, event_col = rep("ev_event", 9), event_time_col = rep("iv_event", 9)),
               "exactly 11 labels")
})
