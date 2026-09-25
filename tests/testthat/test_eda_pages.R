# tests/testthat/test_eda_pages.R
#
# Tests for eda-pages.R: hv_eda_pages(), print.hv_eda_pages(),
# plot.hv_eda_pages(), and the alpha argument added to plot.hv_eda().
#
library(testthat)
library(ggplot2)

dta <- sample_eda_data(n = 200, seed = 42)

# sample_eda_data(): year is the x; op_years, ef, lv_mass, peak_grad are
# continuous; male, cabg, nyha, valve_morph are categorical.
cont_vars <- c("op_years", "ef", "lv_mass", "peak_grad")
cat_vars  <- c("male", "cabg", "nyha", "valve_morph")

test_that("each section keeps exactly the variables of its class, in column order", {
  cont <- hv_eda_pages(dta, x_col = "year", section = "continuous")
  pct  <- hv_eda_pages(dta, x_col = "year", section = "percent")
  cnt  <- hv_eda_pages(dta, x_col = "year", section = "count")
  expect_s3_class(cont, c("hv_eda_pages", "hv_data"))
  expect_identical(cont$data$variable, cont_vars)
  expect_identical(pct$data$variable, cat_vars)
  expect_identical(cnt$data$variable, cat_vars)
  expect_identical(cont$meta$n_other, length(cat_vars))
  expect_false("year" %in% cont$data$variable)
})

test_that("vars sets the order and the subset", {
  x <- hv_eda_pages(dta, section = "continuous", vars = c("peak_grad", "ef", "male"))
  expect_identical(x$data$variable, c("peak_grad", "ef"))
  expect_identical(x$meta$n_other, 1L)
})

test_that("every missing variable is named in one error", {
  expect_error(
    hv_eda_pages(dta, section = "continuous", vars = c("ef", "nope1", "nope2")),
    "nope1, nope2"
  )
})

test_that("percent and count differ only in show_percent", {
  pct <- hv_eda_pages(dta, section = "percent")
  cnt <- hv_eda_pages(dta, section = "count")
  expect_true(all(vapply(pct$tables$panels, function(p) p$meta$show_percent, logical(1))))
  expect_false(any(vapply(cnt$tables$panels, function(p) p$meta$show_percent, logical(1))))
  for (v in cat_vars) {
    expect_identical(pct$tables$panels[[v]]$data, cnt$tables$panels[[v]]$data)
  }
})

test_that("a fractional x is binned by whole year for categorical sections only", {
  pct <- hv_eda_pages(dta, x_col = "op_years", section = "percent")
  expect_true(pct$meta$x_binned)
  bins <- levels(pct$tables$panels$male$data$x)
  expect_identical(bins, as.character(sort(unique(floor(dta$op_years)))))

  cont <- hv_eda_pages(dta, x_col = "op_years", section = "continuous")
  expect_false(cont$meta$x_binned)
  expect_identical(cont$tables$panels$ef$data$x, dta$op_years)
})

test_that("labels replace names where given, and names stand in where not", {
  x <- hv_eda_pages(dta, section = "percent", labels = c(male = "Male", nyha = "NYHA class"))
  expect_identical(x$data$label, c("Male", "cabg", "NYHA class", "valve_morph"))
  expect_identical(x$tables$panels$nyha$meta$y_label, "NYHA class")
  expect_error(hv_eda_pages(dta, labels = c("unnamed")), "named character")
})

test_that("pages hold ncol * nrow panels and name their variables", {
  pages <- plot(hv_eda_pages(dta, section = "continuous"), ncol = 2, nrow = 1)
  expect_length(pages, 2L)
  expect_identical(attr(pages[[1]], "variables"), cont_vars[1:2])
  expect_identical(attr(pages[[2]], "variables"), cont_vars[3:4])
  expect_s3_class(pages[[1]], "patchwork")
})

test_that("every panel on every page has data", {
  for (section in c("continuous", "percent", "count")) {
    pages <- plot(hv_eda_pages(dta, section = section), ncol = 2, nrow = 2)
    for (page in pages) {
      for (i in seq_along(attr(page, "variables"))) {
        expect_plot_has_data(page[[i]])
      }
    }
  }
})

test_that("alpha reaches the points of continuous panels", {
  pages <- plot(hv_eda_pages(dta, section = "continuous", vars = "ef"), alpha = 0.5)
  built <- ggplot2::ggplot_build(pages[[1]][[1]])
  expect_true(all(built$data[[1]]$alpha == 0.5))
  expect_error(plot(hv_eda_pages(dta, section = "continuous"), alpha = 2))
})

test_that("plot.hv_eda keeps its 0.4 point alpha by default", {
  built <- ggplot2::ggplot_build(plot(hv_eda(dta, x_col = "year", y_col = "ef")))
  expect_true(all(built$data[[1]]$alpha == 0.4))
})

test_that("a section with no variables plots as no pages", {
  x <- hv_eda_pages(dta, section = "continuous", vars = cat_vars)
  expect_identical(x$meta$n_vars, 0L)
  expect_identical(plot(x), list())
})

test_that("grid dimensions are validated", {
  x <- hv_eda_pages(dta, section = "continuous")
  expect_error(plot(x, ncol = 0), "positive whole")
  expect_error(plot(x, nrow = 1.5), "positive whole")
  expect_error(plot(x, ncol = Inf), "positive whole")
  expect_error(plot(x, nrow = NA_real_), "positive whole")
})

test_that("print summarises the section", {
  expect_output(print(hv_eda_pages(dta, x_col = "op_years", section = "count")),
                "binned by whole year")
})

# Structural snapshots rather than SVG ones: this package snapshots values with
# expect_snapshot(), and rendered SVGs differ across the CI platforms' fonts.
# Titles, layers, row counts, x bins and fill levels are what a change to the
# report figure would move.
page_structure <- function(page) {
  for (i in seq_along(attr(page, "variables"))) {
    p <- page[[i]]
    built <- ggplot2::ggplot_build(p)
    cat(sprintf("[%s] %s\n", attr(page, "variables")[i], p$labels$title))
    cat("  geoms:", paste(vapply(p$layers, function(l) class(l$geom)[1], ""), collapse = ", "), "\n")
    cat("  rows :", paste(vapply(built$data, nrow, 1L), collapse = ", "), "\n")
    if (is.factor(p$data$x)) cat("  x    :", paste(levels(p$data$x), collapse = " "), "\n")
    if (!is.null(p$data$fill)) cat("  fill :", paste(levels(p$data$fill), collapse = " "), "\n")
    cat("  y    :", p$labels$y, "\n")
  }
}

test_that("page structure is stable for each section", {
  small <- sample_eda_data(n = 60, seed = 1)
  for (section in c("continuous", "percent", "count")) {
    pages <- plot(hv_eda_pages(small, x_col = "year", section = section,
                               vars = c("ef", "peak_grad", "male", "nyha")),
                  ncol = 2, nrow = 1)
    expect_snapshot(for (page in pages) page_structure(page))
  }
})
