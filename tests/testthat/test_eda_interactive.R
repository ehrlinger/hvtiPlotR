# tests/testthat/test_eda_interactive.R
#
# Hover labels on categorical EDA panels: plot.hv_eda(interactive = ),
# .eda_tooltips() and hv_girafe().
#
library(testthat)

dta <- sample_eda_data(n = 300, seed = 42)

test_that("interactive = NULL is static outside knitr HTML output", {
  p <- plot(hv_eda(dta, x_col = "year", y_col = "nyha", show_percent = TRUE))
  expect_false(inherits(p$layers[[1]]$geom, "GeomInteractiveBar"))
})

test_that("interactive is validated, and TRUE needs ggiraph", {
  ed <- hv_eda(dta, x_col = "year", y_col = "nyha")
  expect_error(plot(ed, interactive = NA), "NULL, TRUE or FALSE")
  expect_error(plot(ed, interactive = "yes"), "NULL, TRUE or FALSE")
  local_mocked_bindings(requireNamespace = function(...) FALSE, .package = "base")
  expect_error(plot(ed, interactive = TRUE), "needs the ggiraph package")
})

test_that("interactive bars draw the same as static bars", {
  skip_if_not_installed("ggiraph")
  for (show_percent in c(TRUE, FALSE)) {
    ed <- hv_eda(dta, x_col = "year", y_col = "nyha", show_percent = show_percent)
    static <- ggplot2::layer_data(plot(ed, interactive = FALSE))
    hover  <- ggplot2::layer_data(plot(ed, interactive = TRUE))
    expect_true(inherits(plot(ed, interactive = TRUE)$layers[[1]]$geom, "GeomInteractiveBar"))
    # The drawing, not the bookkeeping: hover bars are grouped by category and
    # bin, so `group` and `prop` differ while every rectangle is the same.
    drawn <- c("fill", "x", "y", "xmin", "xmax", "ymin", "ymax", "count", "PANEL")
    expect_equal(hover[drawn], static[drawn])
  }
})

test_that("tooltips survive a category that spans several bins", {
  skip_if_not_installed("ggiraph")
  expect_no_warning(
    tips <- ggplot2::layer_data(plot(hv_eda(dta, x_col = "year", y_col = "nyha"), interactive = TRUE))$tooltip
  )
  expect_false(anyNA(tips))
  expect_true(any(startsWith(tips, "1\n2005: ")))
})

test_that("each bar's tooltip names its category, bin, count and percent", {
  skip_if_not_installed("ggiraph")
  d <- data.frame(year = c(2001, 2001, 2001, 2002), grp = c("a", "a", NA, "b"))
  pct <- ggplot2::layer_data(plot(hv_eda(d, x_col = "year", y_col = "grp", show_percent = TRUE),
                                  interactive = TRUE))
  expect_setequal(pct$tooltip, c("a\n2001: 66.7% (2 of 3)", "(Missing)\n2001: 33.3% (1 of 3)",
                                 "b\n2002: 100.0% (1 of 1)"))
  cnt <- ggplot2::layer_data(plot(hv_eda(d, x_col = "year", y_col = "grp"), interactive = TRUE))
  expect_true("a\n2001: 2 (66.7%)" %in% cnt$tooltip)
})

test_that("interactive passes through plot.hv_eda_pages and leaves continuous panels alone", {
  skip_if_not_installed("ggiraph")
  pages <- plot(hv_eda_pages(dta, section = "count"), ncol = 2, nrow = 2, interactive = TRUE)
  expect_true(all(grepl("\n", ggplot2::layer_data(pages[[1]])$tooltip, fixed = TRUE)))
  cont <- plot(hv_eda(dta, x_col = "year", y_col = "ef"), interactive = TRUE)
  expect_false(any(vapply(cont$layers, function(l) inherits(l$geom, "GeomInteractive"), logical(1))))
})

test_that("hv_girafe embeds no font files", {
  skip_if_not_installed("ggiraph")
  page <- plot(hv_eda_pages(dta, section = "percent"), ncol = 2, nrow = 2, interactive = TRUE)[[1]]
  w <- hv_girafe(page, width = 6.5, height = 6)
  expect_s3_class(w, "girafe")
  expect_length(w$dependencies, 0L)
  expect_match(w$x$html, "2010: [0-9.]+% \\([0-9]+ of [0-9]+\\)")
})

# Two bins whose level order is the reverse of the order a scale might impose.
two_bins <- data.frame(year = factor(c("early", "early", "early", "late"), levels = c("early", "late")),
                       grp  = c("a", "a", "b", "b"))

test_that("tooltips name the right bin when a scale reorders the bins", {
  skip_if_not_installed("ggiraph")
  p <- plot(hv_eda(two_bins, x_col = "year", y_col = "grp"), interactive = TRUE) +
    ggplot2::scale_x_discrete(limits = c("late", "early"))
  ld <- ggplot2::layer_data(p)
  # "late" is drawn first now; its one bar must still say "late".
  expect_identical(ld$tooltip[ld$x == 1], "b\nlate: 1 (100.0%)")
  expect_setequal(ld$tooltip[ld$x == 2], c("a\nearly: 2 (66.7%)", "b\nearly: 1 (33.3%)"))
})

test_that("tooltips name the right bin when a scale drops a bin", {
  skip_if_not_installed("ggiraph")
  p <- plot(hv_eda(two_bins, x_col = "year", y_col = "grp"), interactive = TRUE) +
    ggplot2::scale_x_discrete(limits = "late")
  ld <- suppressWarnings(ggplot2::layer_data(p))
  ld <- ld[!is.na(ld$x), ]
  expect_identical(ld$tooltip, "b\nlate: 1 (100.0%)")
})

test_that("percent tooltips take the bin total within each facet panel", {
  skip_if_not_installed("ggiraph")
  d <- data.frame(year = 2001, grp = c("a", "a", "a", "b"))
  p <- plot(hv_eda(d, x_col = "year", y_col = "grp", show_percent = TRUE), interactive = TRUE) +
    ggplot2::facet_wrap(~fill)
  ld <- ggplot2::layer_data(p)
  # Each panel draws its bar at 100%, and its tooltip says so.
  expect_equal(ld$ymax - ld$ymin, c(1, 1))
  expect_setequal(ld$tooltip, c("a\n2001: 100.0% (3 of 3)", "b\n2001: 100.0% (1 of 1)"))
})

test_that("hv_girafe works with a ggiraph too old for font_set, and says what it costs", {
  skip_if_not_installed("ggiraph")
  local_mocked_bindings(.ggiraph_has_font_set = function() FALSE)
  page <- plot(hv_eda(dta, x_col = "year", y_col = "nyha"), interactive = TRUE)
  expect_warning(w <- hv_girafe(page, width = 4, height = 3), "embeds its fonts")
  expect_s3_class(w, "girafe")
})
