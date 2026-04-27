# Full test suite for spaghetti-plot.R:
#   sample_spaghetti_data, hv_spaghetti, print.hv_spaghetti,
#   plot.hv_spaghetti
#
# The smoke tests in test_new_plots.R verify basic constructor/plot return
# types.  This file adds depth: $meta slot contents, print output,
# all plot.hv_spaghetti parameters, and edge cases.

library(hvtiPlotR)

# ---------------------------------------------------------------------------
# Shared fixtures
# ---------------------------------------------------------------------------

dta_grp <- sample_spaghetti_data(n_patients = 80, seed = 1L)
dta_one <- sample_spaghetti_data(n_patients = 60, seed = 2L)  # used without colour

# ---------------------------------------------------------------------------
# hv_spaghetti — $meta slot
# ---------------------------------------------------------------------------

test_that("hv_spaghetti $meta contains all expected keys", {
  sp <- hv_spaghetti(dta_grp, colour_col = "group")
  expect_named(sp$meta,
    c("x_col", "y_col", "id_col", "colour_col", "n_subjects", "n_obs"),
    ignore.order = TRUE
  )
})

test_that("hv_spaghetti $meta$n_obs equals nrow(data)", {
  sp <- hv_spaghetti(dta_grp)
  expect_equal(sp$meta$n_obs, nrow(dta_grp))
})

test_that("hv_spaghetti $meta$n_subjects equals number of unique ids", {
  sp <- hv_spaghetti(dta_grp)
  expect_equal(sp$meta$n_subjects, length(unique(dta_grp$id)))
})

test_that("hv_spaghetti $meta$colour_col is NULL when not supplied", {
  sp <- hv_spaghetti(dta_grp)
  expect_null(sp$meta$colour_col)
})

test_that("hv_spaghetti $meta$colour_col is set when supplied", {
  sp <- hv_spaghetti(dta_grp, colour_col = "group")
  expect_equal(sp$meta$colour_col, "group")
})

test_that("hv_spaghetti $meta respects custom x_col / y_col / id_col", {
  df          <- dta_grp
  names(df)[names(df) == "time"]  <- "years"
  names(df)[names(df) == "value"] <- "gradient"
  names(df)[names(df) == "id"]    <- "pid"
  sp <- hv_spaghetti(df, x_col = "years", y_col = "gradient", id_col = "pid")
  expect_equal(sp$meta$x_col,  "years")
  expect_equal(sp$meta$y_col,  "gradient")
  expect_equal(sp$meta$id_col, "pid")
})

test_that("hv_spaghetti $tables is an empty list", {
  sp <- hv_spaghetti(dta_grp)
  expect_identical(sp$tables, list())
})

# ---------------------------------------------------------------------------
# hv_spaghetti — error cases
# ---------------------------------------------------------------------------

test_that("hv_spaghetti errors when id_col is absent from data", {
  dta <- dta_grp
  names(dta)[names(dta) == "id"] <- "patient_id"
  # default id_col = "id" no longer exists
  expect_error(hv_spaghetti(dta), "column")
})

test_that("hv_spaghetti errors when y_col is absent from data", {
  dta <- dta_grp
  names(dta)[names(dta) == "value"] <- "outcome"
  expect_error(hv_spaghetti(dta), "column")
})

# ---------------------------------------------------------------------------
# print.hv_spaghetti
# ---------------------------------------------------------------------------

test_that("print.hv_spaghetti produces output starting with <hv_spaghetti>", {
  sp <- hv_spaghetti(dta_grp)
  expect_output(print(sp), "<hv_spaghetti>")
})

test_that("print.hv_spaghetti shows n_subjects", {
  sp <- hv_spaghetti(dta_grp)
  expect_output(print(sp), as.character(length(unique(dta_grp$id))))
})

test_that("print.hv_spaghetti shows n_obs", {
  sp <- hv_spaghetti(dta_grp)
  expect_output(print(sp), as.character(nrow(dta_grp)))
})

test_that("print.hv_spaghetti shows x_col / y_col / id_col", {
  sp <- hv_spaghetti(dta_grp)
  expect_output(print(sp), "time")
  expect_output(print(sp), "value")
  expect_output(print(sp), "id")
})

test_that("print.hv_spaghetti shows Colour col line when colour_col is set", {
  sp <- hv_spaghetti(dta_grp, colour_col = "group")
  expect_output(print(sp), "Colour col")
  expect_output(print(sp), "group")
})

test_that("print.hv_spaghetti does NOT show Colour col line when colour_col is NULL", {
  sp  <- hv_spaghetti(dta_one)
  out <- capture.output(print(sp))
  expect_false(any(grepl("Colour col", out)))
})

test_that("print.hv_spaghetti returns x invisibly", {
  sp  <- hv_spaghetti(dta_grp)
  ret <- withVisible(print(sp))
  expect_false(ret$visible)
  expect_identical(ret$value, sp)
})

# ---------------------------------------------------------------------------
# plot.hv_spaghetti — parameter coverage
# ---------------------------------------------------------------------------

test_that("plot.hv_spaghetti add_smooth=TRUE with colour_col adds a smooth layer", {
  sp    <- hv_spaghetti(dta_grp, colour_col = "group")
  geoms <- sapply(
    plot(sp, add_smooth = TRUE)$layers,
    function(l) class(l$geom)[1]
  )
  expect_true("GeomSmooth" %in% geoms)
})

test_that("plot.hv_spaghetti smooth_se=TRUE is accepted without error", {
  sp <- hv_spaghetti(dta_grp)
  expect_s3_class(plot(sp, add_smooth = TRUE, smooth_se = TRUE), "ggplot")
})

test_that("plot.hv_spaghetti custom line_colour is accepted without error", {
  sp <- hv_spaghetti(dta_one)
  expect_s3_class(plot(sp, line_colour = "steelblue"), "ggplot")
})

test_that("plot.hv_spaghetti custom line_width is accepted without error", {
  sp <- hv_spaghetti(dta_grp)
  expect_s3_class(plot(sp, line_width = 0.5), "ggplot")
})

test_that("plot.hv_spaghetti alpha=0 is accepted (boundary)", {
  sp <- hv_spaghetti(dta_grp)
  expect_s3_class(plot(sp, alpha = 0), "ggplot")
})

test_that("plot.hv_spaghetti alpha=1 is accepted (boundary)", {
  sp <- hv_spaghetti(dta_grp)
  expect_s3_class(plot(sp, alpha = 1), "ggplot")
})

test_that("plot.hv_spaghetti invalid y_labels (unnamed) raises error", {
  sp <- hv_spaghetti(dta_one)
  # unnamed numeric vector — must error
  expect_error(plot(sp, y_labels = c(0, 1, 2, 3)), "y_labels")
})

test_that("plot.hv_spaghetti invalid y_labels (character) raises error", {
  sp <- hv_spaghetti(dta_one)
  expect_error(plot(sp, y_labels = c("None", "Mild")), "y_labels")
})

test_that("plot.hv_spaghetti smooth_method='lm' is accepted", {
  sp <- hv_spaghetti(dta_grp)
  expect_s3_class(plot(sp, add_smooth = TRUE, smooth_method = "lm"), "ggplot")
})

test_that("plot.hv_spaghetti grouped and ungrouped plots have distinct mappings", {
  p_grp <- plot(hv_spaghetti(dta_grp, colour_col = "group"))
  p_one <- plot(hv_spaghetti(dta_one))
  expect_false(identical(p_grp$layers[[1]]$mapping,
                         p_one$layers[[1]]$mapping))
})

test_that("plot.hv_spaghetti is composable with theme_hv_*", {
  sp <- hv_spaghetti(dta_grp)
  expect_s3_class(plot(sp) + theme_hv_manuscript(), "ggplot")
})
