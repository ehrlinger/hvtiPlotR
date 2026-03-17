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
  dta <- sample_goodness_followup_data()
  expect_true(all(dta$iv_opyrs >= 0))
})

test_that("sample_goodness_followup_data iv_dead is non-negative", {
  dta <- sample_goodness_followup_data()
  expect_true(all(dta$iv_dead >= 0))
})

test_that("sample_goodness_followup_data dead and deads are logical", {
  dta <- sample_goodness_followup_data()
  expect_type(dta$dead,  "logical")
  expect_type(dta$deads, "logical")
})

test_that("sample_goodness_followup_data deads is a subset of dead", {
  dta <- sample_goodness_followup_data(n = 500)
  # Every patient with deads=TRUE must also have dead=TRUE
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
  expect_error(sample_goodness_followup_data(event_rate = 0),  "positive number")
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

test_that("sample_goodness_followup_data works directly with goodness_followup", {
  dta <- sample_goodness_followup_data()
  result <- goodness_followup(dta)
  expect_s3_class(result$death_plot, "ggplot")
})

test_that("sample data event columns work with event panel", {
  dta <- sample_goodness_followup_data()
  result <- goodness_followup(dta,
                              event_col      = "ev_event",
                              event_time_col = "iv_event",
                              death_for_event_col = "deads")
  expect_s3_class(result$event_plot, "ggplot")
})

# ---------------------------------------------------------------------------
# Shared helper (used by remaining tests)
# ---------------------------------------------------------------------------

make_gfup_data <- function(n = 80, seed = 42) {
  sample_goodness_followup_data(n = n, seed = seed)
}

# ---------------------------------------------------------------------------
# goodness_followup — return structure (death-only mode)
# ---------------------------------------------------------------------------

test_that("goodness_followup returns a list", {
  result <- goodness_followup(make_gfup_data())
  expect_type(result, "list")
})

test_that("goodness_followup list has expected names", {
  result <- goodness_followup(make_gfup_data())
  expect_named(result, c("death_plot", "death_data",
                         "event_plot", "event_data", "diagonal"))
})

test_that("death_plot is a ggplot object", {
  result <- goodness_followup(make_gfup_data())
  expect_s3_class(result$death_plot, "ggplot")
})

test_that("event_plot and event_data are NULL in death-only mode", {
  result <- goodness_followup(make_gfup_data())
  expect_null(result$event_plot)
  expect_null(result$event_data)
})

test_that("diagonal is a data frame with operation_year and follow_up", {
  result <- goodness_followup(make_gfup_data())
  expect_true(is.data.frame(result$diagonal))
  expect_true(all(c("operation_year", "follow_up") %in% names(result$diagonal)))
})

test_that("death_data contains required columns", {
  result <- goodness_followup(make_gfup_data())
  expect_true(all(c("operation_year", "follow_up",
                    "segment_end", "state") %in% names(result$death_data)))
})

test_that("death_data state factor has exactly two levels", {
  result <- goodness_followup(make_gfup_data())
  expect_equal(nlevels(result$death_data$state), 2L)
})

test_that("death_data state levels match death_levels argument", {
  result <- goodness_followup(make_gfup_data(),
                              death_levels = c("Alive", "Dead"))
  expect_equal(levels(result$death_data$state), c("Alive", "Dead"))
})

test_that("death_data operation_year reflects origin_year", {
  result <- goodness_followup(make_gfup_data(), origin_year = 2000)
  expect_true(all(result$death_data$operation_year >= 2000))
})

# ---------------------------------------------------------------------------
# goodness_followup — event panel
# ---------------------------------------------------------------------------

test_that("event_plot is a ggplot when event_col is supplied", {
  result <- goodness_followup(
    make_gfup_data(),
    event_col      = "ev_event",
    event_time_col = "iv_event"
  )
  expect_s3_class(result$event_plot, "ggplot")
})

test_that("event_data is a data frame when event_col is supplied", {
  result <- goodness_followup(
    make_gfup_data(),
    event_col      = "ev_event",
    event_time_col = "iv_event"
  )
  expect_true(is.data.frame(result$event_data))
})

test_that("event_data state factor has exactly three levels", {
  result <- goodness_followup(
    make_gfup_data(),
    event_col      = "ev_event",
    event_time_col = "iv_event"
  )
  expect_equal(nlevels(result$event_data$state), 3L)
})

test_that("event_data state levels match event_levels argument", {
  lvls <- c("No event", "Relapse", "Death")
  result <- goodness_followup(
    make_gfup_data(),
    event_col      = "ev_event",
    event_time_col = "iv_event",
    event_levels   = lvls
  )
  expect_equal(levels(result$event_data$state), lvls)
})

test_that("death_for_event_col uses separate death column", {
  result <- goodness_followup(
    make_gfup_data(),
    event_col           = "ev_event",
    event_time_col      = "iv_event",
    death_for_event_col = "deads"
  )
  expect_s3_class(result$event_plot, "ggplot")
  expect_equal(nlevels(result$event_data$state), 3L)
})

test_that("event panel uses same diagonal as death panel", {
  result <- goodness_followup(
    make_gfup_data(),
    event_col      = "ev_event",
    event_time_col = "iv_event"
  )

  # Both death and event plots should contain a geom_line layer that uses
  # the same diagonal data stored in result$diagonal.
  death_layers <- result$death_plot$layers
  event_layers <- result$event_plot$layers

  death_has_diag <- vapply(
    death_layers,
    function(layer) {
      inherits(layer$geom, "GeomLine") &&
        isTRUE(all.equal(layer$data, result$diagonal))
    },
    logical(1)
  )

  event_has_diag <- vapply(
    event_layers,
    function(layer) {
      inherits(layer$geom, "GeomLine") &&
        isTRUE(all.equal(layer$data, result$diagonal))
    },
    logical(1)
  )

  expect_true(any(death_has_diag))
  expect_true(any(event_has_diag))
})

# ---------------------------------------------------------------------------
# goodness_followup — input validation
# ---------------------------------------------------------------------------

test_that("errors when death_levels is not length 2", {
  expect_error(
    goodness_followup(make_gfup_data(), death_levels = c("A", "B", "C")),
    "exactly two labels"
  )
})

test_that("errors when alpha is out of range", {
  expect_error(goodness_followup(make_gfup_data(), alpha = 0),  "alpha")
  expect_error(goodness_followup(make_gfup_data(), alpha = 1.1), "alpha")
})

test_that("errors when segment_drop is negative", {
  expect_error(goodness_followup(make_gfup_data(), segment_drop = -1),
               "non-negative")
})

test_that("errors when event_col supplied without event_time_col", {
  expect_error(
    goodness_followup(make_gfup_data(), event_col = "ev_event"),
    "event_time_col"
  )
})

test_that("errors when event_levels is not length 3", {
  expect_error(
    goodness_followup(make_gfup_data(),
                      event_col      = "ev_event",
                      event_time_col = "iv_event",
                      event_levels   = c("A", "B")),
    "exactly three labels"
  )
})

test_that("errors when a required column is missing", {
  dta <- make_gfup_data()
  dta$dead <- NULL
  expect_error(goodness_followup(dta), "Missing required column")
})

test_that("errors when event column is missing from data", {
  expect_error(
    goodness_followup(make_gfup_data(),
                      event_col      = "nonexistent",
                      event_time_col = "iv_event"),
    "Missing required column"
  )
})

test_that("errors when study_start is after study_end", {
  expect_error(
    goodness_followup(make_gfup_data(),
                      study_start = as.Date("2020-01-01"),
                      study_end   = as.Date("1990-01-01"),
                      close_date  = as.Date("2021-01-01")),
    "study_start"
  )
})

test_that("errors when close_date is before study_end", {
  expect_error(
    goodness_followup(make_gfup_data(),
                      study_start = as.Date("1990-01-01"),
                      study_end   = as.Date("2020-01-01"),
                      close_date  = as.Date("2019-01-01")),
    "close_date"
  )
})

# ---------------------------------------------------------------------------
# goodness_followup — plot layer structure
# ---------------------------------------------------------------------------

test_that("death_plot contains geom_point, geom_segment, and geom_line", {
  result      <- goodness_followup(make_gfup_data())
  layer_geoms <- vapply(result$death_plot$layers,
                        function(l) class(l$geom)[1], character(1))
  expect_true("GeomPoint"   %in% layer_geoms)
  expect_true("GeomSegment" %in% layer_geoms)
  expect_true("GeomLine"    %in% layer_geoms)
})

test_that("event_plot contains geom_point, geom_segment, and geom_line", {
  result      <- goodness_followup(make_gfup_data(),
                                   event_col      = "ev_event",
                                   event_time_col = "iv_event")
  layer_geoms <- vapply(result$event_plot$layers,
                        function(l) class(l$geom)[1], character(1))
  expect_true("GeomPoint"   %in% layer_geoms)
  expect_true("GeomSegment" %in% layer_geoms)
  expect_true("GeomLine"    %in% layer_geoms)
})
